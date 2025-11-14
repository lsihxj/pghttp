-- PostgreSQL HTTP Extension - Examples

\echo '================================================'
\echo 'PostgreSQL HTTP Extension - Usage Examples'
\echo '================================================'
\echo ''

-- 确保扩展已加载
CREATE EXTENSION IF NOT EXISTS pghttp;

\echo '=== Example 1: Simple GET Request ==='
SELECT http_get('https://jsonplaceholder.typicode.com/posts/1') AS response;

\echo ''
\echo '=== Example 2: POST JSON Data ==='
SELECT http_post(
    'https://jsonplaceholder.typicode.com/posts',
    '{"title":"Test Post","body":"This is a test","userId":1}'
) AS response;

\echo ''
\echo '=== Example 3: Get Detailed Response ==='
SELECT 
    status_code,
    content_type,
    substring(body, 1, 100) || '...' AS body_preview
FROM http_request('GET', 'https://jsonplaceholder.typicode.com/users/1');

\echo ''
\echo '=== Example 4: Parse JSON Response ==='
SELECT 
    (http_get('https://jsonplaceholder.typicode.com/posts/1')::json)->>'title' AS title,
    (http_get('https://jsonplaceholder.typicode.com/posts/1')::json)->>'body' AS body;

\echo ''
\echo '=== Example 5: Check HTTP Status ==='
SELECT 
    CASE 
        WHEN status_code = 200 THEN 'Success ✓'
        WHEN status_code >= 400 AND status_code < 500 THEN 'Client Error'
        WHEN status_code >= 500 THEN 'Server Error'
        ELSE 'Other'
    END AS status,
    status_code,
    substring(body, 1, 50) AS preview
FROM http_request('GET', 'https://jsonplaceholder.typicode.com/posts/999999');

\echo ''
\echo '=== Example 6: Create a Helper Function ==='
CREATE OR REPLACE FUNCTION get_post(post_id integer)
RETURNS json AS $$
DECLARE
    api_url text;
    response text;
BEGIN
    api_url := 'https://jsonplaceholder.typicode.com/posts/' || post_id;
    response := http_get(api_url);
    RETURN response::json;
END;
$$ LANGUAGE plpgsql;

SELECT get_post(5) AS post_data;

\echo ''
\echo '=== Example 7: UTF-8 Chinese Support ==='
SELECT http_post(
    'https://httpbin.org/anything',
    '{"message":"你好世界","name":"PostgreSQL扩展","emoji":"🚀"}'
) AS response;

\echo ''
\echo '================================================'
\echo 'All examples completed!'
\echo '================================================'
