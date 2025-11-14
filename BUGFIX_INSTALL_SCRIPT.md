# install.ps1 编码问题修复

## 问题描述

在另一台电脑上运行 `install.ps1` 时出现 PowerShell 解析错误：

```
所在位置 D:\PGSQL\pghttp-1.0.0-win-x64\install.ps1:217 字符: 13
+ Write-Host "Next Steps:" -ForegroundColor Cyan
+             ~~~~
表达式或语句中包含意外的标记"Next"。
```

## 根本原因

脚本中包含 Unicode 特殊字符（✓、✗、⚠ 等），在某些 Windows 系统编码环境下（如 GB2312），PowerShell 无法正确解析这些字符，导致语法错误。

## 修复方案

### 1. 移除所有 Unicode 特殊字符

**之前**：
```powershell
Write-Host "✓ Found PostgreSQL at: $path" -ForegroundColor Green
Write-Host "✗ This script must be run as Administrator!" -ForegroundColor Red
Write-Host "⚠ Cannot find PostgreSQL service automatically" -ForegroundColor Yellow
```

**之后**：
```powershell
Write-Host "[OK] Found PostgreSQL at: $path" -ForegroundColor Green
Write-Host "[ERROR] This script must be run as Administrator!" -ForegroundColor Red
Write-Host "[WARNING] Cannot find PostgreSQL service automatically" -ForegroundColor Yellow
```

### 2. 使用纯 ASCII 字符

所有消息前缀改为：
- `✓` → `[OK]`
- `✗` → `[ERROR]`
- `⚠` → `[WARNING]`

### 3. 简化 Here-String

**之前**：
```powershell
Write-Host @"
========================================
✓ Installation Complete!
========================================
"@ -ForegroundColor Green
```

**之后**：
```powershell
Write-Host "========================================"
Write-Host "  Installation Complete!"
Write-Host "========================================"
```

## 兼容性改进

### 编码兼容性
- ✅ UTF-8 系统
- ✅ GB2312/GBK 系统
- ✅ 其他 ANSI 编码系统

### PowerShell 版本兼容性
- ✅ PowerShell 5.1 (Windows PowerShell)
- ✅ PowerShell 7.x (PowerShell Core)

## 测试验证

### 语法验证
```powershell
# 验证脚本语法正确
$null = [System.Management.Automation.PSParser]::Tokenize(
    (Get-Content 'install.ps1' -Raw), 
    [ref]$null
)
# 如果没有错误，语法正确
```

### 实际测试
在以下环境测试通过：
- ✅ Windows 10 (UTF-8)
- ✅ Windows 11 (UTF-8)
- ✅ Windows Server (GB2312)

## 影响范围

### 修改的文件
- `install.ps1` - 主安装脚本

### 功能影响
- ✅ 无功能变化
- ✅ 仅改变显示文本
- ✅ 更好的跨系统兼容性

## 新发布包

已重新生成发布包，包含修复后的脚本：
- `release/pghttp-1.0.0-win-x64.zip`
- SHA256 校验和已更新

## 用户操作

### 如果已下载旧版本
1. **方案 1**：重新下载最新发布包
2. **方案 2**：只替换 `install.ps1` 文件
   - 下载新版 `install.ps1`
   - 替换到解压目录

### 如果遇到编码错误
```powershell
# 使用 UTF-8 编码运行
powershell -ExecutionPolicy Bypass -NoProfile -File install.ps1
```

## 最佳实践建议

### 未来开发
1. ✅ 脚本中避免使用 Unicode 特殊字符
2. ✅ 使用 ASCII 兼容的符号 ([], ->, etc.)
3. ✅ 在多种编码环境测试
4. ✅ 提供编码说明文档

### 文件保存
- 使用 **UTF-8 with BOM** 保存 PowerShell 脚本
- 或完全使用 ASCII 字符

## 相关链接

- Issue: 在 GB2312 系统上运行失败
- Fix: 替换 Unicode 字符为 ASCII
- Version: v1.0.0 (updated)

---

**修复完成时间**: 2025-11-14  
**修复类型**: 兼容性改进  
**优先级**: 高（影响安装）
