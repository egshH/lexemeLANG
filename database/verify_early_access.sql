SELECT table_name
FROM information_schema.tables
WHERE table_schema = 'lexeme'
  AND table_name IN (
    'early_access_requests',
    'early_access_grants',
    'early_access_logs'
  )
ORDER BY table_name;

SELECT column_name, data_type, column_default
FROM information_schema.columns
WHERE table_schema = 'lexeme'
  AND table_name = 'releases'
  AND column_name = 'access_level';

SELECT r.code AS role_code, p.code AS permission_code
FROM lexeme.role_permissions rp
JOIN lexeme.roles r ON r.id = rp.role_id
JOIN lexeme.permissions p ON p.id = rp.permission_id
WHERE p.code = 'early_access.manage';

