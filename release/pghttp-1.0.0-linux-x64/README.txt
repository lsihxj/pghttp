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
