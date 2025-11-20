# PostgreSQL HTTP Extension - PowerShell Build Script
# Usage: .\build.ps1 [-PgPath "C:\path\to\postgresql"] [-CurlPath "C:\path\to\curl"]

param(
    [string]$PgPath = "",
    [string]$CurlPath = "C:\curl",
    [switch]$Install = $false
)

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "pghttp Extension - Build Script" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# 函数：查找 PostgreSQL 安装路径
function Find-PostgreSQL {
    Write-Host "Searching for PostgreSQL installation..." -ForegroundColor Yellow
    
    # 尝试从 psql 命令查找
    $psqlPath = Get-Command psql -ErrorAction SilentlyContinue
    if ($psqlPath) {
        $pgHome = Split-Path (Split-Path $psqlPath.Source -Parent) -Parent
        Write-Host "Found PostgreSQL via psql command: $pgHome" -ForegroundColor Green
        return $pgHome
    }
    
    # 检查标准安装路径
    $versions = 17, 16, 15, 14, 13, 12
    foreach ($ver in $versions) {
        $path = "C:\Program Files\PostgreSQL\$ver"
        if (Test-Path $path) {
            Write-Host "Found PostgreSQL $ver at: $path" -ForegroundColor Green
            return $path
        }
    }
    
    # 检查 Program Files (x86)
    foreach ($ver in $versions) {
        $path = "C:\Program Files (x86)\PostgreSQL\$ver"
        if (Test-Path $path) {
            Write-Host "Found PostgreSQL $ver at: $path" -ForegroundColor Green
            return $path
        }
    }
    
    return $null
}

# 查找 PostgreSQL
if ($PgPath -eq "") {
    $PgPath = Find-PostgreSQL
    
    if ($PgPath -eq $null) {
        Write-Host "ERROR: PostgreSQL not found!" -ForegroundColor Red
        Write-Host ""
        Write-Host "Please specify PostgreSQL path manually:" -ForegroundColor Yellow
        Write-Host '  .\build.ps1 -PgPath "C:\Program Files\PostgreSQL\15"' -ForegroundColor Cyan
        Write-Host ""
        Write-Host "Or add PostgreSQL bin directory to your PATH" -ForegroundColor Yellow
        exit 1
    }
}

# 验证 PostgreSQL 路径
if (-not (Test-Path $PgPath)) {
    Write-Host "ERROR: PostgreSQL path not found: $PgPath" -ForegroundColor Red
    exit 1
}

$pgBin = Join-Path $PgPath "bin"
$pgConfig = Join-Path $pgBin "pg_config.exe"

if (-not (Test-Path $pgConfig)) {
    Write-Host "ERROR: pg_config.exe not found at: $pgConfig" -ForegroundColor Red
    exit 1
}

Write-Host "PostgreSQL location: $PgPath" -ForegroundColor Green

# 获取 PostgreSQL 版本
$pgVersion = & $pgConfig --version
Write-Host "Version: $pgVersion" -ForegroundColor Green
Write-Host ""

# 检查 libcurl（可选，因为可能需要手动编译）
if (Test-Path $CurlPath) {
    Write-Host "libcurl location: $CurlPath" -ForegroundColor Green
} else {
    Write-Host "WARNING: libcurl not found at $CurlPath" -ForegroundColor Yellow
    Write-Host "You may need to:" -ForegroundColor Yellow
    Write-Host "  1. Download curl from https://curl.se/windows/" -ForegroundColor Cyan
    Write-Host "  2. Extract to C:\curl" -ForegroundColor Cyan
    Write-Host "  3. Or specify path: -CurlPath 'C:\path\to\curl'" -ForegroundColor Cyan
    Write-Host ""
    
    $continue = Read-Host "Continue anyway? (y/n)"
    if ($continue -ne "y") {
        exit 1
    }
}

# 设置环境变量
$env:PATH = "$pgBin;$env:PATH"
$env:PG_CONFIG = $pgConfig

if (Test-Path $CurlPath) {
    $curlInclude = Join-Path $CurlPath "include"
    $curlLib = Join-Path $CurlPath "lib"
    $curlBin = Join-Path $CurlPath "bin"
    
    if (Test-Path $curlBin) {
        $env:PATH = "$curlBin;$env:PATH"
    }
}

Write-Host "Building pghttp extension..." -ForegroundColor Cyan
Write-Host ""

# 清理之前的编译
if (Test-Path "pghttp.o") { Remove-Item "pghttp.o" -Force }
if (Test-Path "pghttp.so") { Remove-Item "pghttp.so" -Force }
if (Test-Path "pghttp.dll") { Remove-Item "pghttp.dll" -Force }

# 编译
Write-Host "Running: make" -ForegroundColor Yellow
$makeResult = make 2>&1
$makeExitCode = $LASTEXITCODE

Write-Host $makeResult
Write-Host ""

if ($makeExitCode -ne 0) {
    Write-Host "ERROR: Build failed!" -ForegroundColor Red
    Write-Host ""
    Write-Host "Common issues:" -ForegroundColor Yellow
    Write-Host "  1. Missing C compiler (install Visual Studio or MinGW)" -ForegroundColor Cyan
    Write-Host "  2. Missing libcurl development files" -ForegroundColor Cyan
    Write-Host "  3. Missing make utility" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "For detailed instructions, see INSTALL.md" -ForegroundColor Yellow
    exit 1
}

Write-Host "Build successful!" -ForegroundColor Green
Write-Host ""

# 安装
if ($Install) {
    Write-Host "Installing extension..." -ForegroundColor Cyan
    
    # 检查管理员权限
    $isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    
    if (-not $isAdmin) {
        Write-Host "WARNING: Installation requires administrator privileges" -ForegroundColor Yellow
        Write-Host "Please run PowerShell as Administrator and try again" -ForegroundColor Yellow
        Write-Host ""
        Write-Host "Or run manually:" -ForegroundColor Cyan
        Write-Host "  make install" -ForegroundColor Cyan
        exit 1
    }
    
    $installResult = make install 2>&1
    $installExitCode = $LASTEXITCODE
    
    Write-Host $installResult
    Write-Host ""
    
    if ($installExitCode -ne 0) {
        Write-Host "ERROR: Installation failed!" -ForegroundColor Red
        exit 1
    }
    
    Write-Host "Installation successful!" -ForegroundColor Green
    Write-Host ""
}

# 显示下一步操作
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Next Steps:" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

if (-not $Install) {
    Write-Host ""
    Write-Host "To install, run as Administrator:" -ForegroundColor Yellow
    Write-Host "  .\build.ps1 -Install" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Or manually:" -ForegroundColor Yellow
    Write-Host "  make install" -ForegroundColor Cyan
}

Write-Host ""
Write-Host "To use the extension:" -ForegroundColor Yellow
Write-Host "  1. Connect to database: psql -U postgres -d postgres" -ForegroundColor Cyan
Write-Host "  2. Create extension: CREATE EXTENSION pghttp;" -ForegroundColor Cyan
Write-Host "  3. Test: SELECT http_get('https://httpbin.org/get');" -ForegroundColor Cyan
Write-Host ""
Write-Host "To run tests:" -ForegroundColor Yellow
Write-Host "  psql -U postgres -d postgres -f test_simple.sql" -ForegroundColor Cyan
Write-Host ""
