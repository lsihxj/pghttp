# pghttp 安装指南

## Windows 平台安装

### 前置要求

1. **PostgreSQL 安装**
   - 下载并安装 PostgreSQL: https://www.postgresql.org/download/windows/
   - 确保安装了开发工具（在安装时勾选 "Command Line Tools"）

2. **libcurl 安装**
   
   **方法 1: 使用预编译的 libcurl (推荐)**
   
   a. 下载 curl for Windows:
      - 访问: https://curl.se/windows/
      - 下载 64-bit 版本（如：curl-8.x.x-win64-mingw.zip）
   
   b. 解压到 C:\curl
   
   c. 设置环境变量:
      ```powershell
      # 添加到系统环境变量 Path
      C:\curl\bin
      
      # 设置 CURL_INCLUDE 和 CURL_LIB
      $env:CURL_INCLUDE = "C:\curl\include"
      $env:CURL_LIB = "C:\curl\lib"
      ```

   **方法 2: 使用 MSYS2/MinGW**
   
   ```bash
   # 安装 MSYS2
   # 下载: https://www.msys2.org/
   
   # 在 MSYS2 终端中安装 curl
   pacman -S mingw-w64-x86_64-curl
   ```

3. **编译工具**
   - Visual Studio (含 C++ 编译器) 或
   - MinGW-w64

### 编译步骤

#### 使用 Visual Studio

1. 打开 "x64 Native Tools Command Prompt for VS"

2. 设置 PostgreSQL 环境变量:
   ```cmd
   set PATH=C:\Program Files\PostgreSQL\15\bin;%PATH%
   set PGROOT=C:\Program Files\PostgreSQL\15
   ```

3. 修改 Makefile 添加 Windows 支持:
   ```makefile
   # 在 Makefile 中添加
   ifdef USE_PGXS
   PG_CONFIG = pg_config
   PGXS := $(shell $(PG_CONFIG) --pgxs)
   
   # Windows specific
   ifeq ($(OS),Windows_NT)
       PG_CPPFLAGS += -I"C:/curl/include"
       SHLIB_LINK += -L"C:/curl/lib" -lcurl
   else
       SHLIB_LINK = -lcurl
   endif
   
   include $(PGXS)
   endif
   ```

4. 编译:
   ```cmd
   nmake /F Makefile
   nmake /F Makefile install
   ```

#### 使用 MinGW (推荐)

1. 在 PowerShell 或 CMD 中:
   ```powershell
   # 设置环境
   $env:PATH = "C:\Program Files\PostgreSQL\15\bin;$env:PATH"
   
   # 编译
   cd d:\CodeBuddy\pghttp
   make
   make install
   ```

### 安装验证

```powershell
# 连接到 PostgreSQL
psql -U postgres -d postgres

# 在 psql 中执行
CREATE EXTENSION pghttp;

# 测试
SELECT http_get('https://httpbin.org/get');
```

---

## Linux 平台安装 (Ubuntu/Debian)

### 安装依赖

```bash
sudo apt-get update
sudo apt-get install -y \
    postgresql-server-dev-all \
    libcurl4-openssl-dev \
    build-essential
```

### 编译安装

```bash
cd pghttp
make
sudo make install
```

### 启用扩展

```bash
# 连接到数据库
sudo -u postgres psql

# 创建扩展
CREATE EXTENSION pghttp;

# 测试
SELECT http_get('https://httpbin.org/get');
```

---

## Linux 平台安装 (CentOS/RHEL)

### 安装依赖

```bash
sudo yum install -y \
    postgresql-devel \
    libcurl-devel \
    gcc \
    make
```

### 编译安装

```bash
cd pghttp
make
sudo make install
```

---

## macOS 平台安装

### 安装依赖

```bash
# 使用 Homebrew
brew install postgresql curl
```

### 编译安装

```bash
cd pghttp
make
sudo make install
```

### 启用扩展

```bash
psql -d postgres
CREATE EXTENSION pghttp;
```

---

## 常见问题排查

### 问题 1: 找不到 pg_config

**解决方法:**
```bash
# Linux/macOS
export PATH=/usr/pgsql-15/bin:$PATH  # 根据实际版本调整

# Windows
set PATH=C:\Program Files\PostgreSQL\15\bin;%PATH%
```

### 问题 2: 找不到 curl.h

**解决方法:**

**Linux:**
```bash
sudo apt-get install libcurl4-openssl-dev
```

**Windows:**
- 确保正确设置了 CURL_INCLUDE 环境变量
- 检查 C:\curl\include 目录是否存在 curl/curl.h

### 问题 3: 编译错误 - undefined reference to curl_*

**解决方法:**

检查 Makefile 中的 SHLIB_LINK:
```makefile
SHLIB_LINK = -lcurl
```

**Windows 需要指定库路径:**
```makefile
SHLIB_LINK = -L"C:/curl/lib" -lcurl
```

### 问题 4: CREATE EXTENSION 失败

**可能原因:**
1. 扩展文件未正确安装到 PostgreSQL 目录
2. 权限不足

**解决方法:**
```bash
# 检查扩展文件位置
pg_config --sharedir
# 应该在 <sharedir>/extension/ 下看到 pghttp.control

# 检查库文件
pg_config --pkglibdir
# 应该在 <pkglibdir>/ 下看到 pghttp.so (Linux) 或 pghttp.dll (Windows)

# 重新安装
sudo make install  # Linux/macOS
# 或以管理员身份运行: make install  # Windows
```

### 问题 5: 运行时错误 - could not load library

**Linux 解决方法:**
```bash
# 检查 libcurl 是否安装
ldconfig -p | grep curl

# 如果未安装
sudo apt-get install libcurl4
```

**Windows 解决方法:**
- 确保 curl.dll 在系统 PATH 中
- 将 libcurl.dll 复制到 PostgreSQL 的 bin 目录

### 问题 6: UTF-8 编码问题

**解决方法:**
```sql
-- 检查数据库编码
SHOW server_encoding;

-- 如果不是 UTF8，创建新数据库
CREATE DATABASE mydb WITH ENCODING 'UTF8';
```

---

## 卸载

```bash
# Linux/macOS
cd pghttp
sudo make uninstall

# 在数据库中
DROP EXTENSION pghttp;
```

---

## 验证安装

运行完整测试:
```bash
psql -d your_database -f test.sql
```

或运行简单测试:
```bash
psql -d your_database -f test_simple.sql
```

---

## 获取帮助

如果遇到问题:

1. 查看 PostgreSQL 日志
   ```bash
   # Linux
   tail -f /var/log/postgresql/postgresql-15-main.log
   
   # Windows
   # 日志位置: C:\Program Files\PostgreSQL\15\data\log\
   ```

2. 检查扩展版本
   ```sql
   SELECT * FROM pg_available_extensions WHERE name = 'pghttp';
   ```

3. 查看已安装的扩展
   ```sql
   \dx
   ```
