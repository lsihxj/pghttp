# PostgreSQL 版本兼容性说明

## 支持的版本

`pghttp` 扩展兼容 **PostgreSQL 12 及以上版本**，包括最新的 17 和 18 版本。

### 已测试版本
- ✅ PostgreSQL 15 (Windows x64) - 完全测试
- ✅ PostgreSQL 12-14 - 理论兼容
- ✅ PostgreSQL 16-18 - 理论兼容

## 兼容性说明

### 为什么兼容？

1. **使用稳定的 C API**
   - 扩展使用的是 PostgreSQL 核心 API，这些 API 从 PG 12 开始保持稳定
   - 主要使用：`fmgr.h`, `utils/builtins.h`, `funcapi.h`
   - 这些头文件在 PG 12-18 版本中没有破坏性更改

2. **不依赖版本特定功能**
   - 使用 Windows WinHTTP API 而非 PostgreSQL 网络功能
   - 简单的函数定义，无复杂依赖
   - 标准的扩展加载机制

3. **遵循扩展最佳实践**
   - 使用 `PG_MODULE_MAGIC` 版本检查
   - 正确的内存管理（使用 `palloc`/`pfree`）
   - 标准的返回值处理

### 重要提示

**不同 PostgreSQL 版本需要重新编译！**

虽然源代码兼容，但编译的 DLL 文件与 PostgreSQL 版本强绑定：
- PostgreSQL 15 编译的 `pghttp.dll` **只能**用于 PG 15
- PostgreSQL 17 需要用 PG 17 的开发包重新编译
- PostgreSQL 18 需要用 PG 18 的开发包重新编译

## 针对不同版本编译

### 准备工作

1. **下载对应版本的 PostgreSQL**
   - PostgreSQL 12-18 都提供 Windows 安装包
   - 下载地址：https://www.postgresql.org/download/windows/

2. **修改编译脚本**
   
   编辑 `build_full.ps1`，修改第 6 行的路径：
   ```powershell
   # 原始 (PostgreSQL 15)
   $pgPath = "D:\PGSQL"
   
   # PostgreSQL 17 示例
   $pgPath = "D:\PostgreSQL\17"
   
   # PostgreSQL 18 示例
   $pgPath = "C:\Program Files\PostgreSQL\18"
   ```

3. **编译扩展**
   ```powershell
   .\build_full.ps1
   ```

### 验证兼容性

编译后在 PostgreSQL 中测试：

```sql
-- 创建扩展
CREATE EXTENSION pghttp;

-- 测试基本功能
SELECT http_get('https://httpbin.org/get');

-- 测试 POST
SELECT http_post(
    'https://httpbin.org/post',
    '{"test": "data"}'
);

-- 检查版本信息
SELECT version();
```

## API 稳定性参考

### 使用的核心函数（稳定）

| 函数/宏 | 首次引入 | PG 12-18 兼容性 |
|---------|----------|----------------|
| `PG_MODULE_MAGIC` | PG 8.2 | ✅ 完全兼容 |
| `PG_FUNCTION_INFO_V1` | PG 8.0 | ✅ 完全兼容 |
| `text_to_cstring` | PG 8.3 | ✅ 完全兼容 |
| `cstring_to_text` | PG 8.3 | ✅ 完全兼容 |
| `palloc/pfree` | PG 6.0 | ✅ 完全兼容 |
| `elog/ereport` | PG 7.0 | ✅ 完全兼容 |
| `heap_form_tuple` | PG 8.0 | ✅ 完全兼容 |

### 类型系统（稳定）

| 类型 | PG 12-18 兼容性 |
|------|----------------|
| `text` | ✅ 完全兼容 |
| `integer` | ✅ 完全兼容 |
| 自定义复合类型 | ✅ 完全兼容 |

## 已知限制

1. **仅支持 Windows**
   - 使用 WinHTTP API，仅限 Windows 系统
   - Linux/macOS 需要重写（使用 libcurl）

2. **需要 MSVC 编译器**
   - 使用 Visual Studio 2019/2022
   - MinGW/GCC 未测试

3. **编译时版本绑定**
   - 每个 PG 主版本都需要重新编译
   - 不能混用不同版本的 DLL

## 多版本分发建议

如果需要支持多个 PostgreSQL 版本，建议：

### 方案 1：提供源代码
- 用户根据自己的 PG 版本编译
- 最灵活但需要编译环境

### 方案 2：多版本预编译包
创建多个发布版本：
```
pghttp-1.0.0-win-x64-pg15.zip
pghttp-1.0.0-win-x64-pg16.zip
pghttp-1.0.0-win-x64-pg17.zip
pghttp-1.0.0-win-x64-pg18.zip
```

### 方案 3：安装时检测
修改 `install.ps1` 自动检测 PostgreSQL 版本，提示用户下载对应版本。

## 测试矩阵

| PostgreSQL 版本 | Windows 10 | Windows 11 | Windows Server 2022 |
|----------------|-----------|-----------|-------------------|
| PG 12 | 理论支持 | 理论支持 | 理论支持 |
| PG 13 | 理论支持 | 理论支持 | 理论支持 |
| PG 14 | 理论支持 | 理论支持 | 理论支持 |
| **PG 15** | **✅ 已测试** | **✅ 已测试** | 理论支持 |
| PG 16 | 理论支持 | 理论支持 | 理论支持 |
| PG 17 | 理论支持 | 理论支持 | 理论支持 |
| PG 18 | 理论支持 | 理论支持 | 理论支持 |

## 升级建议

### 当前使用 PG 15，想升级到 PG 17/18

1. **安装新版本 PostgreSQL**
2. **重新编译扩展**（针对新版本）
3. **迁移数据库**
4. **重新安装扩展**

```sql
-- 在新的 PG 17/18 数据库中
CREATE EXTENSION pghttp;

-- 测试功能
SELECT http_get('https://httpbin.org/get');
```

## 未来兼容性

PostgreSQL 社区承诺保持 C API 稳定性，因此：
- ✅ PostgreSQL 19+ 预计兼容
- ✅ 只要 PostgreSQL C API 不发生破坏性更改就可以继续使用
- ⚠️ 建议在新版本发布时进行测试验证

## 获取帮助

如果在特定 PostgreSQL 版本上遇到问题：
1. 确认使用的是对应版本编译的 DLL
2. 检查 PostgreSQL 日志文件
3. 提供版本信息：`SELECT version();`
4. 提供错误信息

---

**最后更新**: 2025-11-14  
**当前测试版本**: PostgreSQL 15.x  
**理论支持**: PostgreSQL 12-18+
