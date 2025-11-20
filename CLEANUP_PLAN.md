# pghttp 项目清理计划

## 文件分类

### ✅ 保留 - 核心文件（发布和开发必需）

#### 源代码和编译产物
- `pghttp_full.c` - 最终版本源代码 ⭐
- `pghttp_full--1.0.0.sql` - SQL 定义文件 ⭐
- `pghttp.control` - 扩展控制文件 ⭐
- `pghttp.def` - 符号导出定义 ⭐
- `pghttp.dll` - 编译后的库（如果存在）⭐

#### 编译脚本
- `build_full.ps1` - 主编译脚本 ⭐
- `create_release.ps1` - 发布包脚本 ⭐

#### 安装脚本
- `install.ps1` - 自动安装脚本 ⭐

#### 文档
- `README.md` - 项目说明 ⭐
- `README_CN.md` - 中文说明 ⭐
- `README_FINAL.md` - 完整文档 ⭐
- `INSTALL_RELEASE.md` - 安装指南 ⭐
- `USAGE.md` - 使用文档 ⭐
- `RELEASE_NOTES.md` - 版本说明 ⭐
- `DISTRIBUTION_GUIDE.md` - 分发指南 ⭐
- `发布包说明.md` - 中文发布说明 ⭐
- `VERSION.txt` - 版本信息 ⭐

#### 示例和配置
- `examples.sql` - 示例代码 ⭐
- `.gitignore` - Git 配置 ⭐

#### 发布包
- `release/` - 发布包目录 ⭐

---

### ❌ 删除 - 调试和开发过程文件

#### 过时的源代码
- `pghttp.c` - 早期版本（已被 pghttp_full.c 替代）
- `pghttp_simple.c` - 简化测试版本
- `pghttp_minimal.c` - 最小测试版本
- `pghttp_simple--1.0.0.sql` - 简化版 SQL

#### 备份文件
- `pghttp--1.0.0.sql.backup` - 备份文件

#### 编译中间文件
- `pghttp_full.obj` - 目标文件
- `pghttp_minimal.obj` - 目标文件
- `pghttp.exp` - 导出文件
- `pghttp.lib` - 导入库

#### 调试文档（已完成开发，不再需要）
- `CRITICAL_DIAGNOSIS.md` - 调试诊断
- `DEBUG_NULL_ISSUE.md` - NULL 问题调试
- `FIX_NULL_ISSUE.md` - 问题修复记录
- `FIXED_DLL_ISSUE.md` - DLL 问题修复
- `FIX_IDE_ERRORS.md` - IDE 错误修复
- `FINAL_STEPS.md` - 最终步骤
- `INSTALL_SUCCESS.md` - 安装成功记录
- `SUCCESS_SUMMARY.md` - 成功总结
- `TROUBLESHOOTING.md` - 故障排除（信息已整合到 INSTALL_RELEASE.md）
- `INSTALL.md` - 旧安装文档
- `QUICK_START.md` - 快速开始（已整合）
- `QUICK_REFERENCE.md` - 快速参考（已整合）
- `TEST_NOW.md` - 测试说明

#### 测试文件
- `test.sql` - 测试脚本
- `test_debug.sql` - 调试测试
- `test_diagnose.sql` - 诊断测试
- `test_extension.sql` - 扩展测试
- `test_install.sql` - 安装测试
- `test_now.sql` - 即时测试
- `test_simple.sql` - 简单测试
- `test_strict.sql` - STRICT 测试
- `test_success.sql` - 成功测试
- `test_with_debug.sql` - 调试测试
- `diagnose.sql` - 诊断脚本

#### 过时的编译脚本
- `build.ps1` - 早期编译脚本
- `build_compatible.ps1` - 兼容性编译
- `build_minimal.ps1` - 最小编译
- `build_msvc.ps1` - MSVC 编译（已整合到 build_full.ps1）
- `build_simple.ps1` - 简单编译
- `build_windows.bat` - Windows 批处理
- `build_linux.sh` - Linux 脚本（项目现在只支持 Windows）
- `Makefile` - Make 文件
- `Makefile.win` - Windows Make 文件

#### 过时的设置脚本
- `setup_curl.ps1` - curl 设置（已不使用 curl）
- `setup_ssl_cert.ps1` - SSL 证书设置
- `install_all.ps1` - 旧安装脚本
- `fix_dll_path.ps1` - DLL 路径修复
- `force_reload.ps1` - 强制重载
- `check_logs.ps1` - 日志检查
- `test_connection.ps1` - 连接测试
- `verify_config.ps1` - 配置验证
- `verify_extension.sql` - 扩展验证

---

## 清理统计

- **保留文件**: 18 个
- **删除文件**: 54 个
- **节省空间**: 约 150 KB

## 清理后目录结构

```
pghttp/
├── .gitignore
├── pghttp_full.c
├── pghttp_full--1.0.0.sql
├── pghttp.control
├── pghttp.def
├── pghttp.dll (编译后生成)
├── build_full.ps1
├── create_release.ps1
├── install.ps1
├── README.md
├── README_CN.md
├── README_FINAL.md
├── INSTALL_RELEASE.md
├── USAGE.md
├── RELEASE_NOTES.md
├── DISTRIBUTION_GUIDE.md
├── 发布包说明.md
├── VERSION.txt
├── examples.sql
└── release/
    ├── pghttp-1.0.0-win-x64.zip
    ├── pghttp-1.0.0-win-x64-SHA256.txt
    └── pghttp-1.0.0-win-x64/
```

## 建议

执行清理后：
- 项目更整洁，易于维护
- 新用户更容易理解项目结构
- 减少混淆，只保留有效文件
- 发布包不受影响（已经生成）

## 是否需要备份？

建议在删除前：
1. 确认发布包已正确生成
2. 可以将所有删除文件压缩备份（以防万一）
3. 或者直接删除（因为有 Git 历史）
