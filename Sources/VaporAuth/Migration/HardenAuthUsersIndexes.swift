import Fluent
import FluentSQL

/// Aligns auth.users indexes with GoTrue-compatible expectations.
struct HardenAuthUsersIndexes: AsyncMigration {
    func prepare(on database: any Database) async throws {
        guard let sql = database as? any SQLDatabase else { return }
        try await sql.raw("""
            CREATE INDEX IF NOT EXISTS users_instance_id_email_idx
                ON auth.users (instance_id, lower(email));
            """
        ).run()
        try await sql.raw("""
            CREATE INDEX IF NOT EXISTS users_instance_id_idx
                ON auth.users (instance_id);
            """
        ).run()
        try await sql.raw("""
            CREATE INDEX IF NOT EXISTS users_is_anonymous_idx
                ON auth.users (is_anonymous);
            """
        ).run()
        try await sql.raw(
            """
            DO $$
            BEGIN
                IF NOT EXISTS (
                    SELECT 1
                    FROM pg_indexes
                    WHERE schemaname = 'auth'
                      AND tablename = 'users'
                      AND indexname = 'users_email_partial_key'
                ) THEN
                    BEGIN
                        CREATE UNIQUE INDEX users_email_partial_key
                            ON auth.users (email)
                            WHERE is_sso_user = false;
                    EXCEPTION
                        WHEN unique_violation THEN
                            RAISE NOTICE 'Skipping users_email_partial_key because duplicate non-SSO emails exist.';
                    END;
                END IF;
            END
            $$;
            """
        ).run()
    }

    func revert(on _: any Database) async throws {
        // Compatibility migration is intentionally non-reversible.
    }
}
