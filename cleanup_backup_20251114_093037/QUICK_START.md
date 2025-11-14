# pghttp 快速开始指南

## Windows 快速安装

### 方法 1: 使用 PowerShell 脚本（推荐）

```powershell
# 1. 以管理员身份打开 PowerShell
# 右键点击 PowerShell -> "以管理员身份运行"

# 2. 进入项目目录
cd d:\CodeBuddy\pghttp

# 3. 允许执行脚本（如果需要）
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope Process

# 4. 运行构建脚本（自动检测 PostgreSQL）
.\build.ps1

# 5. 如果自动检测失败，手动指定路径
# .\build.ps1 -PgPath "C:\你的PostgreSQL路径"

# 6. 安装扩展（需要管理员权限）
.\build.ps1 -Install
```

### 方法 2: 手动查找 PostgreSQL 并编译

如果自动脚本不工作，请按以下步骤操作：

#### 步骤 1: 找到 PostgreSQL 安装路径

在 PowerShell 中运行：
```powershell
# 查找 psql 命令位置
Get-Command psql | Select-Object Source

# 或者搜索 PostgreSQL 目录
Get-ChildItem "C:\Program Files" -Filter "PostgreSQL" -Directory
Get-ChildItem "C:\Program Files (x86)" -Filter "PostgreSQL" -Directory

# 常见路径：
# C:\Program Files\PostgreSQL\15
# C:\Program Files\PostgreSQL\16
# C:\PostgreSQL\15
```

#### 步骤 2: 设置环境变量

```powershell
# 将 YOUR_PG_PATH 替换为你实际的 PostgreSQL 路径
$PG_PATH = "C:\Program Files\PostgreSQL\15"  # 修改这里！

# 添加到 PATH
$env:PATH = "$PG_PATH\bin;$env:PATH"

# 验证
pg_config --version
```

#### 步骤 3: 检查是否有 libcurl

```powershell
# 检查是否存在
Test-Path "C:\curl"

# 如果不存在，下载 libcurl：
# 1. 访问: https://curl.se/windows/
# 2. 下载 curl-x.x.x-win64-mingw.zip
# 3. 解压到 C:\curl
```

#### 步骤 4: 编译和安装

```powershell
cd d:\CodeBuddy\pghttp

# 编译
make

# 安装（需要管理员权限）
make install
```

### 方法 3: 最简化手动编译

如果 make 命令不可用，可以尝试：

```powershell
# 1. 安装 MinGW 或确保有 C 编译器

# 2. 手动编译（需要调整路径）
gcc -I"C:\Program Files\PostgreSQL\15\include" `
    -I"C:\curl\include" `
    -shared -o pghttp.dll pghttp.c `
    -L"C:\Program Files\PostgreSQL\15\lib" `
    -L"C:\curl\lib" `
    -lpostgres -lcurl

# 3. 复制文件到 PostgreSQL
copy pghttp.dll "C:\Program Files\PostgreSQL\15\lib\"
copy pghttp.control "C:\Program Files\PostgreSQL\15\share\extension\"
copy pghttp--1.0.0.sql "C:\Program Files\PostgreSQL\15\share\extension\"
```

## 在数据库中启用和测试

### 连接到 PostgreSQL

```powershell
# 使用你的用户名和密码
psql -U postgres -d postgres

# 输入密码: 12456
```

### 创建扩展

```sql
-- 在 psql 中执行
CREATE EXTENSION pghttp;

-- 验证安装
\dx pghttp
```

### 快速测试

```sql
-- 测试 1: GET 请求
SELECT http_get('https://httpbin.org/get');

-- 测试 2: POST 请求
SELECT http_post(
    'https://httpbin.org/post',
    '{"name":"test","value":123}'
);

-- 测试 3: UTF-8 中文
SELECT http_post(
    'https://httpbin.org/post',
    '{"姓名":"张三","消息":"你好"}'
);

-- 测试 4: 详细响应
SELECT * FROM http_request(
    'GET',
    'https://httpbin.org/get',
    NULL,
    NULL
);
```

### 运行完整测试

```sql
-- 在 psql 中
\i d:/CodeBuddy/pghttp/test_simple.sql
```

或在 PowerShell 中：
```powershell
psql -U postgres -d postgres -f d:\CodeBuddy\pghttp\test_simple.sql
```

## 常见问题

### 问题 1: "psql 不是内部或外部命令"

**解决方法：** PostgreSQL bin 目录不在 PATH 中

```powershell
# 临时添加（本次会话有效）
$env:PATH = "C:\Program Files\PostgreSQL\15\bin;$env:PATH"

# 永久添加：
# 系统属性 -> 环境变量 -> Path -> 添加：
# C:\Program Files\PostgreSQL\15\bin
```

### 问题 2: "make 不是内部或外部命令"

**解决方法：** 需要安装构建工具

选项 A - 使用 PostgreSQL 自带的 make：
```powershell
# 查找 PostgreSQL 安装目录下的 make
Get-ChildItem "C:\Program Files\PostgreSQL" -Recurse -Filter "make.exe"

# 添加到 PATH
$env:PATH = "C:\Program Files\PostgreSQL\15\bin;$env:PATH"
```

选项 B - 安装 MinGW：
1. 下载：https://sourceforge.net/projects/mingw-w64/
2. 安装后添加到 PATH

选项 C - 安装 Visual Studio Build Tools

### 问题 3: 找不到 curl/curl.h

**解决方法：** 安装 libcurl

1. 访问：https://curl.se/windows/
2. 下载：curl-8.x.x-win64-mingw.zip
3. 解压到 C:\curl
4. 目录结构应该是：
   ```
   C:\curl\
   ├── bin\
   ├── include\
   │   └── curl\
   │       └── curl.h
   └── lib\
   ```

### 问题 4: 权限拒绝

**解决方法：** 以管理员身份运行 PowerShell

右键点击 PowerShell 图标 -> "以管理员身份运行"

### 问题 5: CREATE EXTENSION 失败

```sql
-- 检查扩展文件是否存在
-- 在 psql 中运行：
SHOW data_directory;

-- 然后在 PowerShell 中检查：
Test-Path "C:\Program Files\PostgreSQL\15\share\extension\pghttp.control"
Test-Path "C:\Program Files\PostgreSQL\15\lib\pghttp.dll"
```

如果文件不存在，需要重新运行 `make install`

## 完整示例（一步一步）

假设你的 PostgreSQL 在 `C:\Program Files\PostgreSQL\15`：

```powershell
# 1. 打开管理员 PowerShell
cd d:\CodeBuddy\pghttp

# 2. 设置环境
$env:PATH = "C:\Program Files\PostgreSQL\15\bin;$env:PATH"

# 3. 验证 PostgreSQL
pg_config --version

# 4. 编译（如果有 libcurl）
make

# 5. 安装
make install

# 6. 测试
psql -U postgres -d postgres

# 7. 在 psql 中：
# CREATE EXTENSION pghttp;
# SELECT http_get('https://httpbin.org/get');
```

## 需要帮助？

如果仍然遇到问题，请提供：
1. PostgreSQL 安装路径
2. PostgreSQL 版本 (`pg_config --version`)
3. 错误信息的完整输出
4. 是否有 C 编译器（gcc/Visual Studio）
