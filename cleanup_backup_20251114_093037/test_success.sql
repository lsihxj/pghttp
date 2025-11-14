-- 测试成功的 HTTP 请求

-- 测试 1: JSONPlaceholder API (GET)
SELECT '=== Test 1: GET JSON ===' AS test;
SELECT http_get('https://jsonplaceholder.typicode.com/posts/1') AS result;

-- 测试 2: JSONPlaceholder API (POST)
SELECT '=== Test 2: POST JSON ===' AS test;
SELECT http_post(
    'https://jsonplaceholder.typicode.com/posts',
    '{"title":"foo","body":"bar","userId":1}'
) AS result;

-- 测试 3: 详细响应信息
SELECT '=== Test 3: Detailed Response ===' AS test;
SELECT 
    status_code,
    content_type,
    substring(body, 1, 100) || '...' AS body_preview
FROM http_request('GET', 'https://jsonplaceholder.typicode.com/users/1');

-- 测试 4: 中文支持测试
SELECT '=== Test 4: UTF-8 Support ===' AS test;
SELECT http_post(
    'https://httpbin.org/post',
    '{"message":"你好世界","name":"测试"}'
) AS result;
