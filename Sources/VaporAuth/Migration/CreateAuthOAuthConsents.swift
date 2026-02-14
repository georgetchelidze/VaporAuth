import Fluent
import FluentSQL

struct CreateAuthOAuthConsents: AsyncMigration {
    func prepare(on database: any Database) async throws {
        guard let sql = database as? any SQLDatabase else { return }
        try await sql.raw("""
            CREATE TABLE IF NOT EXISTS auth.oauth_consents (
                id uuid PRIMARY KEY,
                user_id uuid,
                client_id uuid,
                scopes text,
                granted_at timestamptz,
                revoked_at timestamptz
            );
            """).run()
    }

    func revert(on database: any Database) async throws {
        guard let sql = database as? any SQLDatabase else { return }
        try await sql.raw("DROP TABLE IF EXISTS auth.oauth_consents;").run()
    }
}
