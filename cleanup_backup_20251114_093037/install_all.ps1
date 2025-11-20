# pghttp 一键安装脚本
# 适用于 Windows + PostgreSQL + Strawberry Perl/MinGW

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "pghttp Extension - One-Click Install" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# 配置
$PgPath = "D:\pgsql"
$CurlPath = "C:\curl"

# 步骤 1: 检查 libcurl
Write-Host "[1/5] Checking libcurl..." -ForegroundColor Yellow

if (-not (Test-Path "$CurlPath\include\curl\curl.h")) {
    Write-Host "libcurl not found. Installing..." -ForegroundColor Yellow
    
    Write-Host "Please run setup_curl.ps1 first:" -ForegroundColor Red
    Write-Host "  .\setup_curl.ps1" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Or download manually from: https://curl.se/windows/" -ForegroundColor Yellow
    exit 1
} else {
    Write-Host "✓ libcurl found at: $CurlPath" -ForegroundColor Green
}
Write-Host ""

# 步骤 2: 设置环境
Write-Host "[2/5] Setting up environment..." -ForegroundColor Yellow
$env:PATH = "$PgPath\bin;C:\Strawberry\c\bin;$CurlPath\bin;$env:PATH"
$env:PG_CONFIG = "$PgPath\bin\pg_config.exe"

Write-Host "✓ PostgreSQL: $PgPath" -ForegroundColor Green
Write-Host "✓ Compiler: C:\Strawberry\c\bin\gcc.exe" -ForegroundColor Green
Write-Host ""

# 步骤 3: 清理旧文件
Write-Host "[3/5] Cleaning previous build..." -ForegroundColor Yellow
if (Test-Path "pghttp.o") { Remove-Item "pghttp.o" -Force }
if (Test-Path "pghttp.dll") { Remove-Item "pghttp.dll" -Force }
if (Test-Path "pghttp.so") { Remove-Item "pghttp.so" -Force }
Write-Host "✓ Clean complete" -ForegroundColor Green
Write-Host ""

# 步骤 4: 编译
Write-Host "[4/5] Compiling pghttp extension..." -ForegroundColor Yellow
Write-Host "Command: gmake USE_PGXS=1" -ForegroundColor Gray
Write-Host ""

$makeOutput = gmake USE_PGXS=1 2>&1
$makeExit = $LASTEXITCODE

# 显示编译输出
$makeOutput | ForEach-Object { Write-Host $_ }

if ($makeExit -ne 0) {
    Write-Host ""
    Write-Host "✗ Build failed!" -ForegroundColor Red
    Write-Host ""
    Write-Host "Possible issues:" -ForegroundColor Yellow
    Write-Host "  1. libcurl not properly installed" -ForegroundColor Cyan
    Write-Host "  2. Missing PostgreSQL headers" -ForegroundColor Cyan
    Write-Host "  3. Compiler errors" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Try running manually:" -ForegroundColor Yellow
    Write-Host "  gmake USE_PGXS=1" -ForegroundColor Cyan
    exit 1
}

Write-Host ""
Write-Host "✓ Build successful!" -ForegroundColor Green
Write-Host ""

# 步骤 5: 安装
Write-Host "[5/5] Installing extension..." -ForegroundColor Yellow

$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if (-not $isAdmin) {
    Write-Host "✗ Administrator privileges required for installation" -ForegroundColor Red
    Write-Host ""
    Write-Host "Please run PowerShell as Administrator, then run:" -ForegroundColor Yellow
    Write-Host "  gmake USE_PGXS=1 install" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Or continue manually (see instructions below)" -ForegroundColor Yellow
} else {
    $installOutput = gmake USE_PGXS=1 install 2>&1
    $installExit = $LASTEXITCODE
    
    $installOutput | ForEach-Object { Write-Host $_ }
    
    if ($installExit -eq 0) {
        Write-Host ""
        Write-Host "✓ Installation successful!" -ForegroundColor Green
    } else {
        Write-Host ""
        Write-Host "✗ Installation failed!" -ForegroundColor Red
    }
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Next Steps" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

if (-not $isAdmin) {
    Write-Host "Manual installation (as Administrator):" -ForegroundColor Yellow
    Write-Host "  gmake USE_PGXS=1 install" -ForegroundColor Cyan
    Write-Host ""
}

Write-Host "To use the extension:" -ForegroundColor Yellow
Write-Host "  1. psql -U postgres -d postgres" -ForegroundColor Cyan
Write-Host "  2. CREATE EXTENSION pghttp;" -ForegroundColor Cyan
Write-Host "  3. SELECT http_get('https://httpbin.org/get');" -ForegroundColor Cyan
Write-Host ""

Write-Host "To run tests:" -ForegroundColor Yellow
Write-Host "  psql -U postgres -d postgres -f test_simple.sql" -ForegroundColor Cyan
Write-Host ""

Write-Host "Files created:" -ForegroundColor Yellow
if (Test-Path "pghttp.dll") {
    Write-Host "  ✓ pghttp.dll (compiled library)" -ForegroundColor Green
} elseif (Test-Path "pghttp.so") {
    Write-Host "  ✓ pghttp.so (compiled library)" -ForegroundColor Green
}
Write-Host "  ✓ pghttp.control (extension control file)" -ForegroundColor Green
Write-Host "  ✓ pghttp--1.0.0.sql (SQL definitions)" -ForegroundColor Green
Write-Host ""
