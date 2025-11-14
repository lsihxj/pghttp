-- 快速安装测试脚本
\echo '========================================'
\echo '测试 pghttp 扩展安装'
\echo '========================================'
\echo ''

-- 创建扩展
\echo '创建扩展...'
DROP EXTENSION IF EXISTS pghttp CASCADE;
CREATE EXTENSION pghttp;

-- 验证扩展
\echo ''
\echo '扩展信息:'
\dx pghttp

-- 列出函数
\echo ''
\echo '可用函数:'
\df http_*

\echo ''
\echo '========================================'
\echo '扩展安装成功！'
\echo '========================================'
