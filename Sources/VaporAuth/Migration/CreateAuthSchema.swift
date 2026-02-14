import Fluent
import FluentSQL

struct CreateAuthSchema: AsyncMigration {
    func prepare(on database: any Database) async throws {
        guard let sql = database as? any SQLDatabase else { return }
        try await sql.raw("CREATE SCHEMA IF NOT EXISTS auth;").run()
    }

    func revert(on database: any Database) async throws {
        guard let sql = database as? any SQLDatabase else { return }
        try await sql.raw("DROP SCHEMA IF EXISTS auth CASCADE;").run()
    }
}
