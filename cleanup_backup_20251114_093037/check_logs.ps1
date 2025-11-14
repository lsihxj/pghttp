#!/usr/bin/env powershell
# 检查 PostgreSQL 日志配置和内容

Write-Host "======================================" -ForegroundColor Cyan
Write-Host "PostgreSQL 日志诊断" -ForegroundColor Cyan
Write-Host "======================================`n" -ForegroundColor Cyan

# 1. 查找日志目录
Write-Host "[1] 查找 PostgreSQL 日志目录..." -ForegroundColor Yellow

$pgDataDir = "D:\pgsql\data"
$logDir = "$pgDataDir\log"

if (Test-Path $logDir) {
    Write-Host "✓ 日志目录: $logDir`n" -ForegroundColor Green
} else {
    Write-Host "✗ 日志目录不存在: $logDir" -ForegroundColor Red
    
    # 尝试其他位置
    $altLogDirs = @(
        "$pgDataDir\pg_log",
        "D:\pgsql\log",
        "$pgDataDir\logs"
    )
    
    foreach ($dir in $altLogDirs) {
        if (Test-Path $dir) {
            $logDir = $dir
            Write-Host "✓ 找到日志目录: $logDir`n" -ForegroundColor Green
            break
        }
    }
}

# 2. 列出最近的日志文件
Write-Host "[2] 最近的日志文件:" -ForegroundColor Yellow

if (Test-Path $logDir) {
    $logFiles = Get-ChildItem $logDir -Filter "*.log" | 
                Sort-Object LastWriteTime -Descending | 
                Select-Object -First 5
    
    $logFiles | ForEach-Object {
        Write-Host "  $($_.Name) - $($_.LastWriteTime) - $([math]::Round($_.Length/1KB, 2)) KB" -ForegroundColor Gray
    }
    Write-Host ""
} else {
    Write-Host "✗ 无法找到日志文件`n" -ForegroundColor Red
    exit 1
}

# 3. 查看最新日志的最后 50 行
Write-Host "[3] 最新日志内容（最后 50 行）:" -ForegroundColor Yellow
Write-Host "======================================`n" -ForegroundColor Gray

$latestLog = Get-ChildItem $logDir -Filter "*.log" | 
             Sort-Object LastWriteTime -Descending | 
             Select-Object -First 1

if ($latestLog) {
    Write-Host "文件: $($latestLog.FullName)" -ForegroundColor Cyan
    Write-Host "修改时间: $($latestLog.LastWriteTime)" -ForegroundColor Cyan
    Write-Host "大小: $([math]::Round($latestLog.Length/1KB, 2)) KB`n" -ForegroundColor Cyan
    
    Get-Content $latestLog.FullName -Tail 50 -Encoding UTF8
}

Write-Host "`n======================================" -ForegroundColor Gray

# 4. 检查 PostgreSQL 配置
Write-Host "`n[4] 检查 postgresql.conf 日志配置..." -ForegroundColor Yellow

$configFile = "$pgDataDir\postgresql.conf"

if (Test-Path $configFile) {
    Write-Host "✓ 配置文件: $configFile`n" -ForegroundColor Green
    
    $logSettings = @(
        "log_destination",
        "logging_collector",
        "log_directory",
        "log_filename",
        "log_min_messages",
        "client_min_messages",
        "log_statement"
    )
    
    foreach ($setting in $logSettings) {
        $value = Select-String -Path $configFile -Pattern "^\s*$setting\s*=" | Select-Object -First 1
        if ($value) {
            Write-Host "  $value" -ForegroundColor Gray
        } else {
            Write-Host "  $setting = (未配置/已注释)" -ForegroundColor DarkGray
        }
    }
} else {
    Write-Host "✗ 配置文件不存在`n" -ForegroundColor Red
}

# 5. 实时监控日志
Write-Host "`n======================================" -ForegroundColor Cyan
Write-Host "[5] 实时监控选项" -ForegroundColor Cyan
Write-Host "======================================`n" -ForegroundColor Cyan

Write-Host "要实时监控日志，请运行：" -ForegroundColor Yellow
Write-Host "  Get-Content '$($latestLog.FullName)' -Wait -Tail 20`n" -ForegroundColor White

$choice = Read-Host "是否现在开始实时监控？(y/n)"

if ($choice -eq 'y' -or $choice -eq 'Y') {
    Write-Host "`n开始实时监控日志（按 Ctrl+C 停止）...`n" -ForegroundColor Green
    Get-Content $latestLog.FullName -Wait -Tail 20
}
