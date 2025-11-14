#!/bin/bash
# PostgreSQL HTTP Extension - Linux Build Script

set -e  # Exit on error

echo "========================================"
echo "pghttp Extension - Linux Build Script"
echo "========================================"
echo ""

# 检查是否以 root 运行（安装时需要）
if [ "$EUID" -ne 0 ] && [ "$1" = "install" ]; then 
    echo "Please run with sudo for installation: sudo $0 install"
    exit 1
fi

# 检查依赖
echo "Checking dependencies..."

# 检查 pg_config
if ! command -v pg_config &> /dev/null; then
    echo "ERROR: pg_config not found"
    echo "Please install: sudo apt-get install postgresql-server-dev-all"
    exit 1
fi

echo "PostgreSQL version: $(pg_config --version)"

# 检查 curl 开发库
if [ ! -f "/usr/include/curl/curl.h" ]; then
    echo "ERROR: libcurl headers not found"
    echo "Please install: sudo apt-get install libcurl4-openssl-dev"
    exit 1
fi

echo "Dependencies OK"
echo ""

# 清理
echo "Cleaning previous build..."
make clean || true
echo ""

# 编译
echo "Building pghttp extension..."
make
if [ $? -ne 0 ]; then
    echo "ERROR: Build failed"
    exit 1
fi

echo ""
echo "Build successful!"
echo ""

# 安装（如果指定了 install 参数）
if [ "$1" = "install" ]; then
    echo "Installing extension..."
    make install
    if [ $? -ne 0 ]; then
        echo "ERROR: Installation failed"
        exit 1
    fi
    
    echo ""
    echo "========================================"
    echo "Installation completed successfully!"
    echo "========================================"
    echo ""
    echo "Next steps:"
    echo "1. Connect to PostgreSQL: sudo -u postgres psql"
    echo "2. Create extension: CREATE EXTENSION pghttp;"
    echo "3. Test: SELECT http_get('https://httpbin.org/get');"
    echo ""
    echo "For full testing, run: psql -d postgres -f test.sql"
    echo ""
else
    echo "Build completed. To install, run: sudo $0 install"
fi
