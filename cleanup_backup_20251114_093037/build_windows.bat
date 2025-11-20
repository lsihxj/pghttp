@echo off
REM PostgreSQL HTTP Extension - Windows Build Script
REM 确保以管理员权限运行

echo ========================================
echo pghttp Extension - Windows Build Script
echo ========================================
echo.

REM 尝试自动检测 PostgreSQL 路径
set PG_HOME=
set CURL_HOME=C:\curl

REM 检查常见的 PostgreSQL 安装路径
for %%v in (17 16 15 14 13 12) do (
    if exist "C:\Program Files\PostgreSQL\%%v" (
        set PG_HOME=C:\Program Files\PostgreSQL\%%v
        goto :found_pg
    )
)

REM 尝试从环境变量中获取
where pg_config >nul 2>&1
if %errorlevel% equ 0 (
    for /f "delims=" %%i in ('where pg_config') do (
        set PG_CONFIG_PATH=%%i
        for %%a in ("%%i") do set PG_HOME=%%~dpa..
        goto :found_pg
    )
)

REM 如果没找到，提示用户
echo ERROR: PostgreSQL not found in standard locations.
echo.
echo Please enter your PostgreSQL installation path
echo (e.g., C:\Program Files\PostgreSQL\15)
echo or press Ctrl+C to cancel and edit this script manually.
echo.
set /p PG_HOME="PostgreSQL path: "

:found_pg
REM 检查 PostgreSQL 是否存在
if not exist "%PG_HOME%" (
    echo ERROR: PostgreSQL not found at %PG_HOME%
    echo Please check your PostgreSQL installation
    pause
    exit /b 1
)

REM 检查 curl 是否存在
if not exist "%CURL_HOME%" (
    echo ERROR: libcurl not found at %CURL_HOME%
    echo Please download curl from https://curl.se/windows/
    echo and extract it to C:\curl
    pause
    exit /b 1
)

echo Found PostgreSQL at: %PG_HOME%
echo Found libcurl at: %CURL_HOME%
echo.

REM 设置环境变量
set PATH=%PG_HOME%\bin;%CURL_HOME%\bin;%PATH%
set PG_CONFIG=%PG_HOME%\bin\pg_config.exe

echo Checking pg_config...
"%PG_CONFIG%" --version
if errorlevel 1 (
    echo ERROR: pg_config not found or not working
    pause
    exit /b 1
)
echo.

echo Starting build...
echo.

REM 使用 MinGW 或 MSVC 编译
REM 这里假设使用 PostgreSQL 自带的编译工具

echo Building pghttp extension...
make clean
if errorlevel 1 (
    echo Warning: Clean failed, continuing...
)

make
if errorlevel 1 (
    echo ERROR: Build failed
    echo.
    echo Troubleshooting:
    echo 1. Make sure you have a C compiler installed (MinGW or Visual Studio)
    echo 2. Check that libcurl headers are in %CURL_HOME%\include
    echo 3. Check that libcurl library is in %CURL_HOME%\lib
    pause
    exit /b 1
)

echo.
echo Build successful!
echo.

echo Installing extension...
make install
if errorlevel 1 (
    echo ERROR: Installation failed
    echo Please run this script as Administrator
    pause
    exit /b 1
)

echo.
echo ========================================
echo Installation completed successfully!
echo ========================================
echo.
echo Next steps:
echo 1. Connect to PostgreSQL: psql -U postgres
echo 2. Create extension: CREATE EXTENSION pghttp;
echo 3. Test: SELECT http_get('https://httpbin.org/get');
echo.
echo For testing, run: psql -U postgres -d postgres -f test_simple.sql
echo.
pause
