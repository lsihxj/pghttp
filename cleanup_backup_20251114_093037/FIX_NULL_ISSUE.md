# ✅ 修复 HTTP 函数返回 NULL 的问题

## 问题总结

你遇到的问题：
1. ✅ `http_get()` 返回 NULL
2. ✅ `http_post()` 返回 NULL  
3. ❌ `http_request()` 返回乱码错误

## 根本原因

**Windows 环境下的 HTTPS 请求需要 CA 证书包进行 SSL/TLS 验证，但系统中缺少该证书。**

libcurl 在 Windows 上默认不包含 CA 证书，导致所有 HTTPS 请求因 SSL 证书验证失败而返回 NULL。

## 已实施的解决方案

### ✅ 步骤 1: 增强错误处理

更新了 `pghttp.c`，添加了：
- CURL 全局初始化（`_PG_init()` / `_PG_fini()`）
- 更详细的错误消息
- SSL 验证配置

### ✅ 步骤 2: 下载并配置 CA 证书

已自动执行：
```powershell
✓ 下载 CA 证书: https://curl.se/ca/cacert.pem
✓ 保存到: C:\curl\bin\curl-ca-bundle.crt (227.13 KB)
✓ 设置环境变量: CURL_CA_BUNDLE = C:\curl\bin\curl-ca-bundle.crt
✓ PostgreSQL 服务已重启
```

### ✅ 步骤 3: 重新编译扩展

已完成：
```
✓ 清理旧文件
✓ 编译 pghttp.c → pghttp.o
✓ 链接 pghttp.dll
✓ 安装到 D:\pgsql\lib 和 D:\pgsql\share\extension
```

---

## 🚀 立即测试

### 在数据库客户端中执行

```sql
-- 1. 重新创建扩展（加载新版本）
DROP EXTENSION IF EXISTS pghttp CASCADE;
CREATE EXTENSION pghttp;

-- 2. 测试 HTTPS GET 请求
SELECT http_get('https://httpbin.org/get');

-- 3. 测试 POST 请求
SELECT http_post('https://httpbin.org/post', '{"test":"hello","number":123}');

-- 4. 测试 UTF-8 中文
SELECT http_post('https://httpbin.org/post', '{"姓名":"张三","城市":"北京","消息":"你好世界"}');

-- 5. 测试详细响应（先设置编码）
SET client_encoding = 'UTF8';
SELECT * FROM http_request('GET', 'https://httpbin.org/get', NULL, NULL);
```

---

## 预期结果

### ✅ 成功的 GET 请求

```json
{
  "args": {},
  "headers": {
    "Accept-Charset": "utf-8",
    "Host": "httpbin.org",
    "User-Agent": "libcurl/8.11.0",
    "X-Amzn-Trace-Id": "..."
  },
  "origin": "your.ip.address",
  "url": "https://httpbin.org/get"
}
```

### ✅ 成功的 POST 请求（UTF-8）

```json
{
  "args": {},
  "data": "{\"姓名\":\"张三\",\"城市\":\"北京\"}",
  "files": {},
  "form": {},
  "headers": {
    "Accept-Charset": "utf-8",
    "Content-Length": "56",
    "Content-Type": "application/json; charset=utf-8",
    "Host": "httpbin.org"
  },
  "json": {
    "姓名": "张三",
    "城市": "北京"
  },
  "origin": "your.ip.address",
  "url": "https://httpbin.org/post"
}
```

### ✅ 成功的详细响应

```
 status_code | content_type     | body
-------------+------------------+--------------------------------
         200 | application/json | {"args":{},"headers":{...}...}
```

---

## ❌ 如果仍然返回 NULL

### 诊断步骤

#### 1. 检查 PostgreSQL 服务是否已重启

```powershell
# 查看服务状态
Get-Service | Where-Object { $_.Name -like "postgresql*" }

# 手动重启（需要管理员权限）
Restart-Service postgresql-x64-15  # 替换为实际服务名
```

#### 2. 验证环境变量

```powershell
# 检查环境变量
[Environment]::GetEnvironmentVariable("CURL_CA_BUNDLE", "Machine")
# 应该返回: C:\curl\bin\curl-ca-bundle.crt

# 检查证书文件
Test-Path "C:\curl\bin\curl-ca-bundle.crt"
# 应该返回: True
```

#### 3. 查看 PostgreSQL 日志

```powershell
# 查看最新日志的最后 50 行
$logFile = Get-ChildItem "D:\pgsql\data\log\postgresql-*.log" | 
           Sort-Object LastWriteTime -Descending | 
           Select-Object -First 1
Get-Content $logFile.FullName -Tail 50
```

新版本的扩展会在日志中显示详细错误，例如：
```
ERROR: pghttp: HTTP request failed - SSL certificate problem: unable to get local issuer certificate (URL: https://httpbin.org/get)
```

#### 4. 运行诊断脚本

```sql
-- 在数据库客户端中
\i d:/CodeBuddy/pghttp/test_debug.sql
```

或：

```powershell
psql -U postgres -d postgres -f test_debug.sql
```

#### 5. 测试 HTTP（非 HTTPS）

```sql
-- 如果 HTTPS 失败，测试 HTTP
SELECT http_get('http://httpbin.org/get');

-- 如果 HTTP 成功但 HTTPS 失败，说明是 SSL 证书问题
```

---

## 乱码错误的解决方案

### 问题：`http_request()` 返回乱码

**原因：** 数据库客户端编码设置不正确

**解决方案：**

#### 方法 1: 在 SQL 中设置编码

```sql
-- 每次会话开始时执行
SET client_encoding = 'UTF8';

-- 然后执行查询
SELECT * FROM http_request('GET', 'https://httpbin.org/get', NULL, NULL);
```

#### 方法 2: 修改数据库默认编码

```sql
-- 查看当前编码
SHOW client_encoding;
SHOW server_encoding;

-- 如果服务器编码不是 UTF8，可能需要重建数据库
```

#### 方法 3: 配置客户端工具

**pgAdmin:**
1. File → Preferences → SQL Editor
2. Character set: UTF-8

**DBeaver:**
1. 数据库连接 → 编辑连接 → Driver properties
2. 添加: `characterEncoding = UTF-8`

**psql:**
```bash
# Windows
chcp 65001  # 设置 UTF-8 代码页
psql -U postgres -d postgres

# 或在 psql 中
\encoding UTF8
```

---

## 常见问题 FAQ

### Q1: 为什么需要 CA 证书？

A: HTTPS 请求需要验证服务器的 SSL 证书。CA 证书包含了受信任的证书颁发机构列表，用于验证服务器证书的真实性。

### Q2: 证书文件会过期吗？

A: 会的。建议每 6-12 个月更新一次：

```powershell
.\setup_ssl_cert.ps1  # 重新下载最新证书
```

### Q3: 可以禁用 SSL 验证吗？

A: 不建议在生产环境中禁用。如果仅用于测试，可以使用 HTTP 而不是 HTTPS：

```sql
SELECT http_get('http://httpbin.org/get');  -- 使用 HTTP
```

### Q4: 如何调试具体的错误？

A: 新版本会在 PostgreSQL 日志中输出详细错误。查看日志：

```powershell
Get-Content "D:\pgsql\data\log\postgresql-*.log" -Wait -Tail 20
```

### Q5: 在企业网络中需要代理怎么办？

A: 目前扩展不支持代理配置。可以：
1. 配置系统代理（libcurl 会自动使用）
2. 或联系管理员将 `httpbin.org` 加入白名单

---

## 验证清单

在确认问题解决前，请检查：

- [ ] PostgreSQL 服务已重启
- [ ] 扩展已重新创建（`DROP EXTENSION pghttp; CREATE EXTENSION pghttp;`）
- [ ] CA 证书文件存在（`C:\curl\bin\curl-ca-bundle.crt`）
- [ ] 环境变量已设置（`CURL_CA_BUNDLE`）
- [ ] 网络连接正常（可以用浏览器访问 https://httpbin.org）
- [ ] 客户端编码设置为 UTF-8

---

## 快速命令参考

```powershell
# 重启 PostgreSQL
Restart-Service postgresql-x64-15

# 查看日志
Get-Content "D:\pgsql\data\log\postgresql-*.log" -Tail 50

# 验证证书
Test-Path "C:\curl\bin\curl-ca-bundle.crt"

# 检查环境变量
$env:CURL_CA_BUNDLE
```

```sql
-- 重新加载扩展
DROP EXTENSION IF EXISTS pghttp CASCADE;
CREATE EXTENSION pghttp;

-- 设置编码
SET client_encoding = 'UTF8';

-- 测试
SELECT http_get('https://httpbin.org/get');
```

---

## 📚 相关文档

- **[TROUBLESHOOTING.md](TROUBLESHOOTING.md)** - 完整故障排除指南
- **[README_CN.md](README_CN.md)** - 使用文档
- **[QUICK_REFERENCE.md](QUICK_REFERENCE.md)** - 快速参考

---

**现在请在数据库客户端中测试！** 🎉

如果一切正常，你应该能看到 JSON 格式的响应而不是 NULL。
