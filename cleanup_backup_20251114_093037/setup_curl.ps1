# 自动下载和设置 libcurl for Windows
param(
    [string]$InstallPath = "C:\curl"
)

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "libcurl Setup for pghttp" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# 检查是否已经安装
if (Test-Path $InstallPath) {
    if (Test-Path "$InstallPath\include\curl\curl.h") {
        Write-Host "libcurl already installed at: $InstallPath" -ForegroundColor Green
        Write-Host "curl.h found!" -ForegroundColor Green
        exit 0
    }
}

Write-Host "libcurl not found. Setting up..." -ForegroundColor Yellow
Write-Host ""

# curl 下载 URL（使用预编译的 MinGW 版本）
$curlUrl = "https://curl.se/windows/dl-8.11.0_2/curl-8.11.0_2-win64-mingw.zip"
$zipFile = "$env:TEMP\curl.zip"

Write-Host "Downloading libcurl from: $curlUrl" -ForegroundColor Yellow
Write-Host "This may take a few minutes..." -ForegroundColor Yellow
Write-Host ""

try {
    # 下载
    Invoke-WebRequest -Uri $curlUrl -OutFile $zipFile -UseBasicParsing
    Write-Host "Download complete!" -ForegroundColor Green
    Write-Host ""
    
    # 解压
    Write-Host "Extracting to: $InstallPath" -ForegroundColor Yellow
    
    if (Test-Path $InstallPath) {
        Remove-Item $InstallPath -Recurse -Force
    }
    
    Expand-Archive -Path $zipFile -DestinationPath $env:TEMP -Force
    
    # 查找解压后的目录
    $extractedDir = Get-ChildItem "$env:TEMP\curl-*-win64-mingw" | Select-Object -First 1
    
    if ($extractedDir) {
        Move-Item $extractedDir.FullName $InstallPath -Force
        Write-Host "Extraction complete!" -ForegroundColor Green
    } else {
        throw "Failed to find extracted curl directory"
    }
    
    # 清理
    Remove-Item $zipFile -Force
    
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "libcurl installed successfully!" -ForegroundColor Green
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Location: $InstallPath" -ForegroundColor Green
    Write-Host ""
    Write-Host "Directory structure:" -ForegroundColor Yellow
    Get-ChildItem $InstallPath -Directory | ForEach-Object { Write-Host "  $_" -ForegroundColor Cyan }
    Write-Host ""
    
    # 验证
    if (Test-Path "$InstallPath\include\curl\curl.h") {
        Write-Host "✓ curl.h found" -ForegroundColor Green
    }
    if (Test-Path "$InstallPath\lib") {
        Write-Host "✓ lib directory found" -ForegroundColor Green
    }
    if (Test-Path "$InstallPath\bin") {
        Write-Host "✓ bin directory found" -ForegroundColor Green
    }
    
    Write-Host ""
    Write-Host "Next step: Run .\build.ps1 to compile pghttp extension" -ForegroundColor Yellow
    Write-Host ""
    
} catch {
    Write-Host "ERROR: Failed to download or extract libcurl" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
    Write-Host ""
    Write-Host "Manual installation:" -ForegroundColor Yellow
    Write-Host "1. Visit: https://curl.se/windows/" -ForegroundColor Cyan
    Write-Host "2. Download: curl-x.x.x-win64-mingw.zip" -ForegroundColor Cyan
    Write-Host "3. Extract to: $InstallPath" -ForegroundColor Cyan
    exit 1
}
