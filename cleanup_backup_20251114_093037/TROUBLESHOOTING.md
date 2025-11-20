# pghttp 扩展故障排除指南

## 当前问题诊断

### 问题 1: 所有 HTTP 函数返回 NULL

**症状：**
```sql
SELECT http_get('https://httpbin.org/get');  -- 返回 NULL
SELECT http_post('https://httpbin.org/post', '{"test":"hello"}');  -- 返回 NULL
```

**可能原因：**

#### 原因 A: SSL/TLS 证书验证失败（最可能）

Windows 环境下，libcurl 可能找不到 CA 证书包，导致 HTTPS 请求失败。

**解决方案：**

1. **下载 CA 证书包**
   ```powershell
   # 下载 CA 证书
   Invoke-WebRequest -Uri "https://curl.se/ca/cacert.pem" -OutFile "C:\curl\bin\curl-ca-bundle.crt"
   ```

2. **配置环境变量**
   ```powershell
   # 临时设置（当前 PowerShell 会话）
   $env:CURL_CA_BUNDLE = "C:\curl\bin\curl-ca-bundle.crt"
   
   # 永久设置（需要管理员权限）
   [Environment]::SetEnvironmentVariable(
       "CURL_CA_BUNDLE", 
       "C:\curl\bin\curl-ca-bundle.crt", 
       "Machine"
   )
   
   # 重启 PostgreSQL 服务
   Restart-Service postgresql-x64-15
   ```

3. **或者：测试 HTTP（非 HTTPS）**
   ```sql
   -- 使用 HTTP 而不是 HTTPS 测试
   SELECT http_get('http://httpbin.org/get');
   ```

#### 原因 B: 网络连接问题

**测试网络连接：**
```powershell
# 测试 DNS 解析
nslookup httpbin.org

# 测试网络连接
curl https://httpbin.org/get

# 测试从 PostgreSQL 用户权限访问
psql -U postgres -c "COPY (SELECT 1) TO PROGRAM 'curl https://httpbin.org/get'"
```

#### 原因 C: PostgreSQL 错误被忽略

**查看 PostgreSQL 日志：**
```powershell
# 查找最新的日志文件
Get-ChildItem "D:\pgsql\data\log\postgresql-*.log" | Sort-Object LastWriteTime -Descending | Select-Object -First 1

# 查看最后 50 行
Get-Content (Get-ChildItem "D:\pgsql\data\log\postgresql-*.log" | Sort-Object LastWriteTime -Descending | Select-Object -First 1).FullName -Tail 50
```

---

### 问题 2: http_request 函数返回乱码错误

**症状：**
```sql
SELECT * FROM http_request('GET', 'https://httpbin.org/get', NULL, NULL);
-- 错误: ��������: ���ݿ�ϵͳ�ڻָ�ģʽ��
```

**原因：** 客户端编码设置不正确

**解决方案：**

1. **在客户端中设置编码**
   ```sql
   SET client_encoding = 'UTF8';
   SELECT * FROM http_request('GET', 'https://httpbin.org/get', NULL, NULL);
   ```

2. **永久设置数据库编码**
   ```sql
   -- 查看当前编码
   SHOW client_encoding;
   SHOW server_encoding;
   
   -- 如果需要，修改配置文件
   -- D:\pgsql\data\postgresql.conf
   -- client_encoding = 'UTF8'
   ```

3. **如果使用 pgAdmin 或 DBeaver**
   - 检查连接设置中的字符编码
   - 确保设置为 UTF-8

---

## 快速诊断步骤

### 步骤 1: 重新加载扩展

新版本已添加更详细的错误信息。

```sql
-- 删除旧扩展
DROP EXTENSION IF EXISTS pghttp CASCADE;

-- 重新创建
CREATE EXTENSION pghttp;
```

### 步骤 2: 运行诊断脚本

```sql
-- 在 psql 或数据库客户端中运行
\i d:/CodeBuddy/pghttp/test_debug.sql
```

或：

```powershell
# 在 PowerShell 中
psql -U postgres -d postgres -f test_debug.sql
```

### 步骤 3: 测试 HTTP（非 HTTPS）

```sql
-- 测试简单的 HTTP 请求（不需要 SSL）
SELECT http_get('http://httpbin.org/get');

-- 如果成功，说明是 SSL 证书问题
```

### 步骤 4: 查看详细错误

新版本会在错误时显示详细信息：

```sql
-- 应该会看到具体的错误消息，例如：
-- ERROR: pghttp: HTTP request failed - SSL certificate problem: unable to get local issuer certificate
```

---

## 解决方案汇总

### 方案 A: 快速测试（跳过 SSL 验证）- 仅用于测试

创建一个测试版本（不验证 SSL）：

```sql
-- 临时使用 HTTP 而不是 HTTPS
SELECT http_get('http://httpbin.org/get');
```

### 方案 B: 配置 CA 证书（推荐的生产方案）

```powershell
# 1. 下载 CA 证书
Invoke-WebRequest -Uri "https://curl.se/ca/cacert.pem" -OutFile "C:\curl\bin\curl-ca-bundle.crt"

# 2. 设置环境变量（需要管理员权限）
[Environment]::SetEnvironmentVariable("CURL_CA_BUNDLE", "C:\curl\bin\curl-ca-bundle.crt", "Machine")

# 3. 重启 PostgreSQL
Restart-Service postgresql-x64-15

# 4. 测试
psql -U postgres -d postgres -c "SELECT http_get('https://httpbin.org/get');"
```

### 方案 C: 使用系统代理

如果你在企业环境中，可能需要配置代理：

```sql
-- 暂时无法通过 SQL 配置，需要在 C 代码中添加
-- 或者使用环境变量：
-- SET https_proxy=http://proxy.company.com:8080
```

---

## 检查清单

在提交问题之前，请确认：

- [ ] 扩展已重新创建（`DROP EXTENSION pghttp CASCADE; CREATE EXTENSION pghttp;`）
- [ ] 已运行诊断脚本（`test_debug.sql`）
- [ ] 已查看 PostgreSQL 日志文件
- [ ] 已测试 HTTP（非 HTTPS）URL
- [ ] 已检查网络连接（`curl https://httpbin.org/get`）
- [ ] 已检查客户端编码（`SHOW client_encoding;`）
- [ ] libcurl DLL 在 PostgreSQL bin 目录（`D:\pgsql\bin\libcurl.dll`）

---

## 获取帮助

### 查看 PostgreSQL 日志

```powershell
# 实时查看日志
Get-Content "D:\pgsql\data\log\postgresql-*.log" -Wait -Tail 20
```

### 启用详细日志

在 `D:\pgsql\data\postgresql.conf` 中添加：

```
log_error_verbosity = verbose
log_min_messages = debug1
```

重启 PostgreSQL 后重试。

---

## 常见错误及解决方案

| 错误信息 | 原因 | 解决方案 |
|---------|------|---------|
| 返回 NULL | SSL 证书验证失败 | 配置 CA 证书或测试 HTTP |
| `SSL certificate problem` | 缺少 CA 证书 | 下载并配置 cacert.pem |
| `Could not resolve host` | DNS 解析失败 | 检查网络连接 |
| `Connection timed out` | 网络超时 | 检查防火墙/代理设置 |
| `���ݿ�ϵͳ�ڻָ�ģʽ` | 编码问题 | `SET client_encoding = 'UTF8';` |

---

## 下一步

1. **首先尝试：**
   ```powershell
   # 下载 CA 证书
   Invoke-WebRequest -Uri "https://curl.se/ca/cacert.pem" -OutFile "C:\curl\bin\curl-ca-bundle.crt"
   
   # 设置环境变量
   $env:CURL_CA_BUNDLE = "C:\curl\bin\curl-ca-bundle.crt"
   
   # 重启 PostgreSQL
   Restart-Service postgresql-x64-15
   ```

2. **然后测试：**
   ```sql
   DROP EXTENSION IF EXISTS pghttp CASCADE;
   CREATE EXTENSION pghttp;
   SELECT http_get('https://httpbin.org/get');
   ```

3. **如果还是失败，运行诊断：**
   ```sql
   \i d:/CodeBuddy/pghttp/test_debug.sql
   ```

4. **查看 PostgreSQL 日志获取详细错误信息**
