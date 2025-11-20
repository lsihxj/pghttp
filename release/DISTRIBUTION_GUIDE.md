# pghttp v1.0.0 分发指南

---

## 📦 发布包清单

### 核心发布文件（必须分发）

#### Windows 版本
- ✅ **pghttp-1.0.0-win-x64.zip** (33.31 KB)
  - 预编译扩展 + 安装脚本 + 完整文档
- ✅ **pghttp-1.0.0-win-x64-SHA256.txt** (0.36 KB)
  - SHA256 校验和

#### Linux 版本
- ✅ **pghttp-1.0.0-linux-x64.zip** (31.86 KB)
  - 源代码 + Makefile + 安装脚本 + 完整文档
- ✅ **pghttp-1.0.0-linux-x64-SHA256.txt** (0.15 KB)
  - SHA256 校验和

#### 说明文档（推荐分发）
- ✅ **README.md** (3.14 KB)
  - 快速开始指南
- ✅ **RELEASE_NOTES_v1.0.0.md** (7.76 KB)
  - 完整发布说明

**总大小**: 约 76 KB

---

## 🎯 分发方式

### 方案 A: 最小分发
只分发 ZIP 包，适合空间受限场景：
```
pghttp-1.0.0-win-x64.zip
pghttp-1.0.0-win-x64-SHA256.txt
pghttp-1.0.0-linux-x64.zip
pghttp-1.0.0-linux-x64-SHA256.txt
```

### 方案 B: 推荐分发（推荐）
包含所有核心文件和文档：
```
pghttp-1.0.0-win-x64.zip
pghttp-1.0.0-win-x64-SHA256.txt
pghttp-1.0.0-linux-x64.zip
pghttp-1.0.0-linux-x64-SHA256.txt
README.md
RELEASE_NOTES_v1.0.0.md
```

### 方案 C: 完整分发
包含源目录供高级用户查看：
```
pghttp-1.0.0-win-x64.zip
pghttp-1.0.0-win-x64-SHA256.txt
pghttp-1.0.0-win-x64/              (解压目录)
pghttp-1.0.0-linux-x64.zip
pghttp-1.0.0-linux-x64-SHA256.txt
pghttp-1.0.0-linux-x64/            (解压目录)
README.md
RELEASE_NOTES_v1.0.0.md
DISTRIBUTION_GUIDE.md              (本文件)
```

---

## 📋 各包内容清单

### Windows 包内容 (pghttp-1.0.0-win-x64.zip)
```
pghttp-1.0.0-win-x64/
├── pghttp.dll                          # ⚠️ 核心：预编译扩展库
├── pghttp.control                      # ⚠️ 核心：扩展控制文件
├── pghttp--1.0.0.sql                   # ⚠️ 核心：SQL 函数定义
├── install.ps1                         # 🔧 自动安装脚本
├── INSTALL_RELEASE.md                  # 📖 安装指南
├── USAGE.md                            # 📖 使用文档
├── examples.sql                        # 📖 示例代码
├── VERSION.txt                         # 📄 版本信息
├── README.txt                          # 📄 快速开始
├── README.md                           # 📖 项目说明
├── README_CN.md                        # 📖 中文说明
├── POSTGRESQL_COMPATIBILITY.md         # 📖 版本兼容性
├── CROSSPLATFORM_README.md             # 📖 跨平台说明
└── CROSSPLATFORM_IMPLEMENTATION.md     # 📖 实现细节
```

### Linux 包内容 (pghttp-1.0.0-linux-x64.zip)
```
pghttp-1.0.0-linux-x64/
├── pghttp.c                            # ⚠️ 核心：跨平台源代码
├── pghttp.control                      # ⚠️ 核心：扩展控制文件
├── pghttp--1.0.0.sql                   # ⚠️ 核心：SQL 函数定义
├── Makefile                            # 🔧 构建脚本
├── install_linux.sh                    # 🔧 自动安装脚本
├── INSTALL_LINUX.md                    # 📖 Linux 安装指南
├── USAGE.md                            # 📖 使用文档
├── examples.sql                        # 📖 示例代码
├── VERSION.txt                         # 📄 版本信息
├── README.txt                          # 📄 快速开始
├── README.md                           # 📖 项目说明
├── README_CN.md                        # 📖 中文说明
├── POSTGRESQL_COMPATIBILITY.md         # 📖 版本兼容性
├── CROSSPLATFORM_README.md             # 📖 跨平台说明
└── CROSSPLATFORM_IMPLEMENTATION.md     # 📖 实现细节
```

---

## 🌐 分发渠道建议

### 1. GitHub Releases
```markdown
# 发布标题
pghttp v1.0.0 - PostgreSQL HTTP Extension (跨平台)

# 发布说明
使用 RELEASE_NOTES_v1.0.0.md 的内容

# 上传文件
- pghttp-1.0.0-win-x64.zip
- pghttp-1.0.0-win-x64-SHA256.txt
- pghttp-1.0.0-linux-x64.zip
- pghttp-1.0.0-linux-x64-SHA256.txt
```

### 2. 官方网站
创建下载页面：
- 列出两个平台的包
- 提供安装说明链接
- 显示 SHA256 校验值
- 提供快速开始教程

### 3. PostgreSQL 扩展库 (PGXN)
- 提交到 PGXN.org
- 提供完整文档
- 标注支持的 PostgreSQL 版本

### 4. 企业内部分发
- 上传到内部文件服务器
- 更新内部文档库
- 通知相关团队

---

## 📝 下载页面模板

```markdown
# pghttp - PostgreSQL HTTP 扩展

## 下载 v1.0.0

### Windows (推荐新手)
**预编译版本 - 开箱即用**

- [下载 Windows x64](pghttp-1.0.0-win-x64.zip) (33 KB)
- [SHA256 校验](pghttp-1.0.0-win-x64-SHA256.txt)

**系统要求**: Windows 10/11, PostgreSQL 12-18+

**安装**:
```powershell
# 解压后，以管理员身份运行
.\install.ps1
```

### Linux
**源码版本 - 需要编译**

- [下载 Linux x64](pghttp-1.0.0-linux-x64.zip) (32 KB)
- [SHA256 校验](pghttp-1.0.0-linux-x64-SHA256.txt)

**系统要求**: Ubuntu/Debian/CentOS/RHEL, PostgreSQL 12-18+

**安装**:
```bash
# 安装依赖
sudo apt-get install postgresql-server-dev-all libcurl4-openssl-dev gcc make

# 编译安装
make clean && make && sudo make install
```

## 文档
- [发布说明](RELEASE_NOTES_v1.0.0.md)
- [快速开始](README.md)
```

---

## ✅ 校验和验证

### Windows
```powershell
Get-FileHash pghttp-1.0.0-win-x64.zip -Algorithm SHA256
```

预期 SHA256（前 16 位）:
```
查看 pghttp-1.0.0-win-x64-SHA256.txt
```

### Linux
```bash
sha256sum pghttp-1.0.0-linux-x64.zip
```

预期 SHA256（前 16 位）:
```
查看 pghttp-1.0.0-linux-x64-SHA256.txt
```

---

## 📊 使用统计（可选）

建议在分发时收集以下信息（匿名）：
- 下载次数（Windows vs Linux）
- PostgreSQL 版本分布
- 操作系统版本分布
- 常见问题反馈

---

## 🔄 更新策略

### 小版本更新 (v1.0.x)
- 仅修复 bug
- 保持 API 兼容
- 替换发布包，保留旧版本

### 大版本更新 (v1.x.0)
- 新增功能
- 可能有 API 变更
- 同时提供多个版本

---

## 📞 用户支持

建议提供的支持渠道：
1. **文档优先**: 引导用户查看 INSTALL 和 USAGE 文档
2. **FAQ**: 整理常见问题
3. **Issue Tracker**: GitHub Issues 或内部系统
4. **社区论坛**: PostgreSQL 相关论坛

---

## 🎯 成功指标

发布后跟踪：
- ✅ 下载量
- ✅ 安装成功率
- ✅ 用户反馈
- ✅ Bug 报告数量
- ✅ 文档查看量

---

## 📅 发布检查清单

- [x] Windows 包编译成功
- [x] Linux 包包含所有源文件
- [x] SHA256 校验文件生成
- [x] 所有文档更新
- [x] 版本号一致
- [x] README 和发布说明准备完毕
- [ ] 测试 Windows 安装（已测试）
- [ ] 测试 Linux 编译（待实际环境测试）
- [ ] 更新项目网站（如有）
- [ ] 发布公告准备
- [ ] 备份源代码

---

**发布位置**: `d:/CodeBuddy/pghttp/release/`

**准备日期**: 2025-11-14

**状态**: ✅ 准备就绪，可以分发

---

*此指南由 pghttp 构建系统自动生成*
