# 🎯 最后步骤 - 修复 NULL 返回问题

## 已完成的修复

✅ **问题诊断：** HTTP 函数返回 NULL 是因为 HTTPS SSL 证书验证失败  
✅ **下载 CA 证书：** 227.13 KB 从 curl.se  
✅ **配置环境变量：** CURL_CA_BUNDLE 已设置  
✅ **重新编译扩展：** 添加了更好的错误处理  
✅ **重启 PostgreSQL：** 服务已重启（状态: Running）

---

## 🚀 现在请执行这些测试

### 步骤 1: 在你的数据库客户端中运行

打开 **pgAdmin**、**DBeaver** 或 **psql**，连接到数据库，然后执行：

```sql
-- 1. 重新创建扩展
DROP EXTENSION IF EXISTS pghttp CASCADE;
CREATE EXTENSION pghttp;

-- 2. 设置编码（避免乱码）
SET client_encoding = 'UTF8';

-- 3. 测试 GET 请求
SELECT http_get('https://httpbin.org/get');
```

### 预期结果

**成功：** 应该返回类似这样的 JSON：

```json
{
  "args": {},
  "headers": {
    "Accept-Charset": "utf-8",
    "Host": "httpbin.org",
    "User-Agent": "libcurl/8.11.0"
  },
  "origin": "123.45.67.89",
  "url": "https://httpbin.org/get"
}
```

**失败：** 如果仍然返回 NULL，继续下面的诊断步骤。

---

## ❌ 如果仍然返回 NULL

### 诊断 A: 检查 PostgreSQL 日志

新版本会显示详细错误消息。在 PowerShell 中运行：

```powershell
# 查看最新的 PostgreSQL 日志
$log = Get-ChildItem "D:\pgsql\data\log\postgresql-*.log" | Sort-Object LastWriteTime -Descending | Select-Object -First 1
Get-Content $log.FullName -Tail 30
```

查找类似这样的错误：
```
ERROR: pghttp: HTTP request failed - SSL certificate problem: ...
ERROR: pghttp: HTTP request failed - Could not resolve host: ...
ERROR: pghttp: HTTP request failed - Connection timed out
```

### 诊断 B: 测试 HTTP（非 HTTPS）

```sql
-- 测试简单的 HTTP（不需要 SSL）
SELECT http_get('http://httpbin.org/get');
```

- **如果 HTTP 成功，HTTPS 失败** → SSL 证书问题，继续诊断 C
- **如果 HTTP 也失败** → 网络连接问题，检查防火墙/代理

### 诊断 C: 验证 SSL 证书配置

```powershell
# 1. 检查证书文件是否存在
Test-Path "C:\curl\bin\curl-ca-bundle.crt"
# 应该返回: True

# 2. 检查环境变量（系统级）
[Environment]::GetEnvironmentVariable("CURL_CA_BUNDLE", "Machine")
# 应该返回: C:\curl\bin\curl-ca-bundle.crt

# 3. 检查当前会话
$env:CURL_CA_BUNDLE
# 应该返回: C:\curl\bin\curl-ca-bundle.crt

# 4. 如果环境变量未设置，手动设置并重启 PostgreSQL
[Environment]::SetEnvironmentVariable("CURL_CA_BUNDLE", "C:\curl\bin\curl-ca-bundle.crt", "Machine")
Restart-Service postgresql-x64-15
```

### 诊断 D: 运行完整诊断脚本

```sql
-- 在数据库客户端中
\i d:/CodeBuddy/pghttp/test_debug.sql
```

这会测试：
- 扩展是否正确安装
- 数据库恢复状态
- 客户端编码
- HTTP 和 HTTPS 请求

---

## 🔧 快速修复命令

### 选项 1: 重新运行 SSL 配置脚本

```powershell
cd d:\CodeBuddy\pghttp
.\setup_ssl_cert.ps1
```

### 选项 2: 手动配置（需要管理员权限）

```powershell
# 以管理员身份运行 PowerShell

# 设置环境变量
[Environment]::SetEnvironmentVariable(
    "CURL_CA_BUNDLE", 
    "C:\curl\bin\curl-ca-bundle.crt", 
    "Machine"
)

# 重启 PostgreSQL
$service = Get-Service | Where-Object { $_.Name -like "postgresql*" } | Select-Object -First 1
Restart-Service $service.Name

# 等待几秒
Start-Sleep -Seconds 3

# 验证服务状态
Get-Service $service.Name
```

### 选项 3: 临时解决方案（仅用于测试）

如果你只是想快速测试功能，可以暂时使用 HTTP 而不是 HTTPS：

```sql
-- 使用 HTTP 测试所有功能
SELECT http_get('http://httpbin.org/get');
SELECT http_post('http://httpbin.org/post', '{"test":"hello"}');
SELECT http_post('http://httpbin.org/post', '{"姓名":"张三"}');
```

⚠️ **注意：** HTTP 不安全，仅用于测试。生产环境必须使用 HTTPS。

---

## 📊 测试所有功能

一旦 GET 请求成功，请测试完整功能：

```sql
-- 设置编码
SET client_encoding = 'UTF8';

-- 1. 简单 GET
SELECT http_get('https://httpbin.org/get') AS response;

-- 2. 带 Headers 的 GET
SELECT http_get(
    'https://httpbin.org/get',
    '{"User-Agent":"PostgreSQL-pghttp/1.0","Accept":"application/json"}'
) AS response;

-- 3. 简单 POST
SELECT http_post(
    'https://httpbin.org/post',
    '{"test":"hello","number":123}'
) AS response;

-- 4. UTF-8 中文 POST
SELECT http_post(
    'https://httpbin.org/post',
    '{"姓名":"张三","城市":"北京","消息":"你好世界"}'
) AS response;

-- 5. 带自定义 Headers 的 POST
SELECT http_post(
    'https://httpbin.org/post',
    '{"data":"test"}',
    '{"Authorization":"Bearer test-token","Custom-Header":"value"}'
) AS response;

-- 6. 详细响应
SELECT 
    status_code,
    content_type,
    length(body) AS body_length,
    left(body, 100) AS body_preview
FROM http_request(
    'GET',
    'https://httpbin.org/get',
    NULL,
    NULL
);

-- 7. 测试不同状态码
SELECT http_get('https://httpbin.org/status/200') AS status_200;
SELECT http_get('https://httpbin.org/status/404') AS status_404;

-- 8. 实际应用示例：调用真实 API
SELECT http_get('https://api.github.com/repos/torvalds/linux') AS github_api;
```

---

## ✅ 成功标志

如果你看到以下任何一种输出，说明扩展工作正常：

### 成功示例 1: GET 响应

```
                         http_get                          
-----------------------------------------------------------
 {"args":{},"headers":{...},"url":"https://httpbin.org/get"}
(1 row)
```

### 成功示例 2: POST 响应（UTF-8）

```
{"data":"{\"姓名\":\"张三\"}","json":{"姓名":"张三"},...}
```

### 成功示例 3: 详细响应

```
 status_code | content_type     | body_length | body_preview
-------------+------------------+-------------+--------------
         200 | application/json |         425 | {"args":{}...
```

---

## 📞 获取帮助

如果问题仍未解决，请提供以下信息：

1. **PostgreSQL 日志中的错误消息**
   ```powershell
   Get-Content "D:\pgsql\data\log\postgresql-*.log" -Tail 50
   ```

2. **诊断脚本的输出**
   ```sql
   \i d:/CodeBuddy/pghttp/test_debug.sql
   ```

3. **环境信息**
   ```powershell
   # PostgreSQL 版本
   D:\pgsql\bin\psql.exe --version
   
   # 证书文件
   Test-Path "C:\curl\bin\curl-ca-bundle.crt"
   Get-Item "C:\curl\bin\curl-ca-bundle.crt" | Select-Object Length, LastWriteTime
   
   # 环境变量
   [Environment]::GetEnvironmentVariable("CURL_CA_BUNDLE", "Machine")
   
   # 网络测试
   curl https://httpbin.org/get
   ```

---

## 📚 相关文档

| 文档 | 用途 |
|------|------|
| **[FIX_NULL_ISSUE.md](FIX_NULL_ISSUE.md)** | NULL 返回问题的详细说明 |
| **[TROUBLESHOOTING.md](TROUBLESHOOTING.md)** | 完整故障排除指南 |
| [test_debug.sql](test_debug.sql) | 诊断测试脚本 |
| [README_CN.md](README_CN.md) | 完整使用文档 |
| [QUICK_REFERENCE.md](QUICK_REFERENCE.md) | 快速参考 |

---

## 🎯 总结

**你现在应该做的：**

1. ✅ 在数据库客户端中执行：
   ```sql
   DROP EXTENSION IF EXISTS pghttp CASCADE;
   CREATE EXTENSION pghttp;
   SET client_encoding = 'UTF8';
   SELECT http_get('https://httpbin.org/get');
   ```

2. ✅ 如果成功 → 🎉 恭喜！可以开始使用了！

3. ❌ 如果失败 → 查看 PostgreSQL 日志，运行诊断脚本

4. 📖 查看文档了解更多功能

---

**祝你测试顺利！** 🚀
