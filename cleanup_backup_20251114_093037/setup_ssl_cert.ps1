#!/usr/bin/env powershell
# Setup SSL CA Certificate for pghttp
# 为 pghttp 配置 SSL CA 证书

Write-Host "======================================" -ForegroundColor Cyan
Write-Host "pghttp - SSL Certificate Setup" -ForegroundColor Cyan
Write-Host "======================================`n" -ForegroundColor Cyan

$CurlPath = "C:\curl\bin"
$CertFile = "$CurlPath\curl-ca-bundle.crt"
$CertUrl = "https://curl.se/ca/cacert.pem"

# 检查 curl 目录
if (-not (Test-Path $CurlPath)) {
    Write-Host "✗ curl 目录不存在: $CurlPath" -ForegroundColor Red
    Write-Host "请先运行 setup_curl.ps1" -ForegroundColor Yellow
    exit 1
}

Write-Host "[步骤 1/4] 下载 CA 证书包..." -ForegroundColor Yellow
Write-Host "来源: $CertUrl" -ForegroundColor Gray
Write-Host "目标: $CertFile`n" -ForegroundColor Gray

try {
    # 下载证书
    Invoke-WebRequest -Uri $CertUrl -OutFile $CertFile -ErrorAction Stop
    
    $fileSize = (Get-Item $CertFile).Length / 1KB
    Write-Host "✓ 证书下载成功 ($([math]::Round($fileSize, 2)) KB)`n" -ForegroundColor Green
}
catch {
    Write-Host "✗ 下载失败: $_" -ForegroundColor Red
    Write-Host "`n备选方案：手动下载证书" -ForegroundColor Yellow
    Write-Host "1. 访问: https://curl.se/ca/cacert.pem" -ForegroundColor White
    Write-Host "2. 保存为: $CertFile`n" -ForegroundColor White
    exit 1
}

Write-Host "[步骤 2/4] 设置环境变量..." -ForegroundColor Yellow

# 检查是否有管理员权限
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if ($isAdmin) {
    Write-Host "检测到管理员权限，设置系统环境变量..." -ForegroundColor Cyan
    
    try {
        [Environment]::SetEnvironmentVariable("CURL_CA_BUNDLE", $CertFile, "Machine")
        Write-Host "✓ 系统环境变量已设置" -ForegroundColor Green
        Write-Host "  CURL_CA_BUNDLE = $CertFile`n" -ForegroundColor Gray
    }
    catch {
        Write-Host "✗ 设置系统环境变量失败: $_" -ForegroundColor Red
        Write-Host "将使用用户环境变量..." -ForegroundColor Yellow
        [Environment]::SetEnvironmentVariable("CURL_CA_BUNDLE", $CertFile, "User")
        Write-Host "✓ 用户环境变量已设置`n" -ForegroundColor Green
    }
}
else {
    Write-Host "未检测到管理员权限，设置用户环境变量..." -ForegroundColor Cyan
    [Environment]::SetEnvironmentVariable("CURL_CA_BUNDLE", $CertFile, "User")
    Write-Host "✓ 用户环境变量已设置" -ForegroundColor Green
    Write-Host "  CURL_CA_BUNDLE = $CertFile`n" -ForegroundColor Gray
}

# 同时设置当前会话
$env:CURL_CA_BUNDLE = $CertFile
Write-Host "✓ 当前会话环境变量已设置`n" -ForegroundColor Green

Write-Host "[步骤 3/4] 重启 PostgreSQL 服务..." -ForegroundColor Yellow

# 查找 PostgreSQL 服务
$pgService = Get-Service | Where-Object { $_.Name -like "postgresql*" } | Select-Object -First 1

if ($pgService) {
    $serviceName = $pgService.Name
    Write-Host "找到服务: $serviceName (状态: $($pgService.Status))" -ForegroundColor Cyan
    
    if ($isAdmin) {
        try {
            Write-Host "正在重启服务..." -ForegroundColor Gray
            Restart-Service $serviceName -Force -ErrorAction Stop
            Start-Sleep -Seconds 2
            
            $newStatus = (Get-Service $serviceName).Status
            Write-Host "✓ PostgreSQL 服务已重启 (状态: $newStatus)`n" -ForegroundColor Green
        }
        catch {
            Write-Host "✗ 重启失败: $_" -ForegroundColor Red
            Write-Host "`n手动重启命令：" -ForegroundColor Yellow
            Write-Host "  net stop $serviceName" -ForegroundColor White
            Write-Host "  net start $serviceName`n" -ForegroundColor White
        }
    }
    else {
        Write-Host "⚠️  需要管理员权限重启服务" -ForegroundColor Yellow
        Write-Host "请以管理员身份运行：" -ForegroundColor Yellow
        Write-Host "  Restart-Service $serviceName" -ForegroundColor White
        Write-Host "或：" -ForegroundColor Yellow
        Write-Host "  net stop $serviceName && net start $serviceName`n" -ForegroundColor White
    }
}
else {
    Write-Host "⚠️  未找到 PostgreSQL 服务" -ForegroundColor Yellow
    Write-Host "请手动重启 PostgreSQL`n" -ForegroundColor Yellow
}

Write-Host "[步骤 4/4] 验证配置..." -ForegroundColor Yellow

# 验证证书文件
if (Test-Path $CertFile) {
    $certSize = (Get-Item $CertFile).Length
    Write-Host "✓ 证书文件存在 ($certSize bytes)" -ForegroundColor Green
}

# 验证环境变量
$envValue = [Environment]::GetEnvironmentVariable("CURL_CA_BUNDLE", "Machine")
if ($envValue -eq $CertFile) {
    Write-Host "✓ 系统环境变量配置正确" -ForegroundColor Green
}
elseif ([Environment]::GetEnvironmentVariable("CURL_CA_BUNDLE", "User") -eq $CertFile) {
    Write-Host "✓ 用户环境变量配置正确" -ForegroundColor Green
}

Write-Host ""
Write-Host "======================================" -ForegroundColor Cyan
Write-Host "✅ SSL 证书配置完成！" -ForegroundColor Green
Write-Host "======================================`n" -ForegroundColor Cyan

Write-Host "现在测试扩展：`n" -ForegroundColor Yellow

Write-Host "1. 连接数据库：" -ForegroundColor White
Write-Host "   psql -U postgres -d postgres`n" -ForegroundColor Gray

Write-Host "2. 重新创建扩展：" -ForegroundColor White
Write-Host "   DROP EXTENSION IF EXISTS pghttp CASCADE;" -ForegroundColor Gray
Write-Host "   CREATE EXTENSION pghttp;`n" -ForegroundColor Gray

Write-Host "3. 测试 HTTPS 请求：" -ForegroundColor White
Write-Host "   SELECT http_get('https://httpbin.org/get');`n" -ForegroundColor Gray

Write-Host "如果仍然失败，请查看：" -ForegroundColor Yellow
Write-Host "  - PostgreSQL 日志: D:\pgsql\data\log\postgresql-*.log" -ForegroundColor White
Write-Host "  - 故障排除文档: TROUBLESHOOTING.md`n" -ForegroundColor White

Write-Host "提示: 如果 PostgreSQL 服务未重启，请手动重启后再测试" -ForegroundColor Cyan
