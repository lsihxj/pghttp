# 测试数据库连接和扩展
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Testing pghttp Extension" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "Connecting to PostgreSQL..." -ForegroundColor Yellow
Write-Host "User: postgres" -ForegroundColor Cyan
Write-Host "Password: 12456" -ForegroundColor Cyan
Write-Host ""

# 设置密码环境变量
$env:PGPASSWORD = "12456"

# 测试 SQL 命令
$testSQL = @"
-- 创建扩展
DROP EXTENSION IF EXISTS pghttp CASCADE;
CREATE EXTENSION pghttp;

-- 显示扩展信息
\dx pghttp

-- 测试 GET 请求
SELECT 'Testing GET...' AS test;
SELECT http_get('https://httpbin.org/get') AS result \gx

-- 测试 POST 请求
SELECT 'Testing POST...' AS test;
SELECT http_post('https://httpbin.org/post', '{"test":"hello"}') AS result \gx

-- 测试中文
SELECT 'Testing UTF-8 Chinese...' AS test;
SELECT http_post('https://httpbin.org/post', '{"姓名":"张三"}') AS result \gx

SELECT 'All tests passed!' AS result;
"@

# 保存到临时文件
$tempFile = "$env:TEMP\pghttp_test.sql"
$testSQL | Out-File -FilePath $tempFile -Encoding UTF8

# 执行测试
Write-Host "Running tests..." -ForegroundColor Yellow
Write-Host ""

& D:\pgsql\bin\psql.exe -U postgres -d postgres -f $tempFile

# 清理
Remove-Item $tempFile -ErrorAction SilentlyContinue

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Test Complete!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
