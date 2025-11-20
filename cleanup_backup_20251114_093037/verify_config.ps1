# 验证开发环境配置
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "pghttp Environment Verification" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

$allGood = $true

# 检查 PostgreSQL
Write-Host "Checking PostgreSQL..." -ForegroundColor Yellow
$pgPath = "D:\pgsql"

if (Test-Path "$pgPath\bin\pg_config.exe") {
    $version = & "$pgPath\bin\pg_config.exe" --version
    Write-Host "  ✓ PostgreSQL found: $version" -ForegroundColor Green
    
    # 检查头文件
    if (Test-Path "$pgPath\include\server\postgres.h") {
        Write-Host "  ✓ postgres.h found" -ForegroundColor Green
    } else {
        Write-Host "  ✗ postgres.h NOT found at $pgPath\include\server\" -ForegroundColor Red
        $allGood = $false
    }
} else {
    Write-Host "  ✗ PostgreSQL NOT found at $pgPath" -ForegroundColor Red
    $allGood = $false
}
Write-Host ""

# 检查 libcurl
Write-Host "Checking libcurl..." -ForegroundColor Yellow
$curlPath = "C:\curl"

if (Test-Path "$curlPath\include\curl\curl.h") {
    Write-Host "  ✓ curl.h found at $curlPath" -ForegroundColor Green
} else {
    Write-Host "  ✗ curl.h NOT found at $curlPath" -ForegroundColor Red
    Write-Host "    Run: .\setup_curl.ps1" -ForegroundColor Yellow
    $allGood = $false
}
Write-Host ""

# 检查编译器
Write-Host "Checking compiler..." -ForegroundColor Yellow

$gcc = Get-Command gcc -ErrorAction SilentlyContinue
if ($gcc) {
    $gccVersion = & gcc --version | Select-Object -First 1
    Write-Host "  ✓ GCC found: $gccVersion" -ForegroundColor Green
} else {
    Write-Host "  ✗ GCC NOT found" -ForegroundColor Red
    $allGood = $false
}

$gmake = Get-Command gmake -ErrorAction SilentlyContinue
if ($gmake) {
    Write-Host "  ✓ gmake found at: $($gmake.Source)" -ForegroundColor Green
} else {
    Write-Host "  ✗ gmake NOT found" -ForegroundColor Red
    $allGood = $false
}
Write-Host ""

# 检查 VSCode 配置
Write-Host "Checking IDE configuration..." -ForegroundColor Yellow

if (Test-Path ".vscode\c_cpp_properties.json") {
    Write-Host "  ✓ c_cpp_properties.json found" -ForegroundColor Green
} else {
    Write-Host "  ✗ c_cpp_properties.json NOT found" -ForegroundColor Red
    $allGood = $false
}

if (Test-Path ".vscode\settings.json") {
    Write-Host "  ✓ settings.json found" -ForegroundColor Green
} else {
    Write-Host "  ✗ settings.json NOT found" -ForegroundColor Red
    $allGood = $false
}
Write-Host ""

# 总结
Write-Host "========================================" -ForegroundColor Cyan
if ($allGood) {
    Write-Host "✓ All checks passed!" -ForegroundColor Green
    Write-Host ""
    Write-Host "Your environment is ready!" -ForegroundColor Green
    Write-Host ""
    Write-Host "Next steps:" -ForegroundColor Yellow
    Write-Host "  1. Reload VSCode window (Ctrl+Shift+P -> 'Reload Window')" -ForegroundColor Cyan
    Write-Host "  2. Build: .\install_all.ps1" -ForegroundColor Cyan
    Write-Host "  3. Test: psql -U postgres -d postgres -f test_simple.sql" -ForegroundColor Cyan
} else {
    Write-Host "✗ Some issues found" -ForegroundColor Red
    Write-Host ""
    Write-Host "Please fix the issues above before building" -ForegroundColor Yellow
}
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
