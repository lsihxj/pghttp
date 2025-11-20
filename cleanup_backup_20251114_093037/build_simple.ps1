# Build simple WinHTTP version (no libcurl dependency)

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Building Simple WinHTTP Version" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

$PgPath = "D:\pgsql"
$env:PATH = "$PgPath\bin;C:\Strawberry\c\bin;$env:PATH"

# Compile
Write-Host "`n[1/2] Compiling..." -ForegroundColor Yellow
gcc -Wall -O2 `
    -I"$PgPath/include/server" `
    -I"$PgPath/include/server/port/win32" `
    -I"$PgPath/include/server/port/win32_msvc" `
    -I"$PgPath/include" `
    -c -o pghttp_simple.o pghttp_simple.c

if ($LASTEXITCODE -ne 0) {
    Write-Host "✗ Compilation failed!" -ForegroundColor Red
    exit 1
}

Write-Host "✓ Compilation successful" -ForegroundColor Green

# Link
Write-Host "`n[2/2] Linking..." -ForegroundColor Yellow
gcc -shared `
    -L"$PgPath/lib" `
    -o pghttp.dll pghttp_simple.o `
    -lpostgres -lwinhttp

if ($LASTEXITCODE -ne 0) {
    Write-Host "✗ Linking failed!" -ForegroundColor Red
    exit 1
}

Write-Host "✓ Linking successful" -ForegroundColor Green

# Stop PostgreSQL
Write-Host "`n[3/4] Stopping PostgreSQL..." -ForegroundColor Yellow
Stop-Service -Name postgresql-x64-15 -Force -ErrorAction SilentlyContinue
Start-Sleep -Seconds 2
Write-Host "✓ PostgreSQL stopped" -ForegroundColor Green

# Install
Write-Host "`n[4/4] Installing..." -ForegroundColor Yellow
Copy-Item "pghttp.dll" "$PgPath\lib\pghttp.dll" -Force
Write-Host "✓ DLL installed" -ForegroundColor Green

# Start PostgreSQL
Write-Host "`nStarting PostgreSQL..." -ForegroundColor Yellow
Start-Service -Name postgresql-x64-15
Start-Sleep -Seconds 3
Write-Host "✓ PostgreSQL started" -ForegroundColor Green

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "Build Complete!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "`nNow test in psql:" -ForegroundColor Yellow
Write-Host "  DROP EXTENSION IF EXISTS pghttp CASCADE;" -ForegroundColor White
Write-Host "  CREATE EXTENSION pghttp;" -ForegroundColor White
Write-Host "  SELECT http_get('http://httpbin.org/get') AS result;" -ForegroundColor White
