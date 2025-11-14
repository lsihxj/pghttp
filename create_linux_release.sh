#!/bin/bash
# Create pghttp Linux Release Package

set -e

echo "========================================"
echo "  Creating pghttp Linux Release Package"
echo "========================================"
echo

# Version info
VERSION="1.0.0"
RELEASE_NAME="pghttp-$VERSION-linux-x64"
RELEASE_DIR="./release/$RELEASE_NAME"

# Create release directory
echo "Creating release directory..."
rm -rf ./release
mkdir -p "$RELEASE_DIR"
echo "[OK] Created: $RELEASE_DIR"
echo

# Check if required files exist
echo "Checking required files..."

REQUIRED_FILES=(
    "pghttp.c"
    "pghttp.control"
    "pghttp--1.0.0.sql"
    "Makefile"
    "install_linux.sh"
    "INSTALL_LINUX.md"
    "USAGE.md"
    "examples.sql"
    "VERSION.txt"
)

MISSING_FILES=()
for file in "${REQUIRED_FILES[@]}"; do
    if [ -f "$file" ]; then
        echo "  [OK] $file"
    else
        echo "  [ERROR] $file - MISSING!"
        MISSING_FILES+=("$file")
    fi
done

if [ ${#MISSING_FILES[@]} -gt 0 ]; then
    echo
    echo "[ERROR] Missing required files!"
    exit 1
fi
echo

# Copy files to release directory
echo "Copying files to release package..."

for file in "${REQUIRED_FILES[@]}"; do
    cp "$file" "$RELEASE_DIR/"
    echo "  [OK] Copied $file"
done

# Copy optional documentation
OPTIONAL_DOCS=(
    "README.md"
    "README_CN.md"
    "POSTGRESQL_COMPATIBILITY.md"
    "PLATFORM_SUPPORT.md"
    "PLATFORM_SUMMARY.md"
    "CROSSPLATFORM_README.md"
)

for doc in "${OPTIONAL_DOCS[@]}"; do
    if [ -f "$doc" ]; then
        cp "$doc" "$RELEASE_DIR/"
        echo "  [OK] Copied $doc (optional)"
    fi
done
echo

# Create README for release
cat > "$RELEASE_DIR/README.txt" << 'EOF'
pghttp - PostgreSQL HTTP Extension (Linux x64)

Version: 1.0.0
Build Date: 2025-11-14
Platform: Linux x64 (Source Code - Requires Compilation)

Quick Start:

1. Install dependencies:
   
   Ubuntu/Debian:
   sudo apt-get update
   sudo apt-get install postgresql-server-dev-all libcurl4-openssl-dev gcc make

   CentOS/RHEL/Fedora:
   sudo dnf install postgresql-devel libcurl-devel gcc make

   Arch Linux:
   sudo pacman -S postgresql-libs curl

2. Compile:
   make clean && make

3. Install:
   sudo make install
   # Or use the installation script:
   sudo chmod +x install_linux.sh && sudo ./install_linux.sh

4. In PostgreSQL:
   CREATE EXTENSION pghttp;

5. Test:
   SELECT http_get('https://httpbin.org/get');

Features:
✅ HTTP/HTTPS GET requests
✅ HTTP/HTTPS POST requests
✅ All HTTP methods (PUT, DELETE, PATCH, etc.)
✅ Detailed response (status code, content-type, body)
✅ UTF-8 encoding support
✅ Using libcurl (industry standard)
✅ 30 seconds timeout protection
✅ Auto Content-Type header for POST requests

Cross-Platform Support:
This is the Linux source package. For Windows pre-compiled version:
- Download: pghttp-1.0.0-win-x64.zip
- See: CROSSPLATFORM_README.md

For detailed instructions, see:
- INSTALL_LINUX.md - Installation guide
- USAGE.md - Usage examples
- examples.sql - SQL examples
- CROSSPLATFORM_README.md - Cross-platform details

License: MIT - Free to use, modify, and distribute

Happy coding with pghttp! 🚀
EOF

echo "[OK] Created README.txt"
echo

# Create tarball
echo "Creating tarball..."
cd release
tar -czf "$RELEASE_NAME.tar.gz" "$RELEASE_NAME"
cd ..

# Calculate SHA256
echo "Calculating SHA256..."
sha256sum "release/$RELEASE_NAME.tar.gz" > "release/$RELEASE_NAME-SHA256.txt"

# Get file size
FILE_SIZE=$(du -h "release/$RELEASE_NAME.tar.gz" | cut -f1)

echo
echo "========================================"
echo "  Release Package Created!"
echo "========================================"
echo
echo "Package: $RELEASE_NAME.tar.gz"
echo "Size:    $FILE_SIZE"
echo "SHA256:  $(cat release/$RELEASE_NAME-SHA256.txt | cut -d' ' -f1)"
echo
echo "Location: ./release/"
echo
echo "To distribute:"
echo "  1. Upload $RELEASE_NAME.tar.gz"
echo "  2. Include $RELEASE_NAME-SHA256.txt for verification"
echo
echo "Users can verify with:"
echo "  sha256sum -c $RELEASE_NAME-SHA256.txt"
echo
echo "========================================"
echo "Release package is ready for distribution! 🎉"
echo
