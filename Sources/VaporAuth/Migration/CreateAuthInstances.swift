import Fluent
import FluentSQL

struct CreateAuthInstances: AsyncMigration {
    func prepare(on database: any Database) async throws {
        guard let sql = database as? any SQLDatabase else { return }
        try await sql.raw("""
            CREATE TABLE IF NOT EXISTS auth.instances (
                id uuid PRIMARY KEY,
                uuid uuid,
                raw_base_config text,
                created_at timestamptz,
                updated_at timestamptz
            );
            """).run()
    }

    func revert(on database: any Database) async throws {
        guard let sql = database as? any SQLDatabase else { return }
        try await sql.raw("DROP TABLE IF EXISTS auth.instances;").run()
    }
}
