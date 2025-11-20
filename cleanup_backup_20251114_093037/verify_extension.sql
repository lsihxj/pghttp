-- 验证扩展函数定义

-- 检查函数是否存在以及是否为 STRICT
SELECT 
    p.proname AS function_name,
    p.proisstrict AS is_strict,
    pg_get_functiondef(p.oid) AS definition
FROM pg_proc p
JOIN pg_namespace n ON p.pronamespace = n.oid
WHERE n.nspname = 'public' 
  AND p.proname LIKE 'http_%'
ORDER BY p.proname;
