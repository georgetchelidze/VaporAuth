import Fluent
import FluentSQL

/// Backfills constraints/indexes expected by secure refresh-token rotation.
struct HardenAuthRefreshTokens: AsyncMigration {
    func prepare(on database: any Database) async throws {
        guard let sql = database as? any SQLDatabase else { return }
        try await sql.raw(
            """
            DO $$
            BEGIN
                IF NOT EXISTS (
                    SELECT 1
                    FROM pg_constraint
                    WHERE conname = 'refresh_tokens_token_unique'
                      AND connamespace = 'auth'::regnamespace
                ) THEN
                    ALTER TABLE auth.refresh_tokens
                    ADD CONSTRAINT refresh_tokens_token_unique UNIQUE (token);
                END IF;

                IF NOT EXISTS (
                    SELECT 1
                    FROM pg_constraint
                    WHERE conname = 'refresh_tokens_session_id_fkey'
                      AND connamespace = 'auth'::regnamespace
                ) THEN
                    ALTER TABLE auth.refresh_tokens
                    ADD CONSTRAINT refresh_tokens_session_id_fkey
                    FOREIGN KEY (session_id) REFERENCES auth.sessions(id) ON DELETE CASCADE;
                END IF;
            END
            $$;

            CREATE INDEX IF NOT EXISTS refresh_tokens_parent_idx
                ON auth.refresh_tokens (parent);
            CREATE INDEX IF NOT EXISTS refresh_tokens_session_id_revoked_idx
                ON auth.refresh_tokens (session_id, revoked);
            CREATE INDEX IF NOT EXISTS refresh_tokens_updated_at_idx
                ON auth.refresh_tokens (updated_at DESC);
            """
        ).run()
    }

    func revert(on _: any Database) async throws {
        // Compatibility migration is intentionally non-reversible.
    }
}
