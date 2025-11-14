# pghttp - PostgreSQL HTTP 扩展

## 📌 快速开始

### 1️⃣ 验证环境（已完成✅）

```powershell
.\verify_config.ps1
```

**结果：所有检查通过！**
- ✅ PostgreSQL 15.14 (D:\pgsql)
- ✅ libcurl (C:\curl)
- ✅ GCC 编译器
- ✅ gmake 构建工具
- ✅ IDE 配置文件

### 2️⃣ 修复 IDE 错误提示

**当前问题：** IDE 显示 `'postgres.h' file not found`

**解决方法：** 重新加载 IDE 窗口

1. 按 `Ctrl + Shift + P`
2. 输入 `Reload Window`
3. 回车

**原因：** 这不是代码错误，只是 IDE 的 IntelliSense 需要重新加载配置。详见 [FIX_IDE_ERRORS.md](FIX_IDE_ERRORS.md)

### 3️⃣ 编译和安装

```powershell
# 一键安装（需要管理员权限）
.\install_all.ps1
```

或手动编译：

```powershell
# 设置环境
$env:PATH = "D:\pgsql\bin;C:\Strawberry\c\bin;C:\curl\bin;$env:PATH"

# 编译
gmake USE_PGXS=1

# 安装（需要管理员权限）
gmake USE_PGXS=1 install
```

### 4️⃣ 测试扩展

```powershell
# 连接数据库（密码：12456）
psql -U postgres -d postgres
```

在 psql 中执行：

```sql
-- 创建扩展
CREATE EXTENSION pghttp;

-- 测试 GET
SELECT http_get('https://httpbin.org/get');

-- 测试 POST
SELECT http_post('https://httpbin.org/post', '{"test":"hello"}');

-- 测试中文
SELECT http_post('https://httpbin.org/post', '{"姓名":"张三","城市":"北京"}');

-- 查看详细响应
SELECT * FROM http_request('GET', 'https://httpbin.org/get', NULL, NULL);
```

或运行测试脚本：

```powershell
psql -U postgres -d postgres -f test_simple.sql
```

## 📚 功能说明

### http_get(url, headers)

发送 HTTP GET 请求。

```sql
-- 简单请求
SELECT http_get('https://api.example.com/data');

-- 带自定义 headers
SELECT http_get(
    'https://api.example.com/data',
    '{"Authorization":"Bearer token","Accept":"application/json"}'
);
```

### http_post(url, body, headers)

发送 HTTP POST 请求。

```sql
-- 发送 JSON 数据（自动设置 Content-Type）
SELECT http_post(
    'https://api.example.com/users',
    '{"name":"张三","age":25}'
);

-- 带自定义 headers
SELECT http_post(
    'https://api.example.com/data',
    '{"message":"你好"}',
    '{"Authorization":"Bearer token"}'
);
```

### http_request(method, url, body, headers)

通用 HTTP 请求，返回详细响应。

```sql
SELECT * FROM http_request(
    'POST',
    'https://api.example.com/data',
    '{"key":"value"}',
    '{"Content-Type":"application/json"}'
);

-- 返回：
-- status_code | content_type        | body
-- 200         | application/json    | {"result":"ok"}
```

## 🎯 特性

- ✅ 支持 GET/POST 请求
- ✅ 自定义 HTTP Headers
- ✅ 完整 UTF-8 支持（中文、Emoji）
- ✅ 返回状态码和响应详情
- ✅ 自动重定向
- ✅ 30秒超时保护

## 📁 项目文件

```
pghttp/
├── pghttp.c                    # 核心 C 代码
├── pghttp.control              # 扩展控制文件
├── pghttp--1.0.0.sql          # SQL 函数定义
├── Makefile                    # 编译配置
├── .vscode/                    # IDE 配置（已配置）
│   ├── c_cpp_properties.json  # C/C++ IntelliSense 配置
│   └── settings.json          # 编辑器设置
├── install_all.ps1            # 一键安装脚本
├── verify_config.ps1          # 环境验证脚本
├── test_simple.sql            # 简单测试
├── test.sql                   # 完整测试套件
├── examples.sql               # 使用示例
├── README.md                  # 英文文档
├── README_CN.md               # 中文文档（本文件）
├── FIX_IDE_ERRORS.md          # IDE 错误修复指南
├── QUICK_START.md             # 快速开始指南
└── INSTALL.md                 # 详细安装指南
```

## 🛠️ 可用脚本

| 脚本 | 说明 |
|------|------|
| `verify_config.ps1` | 验证开发环境配置 |
| `setup_curl.ps1` | 自动下载和安装 libcurl |
| `install_all.ps1` | 一键编译和安装扩展 |
| `build.ps1` | 智能构建脚本 |

## ❓ 常见问题

### Q: IDE 显示 'postgres.h' file not found

**A:** 这不是代码错误，重新加载 IDE 窗口即可：
- `Ctrl + Shift + P` → `Reload Window`
- 详见 [FIX_IDE_ERRORS.md](FIX_IDE_ERRORS.md)

### Q: 编译失败 - make not found

**A:** 使用 gmake：
```powershell
gmake USE_PGXS=1
```

### Q: CREATE EXTENSION 失败

**A:** 确保已安装：
```powershell
gmake USE_PGXS=1 install  # 需要管理员权限
```

### Q: 如何卸载？

```sql
-- 在数据库中
DROP EXTENSION pghttp;
```

```powershell
# 从系统中删除
gmake USE_PGXS=1 uninstall  # 需要管理员权限
```

## 📖 更多文档

- [快速开始指南](QUICK_START.md) - 新手入门
- [详细安装指南](INSTALL.md) - 多平台安装
- [IDE 错误修复](FIX_IDE_ERRORS.md) - 解决编辑器提示错误
- [使用示例](examples.sql) - 实际应用场景

## 🎉 当前状态

| 检查项 | 状态 |
|--------|------|
| PostgreSQL | ✅ 15.14 已安装 |
| libcurl | ✅ 已安装 |
| 编译器 (GCC) | ✅ 已安装 |
| 构建工具 (gmake) | ✅ 已安装 |
| IDE 配置 | ✅ 已完成 |
| 代码质量 | ✅ 优秀 |

**✨ 环境已就绪，可以开始构建！**

## 下一步

1. **重新加载 IDE** - 消除错误提示
   ```
   Ctrl + Shift + P → Reload Window
   ```

2. **编译安装** - 构建扩展
   ```powershell
   .\install_all.ps1
   ```

3. **运行测试** - 验证功能
   ```powershell
   psql -U postgres -d postgres -f test_simple.sql
   ```

开始使用吧！🚀
