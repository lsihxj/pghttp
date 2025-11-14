#!/bin/bash
# PostgreSQL HTTP Extension - Linux Installation Script

set -e

echo "========================================"
echo "  pghttp Installation Script (Linux)"
echo "========================================"
echo

# Check if running as root
if [ "$EUID" -ne 0 ]; then 
    echo "[ERROR] Please run as root (use sudo)"
    exit 1
fi

# Detect PostgreSQL version and path
echo "Detecting PostgreSQL installation..."

PG_CONFIG=$(which pg_config 2>/dev/null || echo "")

if [ -z "$PG_CONFIG" ]; then
    echo "[ERROR] pg_config not found!"
    echo "Please install postgresql-server-dev package:"
    echo "  Ubuntu/Debian: sudo apt-get install postgresql-server-dev-all"
    echo "  CentOS/RHEL:   sudo yum install postgresql-devel"
    exit 1
fi

PG_VERSION=$($PG_CONFIG --version | awk '{print $2}' | cut -d. -f1)
PG_LIBDIR=$($PG_CONFIG --pkglibdir)
PG_SHAREDIR=$($PG_CONFIG --sharedir)

echo "[OK] PostgreSQL $PG_VERSION detected"
echo "  Library dir: $PG_LIBDIR"
echo "  Share dir:   $PG_SHAREDIR"
echo

# Check dependencies
echo "Checking dependencies..."

if ! pkg-config --exists libcurl; then
    echo "[ERROR] libcurl not found!"
    echo "Please install libcurl development package:"
    echo "  Ubuntu/Debian: sudo apt-get install libcurl4-openssl-dev"
    echo "  CentOS/RHEL:   sudo yum install libcurl-devel"
    exit 1
fi

echo "[OK] libcurl found"
echo

# Check if files exist
echo "Checking extension files..."

REQUIRED_FILES=("pghttp.so" "pghttp.control" "pghttp--1.0.0.sql")
MISSING_FILES=()

for file in "${REQUIRED_FILES[@]}"; do
    if [ ! -f "$file" ]; then
        MISSING_FILES+=("$file")
    fi
done

if [ ${#MISSING_FILES[@]} -gt 0 ]; then
    echo "[ERROR] Missing files:"
    for file in "${MISSING_FILES[@]}"; do
        echo "  - $file"
    done
    echo
    echo "Please compile the extension first:"
    echo "  make clean && make"
    exit 1
fi

echo "[OK] All required files present"
echo

# Stop PostgreSQL
echo "Stopping PostgreSQL service..."
systemctl stop postgresql 2>/dev/null || service postgresql stop 2>/dev/null || {
    echo "[WARNING] Could not stop PostgreSQL automatically"
    echo "Please stop PostgreSQL manually before continuing"
    read -p "Press Enter when PostgreSQL is stopped..."
}

# Install extension
echo "Installing extension files..."

cp pghttp.so "$PG_LIBDIR/" && echo "  [OK] Copied pghttp.so"
cp pghttp.control "$PG_SHAREDIR/extension/" && echo "  [OK] Copied pghttp.control"
cp pghttp--1.0.0.sql "$PG_SHAREDIR/extension/" && echo "  [OK] Copied pghttp--1.0.0.sql"

# Set permissions
chmod 755 "$PG_LIBDIR/pghttp.so"
chmod 644 "$PG_SHAREDIR/extension/pghttp.control"
chmod 644 "$PG_SHAREDIR/extension/pghttp--1.0.0.sql"

echo "[OK] Extension installed successfully"
echo

# Start PostgreSQL
echo "Starting PostgreSQL service..."
systemctl start postgresql 2>/dev/null || service postgresql start 2>/dev/null || {
    echo "[WARNING] Could not start PostgreSQL automatically"
    echo "Please start PostgreSQL manually"
}

echo
echo "========================================"
echo "  Installation Complete!"
echo "========================================"
echo
echo "Next Steps:"
echo "  1. Connect to your PostgreSQL database"
echo "  2. Run the following SQL command:"
echo
echo "     CREATE EXTENSION pghttp;"
echo
echo "  3. Test the extension:"
echo
echo "     SELECT http_get('https://httpbin.org/get');"
echo
echo "For more examples, see examples.sql"
echo "For usage guide, see USAGE.md"
echo
