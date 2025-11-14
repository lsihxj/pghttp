# PostgreSQL HTTP 扩展使用指南

## 安装成功！✅

您的 PostgreSQL HTTP 扩展已成功安装并测试通过。

## 问题解决历程

### 主要问题
- **MinGW vs MSVC 编译器不兼容**：PostgreSQL 使用 MSVC 编译，扩展必须使用相同编译器
- **解决方案**：使用 Visual Studio 2022 MSVC 编译扩展

### 技术栈
- **编译器**: Microsoft Visual C++ (MSVC)
- **HTTP 库**: WinHTTP (Windows 内置，无需外部依赖)
- **PostgreSQL**: 15.14
- **平台**: Windows x64

## 可用函数

### 1. http_get(url, headers)
执行 HTTP GET 请求

```sql
-- 简单 GET 请求
SELECT http_get('https://api.example.com/data');

-- 带自定义 headers（未完全实现，当前版本接受参数但未解析 JSON）
SELECT http_get('https://api.example.com/data', 'User-Agent: MyApp/1.0');
```

### 2. http_post(url, body, headers)
执行 HTTP POST 请求

```sql
-- POST JSON 数据
SELECT http_post(
    'https://api.example.com/users',
    '{"name":"John","email":"john@example.com"}'
);

-- 带自定义 headers
SELECT http_post(
    'https://api.example.com/users',
    '{"name":"John"}',
    'Content-Type: application/json'
);
```

### 3. http_request(method, url, body, headers)
通用 HTTP 请求，返回详细信息

```sql
-- GET 请求并获取详细信息
SELECT * FROM http_request('GET', 'https://api.example.com/data');

-- 返回结果包含三个字段：
-- - status_code (integer): HTTP 状态码
-- - content_type (text): Content-Type 响应头
-- - body (text): 响应体内容

-- PUT 请求
SELECT * FROM http_request(
    'PUT',
    'https://api.example.com/users/1',
    '{"name":"Updated Name"}'
);
```

## 使用示例

### 调用公共 API

```sql
-- JSONPlaceholder API
SELECT http_get('https://jsonplaceholder.typicode.com/posts/1');

-- 创建新文章
SELECT http_post(
    'https://jsonplaceholder.typicode.com/posts',
    '{"title":"My Post","body":"Post content","userId":1}'
);
```

### 在存储过程中使用

```sql
CREATE OR REPLACE FUNCTION fetch_user_data(user_id integer)
RETURNS json AS $$
DECLARE
    api_url text;
    response text;
BEGIN
    api_url := 'https://api.example.com/users/' || user_id;
    response := http_get(api_url);
    RETURN response::json;
END;
$$ LANGUAGE plpgsql;
```

### 处理响应

```sql
-- 解析 JSON 响应
SELECT 
    (http_get('https://jsonplaceholder.typicode.com/posts/1')::json)->>'title' AS title;

-- 检查状态码
SELECT 
    CASE 
        WHEN status_code = 200 THEN '成功'
        WHEN status_code = 404 THEN '未找到'
        ELSE '错误'
    END AS result
FROM http_request('GET', 'https://api.example.com/data');
```

## 功能特性

- ✅ **HTTP/HTTPS 支持**: 自动处理 HTTPS 连接
- ✅ **UTF-8 编码**: 完整支持中文和其他 Unicode 字符
- ✅ **超时设置**: 30 秒连接和接收超时
- ✅ **多种 HTTP 方法**: GET, POST, PUT, DELETE 等
- ✅ **详细响应信息**: 状态码、Content-Type、响应体
- ✅ **日志输出**: NOTICE 级别日志便于调试

## 限制

1. **Headers 参数**: 当前版本接受 headers 参数但未完全实现 JSON 解析，建议传递原始字符串
2. **同步调用**: HTTP 请求是同步的，会阻塞查询直到完成
3. **超时时间**: 固定 30 秒，暂不可配置
4. **Windows 专用**: 使用 WinHTTP API，仅支持 Windows 平台

## 重新编译

如需修改代码并重新编译：

```powershell
# 在管理员 PowerShell 中执行
cd d:\CodeBuddy\pghttp
.\build_full.ps1
```

## 故障排除

### PostgreSQL 服务崩溃
- **原因**: 编译器不兼容（MinGW vs MSVC）
- **解决**: 使用 `build_full.ps1` 和 MSVC 编译

### 函数找不到
- **检查**: 确认 DLL 已安装到 `D:\pgsql\lib\pghttp.dll`
- **检查**: 确认 SQL 文件在 `D:\pgsql\share\extension\pghttp--1.0.0.sql`
- **重启**: PostgreSQL 服务

### HTTP 请求超时
- **增加超时**: 需修改源代码 `pghttp_full.c` 中的 `timeout` 变量

## 源文件

- **pghttp_full.c**: 主要实现（使用 WinHTTP）
- **pghttp_full--1.0.0.sql**: SQL 函数定义
- **pghttp.control**: 扩展控制文件
- **pghttp.def**: 符号导出定义
- **build_full.ps1**: MSVC 编译脚本

## 下一步改进

可能的功能增强：
1. 实现 JSON headers 解析
2. 支持代理设置
3. 可配置超时时间
4. 添加重试机制
5. 支持异步请求
6. 添加请求/响应日志记录

---

**开发完成！** 🎉
