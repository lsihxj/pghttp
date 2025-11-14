-- 诊断测试脚本
-- 使用 WARNING 级别日志确保在 DBeaver 中也能看到

-- 设置日志级别
SET log_statement = 'all';
SET client_min_messages = 'warning';

-- 显示开始标记
SELECT '=== DIAGNOSTIC TEST START ===' AS marker;

-- 重新安装扩展
DROP EXTENSION IF EXISTS pghttp CASCADE;
CREATE EXTENSION pghttp;

-- 检查扩展是否加载
SELECT '=== Extension loaded ===' AS status;

-- 测试 1: 最简单的 HTTP GET 请求
SELECT '=== Test 1: Simple HTTP GET ===' AS test;
SELECT http_get('http://httpbin.org/get') AS result;

-- 结束标记
SELECT '=== DIAGNOSTIC TEST END ===' AS marker;
