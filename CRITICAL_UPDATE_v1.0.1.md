# 🔥 pghttp 紧急更新 v1.0.1

## ⚠️ 重要性：高

如果你在调用 POST API 时遇到 **HTTP 415 错误**（Unsupported Media Type），请立即更新到此版本。

## 🐛 修复的问题

### 问题现象
调用 RESTful API 时返回 415 错误：

```sql
SELECT http_post(
    'http://localhost:3002/api/Crawl',
    '{"models": ["STM32F103C8T6"]}'
);
```

**错误响应**：
```json
{
    "title": "Unsupported Media Type",
    "status": 415
}
```

### 问题原因
旧版本在发送 POST 请求时**没有自动添加 `Content-Type: application/json` 头部**，导致服务器无法识别请求内容类型。

## ✅ 修复内容

- ✅ 自动为带 body 的 POST/PUT 请求添加 `Content-Type: application/json`
- ✅ 支持通过 headers 参数自定义 Content-Type
- ✅ 向后兼容，不影响 GET 请求

## 📦 新版本信息

**版本**: v1.0.1  
**发布日期**: 2025-11-14  
**发布包**: `pghttp-1.0.0-win-x64.zip`  
**SHA256**: `4C3C5BC9625C70168F8A214121F9E0E582719A3BF7F3990D776F7F472DE4B2EF`

## 🚀 更新步骤

### 方案 1: 本地环境（开发机）

```powershell
# 1. 进入项目目录
cd d:\CodeBuddy\pghttp

# 2. 重新编译
.\build_full.ps1

# 3. 在 PostgreSQL 中重新加载
```

然后在 psql 中执行：
```sql
DROP EXTENSION IF EXISTS pghttp CASCADE;
CREATE EXTENSION pghttp;
```

### 方案 2: 其他电脑（使用发布包）

1. **下载最新发布包**
   - 从项目的 `release` 目录获取最新的 ZIP 文件
   - 或从开发机复制：`d:\CodeBuddy\pghttp\release\pghttp-1.0.0-win-x64.zip`

2. **停止 PostgreSQL**
   ```powershell
   net stop postgresql-x64-15
   ```

3. **替换 DLL 文件**
   ```powershell
   # 解压新版本
   Expand-Archive pghttp-1.0.0-win-x64.zip
   
   # 复制新 DLL（根据你的 PostgreSQL 路径调整）
   copy pghttp-1.0.0-win-x64\pghttp.dll "D:\PGSQL\lib\pghttp.dll"
   ```

4. **启动 PostgreSQL**
   ```powershell
   net start postgresql-x64-15
   ```

5. **重新创建扩展**
   ```sql
   DROP EXTENSION IF EXISTS pghttp CASCADE;
   CREATE EXTENSION pghttp;
   ```

### 方案 3: 快速更新（推荐用于测试环境）

如果已经安装了旧版本，只需替换 DLL：

```powershell
# 1. 停止 PostgreSQL
Stop-Service postgresql-x64-15

# 2. 从开发机复制新 DLL
copy \\dev-machine\share\pghttp.dll "D:\PGSQL\lib\pghttp.dll"

# 3. 启动 PostgreSQL
Start-Service postgresql-x64-15

# 4. 在数据库中
# DROP EXTENSION pghttp CASCADE;
# CREATE EXTENSION pghttp;
```

## 🧪 验证更新

更新后，运行测试：

```sql
-- 测试 1: 验证 Content-Type 自动添加
SELECT 
    status_code,
    body::json->'headers'->>'Content-Type' AS sent_content_type
FROM http_request(
    'POST',
    'https://httpbin.org/post',
    '{"test":"update"}'
);
```

**期望结果**：
- `status_code`: 200
- `sent_content_type`: "application/json"

```sql
-- 测试 2: 调用你的实际 API
SELECT http_post(
    'http://localhost:3002/api/Crawl',
    '{
  "models": ["STM32F103C8T6"],
  "useCache": true,
  "retryTimes": 3
}'
);
```

**期望结果**：
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

## 📊 影响范围

### 受影响的 API
几乎所有现代 RESTful API 都需要 Content-Type：
- ✅ ASP.NET Core Web API
- ✅ Node.js/Express API
- ✅ Spring Boot API
- ✅ FastAPI/Flask API
- ✅ 所有标准 JSON API

### 不受影响
- ✅ GET 请求
- ✅ 无 body 的请求
- ✅ 已通过 headers 参数指定 Content-Type 的请求

## 🔍 技术细节

### 修改的代码
`pghttp_full.c` 中的 `perform_http_request` 函数：

```c
/* 新增：自动添加 Content-Type */
if (body != NULL && strlen(body) > 0) {
    WinHttpAddRequestHeaders(hRequest, 
                              L"Content-Type: application/json",
                              -1, 
                              WINHTTP_ADDREQ_FLAG_ADD);
}
```

### HTTP 头部处理顺序
1. 如果有 body，先添加默认 `Content-Type: application/json`
2. 然后添加用户自定义 headers（可覆盖默认值）
3. 发送请求

## ❓ 常见问题

### Q: 为什么之前 Apifox 测试正常？
**A**: Apifox 等工具会自动添加 Content-Type，而旧版 pghttp 没有。

### Q: 需要修改我的 SQL 代码吗？
**A**: 不需要！更新后你的代码无需修改即可正常工作。

### Q: 如何发送非 JSON 数据？
**A**: 通过 headers 参数自定义：
```sql
SELECT http_post(url, 'xml data', 'Content-Type: application/xml');
```

### Q: 更新会影响现有数据吗？
**A**: 不会。这只是扩展代码更新，不影响数据库数据。

## 📞 支持

如有问题：
1. 查看 `BUGFIX_CONTENT_TYPE.md` 详细说明
2. 运行 `test_content_type.sql` 测试脚本
3. 检查 PostgreSQL 日志

## 📝 版本历史

- **v1.0.1** (2025-11-14) - 修复 Content-Type 缺失问题
- **v1.0.0** (2025-11-13) - 初始发布

---

**更新优先级**: 🔥 高  
**影响**: 所有 POST API 调用  
**建议**: 立即更新

如果你在使用 POST 请求调用 API，强烈建议立即更新！
