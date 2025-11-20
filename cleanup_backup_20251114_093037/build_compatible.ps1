# Try to build with MSVC compatibility flags

Write-Host "Building with MSVC Compatibility..." -ForegroundColor Cyan

$PgPath = "D:\pgsql"
$env:PATH = "$PgPath\bin;C:\Strawberry\c\bin;$env:PATH"

# Compile with specific flags for MSVC compatibility
Write-Host "`n[1/2] Compiling..." -ForegroundColor Yellow
gcc -Wall -O2 `
    -D_UCRT `
    -D__USE_MINGW_ANSI_STDIO=0 `
    -I"$PgPath/include/server" `
    -I"$PgPath/include/server/port/win32" `
    -I"$PgPath/include/server/port/win32_msvc" `
    -I"$PgPath/include" `
    -c -o pghttp_minimal.o pghttp_minimal.c

if ($LASTEXITCODE -ne 0) {
    Write-Host "✗ Compilation failed!" -ForegroundColor Red
    exit 1
}

# Link with specific flags
Write-Host "`n[2/2] Linking..." -ForegroundColor Yellow
gcc -shared -Wl,--enable-stdcall-fixup -Wl,--export-all-symbols -L"$PgPath/lib" -o pghttp.dll pghttp_minimal.o -lpostgres

if ($LASTEXITCODE -ne 0) {
    Write-Host "✗ Linking failed!" -ForegroundColor Red
    exit 1
}

Write-Host "✓ Build successful" -ForegroundColor Green

# Check if we need to find MSVC compiler instead
Write-Host "`n========================================" -ForegroundColor Yellow
Write-Host "WARNING: PostgreSQL was built with MSVC" -ForegroundColor Yellow
Write-Host "Extensions should also use MSVC for compatibility" -ForegroundColor Yellow
Write-Host "========================================" -ForegroundColor Yellow
Write-Host "`nChecking for Visual Studio..." -ForegroundColor Cyan

$vsPath = & "C:\Program Files (x86)\Microsoft Visual Studio\Installer\vswhere.exe" `
    -latest -property installationPath -ErrorAction SilentlyContinue

if ($vsPath) {
    Write-Host "✓ Visual Studio found at: $vsPath" -ForegroundColor Green
    Write-Host "`nWe should rebuild using MSVC instead of MinGW!" -ForegroundColor Yellow
} else {
    Write-Host "✗ Visual Studio not found" -ForegroundColor Red
    Write-Host "Please install Visual Studio Build Tools" -ForegroundColor Yellow
}
