-- pghttp 扩展测试脚本
-- 请在数据库客户端中执行此文件

\echo '======================================='
\echo 'pghttp Extension Test'
\echo '======================================='
\echo ''

-- 检查数据库状态
\echo '1. 检查数据库状态...'
SELECT pg_is_in_recovery() AS is_recovering;

\echo ''
\echo '2. 设置客户端编码...'
SET client_encoding = 'UTF8';
SHOW client_encoding;

\echo ''
\echo '3. 重新创建扩展...'
DROP EXTENSION IF EXISTS pghttp CASCADE;
CREATE EXTENSION pghttp;

\echo ''
\echo '4. 检查扩展函数...'
\df http_*

\echo ''
\echo '======================================='
\echo 'Test A: HTTP GET (不使用 HTTPS)'
\echo '======================================='
\echo '测试: http://httpbin.org/get'
\echo ''

SELECT http_get('http://httpbin.org/get') AS response;

\echo ''
\echo '======================================='
\echo 'Test B: HTTPS GET'
\echo '======================================='
\echo '测试: https://httpbin.org/get'
\echo ''

SELECT http_get('https://httpbin.org/get') AS response;

\echo ''
\echo '======================================='
\echo 'Test C: POST Request'
\echo '======================================='
\echo '测试: POST with JSON'
\echo ''

SELECT http_post(
    'https://httpbin.org/post',
    '{"test":"hello","number":123}'
) AS response;

\echo ''
\echo '======================================='
\echo 'Test D: UTF-8 Chinese'
\echo '======================================='
\echo '测试: 中文 UTF-8 支持'
\echo ''

SELECT http_post(
    'https://httpbin.org/post',
    '{"name":"张三","city":"北京"}'
) AS response;

\echo ''
\echo '======================================='
\echo 'Test E: Detailed Response'
\echo '======================================='
\echo '测试: 获取详细响应信息'
\echo ''

SELECT 
    status_code,
    content_type,
    length(body) AS body_length,
    left(body, 200) AS body_preview
FROM http_request(
    'GET',
    'https://httpbin.org/get',
    NULL,
    NULL
);

\echo ''
\echo '======================================='
\echo '✅ 测试完成！'
\echo '======================================='
\echo ''
