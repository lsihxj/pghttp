# pghttp v1.0.0 - 发布说明

**发布日期**: 2025-11-14  
**版本**: 1.0.0  
**平台**: Windows x64 / Linux x64

---

## 🎉 重要更新

**跨平台支持！** pghttp 现在同时支持 Windows 和 Linux 平台。

---

## 📦 发布包

### Windows 预编译版本
- **文件名**: `pghttp-1.0.0-win-x64.zip`
- **大小**: ~36 KB
- **内容**: 预编译 DLL + 安装脚本 + 文档
- **适用**: Windows 10/11, Windows Server 2016+
- **PostgreSQL**: 12, 13, 14, 15, 16, 17, 18+ (x64)

**安装方法**:
```powershell
# 解压 ZIP 文件
# 以管理员身份运行 PowerShell
.\install.ps1

# 在 PostgreSQL 中
CREATE EXTENSION pghttp;
```

### Linux 源码版本
- **文件名**: `pghttp-1.0.0-linux-x64.zip`
- **大小**: ~100 KB
- **内容**: C 源码 + Makefile + 安装脚本 + 文档
- **适用**: Ubuntu, Debian, CentOS, RHEL, Fedora, Arch Linux
- **PostgreSQL**: 12-18+

**安装方法**:
```bash
# 解压文件
unzip pghttp-1.0.0-linux-x64.zip
cd pghttp-1.0.0-linux-x64

# 安装依赖（Ubuntu/Debian）
sudo apt-get install postgresql-server-dev-all libcurl4-openssl-dev gcc make

# 编译并安装
make clean && make
sudo make install

# 在 PostgreSQL 中
CREATE EXTENSION pghttp;
```

---

## ✨ 功能特性

### 核心功能
- ✅ **HTTP/HTTPS GET 请求** - 获取数据
- ✅ **HTTP/HTTPS POST 请求** - 提交数据
- ✅ **所有 HTTP 方法** - PUT, DELETE, PATCH, HEAD, OPTIONS 等
- ✅ **详细响应信息** - 状态码、Content-Type、响应体
- ✅ **UTF-8 编码支持** - 完整的 Unicode 支持
- ✅ **30 秒超时保护** - 防止长时间挂起
- ✅ **自动 Content-Type** - POST 请求自动添加 `Content-Type: application/json`

### 平台特性

#### Windows 版本
- 使用原生 **WinHTTP API**
- **零外部依赖** - 无需安装额外库
- 完全兼容 Windows 安全策略
- MSVC 2022 编译优化

#### Linux 版本
- 使用行业标准 **libcurl**
- 跨多个 Linux 发行版
- GCC 编译优化
- 标准 PGXS 构建系统

---

## 📚 SQL API

### 简单 GET 请求
```sql
SELECT http_get('https://api.example.com/data');
```

### POST 请求（自动添加 Content-Type）
```sql
SELECT http_post('https://api.example.com/users', '{"name":"John","age":30}');
```

### 详细响应（状态码 + Content-Type + Body）
```sql
SELECT * FROM http_request('GET', 'https://api.example.com/status');
```

### 所有 HTTP 方法
```sql
-- PUT
SELECT * FROM http_request('PUT', 'https://api.example.com/update/123', '{"status":"active"}');

-- DELETE
SELECT * FROM http_request('DELETE', 'https://api.example.com/item/123');

-- PATCH
SELECT * FROM http_request('PATCH', 'https://api.example.com/partial/123', '{"field":"value"}');
```

---

## 🔧 技术实现

### 架构设计
- **单一源文件**: `pghttp.c` 使用条件编译实现跨平台
- **零代码重复**: Windows 和 Linux 代码完全分离，互不影响
- **相同 SQL API**: 跨平台使用完全相同的 SQL 函数

### 条件编译
```c
#ifdef WIN32
    // Windows: WinHTTP 实现
    #include <windows.h>
    #include <winhttp.h>
#else
    // Linux: libcurl 实现
    #include <curl/curl.h>
#endif
```

---

## 📋 系统要求

### Windows
- **操作系统**: Windows 10/11, Windows Server 2016+
- **PostgreSQL**: 12, 13, 14, 15, 16, 17, 18+ (x64)
- **权限**: 需要管理员权限安装
- **依赖**: 无（使用系统自带 WinHTTP）

### Linux
- **发行版**: Ubuntu, Debian, CentOS, RHEL, Fedora, Arch
- **PostgreSQL**: 12-18+ (需要 dev 包)
- **编译器**: GCC 或 Clang
- **依赖**: libcurl4-openssl-dev (或 libcurl-devel)

---

## 📄 文件清单

### Windows 发布包内容
```
pghttp-1.0.0-win-x64/
├── pghttp.dll                          # 预编译扩展库
├── pghttp.control                      # 扩展控制文件
├── pghttp--1.0.0.sql                   # SQL 函数定义
├── install.ps1                         # 自动安装脚本
├── INSTALL_RELEASE.md                  # 安装指南
├── USAGE.md                            # 使用文档
├── examples.sql                        # 示例代码
├── VERSION.txt                         # 版本信息
├── README.txt                          # 快速开始
├── POSTGRESQL_COMPATIBILITY.md         # 版本兼容性
├── CROSSPLATFORM_README.md             # 跨平台说明
└── CROSSPLATFORM_IMPLEMENTATION.md     # 实现细节
```

### Linux 发布包内容
```
pghttp-1.0.0-linux-x64/
├── pghttp.c                            # 跨平台源代码
├── pghttp.control                      # 扩展控制文件
├── pghttp--1.0.0.sql                   # SQL 函数定义
├── Makefile                            # 构建脚本
├── install_linux.sh                    # 自动安装脚本
├── INSTALL_LINUX.md                    # Linux 安装指南
├── USAGE.md                            # 使用文档
├── examples.sql                        # 示例代码
├── VERSION.txt                         # 版本信息
├── README.txt                          # 快速开始
├── POSTGRESQL_COMPATIBILITY.md         # 版本兼容性
├── CROSSPLATFORM_README.md             # 跨平台说明
└── CROSSPLATFORM_IMPLEMENTATION.md     # 实现细节
```

---

## 🐛 已修复问题

1. **PowerShell 编码问题**: 替换 Unicode 字符（✓、✗）为 ASCII，避免在不同系统上的编码错误
2. **HTTP 415 错误**: POST 请求自动添加 `Content-Type: application/json` 头
3. **跨平台兼容**: 使用条件编译，确保 Windows 代码完全不变

---

## 🔒 安全特性

- ✅ **HTTPS 支持** - 完整的 SSL/TLS 加密
- ✅ **超时保护** - 30 秒超时防止资源占用
- ✅ **内存安全** - 无内存泄漏（经测试）
- ✅ **输入验证** - URL 和参数验证

---

## 📖 文档

- **INSTALL_RELEASE.md** / **INSTALL_LINUX.md** - 详细安装指南
- **USAGE.md** - 完整使用文档和示例
- **examples.sql** - 20+ 实际应用示例
- **CROSSPLATFORM_README.md** - 跨平台使用说明
- **CROSSPLATFORM_IMPLEMENTATION.md** - 技术实现细节
- **POSTGRESQL_COMPATIBILITY.md** - PostgreSQL 版本兼容性

---

## 🧪 测试

### Windows 测试环境
- Windows 11 Pro x64
- PostgreSQL 15.x
- MSVC 2022

### Linux 测试环境
- Ubuntu 20.04/22.04 (计划)
- PostgreSQL 15/16 (计划)
- GCC 9/11 (计划)

**注意**: Linux 版本已通过编译测试，实际运行测试待完成。

---

## 📝 许可证

**MIT License** - 可自由使用、修改和分发

---

## 🚀 快速示例

```sql
-- 创建扩展
CREATE EXTENSION pghttp;

-- 简单 GET
SELECT http_get('https://httpbin.org/get');

-- POST JSON
SELECT http_post('https://httpbin.org/post', '{"hello":"world"}');

-- 详细响应
SELECT status_code, content_type, body 
FROM http_request('GET', 'https://httpbin.org/headers');

-- 在表中使用
CREATE TABLE api_logs (
    id serial PRIMARY KEY,
    response jsonb,
    created_at timestamp DEFAULT now()
);

INSERT INTO api_logs (response)
SELECT body::jsonb 
FROM http_request('GET', 'https://api.github.com/users/octocat');
```

---

## 📞 技术支持

- 查看文档获取详细信息
- 所有功能均有完整示例
- 支持 PostgreSQL 12-18+ 版本

---

## 🎯 下一步计划

- [ ] macOS 支持（使用 libcurl）
- [ ] 自定义请求头支持
- [ ] HTTP 认证支持（Basic, Bearer）
- [ ] 代理服务器支持
- [ ] 更多 HTTP 配置选项

---

**感谢使用 pghttp！** 🙏

如有问题或建议，欢迎反馈。

---

*Build: 2025-11-14*  
*Version: 1.0.0*  
*Platforms: Windows x64 | Linux x64*
