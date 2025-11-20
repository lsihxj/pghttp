# pghttp 平台支持快速参考

## 📋 平台支持状态一览表

| 平台 | 状态 | 版本 | 技术实现 | 依赖 |
|------|------|------|---------|------|
| **Windows** | ✅ **已支持** | v1.0.0 | WinHTTP API | 无（系统内置） |
| **Linux** | ❌ 暂不支持 | 计划 v1.1.0 | libcurl | libcurl |
| **macOS** | ❌ 暂不支持 | 计划 v1.1.0 | libcurl | libcurl |
| **FreeBSD** | ❌ 暂无计划 | TBD | - | - |

## 🎯 当前版本 (v1.0.0)

### ✅ Windows 支持详情

**支持的系统**:
- Windows 10 (x64)
- Windows 11 (x64)
- Windows Server 2016+ (x64)

**PostgreSQL 版本**:
- 12.x, 13.x, 14.x, 15.x ✅
- 16.x, 17.x, 18.x ✅
- 需要重新编译匹配 PG 版本

**技术栈**:
- API: Windows WinHTTP
- 编译器: MSVC 2019/2022
- 依赖: 零外部依赖

**安装方式**:
```powershell
# 自动安装脚本
.\install.ps1
```

### ❌ Linux/macOS 现状

**当前版本不支持原因**:
1. 使用 Windows 专有 WinHTTP API
2. 代码中有 `#ifdef WIN32` 条件编译
3. 编译脚本针对 Windows/MSVC

**临时替代方案**:
- 使用现有扩展：`pgsql-http` (https://github.com/pramsey/pgsql-http)
- 使用 PL/Python + requests 库
- 使用外部脚本 + COPY 命令

## 🚀 Linux 支持计划 (v1.1.0)

### 目标平台
- Ubuntu 20.04, 22.04, 24.04
- Debian 10, 11, 12
- CentOS 7, 8, 9
- RHEL 7, 8, 9
- Rocky Linux, AlmaLinux

### 技术方案
**实现**: 使用 libcurl
```c
#ifdef __linux__
#include <curl/curl.h>
// libcurl 实现
#endif

#ifdef WIN32
#include <winhttp.h>
// WinHTTP 实现
#endif
```

### 预计时间线
- 开发: 2-3 天
- 测试: 1-2 周
- 发布: v1.1.0 (时间待定)

## 📊 使用场景建议

### Windows 环境 ✅
**适合**:
- Windows Server 上的 PostgreSQL
- 企业内网环境
- 开发测试环境

**操作**:
- 直接使用 v1.0.0
- 一键安装脚本

### Linux 环境 ⚠️
**当前建议**:
1. **等待 v1.1.0**（如果不急）
2. **使用 pgsql-http**（成熟方案）
   ```bash
   # Ubuntu/Debian
   sudo apt-get install postgresql-server-dev-all libcurl4-openssl-dev
   git clone https://github.com/pramsey/pgsql-http
   cd pgsql-http
   make && sudo make install
   ```
3. **自己实现**（参考 [PLATFORM_SUPPORT.md](PLATFORM_SUPPORT.md)）

### 混合环境 🔄
**场景**: 同时有 Windows 和 Linux 服务器

**方案 A**: 使用不同扩展
- Windows: pghttp v1.0.0
- Linux: pgsql-http

**方案 B**: 统一等待
- 等待 pghttp v1.1.0
- 两个平台使用相同扩展

**方案 C**: 应用层统一
- PostgreSQL 仅存储数据
- HTTP 调用在应用层处理

## 🔍 技术对比

### WinHTTP vs libcurl

| 特性 | WinHTTP (Windows) | libcurl (Linux) |
|------|------------------|-----------------|
| 平台 | Windows only | 跨平台 |
| 依赖 | 零依赖（系统内置） | 需要 libcurl 库 |
| SSL/TLS | Windows 证书存储 | OpenSSL/NSS |
| 性能 | 优秀 | 优秀 |
| API 复杂度 | 中等 | 简单 |
| 文档 | Microsoft 文档 | 丰富社区文档 |

### 为什么 Windows 用 WinHTTP？

**优势**:
1. ✅ 零依赖，系统内置
2. ✅ 性能优化良好
3. ✅ 与 Windows 集成好（证书、代理等）
4. ✅ 编译简单
5. ✅ 分发容易（DLL 自包含）

**劣势**:
1. ❌ 只能 Windows
2. ❌ API 相对复杂

### 为什么 Linux 用 libcurl？

**优势**:
1. ✅ 跨平台标准
2. ✅ 大多数发行版预装
3. ✅ API 简单易用
4. ✅ 功能强大
5. ✅ 社区支持好

**劣势**:
1. ❌ 有外部依赖
2. ❌ SSL 证书配置可能复杂

## 📖 相关文档

| 文档 | 内容 | 适用人群 |
|------|------|---------|
| [PLATFORM_SUPPORT.md](PLATFORM_SUPPORT.md) | 详细平台支持说明 | 开发者、跨平台用户 |
| [INSTALL_RELEASE.md](INSTALL_RELEASE.md) | Windows 安装指南 | Windows 用户 |
| [POSTGRESQL_COMPATIBILITY.md](POSTGRESQL_COMPATIBILITY.md) | PG 版本兼容性 | 所有用户 |
| [RELEASE_FINAL_v1.0.0.md](RELEASE_FINAL_v1.0.0.md) | 发布说明 | 所有用户 |

## ❓ 常见问题

### Q1: 为什么不一开始就支持 Linux？
**A**: 因为：
- WinHTTP 在 Windows 上实现更简单（零依赖）
- 可以更快发布稳定版本
- 后续会添加 Linux 支持

### Q2: Linux 版本什么时候发布？
**A**: 计划在 v1.1.0，具体时间待定。需要：
- 实现 libcurl 版本
- 在多个发行版上测试
- 完善文档

### Q3: 我能在 Linux 上编译当前版本吗？
**A**: ❌ 不能。当前代码使用 WinHTTP API，Linux 上无此 API。

### Q4: 有其他 Linux 替代方案吗？
**A**: ✅ 有：
- `pgsql-http` - 成熟的跨平台扩展
- PL/Python + requests
- 外部脚本 + FOREIGN DATA WRAPPER

### Q5: Docker 容器支持吗？
**A**: 
- Windows 容器: ✅ 可以用 v1.0.0
- Linux 容器: ❌ 等待 v1.1.0

### Q6: 能贡献 Linux 版本吗？
**A**: ✅ 欢迎！参考 [PLATFORM_SUPPORT.md](PLATFORM_SUPPORT.md) 的实现指南。

## 🎯 版本规划

```
v1.0.0 (当前)  ✅ Windows 支持
    ↓
v1.1.0 (计划)  📋 Linux 支持
    ↓
v1.2.0 (计划)  🍎 macOS 支持
    ↓
v2.0.0 (未来)  🌟 统一实现 + 高级特性
```

## 📊 平台市场分析

### PostgreSQL 部署平台分布（估算）

| 平台 | 市场占比 | pghttp 支持 |
|------|---------|------------|
| Linux | ~70% | ❌ v1.0.0, ✅ v1.1.0+ |
| Windows | ~20% | ✅ v1.0.0 |
| macOS | ~5% | ❌ v1.0.0, ✅ v1.2.0+ |
| 其他 | ~5% | ❌ 暂无计划 |

### 目标用户

**v1.0.0 主要用户**:
- Windows Server 环境
- 企业内网系统
- 开发测试环境
- 小型项目

**v1.1.0+ 目标用户**:
- 云服务器（AWS/Azure/GCP）
- 容器化部署
- 大规模生产环境
- 跨平台项目

## 总结

| 项目 | Windows | Linux | macOS |
|------|---------|-------|-------|
| **当前状态** | ✅ v1.0.0 | ❌ 暂不支持 | ❌ 暂不支持 |
| **使用建议** | 直接使用 | 用 pgsql-http 或等待 v1.1.0 | 同 Linux |
| **发布时间** | 2025-11-14 | TBD | TBD |
| **技术方案** | WinHTTP | libcurl (计划) | libcurl (计划) |

---

**最后更新**: 2025-11-14  
**当前版本**: v1.0.0 (Windows only)  
**下一版本**: v1.1.0 (Linux support planned)
