# pghttp 快速参考

## 🚀 一行命令

```sql
CREATE EXTENSION pghttp;
SELECT http_get('https://httpbin.org/get');
```

## 📝 三个核心函数

### 1. http_get(url, [headers])

```sql
-- 简单请求
SELECT http_get('https://api.example.com/data');

-- 带 headers
SELECT http_get('https://api.example.com/data', 
    '{"Authorization":"Bearer token"}');
```

### 2. http_post(url, body, [headers])

```sql
-- 发送 JSON
SELECT http_post('https://api.example.com/users',
    '{"name":"张三","age":25}');

-- 带 headers
SELECT http_post('https://api.example.com/data',
    '{"message":"hello"}',
    '{"Authorization":"Bearer token"}');
```

### 3. http_request(method, url, [body], [headers])

```sql
-- 获取详细响应
SELECT * FROM http_request('GET', 'https://httpbin.org/get', NULL, NULL);

-- 返回: status_code | content_type | body
```

## 🔧 重新构建

```powershell
.\build_manual.ps1 -Clean
.\build_manual.ps1 -Install  # 需要管理员权限
```

## 🧪 快速测试

```sql
CREATE EXTENSION pghttp;
SELECT http_post('https://httpbin.org/post', '{"test":"你好"}');
```

## 📖 完整文档

- [中文文档](README_CN.md)
- [安装成功](INSTALL_SUCCESS.md)
- [使用示例](examples.sql)

## ⚠️ IDE 错误？

```
Ctrl + Shift + P → "Reload Window"
```

## 🎯 常用场景

```sql
-- API 数据同步
INSERT INTO table SELECT * FROM json_array_elements(
    http_get('https://api.example.com/data')::json
);

-- Webhook 通知
PERFORM http_post('https://webhook.site/xyz',
    json_build_object('event', 'order_created')::text);
```

---

**就是这么简单！** 🎉
