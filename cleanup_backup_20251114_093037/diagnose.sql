-- 完整诊断脚本
-- 请在数据库客户端中执行并记录所有输出

\echo '======================================='
\echo '完整诊断测试'
\echo '======================================='
\echo ''

-- 显示当前时间（用于在日志中定位）
SELECT 'DIAGNOSTIC START: ' || now()::text AS timestamp;

\echo ''
\echo '=== 1. PostgreSQL 基本信息 ==='
SELECT version();
SELECT current_database();
SELECT current_user;

\echo ''
\echo '=== 2. 日志配置 ==='
SHOW log_destination;
SHOW logging_collector;
SHOW log_directory;
SHOW log_filename;
SHOW log_min_messages;
SHOW client_min_messages;

\echo ''
\echo '=== 3. 设置详细日志 ==='
SET client_min_messages = NOTICE;
SET log_min_messages = NOTICE;
SHOW client_min_messages;

\echo ''
\echo '=== 4. 测试简单查询（应该在日志中可见）==='
SELECT 'TEST: This should appear in logs' AS test_message;

\echo ''
\echo '=== 5. 检查现有扩展 ==='
\dx

\echo ''
\echo '=== 6. 删除旧扩展 ==='
DROP EXTENSION IF EXISTS pghttp CASCADE;

\echo ''
\echo '=== 7. 创建扩展（观察是否有错误）==='
CREATE EXTENSION pghttp;

\echo ''
\echo '=== 8. 验证扩展已创建 ==='
\dx pghttp

\echo ''
\echo '=== 9. 检查扩展函数 ==='
\df http_*

\echo ''
\echo '=== 10. 测试函数类型（不执行请求）==='
SELECT pg_typeof(http_get) FROM pg_proc WHERE proname = 'http_get' LIMIT 1;

\echo ''
\echo '=== 11. 执行 HTTP GET 请求 ==='
\echo '如果此步骤没有任何输出（包括 NOTICE），说明函数没有被调用'
\echo ''

SELECT 'Before HTTP GET: ' || now()::text AS before_request;
SELECT http_get('http://httpbin.org/get') AS http_response;
SELECT 'After HTTP GET: ' || now()::text AS after_request;

\echo ''
\echo '=== 12. 诊断完成 ==='
SELECT 'DIAGNOSTIC END: ' || now()::text AS timestamp;

\echo ''
\echo '======================================='
\echo '请提供以下信息：'
\echo '1. 上面所有步骤的完整输出'
\echo '2. PostgreSQL 日志文件中在 DIAGNOSTIC START 和 END 之间的所有内容'
\echo '3. http_response 的值（NULL 或其他）'
\echo '======================================='
