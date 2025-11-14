# Build minimal test version

Write-Host "Building Minimal Test Version..." -ForegroundColor Cyan

$PgPath = "D:\pgsql"
$env:PATH = "$PgPath\bin;C:\Strawberry\c\bin;$env:PATH"

# Compile
Write-Host "`n[1/2] Compiling..." -ForegroundColor Yellow
gcc -Wall -O2 `
    -I"$PgPath/include/server" `
    -I"$PgPath/include/server/port/win32" `
    -I"$PgPath/include/server/port/win32_msvc" `
    -I"$PgPath/include" `
    -c -o pghttp_minimal.o pghttp_minimal.c

if ($LASTEXITCODE -ne 0) {
    Write-Host "✗ Compilation failed!" -ForegroundColor Red
    exit 1
}

Write-Host "✓ Compilation successful" -ForegroundColor Green

# Link
Write-Host "`n[2/2] Linking..." -ForegroundColor Yellow
gcc -shared `
    -L"$PgPath/lib" `
    -o pghttp.dll pghttp_minimal.o `
    -lpostgres

if ($LASTEXITCODE -ne 0) {
    Write-Host "✗ Linking failed!" -ForegroundColor Red
    exit 1
}

Write-Host "✓ Linking successful" -ForegroundColor Green

# Stop PostgreSQL
Write-Host "`nStopping PostgreSQL..." -ForegroundColor Yellow
Stop-Service -Name postgresql-x64-15 -Force -ErrorAction SilentlyContinue
Start-Sleep -Seconds 2

# Install
Write-Host "Installing..." -ForegroundColor Yellow
Copy-Item "pghttp.dll" "$PgPath\lib\pghttp.dll" -Force

# Start PostgreSQL
Write-Host "Starting PostgreSQL..." -ForegroundColor Yellow
Start-Service -Name postgresql-x64-15
Start-Sleep -Seconds 3

Write-Host "`n✓ Build Complete!" -ForegroundColor Green
Write-Host "`nTest in psql:" -ForegroundColor Yellow
Write-Host "  DROP EXTENSION IF EXISTS pghttp CASCADE;" -ForegroundColor White
Write-Host "  CREATE EXTENSION pghttp;" -ForegroundColor White
Write-Host "  SELECT http_get('http://test.com') AS result;" -ForegroundColor White
