-- 简单快速测试脚本
-- 用于验证扩展基本功能

-- 1. 创建扩展
CREATE EXTENSION IF NOT EXISTS pghttp;

-- 2. 快速测试 GET
SELECT '测试 GET 请求...' AS test;
SELECT http_get('https://httpbin.org/get') AS result;

-- 3. 快速测试 POST
SELECT '测试 POST 请求...' AS test;
SELECT http_post(
    'https://httpbin.org/post',
    '{"name":"test","value":123}'
) AS result;

-- 4. 测试 UTF-8
SELECT '测试 UTF-8 中文...' AS test;
SELECT http_post(
    'https://httpbin.org/post',
    '{"姓名":"张三","消息":"你好世界"}'
) AS result;

-- 5. 测试详细响应
SELECT '测试详细响应...' AS test;
SELECT * FROM http_request(
    'GET',
    'https://httpbin.org/get',
    NULL,
    NULL
);

SELECT '所有测试完成！' AS result;
