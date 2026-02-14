import Fluent
import FluentSQL

struct CreateAuthSSODomains: AsyncMigration {
    func prepare(on database: any Database) async throws {
        guard let sql = database as? any SQLDatabase else { return }
        try await sql.raw("""
            CREATE TABLE IF NOT EXISTS auth.sso_domains (
                id uuid PRIMARY KEY,
                sso_provider_id uuid,
                domain text,
                created_at timestamptz,
                updated_at timestamptz
            );
            """).run()
    }

    func revert(on database: any Database) async throws {
        guard let sql = database as? any SQLDatabase else { return }
        try await sql.raw("DROP TABLE IF EXISTS auth.sso_domains;").run()
    }
}
