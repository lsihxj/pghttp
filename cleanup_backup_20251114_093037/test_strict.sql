-- 测试 STRICT 问题

SET client_min_messages = 'warning';

-- 测试 1: 不传 headers 参数（会是 NULL）
SELECT '=== Test 1: No headers (will be NULL due to default) ===' AS test;
SELECT http_get('http://httpbin.org/get') AS result;

-- 测试 2: 显式传递空字符串而不是 NULL
SELECT '=== Test 2: Empty string headers ===' AS test;
SELECT http_get('http://httpbin.org/get', '') AS result;

-- 测试 3: 传递有效的 headers
SELECT '=== Test 3: With headers ===' AS test;
SELECT http_get('http://httpbin.org/get', '{"User-Agent":"Test"}') AS result;
