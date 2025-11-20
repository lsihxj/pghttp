-- Test Content-Type header fix

\echo '========================================='
\echo 'Testing Content-Type Header Fix'
\echo '========================================='
\echo ''

-- Recreate extension
DROP EXTENSION IF EXISTS pghttp CASCADE;
CREATE EXTENSION pghttp;

\echo '=== Test 1: Simple POST with JSON ==='
SELECT http_post(
    'https://httpbin.org/post',
    '{"test":"data","number":123}'
) AS response;

\echo ''
\echo '=== Test 2: Check headers in response ==='
-- httpbin.org echoes back the request details
SELECT 
    status_code,
    body::json->'headers'->>'Content-Type' AS content_type_sent
FROM http_request(
    'POST',
    'https://httpbin.org/post',
    '{"test":"content-type"}'
);

\echo ''
\echo '=== Test 3: POST to your local API (if running) ==='
\echo 'This will test against localhost:3002'
SELECT http_post(
    'http://localhost:3002/api/Crawl',
    '{
  "models": ["STM32F103C8T6"],
  "useCache": true,
  "retryTimes": 3
}'
) AS api_response;

\echo ''
\echo '========================================='
\echo 'Tests completed!'
\echo '========================================='
