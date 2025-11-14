# Content-Type 头部修复

## 问题描述

用户在调用本地 API 时遇到 HTTP 415 错误（Unsupported Media Type）：

```sql
SELECT http_post(
    'http://localhost:3002/api/Crawl',
    '{"models": ["STM32F103C8T6"], "useCache": true, "retryTimes": 3}'
);
```

**错误响应**：
```json
{
    "type": "https://tools.ietf.org/html/rfc9110#section-15.5.16",
    "title": "Unsupported Media Type",
    "status": 415,
    "traceId": "00-145cf63aac0b87f1ffddb4c508da8aa0-2a364abc1d9e437d-00"
}
```

## 根本原因

HTTP 415 错误表示服务器无法处理请求的 Content-Type。

**分析**：
1. 现代 RESTful API 要求 POST 请求必须包含 `Content-Type` 头
2. 发送 JSON 数据时，需要指定 `Content-Type: application/json`
3. 旧版本的 `pghttp` 在发送 POST 请求时**没有自动添加** Content-Type 头
4. 服务器收到没有 Content-Type 的请求，拒绝处理并返回 415 错误

## 修复方案

### 代码改动

在 `pghttp_full.c` 的 `perform_http_request` 函数中添加自动设置 Content-Type：

```c
/* Add Content-Type header for POST/PUT requests with body */
if (body != NULL && strlen(body) > 0) {
    WinHttpAddRequestHeaders(hRequest, 
                              L"Content-Type: application/json",
                              -1, 
                              WINHTTP_ADDREQ_FLAG_ADD);
}

/* Add custom headers if provided */
if (headers_json != NULL && strlen(headers_json) > 0) {
    WCHAR *wszHeaders = char_to_wchar(headers_json);
    WinHttpAddRequestHeaders(hRequest, wszHeaders, -1, 
                              WINHTTP_ADDREQ_FLAG_ADD | WINHTTP_ADDREQ_FLAG_REPLACE);
    pfree(wszHeaders);
}
```

### 修复逻辑

1. **自动添加 Content-Type**：当 body 不为空时，自动添加 `Content-Type: application/json`
2. **支持自定义覆盖**：用户仍然可以通过 headers 参数自定义 Content-Type
3. **向后兼容**：不影响 GET 请求或没有 body 的请求

## 测试验证

### Test 1: 使用 httpbin.org 验证

```sql
-- httpbin.org 会回显请求头
SELECT 
    status_code,
    body::json->'headers'->>'Content-Type' AS content_type_sent
FROM http_request(
    'POST',
    'https://httpbin.org/post',
    '{"test":"data"}'
);
```

**预期结果**：
- status_code: 200
- content_type_sent: "application/json"

### Test 2: 实际 API 测试

```sql
SELECT http_post(
    'http://localhost:3002/api/Crawl',
    '{
  "models": ["STM32F103C8T6"],
  "useCache": true,
  "retryTimes": 3
}'
);
```

**预期结果**：
```json
{
    "code": 200,
    "message": "任务已提交",
    "data": {
        "taskId": "...",
        "status": "processing",
        "totalCount": 1
    }
}
```

### Test 3: 自定义 Content-Type

```sql
-- 仍然可以自定义 Content-Type
SELECT http_post(
    'http://example.com/api',
    'plain text data',
    'Content-Type: text/plain'
);
```

## 影响范围

### 受益场景
- ✅ 所有需要 Content-Type 的 RESTful API
- ✅ ASP.NET Core Web API
- ✅ Node.js/Express API
- ✅ Spring Boot API
- ✅ FastAPI/Flask API

### 向后兼容性
- ✅ GET 请求不受影响
- ✅ 没有 body 的请求不受影响
- ✅ 已有的自定义 headers 仍然有效
- ✅ 可以通过 headers 参数覆盖默认 Content-Type

## 部署步骤

### 本地环境更新

1. **重新编译**：
   ```powershell
   .\build_full.ps1
   ```

2. **重新加载扩展**（在 PostgreSQL 中）：
   ```sql
   DROP EXTENSION IF EXISTS pghttp CASCADE;
   CREATE EXTENSION pghttp;
   ```

3. **测试**：
   ```sql
   \i test_content_type.sql
   ```

### 分发到其他电脑

1. **重新生成发布包**：
   ```powershell
   .\create_release.ps1
   ```

2. **分发新版本 ZIP**

3. **在目标电脑上安装**：
   ```powershell
   .\install.ps1
   ```

4. **在数据库中重新创建扩展**：
   ```sql
   DROP EXTENSION IF EXISTS pghttp CASCADE;
   CREATE EXTENSION pghttp;
   ```

## API 使用指南

### 标准 JSON POST

```sql
-- 自动添加 Content-Type: application/json
SELECT http_post(
    'https://api.example.com/users',
    '{"name":"John","email":"john@example.com"}'
);
```

### 自定义 Content-Type

```sql
-- 发送 XML 数据
SELECT http_post(
    'https://api.example.com/data',
    '<data><item>value</item></data>',
    'Content-Type: application/xml'
);
```

### 多个自定义头

```sql
-- 添加多个头（未来版本支持）
-- 当前版本可以用换行符分隔（需要测试）
SELECT http_post(
    'https://api.example.com/secure',
    '{"data":"value"}',
    'Content-Type: application/json
Authorization: Bearer TOKEN123'
);
```

## 常见问题

### Q1: 为什么之前 Apifox 测试正常？
**A**: Apifox 等 API 测试工具会自动添加 Content-Type 头，而之前的 pghttp 没有自动添加。

### Q2: 所有 POST 请求都会添加 Content-Type 吗？
**A**: 只有当 body 不为空时才会添加。空 body 的 POST 请求不会添加。

### Q3: 如何发送非 JSON 数据？
**A**: 通过 headers 参数自定义 Content-Type：
```sql
SELECT http_post(url, 'data', 'Content-Type: text/plain');
```

### Q4: 是否需要重新安装扩展？
**A**: 是的，需要：
1. 停止 PostgreSQL
2. 替换 pghttp.dll
3. 启动 PostgreSQL
4. 运行 `DROP EXTENSION pghttp CASCADE; CREATE EXTENSION pghttp;`

## 版本信息

- **修复版本**: v1.0.1（或更新 v1.0.0）
- **修复日期**: 2025-11-14
- **影响文件**: `pghttp_full.c`
- **优先级**: 高（影响 API 调用）

## 相关文件

- `pghttp_full.c` - 源代码修复
- `test_content_type.sql` - 测试脚本
- `BUGFIX_CONTENT_TYPE.md` - 本文档

---

**修复状态**: ✅ 已完成  
**测试状态**: ⏳ 待测试  
**发布状态**: ⏳ 待发布
