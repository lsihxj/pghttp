# Build full version with HTTP support

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Building Full HTTP Extension" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

# Find Visual Studio
$vsPath = & "C:\Program Files (x86)\Microsoft Visual Studio\Installer\vswhere.exe" `
    -latest -property installationPath

if (-not $vsPath) {
    Write-Host "✗ Visual Studio not found!" -ForegroundColor Red
    exit 1
}

$PgPath = "D:\pgsql"
$vcvarsPath = Join-Path $vsPath "VC\Auxiliary\Build\vcvars64.bat"

# Create build batch file
$batchContent = @"
@echo off
call "$vcvarsPath" >nul
echo [1/2] Compiling pghttp.c...
cl.exe /nologo /W3 /O2 /MD ^
    /I"$PgPath\include\server" ^
    /I"$PgPath\include\server\port\win32_msvc" ^
    /I"$PgPath\include\server\port\win32" ^
    /I"$PgPath\include" ^
    /c pghttp.c

if %ERRORLEVEL% NEQ 0 exit /b 1

echo [2/2] Linking pghttp.dll...
link.exe /nologo /DLL ^
    /DEF:pghttp.def ^
    /OUT:pghttp.dll ^
    pghttp.obj ^
    "$PgPath\lib\postgres.lib" ^
    winhttp.lib

if %ERRORLEVEL% NEQ 0 exit /b 1
echo Build successful!
"@

$batchFile = "d:\CodeBuddy\pghttp\build_temp.bat"
$batchContent | Out-File -FilePath $batchFile -Encoding ASCII

# Compile
Write-Host "Compiling..." -ForegroundColor Yellow
& cmd.exe /c $batchFile

if ($LASTEXITCODE -ne 0) {
    Write-Host "`n✗ Build failed!" -ForegroundColor Red
    Remove-Item $batchFile -ErrorAction SilentlyContinue
    exit 1
}

Remove-Item $batchFile -ErrorAction SilentlyContinue

Write-Host "`n✓ Build successful!" -ForegroundColor Green

# Stop PostgreSQL
Write-Host "`nStopping PostgreSQL..." -ForegroundColor Yellow
Stop-Service -Name postgresql-x64-15 -Force -ErrorAction SilentlyContinue
Start-Sleep -Seconds 2

# Install files
Write-Host "Installing extension..." -ForegroundColor Yellow
Copy-Item "pghttp.dll" "$PgPath\lib\pghttp.dll" -Force
Copy-Item "pghttp_full--1.0.0.sql" "$PgPath\share\extension\pghttp--1.0.0.sql" -Force
Write-Host "✓ Extension installed" -ForegroundColor Green

# Start PostgreSQL
Write-Host "`nStarting PostgreSQL..." -ForegroundColor Yellow
Start-Service -Name postgresql-x64-15
Start-Sleep -Seconds 3

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "✓ Installation Complete!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan

Write-Host "`nNow test in psql:" -ForegroundColor Yellow
Write-Host "  DROP EXTENSION IF EXISTS pghttp CASCADE;" -ForegroundColor White
Write-Host "  CREATE EXTENSION pghttp;" -ForegroundColor White
Write-Host "" -ForegroundColor White
Write-Host "  -- Test GET" -ForegroundColor Gray
Write-Host "  SELECT http_get('http://httpbin.org/get');" -ForegroundColor White
Write-Host "" -ForegroundColor White
Write-Host "  -- Test POST" -ForegroundColor Gray
Write-Host "  SELECT http_post('http://httpbin.org/post', '{\"test\":\"data\"}');" -ForegroundColor White
Write-Host "" -ForegroundColor White
Write-Host "  -- Test detailed response" -ForegroundColor Gray
Write-Host "  SELECT * FROM http_request('GET', 'http://httpbin.org/get');" -ForegroundColor White
