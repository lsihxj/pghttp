# pghttp 发布包分发指南

## 📦 发布包内容

发布包已成功创建在 `release` 目录中：

```
release/
├── pghttp-1.0.0-win-x64.zip          # 主发布包（约 25 KB）
├── pghttp-1.0.0-win-x64-SHA256.txt   # 校验和文件
└── pghttp-1.0.0-win-x64/             # 解压后的内容
    ├── install.ps1                   # 自动安装脚本
    ├── pghttp.dll                    # 扩展库
    ├── pghttp.control                # 扩展控制文件
    ├── pghttp--1.0.0.sql            # SQL 定义
    ├── INSTALL_RELEASE.md           # 安装指南
    ├── USAGE.md                      # 使用文档
    ├── examples.sql                  # 示例代码
    ├── VERSION.txt                   # 版本信息
    └── README.txt                    # 快速入门
```

## 🚀 分发方式

### 方式一：直接分发 ZIP 文件（推荐）

将 `pghttp-1.0.0-win-x64.zip` 发送给用户，用户只需：

1. **解压 ZIP 文件**到任意目录
2. **以管理员身份运行 PowerShell**
3. **进入解压目录**并运行：
   ```powershell
   .\install.ps1
   ```
4. **在 PostgreSQL 中创建扩展**：
   ```sql
   CREATE EXTENSION pghttp;
   ```

### 方式二：通过网络分发

上传到以下任一平台：
- GitHub Releases
- 内部文件服务器
- 网盘（百度网盘、OneDrive 等）
- FTP/HTTP 服务器

提供下载链接和 SHA256 校验和供用户验证。

### 方式三：企业内部部署

对于企业环境，可以：

1. **集中式部署**：
   - 将 ZIP 包放在共享网络驱动器
   - 创建批量部署脚本
   - 使用组策略自动部署

2. **Docker/容器化**（未来支持）：
   - 将扩展集成到 PostgreSQL 容器镜像
   - 使用 Docker Compose 管理

## 📋 用户安装步骤（简化版）

为用户提供以下简洁指南：

```
==== pghttp PostgreSQL 扩展安装指南 ====

前提条件：
✓ Windows 10/11
✓ PostgreSQL 15.x (Windows 版)
✓ 管理员权限

安装步骤：
1. 解压 pghttp-1.0.0-win-x64.zip
2. 管理员身份运行 PowerShell
3. cd 到解压目录
4. 运行: .\install.ps1
5. 在 psql 中运行: CREATE EXTENSION pghttp;

测试：
SELECT http_get('https://httpbin.org/get');

详细文档请查看 INSTALL_RELEASE.md
```

## 🔒 安全验证

建议用户安装前验证 SHA256 校验和：

```powershell
# 计算下载文件的 SHA256
Get-FileHash pghttp-1.0.0-win-x64.zip -Algorithm SHA256

# 对比 pghttp-1.0.0-win-x64-SHA256.txt 中的值
```

## 📝 分发清单

分发前确认：

- [ ] ZIP 文件完整（约 25 KB）
- [ ] 包含 SHA256 校验和文件
- [ ] 提供安装文档链接
- [ ] 说明系统要求（Windows + PostgreSQL 15.x）
- [ ] 提供技术支持联系方式
- [ ] 说明许可证（MIT）

## 🎯 不同用户场景

### 场景 1: 技术用户
- 直接提供 ZIP + SHA256
- 引导到 INSTALL_RELEASE.md
- 提供 examples.sql 参考

### 场景 2: 非技术用户
- 提供详细的图文安装教程
- 录制安装视频
- 提供远程协助

### 场景 3: 企业批量部署
- 提供批量安装脚本模板
- 说明网络、防火墙要求
- 提供集中式管理方案

## 📧 支持信息

建议在分发时附带：

- **安装问题**：参考 INSTALL_RELEASE.md 故障排除章节
- **使用问题**：查看 USAGE.md 和 examples.sql
- **技术支持**：提供邮箱或 Issue 跟踪系统链接

## 🔄 版本更新

当发布新版本时：

1. 更新 `VERSION.txt` 中的版本号
2. 重新运行 `build_full.ps1` 编译
3. 运行 `create_release.ps1` 打包
4. 生成更新日志（CHANGELOG.md）
5. 通知现有用户

## 📊 分发统计（可选）

建议跟踪：
- 下载次数
- 安装成功率
- 常见问题反馈
- 用户使用场景

## ⚖️ 许可证说明

pghttp 使用 **MIT License**：
- ✅ 可自由使用、修改、分发
- ✅ 可用于商业项目
- ✅ 无需支付费用
- ⚠️ 需保留原始版权声明
- ⚠️ 不提供任何担保

## 🎉 分发检查清单

最终分发前检查：

```
[✓] ZIP 文件创建成功
[✓] SHA256 校验和生成
[✓] 所有必需文件包含
[✓] 文档完整准确
[✓] 安装脚本测试通过
[✓] 在干净环境测试安装
[✓] 示例代码可运行
[✓] 版本号正确
[✓] 许可证文件包含
```

---

## 快速分发命令

```powershell
# 1. 构建扩展
.\build_full.ps1

# 2. 创建发布包
.\create_release.ps1

# 3. 发布包位置
dir .\release\pghttp-1.0.0-win-x64.zip

# 4. 上传到分发平台
# （根据实际情况选择上传方式）
```

---

**发布包已准备就绪，可以安全分发！** 🚀
