# PostgreSQL HTTP Extension - 开发完成 ✅

## 项目概述

一个用于 PostgreSQL 的 HTTP 客户端扩展，支持在 SQL 查询中直接发送 HTTP/HTTPS 请求。

## 核心功能

- ✅ **HTTP GET/POST 请求**
- ✅ **完整的 HTTP 方法支持**（GET, POST, PUT, DELETE等）
- ✅ **HTTPS 支持**（自动处理 SSL/TLS）
- ✅ **UTF-8 编码**（支持中文和其他 Unicode 字符）
- ✅ **详细响应信息**（状态码、Content-Type、响应体）
- ✅ **自定义 Headers**（接口已准备，可扩展）
- ✅ **超时控制**（30秒默认超时）

## 技术架构

### 编译环境
- **编译器**: Microsoft Visual C++ (MSVC) 2022
- **HTTP 库**: WinHTTP (Windows 内置 API)
- **PostgreSQL**: 15.14
- **平台**: Windows x64

### 关键技术决策

#### 1. 编译器选择：MSVC vs MinGW
**问题**: PostgreSQL Windows 版本使用 MSVC 编译，扩展如果用 MinGW 编译会导致：
- 运行时库不兼容
- 函数调用约定冲突
- 内存管理问题
- **结果**: PostgreSQL 服务崩溃

**解决方案**: 使用 MSVC 编译扩展，确保与 PostgreSQL 完全兼容。

#### 2. HTTP 库选择：WinHTTP vs libcurl
**最初计划**: 使用跨平台的 libcurl
**遇到问题**:
- libcurl 依赖多个第三方库（OpenSSL, nghttp2, zstd等）
- DLL 依赖链复杂
- MinGW 编译的 libcurl 与 MSVC PostgreSQL 不兼容

**最终方案**: 使用 Windows 内置的 WinHTTP API
- 无外部依赖
- 完美集成 Windows
- HTTPS 自动支持
- 性能优秀

## 文件结构

```
pghttp/
├── pghttp_full.c              # 完整实现（WinHTTP + MSVC）
├── pghttp_full--1.0.0.sql     # SQL 函数定义
├── pghttp.control             # 扩展控制文件
├── pghttp.def                 # 符号导出定义（MSVC）
├── build_full.ps1             # MSVC 编译脚本
├── examples.sql               # 使用示例
├── USAGE.md                   # 使用指南
└── README_FINAL.md            # 本文件
```

## 安装

### 前提条件
- PostgreSQL 15+ (Windows)
- Visual Studio 2022 (或 Build Tools)
- 管理员权限

### 编译安装

```powershell
# 在管理员 PowerShell 中执行
cd d:\CodeBuddy\pghttp
.\build_full.ps1
```

脚本会自动：
1. 使用 MSVC 编译 C 代码
2. 链接生成 DLL
3. 停止 PostgreSQL 服务
4. 安装 DLL 和 SQL 文件
5. 启动 PostgreSQL 服务

### 加载扩展

```sql
-- 创建扩展
CREATE EXTENSION pghttp;

-- 测试
SELECT http_get('https://jsonplaceholder.typicode.com/posts/1');
```

## API 文档

### http_get(url, headers)
执行 HTTP GET 请求

```sql
-- 基本用法
SELECT http_get('https://api.example.com/data');

-- 返回: text (响应体内容)
```

### http_post(url, body, headers)
执行 HTTP POST 请求

```sql
-- 发送 JSON 数据
SELECT http_post(
    'https://api.example.com/users',
    '{"name":"John","email":"john@example.com"}'
);

-- 返回: text (响应体内容)
```

### http_request(method, url, body, headers)
通用 HTTP 请求，返回详细信息

```sql
-- GET 请求
SELECT * FROM http_request('GET', 'https://api.example.com/data');

-- 返回类型: http_response
--   status_code: integer
--   content_type: text
--   body: text

-- PUT 请求
SELECT * FROM http_request(
    'PUT',
    'https://api.example.com/users/1',
    '{"name":"Updated"}'
);
```

## 使用示例

查看 `examples.sql` 获取完整示例，包括：
- 简单 GET/POST 请求
- JSON 解析
- 状态码检查
- 创建辅助函数
- UTF-8 中文支持

```sql
\i d:/CodeBuddy/pghttp/examples.sql
```

## 开发历程总结

### 主要挑战

1. **编译器兼容性** ⭐⭐⭐⭐⭐
   - 问题: MinGW 编译的扩展导致 PostgreSQL 崩溃
   - 耗时: 最长，多次尝试
   - 解决: 切换到 MSVC

2. **函数符号导出** ⭐⭐⭐
   - 问题: MSVC DLL 符号导出方式与 GCC 不同
   - 解决: 使用 `.def` 文件显式导出

3. **libcurl 依赖问题** ⭐⭐⭐⭐
   - 问题: 复杂的依赖链，DLL 加载失败
   - 解决: 放弃 libcurl，改用 WinHTTP

4. **字符编码** ⭐⭐
   - 问题: Windows WCHAR 与 UTF-8 转换
   - 解决: MultiByteToWideChar/WideCharToMultiByte

5. **SQL 函数定义** ⭐
   - 问题: STRICT 关键字导致 NULL 参数时函数不被调用
   - 解决: 移除 STRICT

### 关键突破点

1. **识别 MSVC 编译需求** - 通过检查 `pg_config.h` 发现 PostgreSQL 使用 MSVC
2. **最小测试方法** - 创建只返回字符串的最小函数，隔离问题
3. **使用 .def 文件** - 正确导出 DLL 符号
4. **WinHTTP API** - 简化依赖，提高稳定性

## 性能特征

- **同步请求**: 阻塞式，适合即时查询
- **超时时间**: 30秒（可修改源码调整）
- **内存管理**: 使用 PostgreSQL palloc/pfree
- **连接复用**: 每次请求创建新连接

## 限制与注意事项

1. **Windows 专用**: 使用 WinHTTP API，仅支持 Windows
2. **同步阻塞**: HTTP 请求会阻塞当前查询
3. **Headers 参数**: 当前接受字符串，未实现 JSON 解析
4. **无连接池**: 每次请求独立连接

## 未来改进方向

- [ ] 实现 JSON headers 解析
- [ ] 添加代理支持
- [ ] 可配置超时时间
- [ ] 支持异步请求（使用后台 worker）
- [ ] 添加连接池
- [ ] 支持流式响应
- [ ] 跨平台支持（Linux 使用 libcurl）
- [ ] 添加请求重试机制
- [ ] 响应大小限制
- [ ] 详细错误信息

## 测试用例

所有测试已通过：
- ✅ 基本函数调用
- ✅ HTTP GET 请求
- ✅ HTTP POST 请求
- ✅ HTTPS 支持
- ✅ 状态码返回
- ✅ Content-Type 解析
- ✅ UTF-8 编码
- ✅ 中文字符支持

## 贡献者

开发时间: 2025-11-13
技术栈: PostgreSQL 15.14 + MSVC 2022 + WinHTTP

## 许可证

开源项目，可自由使用和修改。

---

**🎉 项目完成！扩展已成功运行！**
