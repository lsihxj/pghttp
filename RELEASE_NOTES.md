# pghttp v1.0.0 发布说明

## 🎉 版本信息

- **版本号**: 1.0.0
- **发布日期**: 2025-11-13
- **平台**: Windows x64
- **PostgreSQL**: 15.x
- **编译器**: MSVC 2022

## 📦 发布包

**文件名**: `pghttp-1.0.0-win-x64.zip`  
**大小**: ~26 KB  
**位置**: `d:\CodeBuddy\pghttp\release\`

### 发布包内容

```
pghttp-1.0.0-win-x64/
├── install.ps1              # 自动安装脚本
├── pghttp.dll               # 扩展库 (MSVC 编译)
├── pghttp.control           # 扩展控制文件
├── pghttp--1.0.0.sql       # SQL 函数定义
├── INSTALL_RELEASE.md      # 详细安装指南
├── USAGE.md                # 使用文档
├── examples.sql            # 示例代码集
├── README.txt              # 快速入门
├── 快速安装指南.txt         # 中文快速指南
└── VERSION.txt             # 版本信息
```

## ✨ 核心功能

### HTTP 请求支持
- ✅ **HTTP GET 请求** - 获取 Web 资源
- ✅ **HTTP POST 请求** - 发送数据到服务器
- ✅ **通用 HTTP 请求** - 支持 PUT, DELETE, PATCH 等所有方法
- ✅ **HTTPS 支持** - 自动处理 SSL/TLS 连接

### 响应处理
- ✅ **简单响应** - 直接返回响应体
- ✅ **详细响应** - 返回状态码、Content-Type 和响应体
- ✅ **UTF-8 编码** - 完整支持 Unicode 和中文
- ✅ **JSON 兼容** - 响应可直接转换为 JSON 类型

### 技术特性
- ✅ **原生实现** - 使用 Windows WinHTTP API
- ✅ **零依赖** - 无需安装第三方库
- ✅ **超时保护** - 30 秒默认超时
- ✅ **内存安全** - 使用 PostgreSQL palloc/pfree
- ✅ **错误处理** - 完善的错误日志

## 🚀 快速开始

### 1. 安装

```powershell
# 解压发布包
Expand-Archive pghttp-1.0.0-win-x64.zip -DestinationPath C:\pghttp

# 以管理员身份运行
cd C:\pghttp\pghttp-1.0.0-win-x64
.\install.ps1
```

### 2. 创建扩展

```sql
CREATE EXTENSION pghttp;
```

### 3. 测试

```sql
-- GET 请求
SELECT http_get('https://jsonplaceholder.typicode.com/posts/1');

-- POST 请求
SELECT http_post(
    'https://jsonplaceholder.typicode.com/posts',
    '{"title":"Test","body":"Content","userId":1}'
);

-- 详细响应
SELECT * FROM http_request('GET', 'https://httpbin.org/status/200');
```

## 📚 API 文档

### http_get(url, headers)

执行 HTTP GET 请求

```sql
SELECT http_get('https://api.example.com/data');
```

**参数**:
- `url` (text) - 目标 URL
- `headers` (text, 可选) - 自定义 HTTP 头

**返回**: text - 响应体内容

### http_post(url, body, headers)

执行 HTTP POST 请求

```sql
SELECT http_post(
    'https://api.example.com/users',
    '{"name":"John","email":"john@example.com"}'
);
```

**参数**:
- `url` (text) - 目标 URL
- `body` (text) - 请求体内容
- `headers` (text, 可选) - 自定义 HTTP 头

**返回**: text - 响应体内容

### http_request(method, url, body, headers)

通用 HTTP 请求，返回详细信息

```sql
SELECT * FROM http_request('PUT', 'https://api.example.com/users/1', '{"name":"Updated"}');
```

**参数**:
- `method` (text) - HTTP 方法 (GET, POST, PUT, DELETE 等)
- `url` (text) - 目标 URL
- `body` (text, 可选) - 请求体内容
- `headers` (text, 可选) - 自定义 HTTP 头

**返回**: http_response - 复合类型
- `status_code` (integer) - HTTP 状态码
- `content_type` (text) - Content-Type 响应头
- `body` (text) - 响应体内容

## 💡 使用场景

### 1. API 集成

```sql
-- 调用外部 REST API
CREATE OR REPLACE FUNCTION get_weather(city text)
RETURNS json AS $$
BEGIN
    RETURN http_get('https://api.weather.com/v1/weather?city=' || city)::json;
END;
$$ LANGUAGE plpgsql;
```

### 2. Webhook 通知

```sql
-- 数据变更时发送通知
CREATE OR REPLACE FUNCTION notify_webhook()
RETURNS trigger AS $$
BEGIN
    PERFORM http_post(
        'https://hooks.slack.com/services/YOUR/WEBHOOK/URL',
        json_build_object('text', 'Data updated: ' || NEW.id)::text
    );
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;
```

### 3. 数据同步

```sql
-- 同步数据到外部系统
INSERT INTO external_users (name, email)
SELECT 
    (data->>'name')::text,
    (data->>'email')::text
FROM (
    SELECT http_get('https://api.example.com/users')::json AS data
) t;
```

## 🔧 系统要求

### 必需
- Windows 10/11 或 Windows Server 2016+
- PostgreSQL 15.x (官方 Windows x64 版本)
- 管理员权限（仅安装时需要）

### 推荐
- 稳定的网络连接
- 防火墙允许 HTTP/HTTPS 出站连接

### 不支持
- ❌ Linux/macOS（当前版本仅支持 Windows）
- ❌ PostgreSQL 14 及以下版本
- ❌ 32 位系统

## 🐛 已知限制

1. **同步阻塞** - HTTP 请求会阻塞 SQL 查询，不适合长时间请求
2. **无连接池** - 每次请求创建新连接
3. **固定超时** - 30 秒超时无法配置（需修改源码）
4. **Windows 专用** - 使用 WinHTTP，仅支持 Windows

## 🔐 安全建议

1. **网络安全**
   - 仅连接可信的 API 端点
   - 使用 HTTPS 传输敏感数据
   - 避免在 URL 中包含敏感信息

2. **权限控制**
   - 限制哪些用户可以调用 HTTP 函数
   - 使用 PostgreSQL GRANT/REVOKE 控制访问

3. **输入验证**
   - 验证用户提供的 URL
   - 防止 SQL 注入和 SSRF 攻击

```sql
-- 示例：限制 HTTP 函数访问
REVOKE EXECUTE ON FUNCTION http_get(text, text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION http_get(text, text) TO trusted_user;
```

## 📊 性能考虑

- **请求延迟**: 取决于网络和目标服务器
- **并发限制**: 受 PostgreSQL 连接数限制
- **内存使用**: 响应体完全加载到内存
- **大文件**: 不建议下载大文件（建议 < 10MB）

## 🆙 升级路径

从源码手动安装升级到发布包：

1. 停止 PostgreSQL 服务
2. 备份现有 `pghttp.dll`
3. 使用 `install.ps1` 安装新版本
4. 启动 PostgreSQL 服务
5. 无需重新 CREATE EXTENSION

## 🤝 贡献与反馈

欢迎提供：
- Bug 报告
- 功能建议
- 文档改进
- 使用案例分享

## 📄 许可证

**MIT License**

```
Copyright (c) 2025 pghttp Contributors

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```

## 🙏 致谢

- PostgreSQL 社区
- Microsoft Visual Studio 团队
- Windows WinHTTP API 文档

## 📞 支持

- **文档**: 查看 INSTALL_RELEASE.md 和 USAGE.md
- **示例**: 参考 examples.sql
- **故障排除**: INSTALL_RELEASE.md 中的故障排除章节

---

## 🎯 下一步计划 (v1.1.0)

计划中的功能：
- [ ] JSON headers 支持
- [ ] 可配置超时时间
- [ ] 异步请求支持
- [ ] 连接池
- [ ] 代理服务器支持
- [ ] 请求重试机制
- [ ] Linux/macOS 支持

---

**感谢使用 pghttp！** 🚀

如有问题或建议，欢迎反馈！
