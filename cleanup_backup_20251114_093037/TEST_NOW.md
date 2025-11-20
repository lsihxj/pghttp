# ⚡ 立即测试 pghttp 扩展

## 📊 日志分析结果

根据你的 PostgreSQL 日志：

✅ **扩展已成功创建**
```
2025-11-13 19:34:48.222 CST [55992] CREATE EXTENSION pghttp
```

⚠️ **数据库多次异常关闭和恢复**
```
数据库系统在恢复模式中
数据库系统没有正确的关闭; 处于自动恢复状态中
```

**结论：** 扩展本身没有问题，是数据库在恢复模式时无法执行查询。现在数据库已正常启动。

---

## 🚀 方法 1: 使用数据库客户端（推荐）

### 使用 DBeaver 或 pgAdmin

1. **连接到数据库**
   - Host: localhost
   - Port: 5432
   - Database: postgres
   - User: postgres
   - Password: 12456

2. **打开 SQL 编辑器**，复制粘贴以下内容：

```sql
-- 重新创建扩展
DROP EXTENSION IF EXISTS pghttp CASCADE;
CREATE EXTENSION pghttp;

-- 设置编码
SET client_encoding = 'UTF8';

-- 测试 HTTP（简单，不需要 SSL）
SELECT http_get('http://httpbin.org/get');
```

3. **执行 SQL**（点击运行按钮或按 F5）

---

## 🚀 方法 2: 使用 psql 命令行

### 步骤 1: 打开 PowerShell

```powershell
cd d:\CodeBuddy\pghttp
```

### 步骤 2: 连接到 PostgreSQL

```powershell
# 连接（会提示输入密码: 12456）
D:\pgsql\bin\psql.exe -U postgres -d postgres
```

### 步骤 3: 在 psql 中执行

```sql
-- 检查数据库状态
SELECT pg_is_in_recovery();
-- 应该返回: f (false，表示不在恢复模式)

-- 重新创建扩展
DROP EXTENSION IF EXISTS pghttp CASCADE;
CREATE EXTENSION pghttp;

-- 设置编码
SET client_encoding = 'UTF8';

-- 测试 HTTP
SELECT http_get('http://httpbin.org/get');

-- 测试 HTTPS
SELECT http_get('https://httpbin.org/get');

-- 测试 POST
SELECT http_post('https://httpbin.org/post', '{"test":"hello"}');

-- 测试中文
SELECT http_post('https://httpbin.org/post', '{"name":"张三"}');

-- 查看详细响应
SELECT * FROM http_request('GET', 'https://httpbin.org/get', NULL, NULL);
```

---

## 🚀 方法 3: 运行测试脚本

### 在 psql 中运行

```powershell
# 连接并运行测试脚本
D:\pgsql\bin\psql.exe -U postgres -d postgres -f test_now.sql
```

或者在已连接的 psql 会话中：

```sql
\i d:/CodeBuddy/pghttp/test_now.sql
```

---

## ✅ 预期的成功输出

### HTTP GET 请求

```
                              response                               
--------------------------------------------------------------------
 {                                                                  +
   "args": {},                                                      +
   "headers": {                                                     +
     "Accept-Charset": "utf-8",                                     +
     "Host": "httpbin.org",                                         +
     "User-Agent": "libcurl/8.11.0"                                 +
   },                                                               +
   "origin": "your.ip.address",                                     +
   "url": "http://httpbin.org/get"                                  +
 }
(1 row)
```

### POST 请求（中文）

```
{
  "data": "{\"name\":\"张三\"}",
  "json": {
    "name": "张三"
  },
  "headers": {
    "Content-Type": "application/json; charset=utf-8"
  }
}
```

---

## ❌ 如果仍然有问题

### 问题 A: 仍然返回 NULL

**可能原因 1: HTTPS SSL 证书问题**

解决方案：先测试 HTTP（不是 HTTPS）

```sql
-- 使用 HTTP 测试
SELECT http_get('http://httpbin.org/get');
```

如果 HTTP 成功但 HTTPS 失败，说明是 SSL 证书问题。运行：

```powershell
.\setup_ssl_cert.ps1
```

**可能原因 2: 网络问题**

测试网络连接：

```powershell
# 在 PowerShell 中测试
curl http://httpbin.org/get
```

### 问题 B: 仍然显示恢复模式错误

检查数据库状态：

```sql
SELECT pg_is_in_recovery();
```

- 返回 `f` (false) → 数据库正常
- 返回 `t` (true) → 数据库仍在恢复模式，需要等待或重启

重启数据库：

```powershell
Restart-Service postgresql-x64-15
```

### 问题 C: 乱码或编码错误

确保设置了编码：

```sql
SET client_encoding = 'UTF8';
SHOW client_encoding;  -- 应该显示: UTF8
```

---

## 📝 快速测试命令（复制粘贴）

```sql
-- === 快速测试 ===
DROP EXTENSION IF EXISTS pghttp CASCADE;
CREATE EXTENSION pghttp;
SET client_encoding = 'UTF8';

-- 测试 1: HTTP
SELECT http_get('http://httpbin.org/get');

-- 测试 2: HTTPS
SELECT http_get('https://httpbin.org/get');

-- 测试 3: POST
SELECT http_post('https://httpbin.org/post', '{"test":"hello"}');

-- 测试 4: 中文
SELECT http_post('https://httpbin.org/post', '{"姓名":"张三"}');
```

---

## 🎯 下一步

1. **选择一个方法**（推荐：方法 1 使用 DBeaver 或 pgAdmin）

2. **执行测试 SQL**

3. **查看结果**：
   - ✅ 如果返回 JSON → 成功！🎉
   - ❌ 如果返回 NULL → 查看 PostgreSQL 日志获取错误信息
   - ❌ 如果有其他错误 → 告诉我具体的错误消息

4. **报告结果**

---

## 📊 调试信息

如果测试失败，请提供：

```sql
-- 1. 数据库状态
SELECT pg_is_in_recovery();
SELECT version();

-- 2. 扩展信息
\dx pghttp

-- 3. 函数列表
\df http_*

-- 4. 编码设置
SHOW client_encoding;
SHOW server_encoding;
```

以及 PowerShell 命令：

```powershell
# PostgreSQL 日志（最后 30 行）
Get-Content "D:\pgsql\data\log\postgresql-*.log" -Tail 30

# SSL 证书检查
Test-Path "C:\curl\bin\curl-ca-bundle.crt"
$env:CURL_CA_BUNDLE
```

---

**现在请选择一个方法开始测试！** 🚀

建议先用简单的 HTTP 测试（不是 HTTPS），确认扩展基本功能正常后，再测试 HTTPS。
