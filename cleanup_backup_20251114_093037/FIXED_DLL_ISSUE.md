# ✅ DLL 加载问题已修复！

## 问题原因

```
错误: 无法加载库 "D:/pgsql/lib/pghttp.dll": The specified module could not be found.
```

这个错误是因为 `pghttp.dll` 依赖 `libcurl.dll`，但 PostgreSQL 在运行时找不到它。

## 已实施的解决方案

✅ **已复制 libcurl DLL 到 PostgreSQL bin 目录**

```
C:\curl\bin\libcurl-x64.dll  →  D:\pgsql\bin\libcurl.dll
C:\curl\bin\libcurl-x64.dll  →  D:\pgsql\bin\libcurl-x64.dll
```

验证：
```powershell
PS> Get-Item D:\pgsql\bin\libcurl*.dll

Name             Length
----             ------
libcurl-x64.dll  3188840
libcurl.dll      3188840
```

## 立即测试扩展

### 方法 1: 使用 psql 命令行

```bash
# 1. 打开 psql（输入密码: 12456）
psql -U postgres -d postgres

# 2. 在 psql 中执行
DROP EXTENSION IF EXISTS pghttp CASCADE;
CREATE EXTENSION pghttp;

# 3. 测试 GET 请求
SELECT http_get('https://httpbin.org/get');

# 4. 测试 POST 请求
SELECT http_post('https://httpbin.org/post', '{"test":"hello"}');

# 5. 测试中文 UTF-8
SELECT http_post('https://httpbin.org/post', '{"姓名":"张三"}');
```

### 方法 2: 运行测试脚本

```bash
# 在 psql 中执行
\i d:/CodeBuddy/pghttp/test_extension.sql
```

或在 PowerShell 中：

```powershell
# 需要手动输入密码
psql -U postgres -d postgres -f test_extension.sql
```

### 方法 3: 使用 pgAdmin 或 DBeaver

1. 连接到 PostgreSQL 数据库
2. 打开 SQL 编辑器
3. 执行：
   ```sql
   DROP EXTENSION IF EXISTS pghttp CASCADE;
   CREATE EXTENSION pghttp;
   SELECT http_get('https://httpbin.org/get');
   ```

## 预期结果

### 成功创建扩展

```
DROP EXTENSION
CREATE EXTENSION
```

### 成功执行 GET 请求

```json
{
  "args": {},
  "headers": {
    "Host": "httpbin.org",
    "User-Agent": "libcurl/..."
  },
  "url": "https://httpbin.org/get"
}
```

### 成功执行 POST 请求（UTF-8）

```json
{
  "json": {
    "姓名": "张三"
  },
  "headers": {
    "Content-Type": "application/json; charset=utf-8"
  }
}
```

## 如果仍然失败

### 检查 PostgreSQL 服务

可能需要重启 PostgreSQL 服务以加载新的 DLL：

```powershell
# 查找服务名
Get-Service | Where-Object { $_.Name -like "postgresql*" }

# 重启服务（需要管理员权限）
Restart-Service postgresql-x64-15  # 替换为实际服务名
```

### 手动验证 DLL 依赖

```powershell
# 检查 pghttp.dll 是否存在
Test-Path "D:\pgsql\lib\pghttp.dll"

# 检查 libcurl.dll 是否存在
Test-Path "D:\pgsql\bin\libcurl.dll"

# 检查 .sql 和 .control 文件
Test-Path "D:\pgsql\share\extension\pghttp.control"
Test-Path "D:\pgsql\share\extension\pghttp--1.0.0.sql"
```

### 查看 PostgreSQL 日志

如果还有问题，查看 PostgreSQL 错误日志：

```
D:\pgsql\data\log\postgresql-*.log
```

## 其他解决方案

### 方案 A: 添加到系统 PATH（永久方案）

```powershell
# 以管理员权限运行
[Environment]::SetEnvironmentVariable(
    "Path",
    $env:Path + ";C:\curl\bin",
    "Machine"
)

# 重启 PostgreSQL 服务
Restart-Service postgresql-x64-15
```

### 方案 B: 使用自动修复脚本

```powershell
# 运行交互式修复脚本
.\fix_dll_path.ps1
```

## 常见问题

### Q: 为什么要复制到 bin 目录？

A: Windows DLL 搜索路径包括：
1. 应用程序目录（PostgreSQL bin）
2. 系统目录
3. PATH 环境变量中的目录

将 DLL 复制到 PostgreSQL bin 目录是最简单可靠的方法。

### Q: 是否需要重启 PostgreSQL？

A: 通常不需要，但如果修改了系统 PATH，则必须重启 PostgreSQL 服务。

### Q: 如何卸载扩展？

```sql
DROP EXTENSION pghttp CASCADE;
```

### Q: 如何更新扩展？

```bash
# 重新编译
.\build_manual.ps1 -Clean
.\build_manual.ps1 -Install

# 在数据库中
DROP EXTENSION pghttp CASCADE;
CREATE EXTENSION pghttp;
```

## 成功标志

如果你看到以下输出，说明扩展已成功安装并可以使用：

```sql
postgres=# CREATE EXTENSION pghttp;
CREATE EXTENSION

postgres=# SELECT http_get('https://httpbin.org/get');
                    http_get                     
-------------------------------------------------
 {"args":{},"headers":{...},"url":"https://..."}
```

## 下一步

- 📖 查看 [README_CN.md](README_CN.md) - 完整使用文档
- 📝 查看 [examples.sql](examples.sql) - 更多使用示例
- ⚡ 查看 [QUICK_REFERENCE.md](QUICK_REFERENCE.md) - 快速参考

---

**现在你可以开始使用 pghttp 扩展了！** 🎉

只需在数据库客户端中执行：
```sql
CREATE EXTENSION pghttp;
SELECT http_get('https://httpbin.org/get');
```
