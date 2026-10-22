BEGIN;

SET search_path TO lexeme, public;

-- РОЛИ
INSERT INTO roles (code, description)
VALUES
('user', 'Regular user'),
('editor', 'Content editor'),
('admin', 'Administrator');


-- РАЗРЕШЕНИЯ
INSERT INTO permissions (code, description)
VALUES
('content.read_drafts', 'Read drafts'),
('content.manage', 'Manage pages and documentation'),
('releases.manage', 'Manage releases'),
('users.manage', 'Manage users'),
('settings.manage', 'Manage settings'),
('contact.manage', 'Manage messages'),
('audit.read', 'Read audit logs');


-- ПРАВА АДМИНИСТРАТОРА И РЕДАКТОРА
INSERT INTO role_permissions (role_id, permission_id)
SELECT r.id, p.id
FROM roles r CROSS JOIN permissions p
WHERE r.code = 'admin'
   OR (
       r.code = 'editor'
       AND p.code IN ('content.read_drafts', 'content.manage')
   );


-- НАСТРОЙКИ САЙТА
INSERT INTO site_settings (key, value)
VALUES
('site_name', '"Lexeme"'),
('site_description', '"Official Lexeme programming language website"'),
('allow_registration', 'true'),
('require_email_verification', 'true'),
('github_url', '"https://github.com/egshH/Lexeme"'),
('downloads_enabled', 'false');


-- СТРАНИЦЫ
INSERT INTO pages (
    slug, title, summary, body_markdown,
    status, nav_order, show_in_navigation, published_at
)
VALUES
(
    'home',
    'Welcome to Lexeme',
    'Lexeme programming language',
    '# Welcome to Lexeme',
    'published', 1, true, now()
),
(
    'download',
    'Download Lexeme',
    'Download Lexeme interpreter',
    '# Download Lexeme',
    'draft', 2, true, NULL
),
(
    'about',
    'About Lexeme',
    'About the programming language',
    '# About Lexeme',
    'published', 3, true, now()
);


-- РАЗДЕЛЫ ДОКУМЕНТАЦИИ
INSERT INTO documentation_sections (
    slug, title, description, sort_order, is_published
)
VALUES
(
    'getting-started',
    'Getting Started',
    'Installation and first steps',
    1, true
),
(
    'syntax',
    'Syntax',
    'Language syntax and features',
    2, true
),
(
    'standard-library',
    'Built-in Functions',
    'Standard functions',
    3, false
);


-- ПЕРВАЯ СТАТЬЯ
INSERT INTO documentation_articles (
    section_id, slug, title, body_markdown,
    status, published_at
)
SELECT
    id,
    'hello-world',
    'Hello World',
    '# Hello World',
    'published',
    now()
FROM documentation_sections
WHERE slug = 'getting-started';


-- ПЕРВЫЙ ПРИМЕР КОДА
INSERT INTO code_examples (
    slug, title, code, expected_output, status
)
VALUES (
    'hello-world',
    'Hello World',
    'print("hello world!")',
    'hello world!',
    'published'
);


-- ТЕГИ
INSERT INTO tags (slug, name)
VALUES
('basics', 'Basics'),
('arrays', 'Arrays'),
('functions', 'Functions'),
('loops', 'Loops');

COMMIT;