import Fluent
import FluentSQL

struct CreateAuthSSOProviders: AsyncMigration {
    func prepare(on database: any Database) async throws {
        guard let sql = database as? any SQLDatabase else { return }
        try await sql.raw("""
            CREATE TABLE IF NOT EXISTS auth.sso_providers (
                id uuid PRIMARY KEY,
                resource_id text,
                created_at timestamptz,
                updated_at timestamptz,
                disabled boolean
            );
            """).run()
    }

    func revert(on database: any Database) async throws {
        guard let sql = database as? any SQLDatabase else { return }
        try await sql.raw("DROP TABLE IF EXISTS auth.sso_providers;").run()
    }
}
