#!/usr/bin/env powershell
# Fix DLL Loading Issue for pghttp Extension
# 修复 pghttp 扩展的 DLL 加载问题

Write-Host "======================================" -ForegroundColor Cyan
Write-Host "pghttp Extension - DLL Path Fix" -ForegroundColor Cyan
Write-Host "======================================`n" -ForegroundColor Cyan

$PgPath = "D:\pgsql"
$CurlPath = "C:\curl"

Write-Host "[解决方案选择]" -ForegroundColor Yellow
Write-Host "有三种方式解决 DLL 加载问题：`n"
Write-Host "1. 复制 libcurl.dll 到 PostgreSQL bin 目录（推荐）" -ForegroundColor Green
Write-Host "2. 添加 C:\curl\bin 到系统 PATH（永久）"
Write-Host "3. 重启 PostgreSQL 服务（如果已设置 PATH）`n"

$choice = Read-Host "请选择方案 (1/2/3)"

switch ($choice) {
    "1" {
        Write-Host "`n[方案 1] 复制 DLL 文件..." -ForegroundColor Yellow
        
        $curlDll = "$CurlPath\bin\libcurl-x64.dll"
        $pgBin = "$PgPath\bin"
        
        if (-not (Test-Path $curlDll)) {
            Write-Host "✗ 找不到 $curlDll" -ForegroundColor Red
            exit 1
        }
        
        try {
            Copy-Item $curlDll "$pgBin\libcurl.dll" -Force
            Write-Host "✓ 已复制: $curlDll -> $pgBin\libcurl.dll" -ForegroundColor Green
            
            # 同时复制原始文件名
            Copy-Item $curlDll "$pgBin\libcurl-x64.dll" -Force
            Write-Host "✓ 已复制: $curlDll -> $pgBin\libcurl-x64.dll" -ForegroundColor Green
            
            Write-Host "`n✅ 完成！现在可以在 PostgreSQL 中执行：" -ForegroundColor Green
            Write-Host "   CREATE EXTENSION pghttp;" -ForegroundColor White
        }
        catch {
            Write-Host "✗ 复制失败: $_" -ForegroundColor Red
            Write-Host "提示: 可能需要管理员权限" -ForegroundColor Yellow
            exit 1
        }
    }
    
    "2" {
        Write-Host "`n[方案 2] 添加到系统 PATH..." -ForegroundColor Yellow
        
        $currentPath = [Environment]::GetEnvironmentVariable("Path", "Machine")
        
        if ($currentPath -like "*$CurlPath\bin*") {
            Write-Host "✓ C:\curl\bin 已经在系统 PATH 中" -ForegroundColor Green
        }
        else {
            Write-Host "提示: 需要管理员权限添加到系统 PATH" -ForegroundColor Yellow
            
            try {
                $newPath = "$currentPath;$CurlPath\bin"
                [Environment]::SetEnvironmentVariable("Path", $newPath, "Machine")
                Write-Host "✓ 已添加 C:\curl\bin 到系统 PATH" -ForegroundColor Green
            }
            catch {
                Write-Host "✗ 失败（需要管理员权限）" -ForegroundColor Red
                Write-Host "`n手动添加步骤：" -ForegroundColor Yellow
                Write-Host "1. Win + X -> 系统 -> 高级系统设置"
                Write-Host "2. 环境变量 -> 系统变量 -> Path -> 编辑"
                Write-Host "3. 新建 -> 输入: C:\curl\bin"
                exit 1
            }
        }
        
        Write-Host "`n⚠️  重要: 需要重启 PostgreSQL 服务！" -ForegroundColor Yellow
        Write-Host "执行: net stop postgresql-x64-15 && net start postgresql-x64-15" -ForegroundColor White
        Write-Host "或者运行方案 3" -ForegroundColor White
    }
    
    "3" {
        Write-Host "`n[方案 3] 重启 PostgreSQL 服务..." -ForegroundColor Yellow
        
        # 尝试查找 PostgreSQL 服务名
        $pgService = Get-Service | Where-Object { $_.Name -like "postgresql*" }
        
        if ($pgService) {
            $serviceName = $pgService.Name
            Write-Host "找到 PostgreSQL 服务: $serviceName" -ForegroundColor Cyan
            
            try {
                Write-Host "停止服务..." -ForegroundColor Yellow
                Stop-Service $serviceName -Force
                Start-Sleep -Seconds 2
                
                Write-Host "启动服务..." -ForegroundColor Yellow
                Start-Service $serviceName
                
                Write-Host "✓ PostgreSQL 服务已重启" -ForegroundColor Green
                Write-Host "`n现在可以测试扩展了！" -ForegroundColor Green
            }
            catch {
                Write-Host "✗ 重启失败（需要管理员权限）" -ForegroundColor Red
                Write-Host "`n请以管理员权限运行：" -ForegroundColor Yellow
                Write-Host "net stop $serviceName" -ForegroundColor White
                Write-Host "net start $serviceName" -ForegroundColor White
                exit 1
            }
        }
        else {
            Write-Host "✗ 未找到 PostgreSQL 服务" -ForegroundColor Red
            Write-Host "请手动在服务管理器中重启 PostgreSQL" -ForegroundColor Yellow
        }
    }
    
    default {
        Write-Host "无效选择，退出" -ForegroundColor Red
        exit 1
    }
}

Write-Host "`n======================================" -ForegroundColor Cyan
Write-Host "测试扩展：" -ForegroundColor Cyan
Write-Host "psql -U postgres -d postgres" -ForegroundColor White
Write-Host "CREATE EXTENSION pghttp;" -ForegroundColor White
Write-Host "SELECT http_get('https://httpbin.org/get');" -ForegroundColor White
Write-Host "======================================" -ForegroundColor Cyan
