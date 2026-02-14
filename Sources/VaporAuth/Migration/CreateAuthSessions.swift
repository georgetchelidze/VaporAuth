import Fluent
import FluentSQL

struct CreateAuthSessions: AsyncMigration {
    func prepare(on database: any Database) async throws {
        guard let sql = database as? any SQLDatabase else { return }
        try await sql.raw("""
            CREATE TABLE IF NOT EXISTS auth.sessions (
                id uuid PRIMARY KEY,
                user_id uuid,
                created_at timestamptz,
                updated_at timestamptz,
                factor_id uuid,
                aal auth.aal_level,
                not_after timestamptz,
                refreshed_at timestamptz,
                user_agent text,
                ip inet,
                tag text,
                oauth_client_id uuid,
                refresh_token_hmac_key text,
                refresh_token_counter bigint
            );
            """).run()
    }

    func revert(on database: any Database) async throws {
        guard let sql = database as? any SQLDatabase else { return }
        try await sql.raw("DROP TABLE IF EXISTS auth.sessions;").run()
    }
}
