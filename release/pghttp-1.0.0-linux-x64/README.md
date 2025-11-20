# pghttp - PostgreSQL HTTP Client Extension

一个**跨平台**的 PostgreSQL 扩展，允许你在 SQL 中直接调用 HTTP API 接口，支持 GET 和 POST 请求，完整支持 UTF-8 编码。

> **✅ 跨平台支持**: v1.0.0 **同时支持 Windows 和 Linux 平台**！使用相同的 SQL API，无缝跨平台。详见 [跨平台说明](CROSSPLATFORM_README.md)

## 功能特性

- ✅ **HTTP GET 请求** - 简单的 GET 请求支持
- ✅ **HTTP POST 请求** - 支持发送 JSON 数据（自动添加 Content-Type）
- ✅ **自定义 Headers** - 支持自定义请求头（如 Authorization 等）
- ✅ **UTF-8 支持** - 完整支持中文等多字节字符
- ✅ **详细响应** - 返回状态码、Content-Type 和响应体
- ✅ **超时控制** - 默认 30 秒超时
- ✅ **零依赖** - 使用 Windows 原生 WinHTTP API

## 系统要求

### Windows
- **PostgreSQL**: 12 或更高版本（支持 12-18+）
- **操作系统**: Windows 10/11 或 Windows Server 2016+
- **编译器**: Visual Studio 2019/2022 (MSVC)
- **依赖库**: WinHTTP (Windows 内置，零外部依赖)

### Linux
- **PostgreSQL**: 12 或更高版本（支持 12-18+）
- **操作系统**: Ubuntu/Debian/CentOS/RHEL/Fedora
- **编译器**: GCC 或 Clang
- **依赖库**: libcurl (标准库)

### macOS
- **PostgreSQL**: 12 或更高版本
- **依赖库**: libcurl (通过 Homebrew 安装)
- 使用与 Linux 相同的编译方式

> **重要**: 
> - 不同 PostgreSQL 主版本需要重新编译
> - Windows 使用 WinHTTP，Linux/macOS 使用 libcurl
> - SQL API 在所有平台上完全一致
> - 详见 [版本兼容性说明](POSTGRESQL_COMPATIBILITY.md) 和 [跨平台说明](CROSSPLATFORM_README.md)

## 安装

### Windows 快速安装

1. **下载发布包**: `pghttp-1.0.0-win-x64.zip`

2. **解压到任意目录**

3. **管理员身份运行 PowerShell**:
   ```powershell
   cd <解压目录>
   .\install.ps1
   ```

4. **在 PostgreSQL 中启用**:
   ```sql
   CREATE EXTENSION pghttp;
   ```

详细安装说明请查看 [INSTALL_RELEASE.md](INSTALL_RELEASE.md)

### Linux 快速安装

1. **安装依赖**:
   ```bash
   # Ubuntu/Debian
   sudo apt-get install postgresql-server-dev-all libcurl4-openssl-dev
   
   # CentOS/RHEL
   sudo dnf install postgresql-devel libcurl-devel gcc make
   ```

2. **编译扩展**:
   ```bash
   make clean && make
   ```

3. **安装扩展**:
   ```bash
   sudo make install
   # 或使用安装脚本
   sudo chmod +x install_linux.sh && sudo ./install_linux.sh
   ```

4. **在 PostgreSQL 中启用**:
   ```sql
   CREATE EXTENSION pghttp;
   ```

详细安装说明请查看 [INSTALL_LINUX.md](INSTALL_LINUX.md)

### macOS 快速安装

```bash
# 安装依赖
brew install postgresql libcurl

# 编译安装（同 Linux）
make clean && make
sudo make install

# 启用扩展
CREATE EXTENSION pghttp;
```
```

## 使用方法

### 1. HTTP GET 请求

#### 简单 GET 请求
```sql
-- 获取数据
SELECT http_get('https://api.github.com/users/octocat');

-- 返回 JSON 字符串
```

#### 带自定义 Headers 的 GET 请求
```sql
SELECT http_get(
    'https://api.github.com/user/repos',
    '{"Authorization":"token YOUR_TOKEN","Accept":"application/json"}'
);
```

### 2. HTTP POST 请求

#### 简单 POST 请求
```sql
-- 发送 JSON 数据（自动设置 Content-Type: application/json; charset=utf-8）
SELECT http_post(
    'https://api.example.com/users',
    '{"name":"张三","email":"zhangsan@example.com","age":25}'
);
```

#### 带自定义 Headers 的 POST 请求
```sql
SELECT http_post(
    'https://api.example.com/data',
    '{"message":"你好世界","type":"greeting"}',
    '{"Authorization":"Bearer YOUR_TOKEN","Content-Type":"application/json; charset=utf-8"}'
);
```

### 3. 通用 HTTP 请求（获取详细响应）

```sql
-- 获取完整的响应信息（状态码、Content-Type、响应体）
SELECT * FROM http_request(
    'POST',
    'https://api.example.com/data',
    '{"key":"value"}',
    '{"Authorization":"Bearer token"}'
);

-- 返回结果:
--  status_code | content_type           | body
-- -------------+------------------------+------------------
--  200         | application/json       | {"result":"ok"}
```

### 4. UTF-8 中文支持示例

```sql
-- 发送包含中文的数据
SELECT http_post(
    'https://api.example.com/messages',
    '{"title":"测试标题","content":"这是一条包含中文的消息","user":"李四"}',
    '{"Content-Type":"application/json; charset=utf-8"}'
);

-- 接收包含中文的响应
SELECT http_get('https://api.example.com/chinese-data');
-- 返回: {"message":"你好，世界！","status":"成功"}
```

## 函数参考

### http_get(url, headers)

执行 HTTP GET 请求。

**参数:**
- `url` (text) - 请求的 URL
- `headers` (text, 可选) - JSON 格式的自定义请求头

**返回:** text - 响应体内容

**示例:**
```sql
SELECT http_get('https://api.example.com/data');
SELECT http_get('https://api.example.com/data', '{"Authorization":"Bearer token"}');
```

### http_post(url, body, headers)

执行 HTTP POST 请求。

**参数:**
- `url` (text) - 请求的 URL
- `body` (text) - 请求体（通常是 JSON 字符串）
- `headers` (text, 可选) - JSON 格式的自定义请求头

**返回:** text - 响应体内容

**示例:**
```sql
SELECT http_post('https://api.example.com/users', '{"name":"John"}');
SELECT http_post('https://api.example.com/users', '{"name":"John"}', '{"Authorization":"Bearer token"}');
```

### http_request(method, url, body, headers)

执行 HTTP 请求并返回详细响应信息。

**参数:**
- `method` (text) - HTTP 方法（GET, POST, PUT, DELETE 等）
- `url` (text) - 请求的 URL
- `body` (text, 可选) - 请求体
- `headers` (text, 可选) - JSON 格式的自定义请求头

**返回:** http_response - 包含以下字段的记录类型：
- `status_code` (integer) - HTTP 状态码
- `content_type` (text) - 响应的 Content-Type
- `body` (text) - 响应体内容

**示例:**
```sql
SELECT * FROM http_request('GET', 'https://api.example.com/data', NULL, NULL);
SELECT * FROM http_request('POST', 'https://api.example.com/data', '{"key":"value"}', '{"Authorization":"Bearer token"}');
```

## 实际应用场景

### 1. 与第三方 API 集成

```sql
-- 调用天气 API
SELECT http_get('https://api.weather.com/v1/current?city=Beijing&key=YOUR_KEY');

-- 发送短信通知
SELECT http_post(
    'https://api.sms.com/send',
    '{"phone":"13800138000","message":"验证码：123456"}',
    '{"Authorization":"Bearer YOUR_TOKEN"}'
);
```

### 2. Webhook 通知

```sql
-- 数据变更时发送 Webhook
CREATE OR REPLACE FUNCTION notify_webhook()
RETURNS TRIGGER AS $$
BEGIN
    PERFORM http_post(
        'https://your-webhook-url.com/notify',
        json_build_object(
            'event', TG_OP,
            'table', TG_TABLE_NAME,
            'data', row_to_json(NEW)
        )::text,
        '{"Content-Type":"application/json"}'
    );
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 创建触发器
CREATE TRIGGER user_change_webhook
AFTER INSERT OR UPDATE ON users
FOR EACH ROW
EXECUTE FUNCTION notify_webhook();
```

### 3. 数据同步

```sql
-- 从远程 API 同步数据到本地表
INSERT INTO local_products (id, name, price)
SELECT 
    (product->>'id')::int,
    product->>'name',
    (product->>'price')::numeric
FROM json_array_elements(
    http_get('https://api.example.com/products')::json
) AS product;
```

## 注意事项

1. **安全性**: 谨慎使用，避免在 SQL 注入风险的场景中使用
2. **性能**: HTTP 请求是阻塞操作，大量请求可能影响数据库性能
3. **超时**: 默认超时 30 秒，长时间请求可能需要调整代码
4. **权限**: 确保 PostgreSQL 用户有权限访问外部网络
5. **UTF-8**: 所有字符串都以 UTF-8 编码处理，确保数据库编码设置正确

## 故障排除

### 编译错误：找不到 curl.h

```bash
# 确保安装了 libcurl 开发包
sudo apt-get install libcurl4-openssl-dev
```

### 运行时错误：无法加载扩展

```bash
# 检查扩展是否正确安装
SELECT * FROM pg_available_extensions WHERE name = 'pghttp';

# 重新安装
DROP EXTENSION IF EXISTS pghttp;
CREATE EXTENSION pghttp;
```

### UTF-8 编码问题

```sql
-- 检查数据库编码
SHOW server_encoding;

-- 如果不是 UTF8，创建新数据库时指定
CREATE DATABASE mydb ENCODING 'UTF8';
```

## 卸载

```sql
-- 从数据库中删除扩展
DROP EXTENSION pghttp;
```

```bash
# 从系统中删除文件
cd pghttp
sudo make uninstall
```

## 许可证

MIT License

## 贡献

欢迎提交 Issue 和 Pull Request！

## 更新日志

### v1.0.0 (2025-11-13)
- ✨ 初始版本发布
- ✅ 支持 HTTP GET 和 POST 请求
- ✅ 支持自定义 Headers
- ✅ 完整的 UTF-8 支持
- ✅ 返回详细响应信息（状态码、Content-Type、响应体）
