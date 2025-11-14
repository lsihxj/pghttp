# 🔍 调试 NULL 返回问题

## 当前状态

✅ 扩展已编译并安装（包含调试日志）  
❌ HTTP 请求返回 NULL  
⚠️ PostgreSQL 日志中**没有任何错误信息**

这很不正常 - 说明可能：
1. 函数根本没有执行
2. 错误被静默处理
3. CURL 库有问题

---

## 🚀 立即测试（带调试日志）

### 步骤 1: 重新创建扩展

在你的数据库客户端中执行：

```sql
-- 启用调试消息
SET client_min_messages = NOTICE;

-- 重新创建扩展
DROP EXTENSION IF EXISTS pghttp CASCADE;
CREATE EXTENSION pghttp;

-- 设置编码
SET client_encoding = 'UTF8';
```

### 步骤 2: 执行 HTTP 请求并观察日志

```sql
-- 执行请求
SELECT http_get('http://httpbin.org/get');
```

### 预期看到的调试消息

**如果函数正常执行，你应该看到：**

```
NOTICE:  pghttp: Starting HTTP request - Method: GET, URL: http://httpbin.org/get
NOTICE:  pghttp: Initializing CURL...
NOTICE:  pghttp: CURL initialized successfully
NOTICE:  pghttp: Executing HTTP request...
NOTICE:  pghttp: HTTP request completed with code: 0
NOTICE:  pghttp: Request successful, response size: 425 bytes
```

然后是 JSON 响应。

**如果看到错误：**

```
NOTICE:  pghttp: Starting HTTP request...
NOTICE:  pghttp: Initializing CURL...
NOTICE:  pghttp: CURL initialized successfully
NOTICE:  pghttp: Executing HTTP request...
NOTICE:  pghttp: HTTP request completed with code: 60
ERROR:   pghttp: HTTP request failed - SSL certificate problem: unable to get local issuer certificate
```

会显示具体的 CURL 错误代码和消息。

**如果什么都没看到：**

说明函数根本没有执行，可能是：
- 扩展加载失败
- 函数定义问题
- PostgreSQL 配置问题

---

## 🔧 诊断步骤

### 诊断 A: 验证扩展已正确安装

```sql
-- 1. 检查扩展
\dx pghttp

-- 应该显示：
-- Name  | Version | Schema | Description
-- pghttp| 1.0.0   | public | HTTP client for PostgreSQL

-- 2. 检查函数
\df http_*

-- 应该列出：
-- http_get(text, text)
-- http_post(text, text, text)
-- http_request(text, text, text, text)
```

### 诊断 B: 检查 DLL 加载

```sql
-- 尝试创建扩展时观察是否有 DLL 加载错误
DROP EXTENSION IF EXISTS pghttp CASCADE;
CREATE EXTENSION pghttp;

-- 如果看到 "could not load library" 错误，说明 DLL 有问题
```

### 诊断 C: 测试简单函数

```sql
-- 测试函数是否能被调用（不实际执行 HTTP）
SELECT pg_typeof(http_get('http://example.com', NULL));

-- 应该返回: text
```

### 诊断 D: 检查 PostgreSQL 配置

```sql
-- 检查日志级别
SHOW log_min_messages;
SHOW client_min_messages;

-- 设置为详细模式
SET client_min_messages = NOTICE;
SET log_min_messages = NOTICE;
```

---

## 🛠️ 可能的问题及解决方案

### 问题 1: libcurl.dll 找不到

**症状：** 创建扩展时报错 "could not load library"

**解决方案：**

```powershell
# 检查 DLL
Test-Path "D:\pgsql\bin\libcurl.dll"
Test-Path "D:\pgsql\lib\pghttp.dll"

# 如果缺失，重新复制
Copy-Item "C:\curl\bin\libcurl-x64.dll" "D:\pgsql\bin\libcurl.dll" -Force
```

### 问题 2: CURL 初始化失败

**症状：** 看到 "pghttp: failed to initialize CURL"

**解决方案：**

检查是否有其他程序占用 CURL 资源，或重启 PostgreSQL：

```powershell
Restart-Service postgresql-x64-15
```

### 问题 3: SSL 证书问题

**症状：** 看到 "SSL certificate problem" 或 CURL 错误代码 60

**解决方案：**

```powershell
# 运行 SSL 证书配置脚本
.\setup_ssl_cert.ps1

# 重启 PostgreSQL
Restart-Service postgresql-x64-15
```

### 问题 4: 网络连接问题

**症状：** 看到 "Could not resolve host" 或 "Connection timed out"

**解决方案：**

```powershell
# 测试网络连接
curl http://httpbin.org/get

# 检查防火墙
# 检查代理设置
```

---

## 📝 运行测试脚本

### 方法 1: 在数据库客户端中

```sql
\i d:/CodeBuddy/pghttp/test_with_debug.sql
```

### 方法 2: 使用 psql

```powershell
D:\pgsql\bin\psql.exe -U postgres -d postgres -f test_with_debug.sql
```

---

## 🔍 查看详细日志

在执行测试后，查看 PostgreSQL 日志：

```powershell
# 实时查看日志
Get-Content "D:\pgsql\data\log\postgresql-*.log" -Wait -Tail 30
```

在另一个窗口执行 SQL 测试，你会看到实时的日志输出。

---

## 📊 收集诊断信息

如果问题仍然存在，请收集以下信息：

### SQL 命令

```sql
-- 1. 版本信息
SELECT version();

-- 2. 扩展信息
\dx+ pghttp

-- 3. 函数定义
\df+ http_get

-- 4. 测试并观察输出
SET client_min_messages = NOTICE;
SELECT http_get('http://httpbin.org/get');

-- 5. 数据库状态
SELECT pg_is_in_recovery();
SHOW shared_preload_libraries;
```

### PowerShell 命令

```powershell
# 1. 检查文件
Get-Item "D:\pgsql\lib\pghttp.dll" | Select-Object Length, LastWriteTime
Get-Item "D:\pgsql\bin\libcurl.dll" | Select-Object Length, LastWriteTime
Get-Item "C:\curl\bin\curl-ca-bundle.crt" | Select-Object Length, LastWriteTime

# 2. 环境变量
$env:CURL_CA_BUNDLE
[Environment]::GetEnvironmentVariable("CURL_CA_BUNDLE", "Machine")

# 3. 测试 CURL
curl http://httpbin.org/get

# 4. 查看最新日志
Get-Content (Get-ChildItem "D:\pgsql\data\log\postgresql-*.log" | 
             Sort-Object LastWriteTime -Descending | 
             Select-Object -First 1).FullName -Tail 50
```

---

## 🎯 下一步

1. **在数据库客户端中执行：**
   ```sql
   SET client_min_messages = NOTICE;
   DROP EXTENSION IF EXISTS pghttp CASCADE;
   CREATE EXTENSION pghttp;
   SELECT http_get('http://httpbin.org/get');
   ```

2. **仔细观察输出：**
   - ✅ 如果看到 NOTICE 消息 → 好！记录下错误代码
   - ❌ 如果没有任何 NOTICE 消息 → 函数没执行
   - ❌ 如果看到 ERROR 消息 → 记录完整错误

3. **告诉我你看到了什么：**
   - 所有的 NOTICE 消息
   - 任何 ERROR 或 WARNING
   - 最终返回的结果（NULL 或其他）

---

## 🔑 关键点

新版本的扩展会在每个关键步骤输出调试信息：

1. 开始 HTTP 请求
2. 初始化 CURL
3. 执行请求
4. 请求完成（成功或失败）
5. 响应大小

**如果你没有看到这些消息，说明函数根本没有被调用。**

---

**现在请执行测试并告诉我你看到的所有消息！** 🎯
