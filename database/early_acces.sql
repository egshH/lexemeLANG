BEGIN;

-- 1. Applications for access.
CREATE TABLE IF NOT EXISTS lexeme.early_access_requests (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES lexeme.users(id) ON DELETE CASCADE,
    reason TEXT NOT NULL CHECK (length(btrim(reason)) > 0),
    status VARCHAR(16) NOT NULL DEFAULT 'pending'
        CHECK (status IN ('pending', 'approved', 'rejected')),
    reviewed_by UUID REFERENCES lexeme.users(id) ON DELETE SET NULL,
    reviewed_at TIMESTAMPTZ,
    review_note TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Only one pending application per user; old decisions are retained.
CREATE UNIQUE INDEX IF NOT EXISTS idx_early_access_requests_one_pending
    ON lexeme.early_access_requests (user_id)
    WHERE status = 'pending';

CREATE INDEX IF NOT EXISTS idx_early_access_requests_status_created
    ON lexeme.early_access_requests (status, created_at DESC);

CREATE INDEX IF NOT EXISTS idx_early_access_requests_user_created
    ON lexeme.early_access_requests (user_id, created_at DESC);

-- Reuse the timestamp function that already exists in tables.sql.
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM pg_trigger
        WHERE tgrelid = 'lexeme.early_access_requests'::regclass
          AND tgname = 'trg_early_access_requests_updated_at'
          AND NOT tgisinternal
    ) THEN
        CREATE TRIGGER trg_early_access_requests_updated_at
        BEFORE UPDATE ON lexeme.early_access_requests
        FOR EACH ROW
        EXECUTE FUNCTION lexeme.set_updated_at();
    END IF;
END;
$$;

-- 2. Access grants. Revoked grants remain in the history.
CREATE TABLE IF NOT EXISTS lexeme.early_access_grants (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES lexeme.users(id) ON DELETE CASCADE,
    request_id UUID REFERENCES lexeme.early_access_requests(id) ON DELETE SET NULL,
    granted_by UUID REFERENCES lexeme.users(id) ON DELETE SET NULL,
    granted_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    revoked_by UUID REFERENCES lexeme.users(id) ON DELETE SET NULL,
    revoked_at TIMESTAMPTZ,
    revoke_reason TEXT,
    CHECK (revoked_at IS NULL OR revoked_at >= granted_at),
    CHECK (revoked_by IS NULL OR revoked_at IS NOT NULL)
);

-- An unrevoked grant is the current grant. A new grant can follow a revocation.
CREATE UNIQUE INDEX IF NOT EXISTS idx_early_access_grants_one_active
    ON lexeme.early_access_grants (user_id)
    WHERE revoked_at IS NULL;

CREATE INDEX IF NOT EXISTS idx_early_access_grants_user_granted
    ON lexeme.early_access_grants (user_id, granted_at DESC);

-- 3. Event log. The application must insert an entry for each action.
CREATE TABLE IF NOT EXISTS lexeme.early_access_logs (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    user_id UUID REFERENCES lexeme.users(id) ON DELETE SET NULL,
    actor_user_id UUID REFERENCES lexeme.users(id) ON DELETE SET NULL,
    request_id UUID REFERENCES lexeme.early_access_requests(id) ON DELETE SET NULL,
    grant_id UUID REFERENCES lexeme.early_access_grants(id) ON DELETE SET NULL,
    action VARCHAR(24) NOT NULL
        CHECK (action IN ('requested', 'approved', 'rejected', 'granted', 'revoked')),
    metadata JSONB NOT NULL DEFAULT '{}'::jsonb
        CHECK (jsonb_typeof(metadata) = 'object'),
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_early_access_logs_user_created
    ON lexeme.early_access_logs (user_id, created_at DESC);

CREATE INDEX IF NOT EXISTS idx_early_access_logs_actor_created
    ON lexeme.early_access_logs (actor_user_id, created_at DESC);

-- 4. Release visibility. Channel (stable/beta/nightly) is unchanged.
ALTER TABLE lexeme.releases
    ADD COLUMN IF NOT EXISTS access_level VARCHAR(16) NOT NULL DEFAULT 'public';

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM pg_constraint
        WHERE conrelid = 'lexeme.releases'::regclass
          AND conname = 'releases_access_level_check'
    ) THEN
        ALTER TABLE lexeme.releases
            ADD CONSTRAINT releases_access_level_check
            CHECK (access_level IN ('public', 'early_access', 'admin_only'));
    END IF;
END;
$$;

-- 5. Admin permission (admin role comes from testData.sql / existing data).
INSERT INTO lexeme.permissions (code, description)
VALUES ('early_access.manage', 'Review Early Access requests and manage grants')
ON CONFLICT (code) DO NOTHING;

INSERT INTO lexeme.role_permissions (role_id, permission_id)
SELECT r.id, p.id
FROM lexeme.roles AS r
JOIN lexeme.permissions AS p ON p.code = 'early_access.manage'
WHERE r.code = 'admin'
ON CONFLICT (role_id, permission_id) DO NOTHING;

COMMIT;
