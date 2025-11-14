# pghttp PostgreSQL 扩展 - 安装指南 (Windows)

> **⚠️ 平台说明**: 本指南适用于 **Windows 平台**。当前版本 (v1.0.0) 仅支持 Windows。Linux/macOS 支持计划中，详见 [PLATFORM_SUPPORT.md](PLATFORM_SUPPORT.md)

## 版本信息
- **版本**: 1.0.0
- **平台**: Windows only (使用 WinHTTP)
- **PostgreSQL**: 12+ (测试于 15.x，理论支持 12-18+)
- **编译器**: MSVC 2022
- **依赖**: 无 (使用 Windows 原生 WinHTTP)

## 系统要求

### 必需条件
- **操作系统**: Windows 10/11 或 Windows Server 2016+
- **PostgreSQL**: 12 或更高版本 (Windows x64 版本)
- **权限**: 管理员权限

### 平台兼容性
✅ **仅支持 Windows** (当前版本)
❌ Linux/macOS 暂不支持（计划在 v1.1.0 提供）

### 版本兼容性
✅ **支持 PostgreSQL 12-18+** (包括最新的 17 和 18)

⚠️ **重要**: 
- 此扩展使用 MSVC 编译，仅兼容 Windows 平台的 PostgreSQL
- **不同 PostgreSQL 主版本需要重新编译**（例如从 PG 15 升级到 PG 17 需要用 PG 17 开发包重新编译）
- 当前发布包基于 PostgreSQL 15.x 编译，如需其他版本请查看 [版本兼容性说明](POSTGRESQL_COMPATIBILITY.md)

## 快速安装（推荐）

### 方法一：使用自动安装脚本

1. **解压发布包** 到任意目录（如 `C:\pghttp`）

2. **以管理员身份运行 PowerShell**，进入解压目录：
   ```powershell
   cd C:\pghttp
   ```

3. **运行安装脚本**：
   ```powershell
   .\install.ps1
   ```

4. 脚本会：
   - 自动检测 PostgreSQL 安装路径
   - 停止 PostgreSQL 服务
   - 复制扩展文件
   - 启动 PostgreSQL 服务

5. **在 psql 中创建扩展**：
   ```sql
   CREATE EXTENSION pghttp;
   ```

6. **测试**：
   ```sql
   SELECT http_get('https://jsonplaceholder.typicode.com/posts/1');
   ```

### 方法二：手动安装

如果自动脚本无法识别你的 PostgreSQL 安装路径，可以手动安装：

1. **找到 PostgreSQL 安装目录**（通常是 `C:\Program Files\PostgreSQL\15` 或 `D:\pgsql`）

2. **停止 PostgreSQL 服务**：
   ```powershell
   Stop-Service -Name postgresql-x64-15
   ```
   
   *注意：服务名可能不同，请在"服务"管理器中确认*

3. **复制文件**：
   - 复制 `pghttp.dll` 到 `[PostgreSQL]\lib\`
   - 复制 `pghttp.control` 到 `[PostgreSQL]\share\extension\`
   - 复制 `pghttp--1.0.0.sql` 到 `[PostgreSQL]\share\extension\`

4. **启动 PostgreSQL 服务**：
   ```powershell
   Start-Service -Name postgresql-x64-15
   ```

5. **在数据库中创建扩展**：
   ```sql
   CREATE EXTENSION pghttp;
   ```

## 验证安装

连接到 PostgreSQL 数据库后，执行以下命令验证：

```sql
-- 查看扩展是否安装
\dx pghttp

-- 测试 GET 请求
SELECT http_get('https://httpbin.org/get');

-- 测试 POST 请求
SELECT http_post('https://httpbin.org/post', '{"name":"test"}');

-- 测试详细响应
SELECT * FROM http_request('GET', 'https://httpbin.org/status/200');
```

如果所有命令都正常返回结果，说明安装成功！

## 使用示例

### 基本 GET 请求
```sql
-- 获取 JSON 数据
SELECT http_get('https://api.github.com/users/octocat');

-- 解析 JSON
SELECT 
    data->>'login' AS username,
    data->>'name' AS fullname
FROM (
    SELECT http_get('https://api.github.com/users/octocat')::jsonb AS data
) t;
```

### POST 请求
```sql
-- 发送 JSON 数据
SELECT http_post(
    'https://jsonplaceholder.typicode.com/posts',
    '{"title":"foo","body":"bar","userId":1}'
);
```

### 详细响应（包含状态码）
```sql
-- 检查 HTTP 状态码
SELECT 
    status_code,
    content_type,
    left(body, 100) AS preview
FROM http_request('GET', 'https://httpbin.org/status/404');
```

### 更多示例
查看 `examples.sql` 文件获取完整示例集。

## 卸载

如需卸载扩展：

```sql
-- 在数据库中删除扩展
DROP EXTENSION IF EXISTS pghttp CASCADE;
```

完全移除文件：
1. 停止 PostgreSQL 服务
2. 删除 `[PostgreSQL]\lib\pghttp.dll`
3. 删除 `[PostgreSQL]\share\extension\pghttp.control`
4. 删除 `[PostgreSQL]\share\extension\pghttp--1.0.0.sql`
5. 启动 PostgreSQL 服务

## 故障排除

### 问题 1: "找不到 pghttp.dll"
**解决**：确保 `pghttp.dll` 已复制到 `[PostgreSQL]\lib\` 目录

### 问题 2: "无法加载扩展"
**解决**：
- 确认 PostgreSQL 版本为 15.x
- 确认是 Windows x64 版本
- 以管理员身份重启 PostgreSQL 服务

### 问题 3: "函数返回 NULL"
**解决**：检查 URL 是否正确，网络是否可访问

### 问题 4: 函数执行超时
**解决**：当前超时设置为 30 秒，如需修改需要重新编译源码

### 问题 5: "服务名称无效"
**解决**：在"服务"管理器中查找 PostgreSQL 服务的实际名称，可能是：
- `postgresql-x64-15`
- `PostgreSQL 15`
- `postgresql15`

使用 `Get-Service *postgres*` 命令查看服务名。

## 技术支持

如遇到问题，请查看：
- `USAGE.md` - 详细使用文档
- `examples.sql` - 完整示例代码
- `README.md` - 项目说明

## 功能特性

✅ HTTP/HTTPS GET 请求  
✅ HTTP/HTTPS POST 请求  
✅ 支持所有 HTTP 方法 (PUT, DELETE, PATCH 等)  
✅ 返回详细响应 (状态码, Content-Type, 响应体)  
✅ UTF-8 编码支持  
✅ 30 秒超时保护  
✅ 无外部依赖  

## 限制

⚠️ 仅支持 Windows 平台  
⚠️ 同步阻塞式请求（会阻塞 SQL 查询）  
⚠️ 每次请求独立连接（无连接池）  

## 许可证

MIT License - 可自由使用、修改和分发

---

**安装成功后，尽情使用 PostgreSQL 的 HTTP 功能吧！** 🎉
