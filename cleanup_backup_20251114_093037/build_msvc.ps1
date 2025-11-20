# Build using MSVC (Microsoft Visual C++)

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Building with MSVC" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

# Find Visual Studio
$vsPath = & "C:\Program Files (x86)\Microsoft Visual Studio\Installer\vswhere.exe" `
    -latest -property installationPath

if (-not $vsPath) {
    Write-Host "✗ Visual Studio not found!" -ForegroundColor Red
    exit 1
}

Write-Host "Visual Studio: $vsPath" -ForegroundColor Green

# Setup MSVC environment
$vcvarsPath = Join-Path $vsPath "VC\Auxiliary\Build\vcvars64.bat"
if (-not (Test-Path $vcvarsPath)) {
    Write-Host "✗ vcvars64.bat not found!" -ForegroundColor Red
    exit 1
}

$PgPath = "D:\pgsql"

# Create a temporary batch file to run MSVC commands
$batchContent = @"
@echo off
call "$vcvarsPath"
echo.
echo [1/2] Compiling with MSVC...
cl.exe /nologo /W3 /O2 /MD ^
    /I"$PgPath\include\server" ^
    /I"$PgPath\include\server\port\win32_msvc" ^
    /I"$PgPath\include\server\port\win32" ^
    /I"$PgPath\include" ^
    /c pghttp_minimal.c

if %ERRORLEVEL% NEQ 0 (
    echo Build failed!
    exit /b 1
)

echo.
echo [2/2] Linking with MSVC...
link.exe /nologo /DLL ^
    /DEF:pghttp.def ^
    /OUT:pghttp.dll ^
    pghttp_minimal.obj ^
    "$PgPath\lib\postgres.lib"

if %ERRORLEVEL% NEQ 0 (
    echo Linking failed!
    exit /b 1
)

echo.
echo Build successful!
"@

$batchFile = "d:\CodeBuddy\pghttp\build_temp.bat"
$batchContent | Out-File -FilePath $batchFile -Encoding ASCII

# Run the batch file
Write-Host "`nCompiling..." -ForegroundColor Yellow
& cmd.exe /c $batchFile

if ($LASTEXITCODE -ne 0) {
    Write-Host "`n✗ Build failed!" -ForegroundColor Red
    Remove-Item $batchFile -ErrorAction SilentlyContinue
    exit 1
}

# Clean up
Remove-Item $batchFile -ErrorAction SilentlyContinue

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "✓ Build Complete!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan

# Stop PostgreSQL
Write-Host "`nStopping PostgreSQL..." -ForegroundColor Yellow
Stop-Service -Name postgresql-x64-15 -Force -ErrorAction SilentlyContinue
Start-Sleep -Seconds 2

# Install
Write-Host "Installing DLL..." -ForegroundColor Yellow
Copy-Item "pghttp.dll" "$PgPath\lib\pghttp.dll" -Force
Write-Host "✓ DLL installed" -ForegroundColor Green

# Start PostgreSQL
Write-Host "`nStarting PostgreSQL..." -ForegroundColor Yellow
Start-Service -Name postgresql-x64-15
Start-Sleep -Seconds 3

Write-Host "`n✓ PostgreSQL started" -ForegroundColor Green
Write-Host "`nNow test in psql:" -ForegroundColor Cyan
Write-Host "  DROP EXTENSION IF EXISTS pghttp CASCADE;" -ForegroundColor White
Write-Host "  CREATE EXTENSION pghttp;" -ForegroundColor White
Write-Host "  SELECT http_get('http://test.com') AS result;" -ForegroundColor White
