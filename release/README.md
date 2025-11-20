# pghttp v1.0.0 发布包

**PostgreSQL HTTP 扩展 - 跨平台版本**

---

## 📦 发布文件

### 1. Windows 预编译版本 (推荐)
```
pghttp-1.0.0-win-x64.zip                 (33.31 KB)
pghttp-1.0.0-win-x64-SHA256.txt          (校验文件)
```

**内容**: 预编译 DLL + 自动安装脚本 + 完整文档  
**适用**: Windows 10/11, Server 2016+  
**PostgreSQL**: 12-18+ (x64)

**快速安装**:
```powershell
# 1. 解压 ZIP 文件
# 2. 以管理员身份运行 PowerShell
.\install.ps1

# 3. 在 PostgreSQL 中
CREATE EXTENSION pghttp;
```

---

### 2. Linux 源码版本
```
pghttp-1.0.0-linux-x64.zip               (31.86 KB)
pghttp-1.0.0-linux-x64-SHA256.txt        (校验文件)
```

**内容**: C 源码 + Makefile + 安装脚本 + 完整文档  
**适用**: Ubuntu, Debian, CentOS, RHEL, Fedora, Arch  
**PostgreSQL**: 12-18+

**快速安装**:
```bash
# 1. 安装依赖（Ubuntu/Debian）
sudo apt-get install postgresql-server-dev-all libcurl4-openssl-dev gcc make

# 2. 编译安装
make clean && make
sudo make install

# 3. 在 PostgreSQL 中
CREATE EXTENSION pghttp;
```

---

## ✨ 功能特性

- ✅ HTTP/HTTPS GET/POST 请求
- ✅ 支持所有 HTTP 方法（PUT, DELETE, PATCH 等）
- ✅ 详细响应（状态码 + Content-Type + Body）
- ✅ UTF-8 编码支持
- ✅ 30 秒超时保护
- ✅ 自动添加 Content-Type: application/json

**Windows**: 使用原生 WinHTTP API，**零外部依赖**  
**Linux**: 使用行业标准 libcurl

---

## 🚀 快速示例

```sql
-- 创建扩展
CREATE EXTENSION pghttp;

-- GET 请求
SELECT http_get('https://api.github.com/users/octocat');

-- POST 请求
SELECT http_post('https://httpbin.org/post', '{"name":"John"}');

-- 详细响应
SELECT status_code, content_type, body 
FROM http_request('GET', 'https://httpbin.org/json');
```

---

## 📚 文档

- **RELEASE_NOTES_v1.0.0.md** - 完整发布说明（推荐阅读）
- **Windows 包内**: INSTALL_RELEASE.md, USAGE.md, examples.sql
- **Linux 包内**: INSTALL_LINUX.md, USAGE.md, examples.sql
- **跨平台**: CROSSPLATFORM_README.md

---

## 🔒 SHA256 校验

**Windows**:
```powershell
Get-FileHash pghttp-1.0.0-win-x64.zip -Algorithm SHA256
```

**Linux**:
```bash
sha256sum pghttp-1.0.0-linux-x64.zip
```

校验值见对应的 SHA256.txt 文件。

---

## 📋 版本信息

- **版本**: 1.0.0
- **发布日期**: 2025-11-14
- **平台**: Windows x64 / Linux x64
- **PostgreSQL**: 12, 13, 14, 15, 16, 17, 18+
- **许可证**: MIT

---

## 🎯 选择哪个版本？

| 平台 | 推荐包 | 说明 |
|------|--------|------|
| Windows | `pghttp-1.0.0-win-x64.zip` | 预编译，开箱即用 |
| Linux | `pghttp-1.0.0-linux-x64.zip` | 源码，需编译（简单） |
| macOS | `pghttp-1.0.0-linux-x64.zip` | 使用 Linux 源码包（未测试） |

---

## 📞 需要帮助？

1. 查看 **RELEASE_NOTES_v1.0.0.md** 了解详细信息
2. 查看包内 **INSTALL** 文件获取安装帮助
3. 查看 **examples.sql** 获取 20+ 实用示例

---

**Happy Coding! 🚀**

*pghttp - 让 PostgreSQL 轻松调用 HTTP API*
