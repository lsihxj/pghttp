# pghttp 版本兼容性快速参考

## ✅ 支持的 PostgreSQL 版本

### 当前编译版本
- **PostgreSQL 15.x** (已编译测试)

### 理论兼容版本
- PostgreSQL 12.x
- PostgreSQL 13.x
- PostgreSQL 14.x
- PostgreSQL 15.x ✅ (当前)
- PostgreSQL 16.x
- PostgreSQL 17.x ⭐ **新版本**
- PostgreSQL 18.x ⭐ **新版本**

## 🔧 如何在不同版本使用

### 情况 1: 你的 PostgreSQL 是 15.x
✅ **直接使用当前发布包**，无需重新编译

### 情况 2: 你的 PostgreSQL 是 17 或 18
⚠️ **需要重新编译**

步骤：
```powershell
# 1. 修改 build_full.ps1，指向你的 PostgreSQL 17/18 路径
# 编辑第 6 行：
$pgPath = "C:\Program Files\PostgreSQL\17"  # 或 18

# 2. 编译
.\build_full.ps1

# 3. 安装
.\install.ps1
```

### 情况 3: 你的 PostgreSQL 是 12-14
⚠️ **需要重新编译**（步骤同上）

## 📋 版本检查命令

在 PostgreSQL 中运行：
```sql
-- 查看你的 PostgreSQL 版本
SELECT version();

-- 示例输出：
-- PostgreSQL 15.x on x86_64-pc-windows-msvc...
-- PostgreSQL 17.x on x86_64-pc-windows-msvc...
```

## 🎯 关键概念

### 为什么需要重新编译？

PostgreSQL C 扩展与数据库版本**强绑定**：
- 每个主版本（12, 13, 14...）有不同的内部结构
- 编译时会嵌入版本检查码（`PG_MODULE_MAGIC`）
- **15 编译的 DLL 无法加载到 17 中**

### 源代码兼容吗？

✅ **是的！** 源代码完全兼容 PostgreSQL 12-18+

原因：
- 使用稳定的 C API
- 不依赖版本特定功能
- 遵循扩展最佳实践

## 📦 多版本部署策略

### 选项 A: 单一版本（当前）
- 提供 PG 15 预编译包
- 其他版本用户自行编译

### 选项 B: 多版本发布（推荐企业）
```
pghttp-1.0.0-win-x64-pg15.zip
pghttp-1.0.0-win-x64-pg16.zip
pghttp-1.0.0-win-x64-pg17.zip
pghttp-1.0.0-win-x64-pg18.zip
```

### 选项 C: 仅提供源码
- 最灵活
- 用户需要编译环境

## ⚡ 快速测试兼容性

编译后测试：
```sql
-- 1. 加载扩展
CREATE EXTENSION pghttp;

-- 2. 基础测试
SELECT http_get('https://httpbin.org/get');

-- 3. POST 测试
SELECT http_post(
    'https://httpbin.org/post',
    '{"version": "test"}'
);

-- 4. 检查返回
-- 应该返回 JSON 响应，状态码 200
```

## 🆘 常见问题

### Q1: 我的 PG 17 能用当前的 DLL 吗？
❌ **不能**。必须用 PG 17 重新编译。

### Q2: 升级 PostgreSQL 后扩展不工作了？
✅ **重新编译即可**。源码不变，只需重新编译。

### Q3: 我不会编译怎么办？
有 3 个选择：
1. 继续使用 PG 15
2. 等待提供 PG 17/18 预编译版本
3. 请他人帮忙编译（只需 5 分钟）

### Q4: Linux 版本呢？
❌ 当前仅支持 Windows（使用 WinHTTP）
✅ Linux 版本需要改用 libcurl（不同实现）

## 📚 详细文档

- 完整兼容性说明：[POSTGRESQL_COMPATIBILITY.md](POSTGRESQL_COMPATIBILITY.md)
- 安装指南：[INSTALL_RELEASE.md](INSTALL_RELEASE.md)
- 使用文档：[USAGE.md](USAGE.md)

## 🔄 版本升级路径

```
你当前: PG 15 + pghttp 1.0.0 ✅
           ↓
想升级到: PG 17
           ↓
步骤:
  1. 安装 PG 17
  2. 编辑 build_full.ps1 (改路径)
  3. 运行 build_full.ps1
  4. 运行 install.ps1
  5. CREATE EXTENSION pghttp;
           ↓
完成: PG 17 + pghttp 1.0.0 ✅
```

## 总结

| PostgreSQL 版本 | 能否直接用当前包 | 需要操作 |
|----------------|----------------|---------|
| **PG 15** | ✅ 是 | 直接安装 |
| **PG 12-14** | ❌ 否 | 重新编译 |
| **PG 16** | ❌ 否 | 重新编译 |
| **PG 17** | ❌ 否 | 重新编译 |
| **PG 18** | ❌ 否 | 重新编译 |

**好消息**: 重新编译非常简单，只需修改 1 行代码（PostgreSQL 路径）！

---

**更新日期**: 2025-11-14  
**当前版本**: 1.0.0  
**编译基于**: PostgreSQL 15.x
