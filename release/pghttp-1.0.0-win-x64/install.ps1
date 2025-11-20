# pghttp Extension Installer
# Auto-detect PostgreSQL and install extension files

param(
    [string]$PgPath = "",
    [string]$ServiceName = ""
)

$ErrorActionPreference = "Stop"

Write-Host "========================================"
Write-Host "  pghttp Extension Installer v1.0.0"
Write-Host "========================================"

# Function to find PostgreSQL installation
function Find-PostgreSQL {
    Write-Host "Searching for PostgreSQL installation..." -ForegroundColor Yellow
    
    # Common installation paths
    $possiblePaths = @(
        "C:\Program Files\PostgreSQL\15",
        "C:\Program Files\PostgreSQL\16",
        "D:\pgsql",
        "D:\PostgreSQL\15",
        "C:\PostgreSQL\15",
        "${env:ProgramFiles}\PostgreSQL\15",
        "${env:ProgramFiles(x86)}\PostgreSQL\15"
    )
    
    foreach ($path in $possiblePaths) {
        if (Test-Path "$path\bin\postgres.exe") {
            Write-Host "[OK] Found PostgreSQL at: $path" -ForegroundColor Green
            return $path
        }
    }
    
    # Try to find from registry
    try {
        $regPath = "HKLM:\SOFTWARE\PostgreSQL\Installations\postgresql-x64-15"
        if (Test-Path $regPath) {
            $path = (Get-ItemProperty $regPath).Base_Directory
            if (Test-Path "$path\bin\postgres.exe") {
                Write-Host "[OK] Found PostgreSQL from registry: $path" -ForegroundColor Green
                return $path
            }
        }
    } catch {}
    
    return $null
}

# Function to find PostgreSQL service
function Find-PostgreSQLService {
    Write-Host "Searching for PostgreSQL service..." -ForegroundColor Yellow
    
    $services = Get-Service *postgres* -ErrorAction SilentlyContinue
    
    if ($services.Count -eq 0) {
        return $null
    }
    
    if ($services.Count -eq 1) {
        $serviceName = $services[0].Name
        Write-Host "[OK] Found PostgreSQL service: $serviceName" -ForegroundColor Green
        return $serviceName
    }
    
    # Multiple services found, prefer version 15
    foreach ($svc in $services) {
        if ($svc.Name -like "*15*") {
            Write-Host "[OK] Found PostgreSQL service: $($svc.Name)" -ForegroundColor Green
            return $svc.Name
        }
    }
    
    # Return first service
    Write-Host "[OK] Found PostgreSQL service: $($services[0].Name)" -ForegroundColor Green
    return $services[0].Name
}

# Check if running as administrator
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if (-not $isAdmin) {
    Write-Host "[ERROR] This script must be run as Administrator!" -ForegroundColor Red
    Write-Host "  Right-click PowerShell and select 'Run as Administrator'" -ForegroundColor Yellow
    exit 1
}

# Find PostgreSQL if not specified
if (-not $PgPath) {
    $PgPath = Find-PostgreSQL
    
    if (-not $PgPath) {
        Write-Host "[ERROR] Cannot find PostgreSQL installation!" -ForegroundColor Red
        Write-Host "  Please specify path manually:" -ForegroundColor Yellow
        Write-Host "  .\install.ps1 -PgPath 'C:\Program Files\PostgreSQL\15'" -ForegroundColor White
        exit 1
    }
}

# Verify PostgreSQL path
if (-not (Test-Path "$PgPath\bin\postgres.exe")) {
    Write-Host "[ERROR] Invalid PostgreSQL path: $PgPath" -ForegroundColor Red
    Write-Host "  postgres.exe not found in bin directory" -ForegroundColor Yellow
    exit 1
}

# Find PostgreSQL service if not specified
if (-not $ServiceName) {
    $ServiceName = Find-PostgreSQLService
    
    if (-not $ServiceName) {
        Write-Host "[WARNING] Cannot find PostgreSQL service automatically" -ForegroundColor Yellow
        Write-Host "  You may need to restart PostgreSQL manually after installation" -ForegroundColor Yellow
    }
}

Write-Host ""
Write-Host "Installation Settings:" -ForegroundColor Cyan
Write-Host "  PostgreSQL Path: $PgPath" -ForegroundColor White
Write-Host "  Service Name: $ServiceName" -ForegroundColor White
Write-Host ""

# Check if extension files exist
$requiredFiles = @(
    "pghttp.dll",
    "pghttp.control",
    "pghttp--1.0.0.sql"
)

$missingFiles = @()
foreach ($file in $requiredFiles) {
    if (-not (Test-Path $file)) {
        $missingFiles += $file
    }
}

if ($missingFiles.Count -gt 0) {
    Write-Host "[ERROR] Missing required files:" -ForegroundColor Red
    $missingFiles | ForEach-Object { Write-Host "  - $_" -ForegroundColor Yellow }
    Write-Host "  Please ensure you have extracted the complete release package" -ForegroundColor Yellow
    exit 1
}

Write-Host "[OK] All required files found" -ForegroundColor Green
Write-Host ""

# Stop PostgreSQL service
if ($ServiceName) {
    Write-Host "Stopping PostgreSQL service..." -ForegroundColor Yellow
    try {
        Stop-Service -Name $ServiceName -Force -ErrorAction Stop
        Start-Sleep -Seconds 2
        Write-Host "[OK] Service stopped" -ForegroundColor Green
    } catch {
        Write-Host "[WARNING] Failed to stop service: $_" -ForegroundColor Yellow
        Write-Host "  Continuing anyway..." -ForegroundColor Yellow
    }
}

# Copy files
Write-Host ""
Write-Host "Installing extension files..." -ForegroundColor Yellow

try {
    # Copy DLL
    $dllDest = Join-Path $PgPath "lib\pghttp.dll"
    Copy-Item "pghttp.dll" $dllDest -Force
    Write-Host "[OK] Copied pghttp.dll to lib\" -ForegroundColor Green
    
    # Copy control file
    $controlDest = Join-Path $PgPath "share\extension\pghttp.control"
    Copy-Item "pghttp.control" $controlDest -Force
    Write-Host "[OK] Copied pghttp.control to share\extension\" -ForegroundColor Green
    
    # Copy SQL file
    $sqlDest = Join-Path $PgPath "share\extension\pghttp--1.0.0.sql"
    Copy-Item "pghttp--1.0.0.sql" $sqlDest -Force
    Write-Host "[OK] Copied pghttp--1.0.0.sql to share\extension\" -ForegroundColor Green
    
} catch {
    Write-Host "[ERROR] Failed to copy files: $_" -ForegroundColor Red
    
    # Try to start service again
    if ($ServiceName) {
        Start-Service -Name $ServiceName -ErrorAction SilentlyContinue
    }
    
    exit 1
}

# Start PostgreSQL service
if ($ServiceName) {
    Write-Host ""
    Write-Host "Starting PostgreSQL service..." -ForegroundColor Yellow
    try {
        Start-Service -Name $ServiceName -ErrorAction Stop
        Start-Sleep -Seconds 3
        Write-Host "[OK] Service started" -ForegroundColor Green
    } catch {
        Write-Host "[ERROR] Failed to start service: $_" -ForegroundColor Red
        Write-Host "  Please start PostgreSQL manually" -ForegroundColor Yellow
    }
}

Write-Host ""
Write-Host "========================================"
Write-Host "  Installation Complete!"
Write-Host "========================================"

Write-Host ""
Write-Host "Next Steps:" -ForegroundColor Cyan
Write-Host "  1. Connect to your PostgreSQL database" -ForegroundColor White
Write-Host "  2. Run the following SQL command:" -ForegroundColor White
Write-Host ""
Write-Host "     CREATE EXTENSION pghttp;" -ForegroundColor Yellow
Write-Host ""
Write-Host "  3. Test the extension:" -ForegroundColor White
Write-Host ""
Write-Host "     SELECT http_get('https://httpbin.org/get');" -ForegroundColor Yellow
Write-Host ""
Write-Host "For more examples, see examples.sql" -ForegroundColor Gray
Write-Host "For usage guide, see USAGE.md" -ForegroundColor Gray
Write-Host ""
