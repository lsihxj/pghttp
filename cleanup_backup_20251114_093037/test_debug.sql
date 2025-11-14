-- pghttp Extension Debug Test
-- 调试测试脚本

\echo '======================================='
\echo 'pghttp Extension - Debug Test'
\echo '======================================='
\echo ''

-- 检查扩展是否已安装
\echo 'Checking extension...'
\dx pghttp

\echo ''
\echo 'Checking available functions...'
\df http_*

\echo ''
\echo '======================================='
\echo 'Test 1: Simple GET Request'
\echo '======================================='
\echo 'Testing: httpbin.org/get'
\echo ''

DO $$
DECLARE
    result TEXT;
BEGIN
    BEGIN
        result := http_get('https://httpbin.org/get');
        
        IF result IS NULL THEN
            RAISE NOTICE 'RESULT: NULL (Request failed or returned empty)';
        ELSIF length(result) > 200 THEN
            RAISE NOTICE 'RESULT: % ... (truncated, total length: %)', 
                         left(result, 200), length(result);
        ELSE
            RAISE NOTICE 'RESULT: %', result;
        END IF;
        
    EXCEPTION WHEN OTHERS THEN
        RAISE NOTICE 'ERROR: % - %', SQLSTATE, SQLERRM;
    END;
END $$;

\echo ''
\echo '======================================='
\echo 'Test 2: Simpler URL (no HTTPS)'
\echo '======================================='
\echo 'Testing: http://httpbin.org/get'
\echo ''

DO $$
DECLARE
    result TEXT;
BEGIN
    BEGIN
        result := http_get('http://httpbin.org/get');
        
        IF result IS NULL THEN
            RAISE NOTICE 'RESULT: NULL';
        ELSE
            RAISE NOTICE 'RESULT LENGTH: %', length(result);
            RAISE NOTICE 'FIRST 100 CHARS: %', left(result, 100);
        END IF;
        
    EXCEPTION WHEN OTHERS THEN
        RAISE NOTICE 'ERROR: % - %', SQLSTATE, SQLERRM;
    END;
END $$;

\echo ''
\echo '======================================='
\echo 'Test 3: Check PostgreSQL Logs'
\echo '======================================='
\echo 'If tests return NULL, check PostgreSQL error log at:'
\echo 'D:\pgsql\data\log\postgresql-*.log'
\echo ''

\echo '======================================='
\echo 'Test 4: Database Recovery Status'
\echo '======================================='
SELECT pg_is_in_recovery() AS in_recovery_mode;

\echo ''
\echo '======================================='
\echo 'Test 5: Client Encoding'
\echo '======================================='
SHOW client_encoding;
SHOW server_encoding;

\echo ''
\echo 'Debug test completed.'
\echo ''
