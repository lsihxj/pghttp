-- pghttp 扩展测试脚本
-- 使用方法: psql -d your_database -f test.sql

\echo '======================================'
\echo 'pghttp Extension Test Suite'
\echo 'Testing HTTP GET and POST with UTF-8'
\echo '======================================'
\echo ''

-- 创建扩展（如果已存在则跳过）
\echo '1. Creating extension...'
DROP EXTENSION IF EXISTS pghttp CASCADE;
CREATE EXTENSION pghttp;

\echo 'Extension created successfully!'
\echo ''

-- 测试 1: 简单的 GET 请求
\echo '======================================'
\echo 'Test 1: Simple GET Request'
\echo '======================================'
\echo 'URL: https://httpbin.org/get'
\echo ''

SELECT http_get('https://httpbin.org/get') AS response \gx

\echo ''
\echo 'Test 1 completed!'
\echo ''

-- 测试 2: 带参数的 GET 请求
\echo '======================================'
\echo 'Test 2: GET Request with Query Parameters'
\echo '======================================'
\echo 'URL: https://httpbin.org/get?name=test&value=123'
\echo ''

SELECT http_get('https://httpbin.org/get?name=test&value=123') AS response \gx

\echo ''
\echo 'Test 2 completed!'
\echo ''

-- 测试 3: 带自定义 Headers 的 GET 请求
\echo '======================================'
\echo 'Test 3: GET Request with Custom Headers'
\echo '======================================'
\echo 'Headers: User-Agent, Accept'
\echo ''

SELECT http_get(
    'https://httpbin.org/headers',
    '{"User-Agent":"pghttp/1.0","Accept":"application/json"}'
) AS response \gx

\echo ''
\echo 'Test 3 completed!'
\echo ''

-- 测试 4: 简单的 POST 请求
\echo '======================================'
\echo 'Test 4: Simple POST Request'
\echo '======================================'
\echo 'Sending JSON data...'
\echo ''

SELECT http_post(
    'https://httpbin.org/post',
    '{"name":"John","age":30,"active":true}'
) AS response \gx

\echo ''
\echo 'Test 4 completed!'
\echo ''

-- 测试 5: UTF-8 中文测试
\echo '======================================'
\echo 'Test 5: UTF-8 Chinese Character Test'
\echo '======================================'
\echo 'Sending Chinese characters...'
\echo ''

SELECT http_post(
    'https://httpbin.org/post',
    '{"姓名":"张三","城市":"北京","消息":"你好世界！这是UTF-8测试。"}'
) AS response \gx

\echo ''
\echo 'Test 5 completed!'
\echo ''

-- 测试 6: 带自定义 Headers 的 POST 请求
\echo '======================================'
\echo 'Test 6: POST Request with Custom Headers'
\echo '======================================'
\echo 'Headers: Authorization, Content-Type'
\echo ''

SELECT http_post(
    'https://httpbin.org/post',
    '{"data":"test","number":42}',
    '{"Authorization":"Bearer test-token-123","Content-Type":"application/json; charset=utf-8","X-Custom-Header":"CustomValue"}'
) AS response \gx

\echo ''
\echo 'Test 6 completed!'
\echo ''

-- 测试 7: http_request 函数测试（详细响应）
\echo '======================================'
\echo 'Test 7: Detailed Response with http_request'
\echo '======================================'
\echo 'Getting status code, content type, and body...'
\echo ''

SELECT 
    status_code,
    content_type,
    left(body, 200) || '...' AS body_preview
FROM http_request(
    'GET',
    'https://httpbin.org/get',
    NULL,
    NULL
) \gx

\echo ''
\echo 'Test 7 completed!'
\echo ''

-- 测试 8: POST with http_request
\echo '======================================'
\echo 'Test 8: POST with http_request (Detailed)'
\echo '======================================'
\echo ''

SELECT 
    status_code,
    content_type,
    left(body, 200) || '...' AS body_preview
FROM http_request(
    'POST',
    'https://httpbin.org/post',
    '{"test":"中文数据","value":999}',
    '{"Content-Type":"application/json; charset=utf-8"}'
) \gx

\echo ''
\echo 'Test 8 completed!'
\echo ''

-- 测试 9: 测试不同的 HTTP 状态码
\echo '======================================'
\echo 'Test 9: HTTP Status Code Tests'
\echo '======================================'
\echo ''

\echo 'Test 9a: 200 OK'
SELECT 
    status_code,
    CASE 
        WHEN status_code = 200 THEN 'SUCCESS ✓'
        ELSE 'FAILED ✗'
    END AS result
FROM http_request('GET', 'https://httpbin.org/status/200', NULL, NULL);

\echo ''
\echo 'Test 9b: 404 Not Found'
SELECT 
    status_code,
    CASE 
        WHEN status_code = 404 THEN 'SUCCESS ✓'
        ELSE 'FAILED ✗'
    END AS result
FROM http_request('GET', 'https://httpbin.org/status/404', NULL, NULL);

\echo ''
\echo 'Test 9c: 500 Server Error'
SELECT 
    status_code,
    CASE 
        WHEN status_code = 500 THEN 'SUCCESS ✓'
        ELSE 'FAILED ✗'
    END AS result
FROM http_request('GET', 'https://httpbin.org/status/500', NULL, NULL);

\echo ''
\echo 'Test 9 completed!'
\echo ''

-- 测试 10: JSON 数据测试
\echo '======================================'
\echo 'Test 10: JSON API Test (JSONPlaceholder)'
\echo '======================================'
\echo 'Fetching post #1...'
\echo ''

SELECT 
    response::json->>'userId' AS user_id,
    response::json->>'id' AS post_id,
    response::json->>'title' AS title
FROM (
    SELECT http_get('https://jsonplaceholder.typicode.com/posts/1') AS response
) AS result;

\echo ''
\echo 'Test 10 completed!'
\echo ''

-- 测试 11: 综合测试 - 创建表并从 API 获取数据
\echo '======================================'
\echo 'Test 11: Integration Test - API to Table'
\echo '======================================'
\echo 'Creating test table and fetching data from API...'
\echo ''

-- 创建测试表
DROP TABLE IF EXISTS test_users;
CREATE TABLE test_users (
    id SERIAL PRIMARY KEY,
    user_id INTEGER,
    name TEXT,
    email TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 从 API 获取数据并插入
INSERT INTO test_users (user_id, name, email)
SELECT 
    (user_data->>'id')::INTEGER,
    user_data->>'name',
    user_data->>'email'
FROM json_array_elements(
    http_get('https://jsonplaceholder.typicode.com/users')::json
) AS user_data
LIMIT 5;  -- 只插入前 5 条

-- 显示插入的数据
\echo 'Data inserted into test_users table:'
SELECT * FROM test_users;

\echo ''
\echo 'Test 11 completed!'
\echo ''

-- 测试 12: UTF-8 emoji 测试
\echo '======================================'
\echo 'Test 12: UTF-8 Emoji Test'
\echo '======================================'
\echo 'Sending emojis and special characters...'
\echo ''

SELECT http_post(
    'https://httpbin.org/post',
    '{"message":"Hello 世界 🌍","emoji":"👍 ❤️ 🎉","mixed":"中文English123"}'
) AS response \gx

\echo ''
\echo 'Test 12 completed!'
\echo ''

-- 测试总结
\echo '======================================'
\echo 'TEST SUMMARY'
\echo '======================================'
\echo 'All tests completed!'
\echo ''
\echo 'Tests performed:'
\echo '  ✓ Test 1:  Simple GET request'
\echo '  ✓ Test 2:  GET with query parameters'
\echo '  ✓ Test 3:  GET with custom headers'
\echo '  ✓ Test 4:  Simple POST request'
\echo '  ✓ Test 5:  UTF-8 Chinese characters'
\echo '  ✓ Test 6:  POST with custom headers'
\echo '  ✓ Test 7:  Detailed response (GET)'
\echo '  ✓ Test 8:  Detailed response (POST)'
\echo '  ✓ Test 9:  HTTP status codes (200/404/500)'
\echo '  ✓ Test 10: JSON API integration'
\echo '  ✓ Test 11: API data to table'
\echo '  ✓ Test 12: UTF-8 emoji support'
\echo ''
\echo 'Cleanup (optional): DROP TABLE test_users;'
\echo '======================================'
