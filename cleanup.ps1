# pghttp Project Cleanup Script
# Removes unnecessary development and debug files

param(
    [switch]$DryRun = $false,
    [switch]$Backup = $false
)

$ErrorActionPreference = "Stop"

Write-Host @"
========================================
  pghttp Project Cleanup
========================================
"@ -ForegroundColor Cyan

if ($DryRun) {
    Write-Host "DRY RUN MODE - No files will be deleted" -ForegroundColor Yellow
    Write-Host ""
}

# Files to delete
$filesToDelete = @(
    # 过时的源代码
    "pghttp.c",
    "pghttp_simple.c",
    "pghttp_minimal.c",
    "pghttp_simple--1.0.0.sql",
    
    # 备份文件
    "pghttp--1.0.0.sql.backup",
    
    # 编译中间文件
    "pghttp_full.obj",
    "pghttp_minimal.obj",
    "pghttp.exp",
    "pghttp.lib",
    
    # 调试文档
    "CRITICAL_DIAGNOSIS.md",
    "DEBUG_NULL_ISSUE.md",
    "FIX_NULL_ISSUE.md",
    "FIXED_DLL_ISSUE.md",
    "FIX_IDE_ERRORS.md",
    "FINAL_STEPS.md",
    "INSTALL_SUCCESS.md",
    "SUCCESS_SUMMARY.md",
    "TROUBLESHOOTING.md",
    "INSTALL.md",
    "QUICK_START.md",
    "QUICK_REFERENCE.md",
    "TEST_NOW.md",
    
    # 测试文件
    "test.sql",
    "test_debug.sql",
    "test_diagnose.sql",
    "test_extension.sql",
    "test_install.sql",
    "test_now.sql",
    "test_simple.sql",
    "test_strict.sql",
    "test_success.sql",
    "test_with_debug.sql",
    "diagnose.sql",
    
    # 过时的编译脚本
    "build.ps1",
    "build_compatible.ps1",
    "build_minimal.ps1",
    "build_msvc.ps1",
    "build_simple.ps1",
    "build_windows.bat",
    "build_linux.sh",
    "Makefile",
    "Makefile.win",
    
    # 过时的设置脚本
    "setup_curl.ps1",
    "setup_ssl_cert.ps1",
    "install_all.ps1",
    "fix_dll_path.ps1",
    "force_reload.ps1",
    "check_logs.ps1",
    "test_connection.ps1",
    "verify_config.ps1",
    "verify_extension.sql"
)

# Create backup if requested
if ($Backup -and -not $DryRun) {
    Write-Host "Creating backup..." -ForegroundColor Yellow
    $backupDir = ".\cleanup_backup_$(Get-Date -Format 'yyyyMMdd_HHmmss')"
    New-Item -ItemType Directory -Path $backupDir -Force | Out-Null
    
    $backedUp = 0
    foreach ($file in $filesToDelete) {
        if (Test-Path $file) {
            Copy-Item $file $backupDir -Force
            $backedUp++
        }
    }
    
    Write-Host "✓ Backed up $backedUp files to: $backupDir" -ForegroundColor Green
    Write-Host ""
}

# Delete files
Write-Host "Files to be deleted:" -ForegroundColor Yellow
Write-Host ""

$deletedCount = 0
$notFoundCount = 0
$totalSize = 0

foreach ($file in $filesToDelete) {
    if (Test-Path $file) {
        $fileInfo = Get-Item $file
        $size = $fileInfo.Length
        $totalSize += $size
        $sizeKB = [math]::Round($size / 1KB, 2)
        
        Write-Host "  [DELETE] $file ($sizeKB KB)" -ForegroundColor Red
        
        if (-not $DryRun) {
            Remove-Item $file -Force
            $deletedCount++
        }
    } else {
        Write-Host "  [SKIP] $file (not found)" -ForegroundColor Gray
        $notFoundCount++
    }
}

Write-Host ""
Write-Host "Summary:" -ForegroundColor Cyan
Write-Host "  Files deleted: $deletedCount" -ForegroundColor $(if ($deletedCount -gt 0) { "Green" } else { "Gray" })
Write-Host "  Files not found: $notFoundCount" -ForegroundColor Gray
Write-Host "  Total size freed: $([math]::Round($totalSize / 1KB, 2)) KB" -ForegroundColor Green

if ($DryRun) {
    Write-Host ""
    Write-Host "This was a DRY RUN - no files were actually deleted" -ForegroundColor Yellow
    Write-Host "Run without -DryRun to actually delete files:" -ForegroundColor Yellow
    Write-Host "  .\cleanup.ps1" -ForegroundColor White
    Write-Host ""
    Write-Host "To create a backup before deleting:" -ForegroundColor Yellow
    Write-Host "  .\cleanup.ps1 -Backup" -ForegroundColor White
}

Write-Host ""
Write-Host "Remaining important files:" -ForegroundColor Cyan

$keepFiles = @(
    "pghttp_full.c",
    "pghttp_full--1.0.0.sql",
    "pghttp.control",
    "pghttp.def",
    "build_full.ps1",
    "create_release.ps1",
    "install.ps1",
    "README.md",
    "README_CN.md",
    "README_FINAL.md",
    "INSTALL_RELEASE.md",
    "USAGE.md",
    "RELEASE_NOTES.md",
    "DISTRIBUTION_GUIDE.md",
    "发布包说明.md",
    "VERSION.txt",
    "examples.sql",
    ".gitignore"
)

foreach ($file in $keepFiles) {
    if (Test-Path $file) {
        Write-Host "  ✓ $file" -ForegroundColor Green
    } else {
        Write-Host "  ✗ $file (missing!)" -ForegroundColor Red
    }
}

Write-Host ""

if (-not $DryRun) {
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "✓ Cleanup Complete!" -ForegroundColor Green
    Write-Host "========================================" -ForegroundColor Cyan
} else {
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "Dry run complete - review the list above" -ForegroundColor Yellow
    Write-Host "========================================" -ForegroundColor Cyan
}

Write-Host ""
