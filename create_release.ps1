# Create pghttp Release Package
# This script creates a distributable release package

$ErrorActionPreference = "Stop"

Write-Host @"
========================================
  Creating pghttp Release Package
========================================
"@ -ForegroundColor Cyan

# Version info
$version = "1.0.0"
$releaseDate = Get-Date -Format "yyyy-MM-dd"
$releaseName = "pghttp-$version-win-x64"
$releaseDir = ".\release\$releaseName"

# Create release directory
Write-Host "`nCreating release directory..." -ForegroundColor Yellow
if (Test-Path ".\release") {
    Remove-Item ".\release" -Recurse -Force
}
New-Item -ItemType Directory -Path $releaseDir -Force | Out-Null
Write-Host "✓ Created: $releaseDir" -ForegroundColor Green

# Check if required files exist
Write-Host "`nChecking required files..." -ForegroundColor Yellow

$requiredFiles = @{
    "pghttp.dll" = "Extension library (compiled)"
    "pghttp.control" = "Extension control file"
    "pghttp--1.0.0.sql" = "SQL definitions"
    "install.ps1" = "Installation script"
    "INSTALL_RELEASE.md" = "Installation guide"
    "USAGE.md" = "Usage documentation"
    "examples.sql" = "Example queries"
    "VERSION.txt" = "Version information"
}

$missingFiles = @()
foreach ($file in $requiredFiles.Keys) {
    if (Test-Path $file) {
        Write-Host "  ✓ $file" -ForegroundColor Green
    } else {
        Write-Host "  ✗ $file - MISSING!" -ForegroundColor Red
        $missingFiles += $file
    }
}

if ($missingFiles.Count -gt 0) {
    Write-Host "`n✗ Missing required files!" -ForegroundColor Red
    Write-Host "  Please ensure the extension is built first:" -ForegroundColor Yellow
    Write-Host "  .\build_full.ps1" -ForegroundColor White
    exit 1
}

# Copy files to release directory
Write-Host "`nCopying files to release package..." -ForegroundColor Yellow

foreach ($file in $requiredFiles.Keys) {
    Copy-Item $file $releaseDir -Force
    Write-Host "  ✓ Copied $file" -ForegroundColor Green
}

# Copy optional documentation
$optionalDocs = @(
    "README.md",
    "README_CN.md",
    "POSTGRESQL_COMPATIBILITY.md",
    "CROSSPLATFORM_README.md",
    "CROSSPLATFORM_IMPLEMENTATION.md"
)

foreach ($doc in $optionalDocs) {
    if (Test-Path $doc) {
        Copy-Item $doc $releaseDir -Force
        Write-Host "  ✓ Copied $doc (optional)" -ForegroundColor Gray
    }
}

# Create README for release
$readmeContent = @"
# pghttp - PostgreSQL HTTP Extension

Version: $version
Build Date: $releaseDate
Platform: Windows x64

## Quick Start

1. **以管理员身份运行 PowerShell**

2. **运行安装脚本**:
   ``````powershell
   .\install.ps1
   ``````

3. **在 PostgreSQL 中创建扩展**:
   ``````sql
   CREATE EXTENSION pghttp;
   ``````

4. **测试**:
   ``````sql
   SELECT http_get('https://httpbin.org/get');
   ``````

## 文件说明

- **install.ps1** - 自动安装脚本（推荐使用）
- **INSTALL_RELEASE.md** - 详细安装指南
- **USAGE.md** - 使用文档
- **examples.sql** - 示例代码
- **pghttp.dll** - 扩展库文件
- **pghttp.control** - 扩展控制文件
- **pghttp--1.0.0.sql** - SQL 函数定义
- **VERSION.txt** - 版本信息

## 系统要求

- Windows 10/11 或 Windows Server 2016+
- PostgreSQL 15.x (Windows x64)
- 管理员权限

## 功能特性

✅ HTTP/HTTPS GET 请求
✅ HTTP/HTTPS POST 请求
✅ 支持所有 HTTP 方法
✅ 详细响应信息（状态码、Content-Type、响应体）
✅ UTF-8 编码支持
✅ 无外部依赖（使用 Windows 原生 WinHTTP）

## 快速示例

``````sql
-- 简单 GET 请求
SELECT http_get('https://api.example.com/data');

-- POST JSON 数据
SELECT http_post('https://api.example.com/users', '{"name":"John"}');

-- 获取详细响应
SELECT * FROM http_request('GET', 'https://api.example.com/status');
``````

查看 **examples.sql** 获取更多示例。

## 技术支持

- 详细文档: INSTALL_RELEASE.md, USAGE.md
- 示例代码: examples.sql
- 项目说明: README_FINAL.md

## 许可证

MIT License - 可自由使用、修改和分发

---

**Happy coding with pghttp!** 🚀
"@

$readmeContent | Out-File -FilePath "$releaseDir\README.txt" -Encoding UTF8
Write-Host "  ✓ Created README.txt" -ForegroundColor Green

# Create ZIP archive
Write-Host "`nCreating ZIP archive..." -ForegroundColor Yellow

$zipPath = ".\release\$releaseName.zip"
if (Test-Path $zipPath) {
    Remove-Item $zipPath -Force
}

# Use .NET compression
Add-Type -AssemblyName System.IO.Compression.FileSystem
[System.IO.Compression.ZipFile]::CreateFromDirectory($releaseDir, $zipPath, 'Optimal', $false)

Write-Host "✓ Created: $zipPath" -ForegroundColor Green

# Get file size
$zipSize = [math]::Round((Get-Item $zipPath).Length / 1MB, 2)

# Generate checksum
Write-Host "`nGenerating checksum..." -ForegroundColor Yellow
$hash = Get-FileHash $zipPath -Algorithm SHA256
$checksum = $hash.Hash

# Create checksum file
$checksumContent = @"
SHA256 Checksum for $releaseName.zip
=========================================

File: $releaseName.zip
Size: $zipSize MB
Date: $releaseDate
SHA256: $checksum

Verify with PowerShell:
  Get-FileHash $releaseName.zip -Algorithm SHA256

Expected hash should match the value above.
"@

$checksumContent | Out-File -FilePath ".\release\$releaseName-SHA256.txt" -Encoding UTF8
Write-Host "✓ Checksum: $checksum" -ForegroundColor Green

# Summary
Write-Host @"

========================================
✓ Release Package Created Successfully!
========================================

Package: $releaseName.zip
Size: $zipSize MB
Location: $zipPath

Files included:
"@ -ForegroundColor Green

Get-ChildItem $releaseDir | ForEach-Object {
    $size = [math]::Round($_.Length / 1KB, 1)
    Write-Host ("  - {0,-30} {1,8} KB" -f $_.Name, $size) -ForegroundColor White
}

Write-Host @"

========================================
Distribution Instructions:
========================================

1. 分发 ZIP 文件:
   $releaseName.zip

2. 收件人解压后运行:
   .\install.ps1

3. 在 PostgreSQL 中:
   CREATE EXTENSION pghttp;

========================================
"@ -ForegroundColor Cyan

Write-Host "Release package is ready for distribution! 🎉" -ForegroundColor Green
Write-Host ""
