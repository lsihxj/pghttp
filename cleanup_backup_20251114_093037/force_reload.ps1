# 强制重新加载扩展
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Force Reload PostgreSQL Extension" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

# 1. 停止 PostgreSQL 服务
Write-Host "`n[1/4] Stopping PostgreSQL service..." -ForegroundColor Yellow
Stop-Service -Name postgresql-x64-15 -Force -ErrorAction SilentlyContinue
Start-Sleep -Seconds 2

# 2. 确认服务已停止
$service = Get-Service -Name postgresql-x64-15
if ($service.Status -eq 'Stopped') {
    Write-Host "  ✓ PostgreSQL service stopped" -ForegroundColor Green
} else {
    Write-Host "  ✗ Failed to stop service, status: $($service.Status)" -ForegroundColor Red
    exit 1
}

# 3. 复制新的 DLL（确保使用最新版本）
Write-Host "`n[2/4] Copying new DLL to PostgreSQL lib directory..." -ForegroundColor Yellow
Copy-Item "d:\CodeBuddy\pghttp\pghttp.dll" "D:\pgsql\lib\pghttp.dll" -Force
Write-Host "  ✓ DLL copied" -ForegroundColor Green

# 4. 启动 PostgreSQL 服务
Write-Host "`n[3/4] Starting PostgreSQL service..." -ForegroundColor Yellow
Start-Service -Name postgresql-x64-15
Start-Sleep -Seconds 3

# 5. 确认服务已启动
$service = Get-Service -Name postgresql-x64-15
if ($service.Status -eq 'Running') {
    Write-Host "  ✓ PostgreSQL service started" -ForegroundColor Green
} else {
    Write-Host "  ✗ Failed to start service, status: $($service.Status)" -ForegroundColor Red
    exit 1
}

Write-Host "`n[4/4] Extension reload complete!" -ForegroundColor Green
Write-Host "`nYou can now reconnect to PostgreSQL and test:" -ForegroundColor Cyan
Write-Host "  psql -U postgres -d postgres" -ForegroundColor White
Write-Host "  DROP EXTENSION IF EXISTS pghttp CASCADE;" -ForegroundColor White
Write-Host "  CREATE EXTENSION pghttp;" -ForegroundColor White
Write-Host "  \i d:/CodeBuddy/pghttp/test_strict.sql" -ForegroundColor White
