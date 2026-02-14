import Fluent
import FluentSQL

struct CreateAuthAuditLogEntries: AsyncMigration {
    func prepare(on database: any Database) async throws {
        guard let sql = database as? any SQLDatabase else { return }
        try await sql.raw("""
            CREATE TABLE IF NOT EXISTS auth.audit_log_entries (
                id uuid PRIMARY KEY,
                instance_id uuid,
                payload jsonb,
                created_at timestamptz,
                ip_address text
            );
            """).run()
    }

    func revert(on database: any Database) async throws {
        guard let sql = database as? any SQLDatabase else { return }
        try await sql.raw("DROP TABLE IF EXISTS auth.audit_log_entries;").run()
    }
}
