-- pghttp Extension Test Script
-- 测试 pghttp 扩展

\echo '======================================='
\echo 'pghttp Extension - Quick Test'
\echo '======================================='
\echo ''

-- 删除旧扩展（如果存在）
DROP EXTENSION IF EXISTS pghttp CASCADE;

-- 创建扩展
\echo 'Creating extension...'
CREATE EXTENSION pghttp;

\echo '✓ Extension created successfully!'
\echo ''

-- 测试 1: 简单 GET 请求
\echo 'Test 1: Simple GET Request'
\echo '-----------------------------------'
SELECT http_get('https://httpbin.org/get') AS response \gx

-- 测试 2: POST 请求
\echo ''
\echo 'Test 2: POST Request'
\echo '-----------------------------------'
SELECT http_post(
    'https://httpbin.org/post',
    '{"name":"test","value":123}'
) AS response \gx

-- 测试 3: UTF-8 中文支持
\echo ''
\echo 'Test 3: UTF-8 Chinese Support'
\echo '-----------------------------------'
SELECT http_post(
    'https://httpbin.org/post',
    '{"姓名":"张三","城市":"北京"}'
) AS response \gx

-- 测试 4: 详细响应
\echo ''
\echo 'Test 4: Detailed Response'
\echo '-----------------------------------'
SELECT * FROM http_request(
    'GET',
    'https://httpbin.org/status/200',
    NULL,
    NULL
) \gx

\echo ''
\echo '======================================='
\echo '✅ All tests completed!'
\echo '======================================='
\echo ''
\echo 'Available functions:'
\echo '  - http_get(url, headers)'
\echo '  - http_post(url, body, headers)'
\echo '  - http_request(method, url, body, headers)'
\echo ''
