# pghttp v1.0.0 最终发布说明 (Windows)

> **⚠️ 重要**: 本版本**仅支持 Windows 平台**。Linux/macOS 支持计划在 v1.1.0 提供。详见 [平台支持说明](PLATFORM_SUPPORT.md)

## 📦 发布信息

**版本**: 1.0.0  
**发布日期**: 2025-11-14  
**平台**: Windows only (使用 WinHTTP API)  
**编译基于**: PostgreSQL 15.x (Windows x64)  
**兼容版本**: PostgreSQL 12-18+ (需重新编译)

## ✨ 核心特性

### HTTP 功能
- ✅ HTTP GET 请求
- ✅ HTTP POST 请求（自动添加 Content-Type: application/json）
- ✅ 支持所有 HTTP 方法（PUT, DELETE, PATCH 等）
- ✅ 自定义请求头支持
- ✅ UTF-8 完整支持
- ✅ 详细响应（状态码、Content-Type、响应体）

### 系统特性
- ✅ 零外部依赖（使用 Windows 原生 WinHTTP）
- ✅ 30 秒超时保护
- ✅ 自动安装脚本
- ✅ 完整的中英文文档

## 🎯 PostgreSQL 版本兼容性

### 当前发布包
- **编译版本**: PostgreSQL 15.x
- **平台**: Windows x64
- **编译器**: MSVC 2022

### 支持的版本
| PostgreSQL 版本 | 状态 | 说明 |
|----------------|------|------|
| 12.x | ✅ 理论支持 | 需重新编译 |
| 13.x | ✅ 理论支持 | 需重新编译 |
| 14.x | ✅ 理论支持 | 需重新编译 |
| **15.x** | **✅ 已测试** | **可直接使用当前包** |
| 16.x | ✅ 理论支持 | 需重新编译 |
| **17.x** | **✅ 理论支持** | 需重新编译 |
| **18.x** | **✅ 理论支持** | 需重新编译 |

> **重要**: 源代码完全兼容所有版本，但不同 PostgreSQL 主版本需要使用对应版本的开发包重新编译

## 📥 发布包详情

**文件名**: `pghttp-1.0.0-win-x64.zip`  
**大小**: 26.2 KB  
**SHA256**: `231FB6E7ACD1E543AF0767E2DD122635CA85A1CD55C0EF0C463CDAA6531FDC16`

### 包含文件
```
pghttp-1.0.0-win-x64/
├── pghttp.dll                      # 扩展库（编译好的二进制）
├── pghttp.control                  # 扩展控制文件
├── pghttp--1.0.0.sql              # SQL 函数定义
├── install.ps1                     # 自动安装脚本
├── examples.sql                    # 示例查询
├── INSTALL_RELEASE.md             # 安装指南
├── USAGE.md                        # 使用文档
├── README.md                       # 项目说明
├── VERSION.txt                     # 版本信息
├── POSTGRESQL_COMPATIBILITY.md    # 版本兼容性详细说明
└── 快速安装指南.txt                # 中文快速入门
```

## 🚀 快速开始

### 1. 检查你的 PostgreSQL 版本
```sql
SELECT version();
```

### 2. 选择安装方式

#### 如果是 PostgreSQL 15.x
✅ **直接使用当前发布包**
```powershell
# 解压后运行
.\install.ps1
```

#### 如果是 PostgreSQL 17 或 18
⚠️ **需要重新编译**
```powershell
# 1. 修改 build_full.ps1，第 6 行改为你的 PG 路径
$pgPath = "C:\Program Files\PostgreSQL\17"

# 2. 编译
.\build_full.ps1

# 3. 安装
.\install.ps1
```

### 3. 在 PostgreSQL 中使用
```sql
-- 创建扩展
CREATE EXTENSION pghttp;

-- 测试 GET
SELECT http_get('https://httpbin.org/get');

-- 测试 POST
SELECT http_post(
    'https://httpbin.org/post',
    '{"test": "data"}'
);
```

## 🔧 已修复问题

### v1.0.0 修复记录

1. **PowerShell 脚本编码问题** (2025-11-14)
   - 移除 Unicode 特殊字符（✓、✗、⚠）
   - 改用 ASCII 兼容标记（[OK]、[ERROR]、[WARNING]）
   - 修复在 GB2312/GBK 系统上的解析错误

2. **HTTP POST Content-Type 问题** (2025-11-14)
   - 自动为 POST 请求添加 `Content-Type: application/json` 头
   - 修复 415 Unsupported Media Type 错误
   - 支持自定义头覆盖默认 Content-Type

## 📚 文档说明

| 文档 | 用途 | 适合人群 |
|------|------|---------|
| `快速安装指南.txt` | 5 分钟快速上手 | 所有用户 |
| `INSTALL_RELEASE.md` | 详细安装说明 | 首次安装 |
| `USAGE.md` | API 使用文档 | 开发者 |
| `POSTGRESQL_COMPATIBILITY.md` | 版本兼容性详解 | 多版本用户 |
| `VERSION_COMPATIBILITY_SUMMARY.md` | 兼容性快速参考 | 快速查阅 |
| `examples.sql` | 示例代码 | 学习参考 |

## 🎓 使用示例

### 基础 GET 请求
```sql
SELECT http_get('https://api.github.com/users/github');
```

### POST 请求（自动 Content-Type）
```sql
SELECT http_post(
    'http://localhost:3000/api/users',
    '{"name": "张三", "age": 25}'
);
```

### 自定义请求头
```sql
SELECT http_post(
    'https://api.example.com/data',
    '{"key": "value"}',
    'Authorization: Bearer YOUR_TOKEN'
);
```

### 详细响应信息
```sql
SELECT * FROM http_request(
    'GET',
    'https://httpbin.org/get'
);
-- 返回: (status_code, content_type, body)
```

## ⚙️ 编译要求（仅针对其他 PG 版本）

如果你需要为 PostgreSQL 17/18 重新编译：

### 必需工具
- Visual Studio 2019/2022 (含 MSVC 编译器)
- PostgreSQL 17/18 Windows 安装包（包含开发头文件）

### 编译步骤
```powershell
# 1. 克隆或下载源代码
git clone <repository-url>
cd pghttp

# 2. 修改编译脚本
# 编辑 build_full.ps1，第 6 行
$pgPath = "你的 PostgreSQL 路径"

# 3. 编译
.\build_full.ps1

# 4. 安装
.\install.ps1
```

### 验证编译
```sql
-- 在 PostgreSQL 中
CREATE EXTENSION pghttp;
SELECT http_get('https://httpbin.org/get');
```

## 🔐 安全考虑

- ✅ 使用 Windows 原生 WinHTTP，经过微软安全审计
- ✅ 支持 HTTPS/TLS 加密连接
- ✅ 30 秒超时防止挂起
- ⚠️ 确保 URL 来源可信（避免 SSRF 攻击）
- ⚠️ 敏感数据（如 API Token）应通过 headers 参数传递

## 🆘 故障排除

### 问题 1: 安装脚本报错
**症状**: PowerShell 语法错误  
**解决**: 确保使用最新版本的 `install.ps1`（已修复编码问题）

### 问题 2: HTTP 415 错误
**症状**: Unsupported Media Type  
**解决**: 使用 v1.0.0+，已自动添加 Content-Type 头

### 问题 3: 扩展无法加载
**症状**: "incompatible with server" 错误  
**解决**: 重新编译（DLL 必须与 PostgreSQL 版本匹配）

### 问题 4: 中文乱码
**症状**: 响应中文显示为 ���  
**解决**: 
```sql
-- 检查数据库编码
SHOW server_encoding;  -- 应该是 UTF8

-- 检查客户端编码
SHOW client_encoding;  -- 应该是 UTF8
```

## 📊 性能特性

- **内存使用**: 最小化（使用 PostgreSQL 内存管理）
- **超时控制**: 30 秒连接和接收超时
- **并发支持**: 支持多个并发请求
- **响应大小**: 无硬性限制（受 PostgreSQL 配置影响）

## 🌟 未来计划

### v1.1.0 (计划中)
- [ ] **Linux 支持**（基于 libcurl）
- [ ] Ubuntu/Debian 预编译包
- [ ] CentOS/RHEL 预编译包
- [ ] macOS 支持

### v1.2.0 及以后
- [ ] 支持异步请求
- [ ] 添加请求缓存
- [ ] 支持代理配置
- [ ] 添加请求重试机制
- [ ] 提供 PG 16/17/18 预编译包

### 平台路线图
当前版本专注 Windows 平台，详细的跨平台计划请查看 [PLATFORM_SUPPORT.md](PLATFORM_SUPPORT.md)

## 📜 许可证

MIT License - 自由使用、修改和分发

## 🙏 致谢

- PostgreSQL 社区提供的扩展开发文档
- Windows WinHTTP API 团队
- 所有测试和反馈的用户

## 📞 支持

- **文档**: 查看项目中的 Markdown 文档
- **问题**: 检查 `POSTGRESQL_COMPATIBILITY.md` 和 `INSTALL_RELEASE.md`
- **示例**: 参考 `examples.sql`

## 版本历史

### v1.0.0 (2025-11-14)
- ✅ 初始发布
- ✅ HTTP GET/POST 支持
- ✅ 自动 Content-Type 头
- ✅ UTF-8 完整支持
- ✅ Windows 原生实现
- ✅ PostgreSQL 12-18+ 兼容性
- ✅ 完整文档和示例
- ✅ 自动安装脚本

---

## 🎉 总结

`pghttp v1.0.0` 是一个：
- ✅ **功能完整**的 PostgreSQL HTTP 扩展
- ✅ **版本兼容**（支持 PG 12-18+）
- ✅ **易于安装**（一键脚本）
- ✅ **零依赖**（Windows 原生）
- ✅ **文档齐全**（中英文）

**适用场景**：
- 数据库触发器调用 webhook
- 定时任务调用 REST API
- 数据同步到外部系统
- 集成第三方服务

**立即开始使用吧！** 🚀

---

**SHA256**: `231FB6E7ACD1E543AF0767E2DD122635CA85A1CD55C0EF0C463CDAA6531FDC16`  
**下载地址**: `release/pghttp-1.0.0-win-x64.zip`  
**发布日期**: 2025-11-14
