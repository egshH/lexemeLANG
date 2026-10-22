BEGIN;

CREATE SCHEMA IF NOT EXISTS lexeme;
SET search_path TO lexeme, public;

CREATE OR REPLACE FUNCTION set_updated_at()
RETURNS trigger AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;


-- ПОЛЬЗОВАТЕЛИ

CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    username VARCHAR(32) NOT NULL,
    email VARCHAR(254) NOT NULL,
    password_hash TEXT NOT NULL,
    display_name VARCHAR(80),
    bio VARCHAR(500),
    avatar_url TEXT,
    locale VARCHAR(12) DEFAULT 'en',
    timezone VARCHAR(64) DEFAULT 'UTC',
    status VARCHAR(16) DEFAULT 'active'
        CHECK (status IN ('active', 'blocked', 'deleted')),
    email_verified_at TIMESTAMPTZ,
    password_changed_at TIMESTAMPTZ,
    last_login_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now(),
    deleted_at TIMESTAMPTZ,
    CHECK (username ~ '^[A-Za-z0-9_]{3,32}$')
);

CREATE UNIQUE INDEX users_username_unique
ON users (lower(username));

CREATE UNIQUE INDEX users_email_unique
ON users (lower(email));


-- РОЛИ

CREATE TABLE roles (
    id SMALLINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    code VARCHAR(32) NOT NULL UNIQUE,
    description TEXT NOT NULL
);


-- РАЗРЕШЕНИЯ

CREATE TABLE permissions (
    id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    code VARCHAR(80) NOT NULL UNIQUE,
    description TEXT NOT NULL
);


-- РАЗРЕШЕНИЯ РОЛЕЙ

CREATE TABLE role_permissions (
    role_id SMALLINT REFERENCES roles(id) ON DELETE CASCADE,
    permission_id INTEGER REFERENCES permissions(id) ON DELETE CASCADE,
    PRIMARY KEY (role_id, permission_id)
);


-- РОЛИ ПОЛЬЗОВАТЕЛЕЙ

CREATE TABLE user_roles (
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    role_id SMALLINT REFERENCES roles(id) ON DELETE CASCADE,
    granted_at TIMESTAMPTZ DEFAULT now(),
    PRIMARY KEY (user_id, role_id)
);


-- СЕССИИ АВТОРИЗАЦИИ

CREATE TABLE auth_sessions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    refresh_token_hash TEXT NOT NULL UNIQUE,
    user_agent TEXT,
    ip_address INET,
    created_at TIMESTAMPTZ DEFAULT now(),
    last_used_at TIMESTAMPTZ,
    expires_at TIMESTAMPTZ NOT NULL,
    revoked_at TIMESTAMPTZ,
    CHECK (expires_at > created_at)
);


-- ТОКЕНЫ ПОДТВЕРЖДЕНИЯ И ВОССТАНОВЛЕНИЯ

CREATE TABLE auth_tokens (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    purpose VARCHAR(32) NOT NULL
        CHECK (purpose IN (
            'verify_email',
            'reset_password',
            'change_email'
        )),
    token_hash TEXT NOT NULL UNIQUE,
    pending_email VARCHAR(254),
    created_at TIMESTAMPTZ DEFAULT now(),
    expires_at TIMESTAMPTZ NOT NULL,
    consumed_at TIMESTAMPTZ,
    CHECK (expires_at > created_at),
    CHECK (
        purpose <> 'change_email'
        OR pending_email IS NOT NULL
    )
);


-- ПОПЫТКИ ВХОДА

CREATE TABLE login_attempts (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    user_id UUID REFERENCES users(id) ON DELETE SET NULL,
    attempted_email VARCHAR(254),
    ip_address INET,
    user_agent TEXT,
    was_successful BOOLEAN NOT NULL,
    failure_reason VARCHAR(80),
    created_at TIMESTAMPTZ DEFAULT now()
);


-- ЖУРНАЛ ДЕЙСТВИЙ

CREATE TABLE audit_events (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    actor_user_id UUID REFERENCES users(id) ON DELETE SET NULL,
    event_type VARCHAR(100) NOT NULL,
    entity_type VARCHAR(80),
    entity_id TEXT,
    ip_address INET,
    metadata JSONB DEFAULT '{}'::jsonb,
    created_at TIMESTAMPTZ DEFAULT now()
);


-- СТРАНИЦЫ САЙТА

CREATE TABLE pages (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    slug VARCHAR(180) NOT NULL UNIQUE,
    page_type VARCHAR(24) DEFAULT 'page'
        CHECK (page_type IN (
            'page', 'guide', 'reference', 'legal'
        )),
    status VARCHAR(16) DEFAULT 'draft'
        CHECK (status IN (
            'draft', 'published', 'archived'
        )),
    title VARCHAR(200) NOT NULL,
    summary TEXT,
    body_markdown TEXT DEFAULT '',
    seo_title VARCHAR(200),
    seo_description VARCHAR(320),
    nav_order INTEGER,
    show_in_navigation BOOLEAN DEFAULT false,
    author_user_id UUID REFERENCES users(id) ON DELETE SET NULL,
    published_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);


-- ИСТОРИЯ РЕДАКТИРОВАНИЯ СТРАНИЦ

CREATE TABLE page_revisions (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    page_id UUID NOT NULL REFERENCES pages(id) ON DELETE CASCADE,
    version_no INTEGER NOT NULL CHECK (version_no > 0),
    title VARCHAR(200) NOT NULL,
    body_markdown TEXT NOT NULL,
    changed_by UUID REFERENCES users(id) ON DELETE SET NULL,
    change_note TEXT,
    created_at TIMESTAMPTZ DEFAULT now(),
    UNIQUE (page_id, version_no)
);


-- НАВИГАЦИЯ САЙТА

CREATE TABLE navigation_items (
    id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    label VARCHAR(100) NOT NULL,
    page_id UUID REFERENCES pages(id) ON DELETE CASCADE,
    external_url TEXT,
    parent_id INTEGER REFERENCES navigation_items(id) ON DELETE CASCADE,
    sort_order INTEGER DEFAULT 0,
    is_visible BOOLEAN DEFAULT true,
    CHECK (num_nonnulls(page_id, external_url) = 1),
    CHECK (parent_id IS NULL OR id <> parent_id)
);


-- НАСТРОЙКИ САЙТА

CREATE TABLE site_settings (
    key VARCHAR(120) PRIMARY KEY,
    value JSONB NOT NULL,
    description TEXT,
    updated_at TIMESTAMPTZ DEFAULT now()
);


-- ОБЪЯВЛЕНИЯ

CREATE TABLE announcements (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    title VARCHAR(200) NOT NULL,
    body_markdown TEXT NOT NULL,
    severity VARCHAR(16) DEFAULT 'info'
        CHECK (severity IN (
            'info', 'success', 'warning', 'error'
        )),
    is_enabled BOOLEAN DEFAULT false,
    starts_at TIMESTAMPTZ,
    ends_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now(),
    CHECK (
        ends_at IS NULL
        OR starts_at IS NULL
        OR ends_at > starts_at
    )
);


-- ВЕРСИИ ЯЗЫКА LEXEME

CREATE TABLE releases (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    version VARCHAR(64) NOT NULL UNIQUE,
    channel VARCHAR(16) DEFAULT 'stable'
        CHECK (channel IN ('stable', 'beta', 'nightly')),
    title VARCHAR(160),
    release_notes_markdown TEXT DEFAULT '',
    source_url TEXT,
    is_published BOOLEAN DEFAULT false,
    is_featured BOOLEAN DEFAULT false,
    published_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);


-- ФАЙЛЫ ДЛЯ СКАЧИВАНИЯ

CREATE TABLE release_assets (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    release_id UUID NOT NULL REFERENCES releases(id) ON DELETE CASCADE,
    filename VARCHAR(255) NOT NULL,
    platform VARCHAR(24) NOT NULL
        CHECK (platform IN (
            'windows', 'linux', 'macos', 'source', 'other'
        )),
    architecture VARCHAR(16) NOT NULL
        CHECK (architecture IN (
            'x86', 'x64', 'arm64', 'universal', 'any'
        )),
    file_kind VARCHAR(16) NOT NULL
        CHECK (file_kind IN (
            'exe', 'zip', 'tar.gz', 'binary', 'source', 'other'
        )),
    storage_key TEXT NOT NULL UNIQUE,
    external_url TEXT,
    content_type VARCHAR(120) DEFAULT 'application/octet-stream',
    size_bytes BIGINT CHECK (size_bytes >= 0),
    sha256 CHAR(64),
    is_available BOOLEAN DEFAULT false,
    created_at TIMESTAMPTZ DEFAULT now(),
    UNIQUE (release_id, filename),
    CHECK (sha256 IS NULL OR sha256 ~ '^[0-9a-fA-F]{64}$')
);


-- ИСТОРИЯ СКАЧИВАНИЙ

CREATE TABLE download_events (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    asset_id UUID NOT NULL REFERENCES release_assets(id) ON DELETE RESTRICT,
    user_id UUID REFERENCES users(id) ON DELETE SET NULL,
    ip_address INET,
    user_agent TEXT,
    referrer TEXT,
    country_code CHAR(2),
    created_at TIMESTAMPTZ DEFAULT now(),
    CHECK (
        country_code IS NULL
        OR country_code ~ '^[A-Z]{2}$'
    )
);


-- РАЗДЕЛЫ ДОКУМЕНТАЦИИ

CREATE TABLE documentation_sections (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    slug VARCHAR(120) NOT NULL UNIQUE,
    title VARCHAR(160) NOT NULL,
    description TEXT,
    sort_order INTEGER DEFAULT 0,
    is_published BOOLEAN DEFAULT false,
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);


-- СТАТЬИ ДОКУМЕНТАЦИИ

CREATE TABLE documentation_articles (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    section_id UUID NOT NULL
        REFERENCES documentation_sections(id) ON DELETE RESTRICT,
    slug VARCHAR(180) NOT NULL UNIQUE,
    title VARCHAR(200) NOT NULL,
    summary TEXT,
    body_markdown TEXT DEFAULT '',
    sort_order INTEGER DEFAULT 0,
    status VARCHAR(16) DEFAULT 'draft'
        CHECK (status IN (
            'draft', 'published', 'archived'
        )),
    min_lexeme_version VARCHAR(64),
    author_user_id UUID REFERENCES users(id) ON DELETE SET NULL,
    published_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);


-- ПРИМЕРЫ КОДА

CREATE TABLE code_examples (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    slug VARCHAR(160) NOT NULL UNIQUE,
    title VARCHAR(200) NOT NULL,
    description TEXT,
    code TEXT NOT NULL,
    expected_output TEXT,
    difficulty VARCHAR(16) DEFAULT 'beginner'
        CHECK (difficulty IN (
            'beginner', 'intermediate', 'advanced'
        )),
    article_id UUID REFERENCES documentation_articles(id) ON DELETE SET NULL,
    author_user_id UUID REFERENCES users(id) ON DELETE SET NULL,
    status VARCHAR(16) DEFAULT 'draft'
        CHECK (status IN (
            'draft', 'published', 'archived'
        )),
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);


-- ТЕГИ

CREATE TABLE tags (
    id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    slug VARCHAR(64) NOT NULL UNIQUE,
    name VARCHAR(80) NOT NULL UNIQUE
);


-- ТЕГИ СТАТЕЙ

CREATE TABLE article_tags (
    article_id UUID NOT NULL
        REFERENCES documentation_articles(id) ON DELETE CASCADE,
    tag_id INTEGER NOT NULL
        REFERENCES tags(id) ON DELETE CASCADE,
    PRIMARY KEY (article_id, tag_id)
);


-- ТЕГИ ПРИМЕРОВ

CREATE TABLE example_tags (
    example_id UUID NOT NULL
        REFERENCES code_examples(id) ON DELETE CASCADE,
    tag_id INTEGER NOT NULL
        REFERENCES tags(id) ON DELETE CASCADE,
    PRIMARY KEY (example_id, tag_id)
);


-- ЗАКЛАДКИ ПОЛЬЗОВАТЕЛЕЙ

CREATE TABLE user_bookmarks (
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    article_id UUID NOT NULL
        REFERENCES documentation_articles(id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ DEFAULT now(),
    PRIMARY KEY (user_id, article_id)
);


-- ОБРАТНАЯ СВЯЗЬ

CREATE TABLE contact_messages (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id) ON DELETE SET NULL,
    sender_name VARCHAR(120) NOT NULL,
    sender_email VARCHAR(254) NOT NULL,
    subject VARCHAR(200) NOT NULL,
    message TEXT NOT NULL,
    status VARCHAR(16) DEFAULT 'new'
        CHECK (status IN (
            'new', 'in_progress', 'closed', 'spam'
        )),
    internal_note TEXT,
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);


-- ИНДЕКСЫ

CREATE INDEX idx_users_status ON users(status);

CREATE INDEX idx_user_roles_role ON user_roles(role_id);

CREATE INDEX idx_auth_sessions_user
ON auth_sessions(user_id, expires_at DESC);

CREATE INDEX idx_auth_sessions_active
ON auth_sessions(expires_at)
WHERE revoked_at IS NULL;

CREATE INDEX idx_auth_tokens_user
ON auth_tokens(user_id, purpose, expires_at DESC);

CREATE INDEX idx_login_attempts_ip
ON login_attempts(ip_address, created_at DESC);

CREATE INDEX idx_login_attempts_email
ON login_attempts(lower(attempted_email), created_at DESC);

CREATE INDEX idx_audit_actor
ON audit_events(actor_user_id, created_at DESC);

CREATE INDEX idx_audit_type
ON audit_events(event_type, created_at DESC);

CREATE INDEX idx_pages_navigation
ON pages(nav_order)
WHERE status = 'published' AND show_in_navigation = true;

CREATE INDEX idx_navigation_parent
ON navigation_items(parent_id, sort_order);

CREATE INDEX idx_releases_published
ON releases(channel, published_at DESC)
WHERE is_published = true;

CREATE UNIQUE INDEX idx_releases_featured
ON releases(channel)
WHERE is_featured = true;

CREATE INDEX idx_assets_release
ON release_assets(release_id, platform, architecture);

CREATE INDEX idx_download_asset
ON download_events(asset_id, created_at DESC);

CREATE INDEX idx_download_date
ON download_events(created_at DESC);

CREATE INDEX idx_docs_articles_section
ON documentation_articles(section_id, sort_order);

CREATE INDEX idx_docs_articles_public
ON documentation_articles(published_at DESC)
WHERE status = 'published';

CREATE INDEX idx_code_examples_article
ON code_examples(article_id);

CREATE INDEX idx_article_tags_tag
ON article_tags(tag_id);

CREATE INDEX idx_example_tags_tag
ON example_tags(tag_id);

CREATE INDEX idx_bookmarks_article
ON user_bookmarks(article_id);

CREATE INDEX idx_contact_status
ON contact_messages(status, created_at DESC);


-- АВТООБНОВЛЕНИЕ updated_at

DO $$
DECLARE
    table_name TEXT;
BEGIN
    FOR table_name IN
        SELECT c.table_name
        FROM information_schema.columns c
        WHERE c.table_schema = 'lexeme'
          AND c.column_name = 'updated_at'
    LOOP
        EXECUTE format(
            'CREATE TRIGGER %I
             BEFORE UPDATE ON lexeme.%I
             FOR EACH ROW
             EXECUTE FUNCTION lexeme.set_updated_at()',
            'trg_' || table_name || '_updated_at',
            table_name
        );
    END LOOP;
END;
$$;

COMMIT;