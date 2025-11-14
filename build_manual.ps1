# 手动构建脚本 - 不依赖 PGXS
param(
    [switch]$Install = $false,
    [switch]$Clean = $false
)

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "pghttp Manual Build (Windows)" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# 配置路径
$PgPath = "D:\pgsql"
$CurlPath = "C:\curl"

# 设置环境
$env:PATH = "$PgPath\bin;C:\Strawberry\c\bin;$CurlPath\bin;$env:PATH"

Write-Host "Configuration:" -ForegroundColor Yellow
Write-Host "  PostgreSQL: $PgPath" -ForegroundColor Cyan
Write-Host "  libcurl: $CurlPath" -ForegroundColor Cyan
Write-Host "  Compiler: gcc (Strawberry Perl)" -ForegroundColor Cyan
Write-Host ""

if ($Clean) {
    Write-Host "Cleaning..." -ForegroundColor Yellow
    if (Test-Path "pghttp.o") { Remove-Item "pghttp.o" -Force }
    if (Test-Path "pghttp.dll") { Remove-Item "pghttp.dll" -Force }
    Write-Host "✓ Clean complete" -ForegroundColor Green
    Write-Host ""
    if (-not $Install) {
        exit 0
    }
}

# 编译
Write-Host "[1/2] Compiling pghttp.c..." -ForegroundColor Yellow
Write-Host ""

$compileCmd = @"
gcc -Wall -Wmissing-prototypes -Wpointer-arith ``
    -fno-strict-aliasing -fwrapv -O2 ``
    -I"$PgPath/include/server" ``
    -I"$PgPath/include/server/port/win32" ``
    -I"$PgPath/include/server/port/win32_msvc" ``
    -I"$PgPath/include" ``
    -I"$CurlPath/include" ``
    -c -o pghttp.o pghttp.c
"@

Write-Host "Command:" -ForegroundColor Gray
Write-Host $compileCmd -ForegroundColor DarkGray
Write-Host ""

Invoke-Expression $compileCmd
$compileExit = $LASTEXITCODE

if ($compileExit -ne 0) {
    Write-Host "✗ Compilation failed!" -ForegroundColor Red
    exit 1
}

Write-Host "✓ Compilation successful" -ForegroundColor Green
Write-Host ""

# 链接
Write-Host "[2/2] Linking pghttp.dll..." -ForegroundColor Yellow
Write-Host ""

$linkCmd = @"
gcc -shared ``
    -L"$PgPath/lib" ``
    -L"$CurlPath/lib" ``
    -o pghttp.dll pghttp.o ``
    -lpostgres -lcurl
"@

Write-Host "Command:" -ForegroundColor Gray
Write-Host $linkCmd -ForegroundColor DarkGray
Write-Host ""

Invoke-Expression $linkCmd
$linkExit = $LASTEXITCODE

if ($linkExit -ne 0) {
    Write-Host "✗ Linking failed!" -ForegroundColor Red
    Write-Host ""
    Write-Host "Common issues:" -ForegroundColor Yellow
    Write-Host "  1. Missing postgres.lib in $PgPath\lib" -ForegroundColor Cyan
    Write-Host "  2. Missing libcurl in $CurlPath\lib" -ForegroundColor Cyan
    exit 1
}

Write-Host "✓ Linking successful" -ForegroundColor Green
Write-Host ""

# 验证生成的文件
if (Test-Path "pghttp.dll") {
    $dllSize = (Get-Item "pghttp.dll").Length
    Write-Host "✓ pghttp.dll created ($([math]::Round($dllSize/1KB, 2)) KB)" -ForegroundColor Green
} else {
    Write-Host "✗ pghttp.dll not found!" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Build Complete!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# 安装
if ($Install) {
    Write-Host "Installing extension..." -ForegroundColor Yellow
    Write-Host ""
    
    # 检查管理员权限
    $isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    
    if (-not $isAdmin) {
        Write-Host "✗ Administrator privileges required!" -ForegroundColor Red
        Write-Host ""
        Write-Host "Please run as Administrator:" -ForegroundColor Yellow
        Write-Host "  .\build_manual.ps1 -Install" -ForegroundColor Cyan
        exit 1
    }
    
    # 复制文件
    $libDir = "$PgPath\lib"
    $extDir = "$PgPath\share\extension"
    
    Write-Host "Installing to:" -ForegroundColor Yellow
    Write-Host "  Library: $libDir" -ForegroundColor Cyan
    Write-Host "  Extension: $extDir" -ForegroundColor Cyan
    Write-Host ""
    
    try {
        Copy-Item "pghttp.dll" "$libDir\pghttp.dll" -Force
        Write-Host "  ✓ Copied pghttp.dll" -ForegroundColor Green
        
        Copy-Item "pghttp--1.0.0.sql" "$extDir\pghttp--1.0.0.sql" -Force
        Write-Host "  ✓ Copied pghttp--1.0.0.sql" -ForegroundColor Green
        
        Copy-Item "pghttp.control" "$extDir\pghttp.control" -Force
        Write-Host "  ✓ Copied pghttp.control" -ForegroundColor Green
        
        Write-Host ""
        Write-Host "✓ Installation successful!" -ForegroundColor Green
        
    } catch {
        Write-Host "✗ Installation failed: $($_.Exception.Message)" -ForegroundColor Red
        exit 1
    }
    
    Write-Host ""
}

# 显示下一步
Write-Host "Next steps:" -ForegroundColor Yellow

if (-not $Install) {
    Write-Host "  1. Install (as Administrator):" -ForegroundColor Cyan
    Write-Host "     .\build_manual.ps1 -Install" -ForegroundColor White
    Write-Host ""
}

Write-Host "  1. Connect to database:" -ForegroundColor Cyan
Write-Host "     psql -U postgres -d postgres" -ForegroundColor White
Write-Host ""
Write-Host "  2. Create extension:" -ForegroundColor Cyan
Write-Host "     CREATE EXTENSION pghttp;" -ForegroundColor White
Write-Host ""
Write-Host "  3. Test:" -ForegroundColor Cyan
Write-Host "     SELECT http_get('https://httpbin.org/get');" -ForegroundColor White
Write-Host ""
