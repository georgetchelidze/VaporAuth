import Fluent
import FluentSQL

/// Compatibility migration for legacy VaporAuth versions where
/// auth.sessions.ip may have been created as `text`.
struct AlterAuthSessionsIPToInetIfNeeded: AsyncMigration {
    func prepare(on database: any Database) async throws {
        guard let sql = database as? any SQLDatabase else { return }
        try await sql.raw(
            """
            DO $$
            BEGIN
                IF EXISTS (
                    SELECT 1
                    FROM information_schema.columns
                    WHERE table_schema = 'auth'
                      AND table_name = 'sessions'
                      AND column_name = 'ip'
                      AND udt_name = 'text'
                ) THEN
                    ALTER TABLE auth.sessions
                    ALTER COLUMN ip TYPE inet
                    USING CASE
                        WHEN ip IS NULL OR btrim(ip) = '' THEN NULL
                        ELSE ip::inet
                    END;
                END IF;
            END
            $$;
            """
        ).run()
    }

    func revert(on _: any Database) async throws {
        // Irreversible compatibility migration.
    }
}
