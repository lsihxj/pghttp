-- pghttp Extension Debug Test
-- 带调试日志的测试脚本

\echo '======================================='
\echo 'pghttp Debug Test'
\echo '======================================='
\echo ''

-- 启用详细消息显示
SET client_min_messages = NOTICE;

\echo '1. 重新创建扩展...'
DROP EXTENSION IF EXISTS pghttp CASCADE;
CREATE EXTENSION pghttp;

\echo ''
\echo '2. 设置编码...'
SET client_encoding = 'UTF8';

\echo ''
\echo '======================================='
\echo 'Test: HTTP GET Request'
\echo '======================================='
\echo 'URL: http://httpbin.org/get'
\echo '期待看到调试消息：'
\echo '  - pghttp: Starting HTTP request...'
\echo '  - pghttp: Initializing CURL...'
\echo '  - pghttp: Executing HTTP request...'
\echo '  - pghttp: Request successful...'
\echo ''

SELECT http_get('http://httpbin.org/get') AS response;

\echo ''
\echo '======================================='
\echo 'Debug Test Complete'
\echo '======================================='
\echo ''
\echo '如果没有看到调试消息，说明函数根本没有执行。'
\echo '如果看到错误消息，会显示具体的失败原因。'
\echo ''
