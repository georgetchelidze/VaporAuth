import Fluent
import FluentSQL

struct CreateAuthIdentities: AsyncMigration {
    func prepare(on database: any Database) async throws {
        guard let sql = database as? any SQLDatabase else { return }
        try await sql.raw("""
            CREATE TABLE IF NOT EXISTS auth.identities (
                id uuid PRIMARY KEY,
                provider_id text,
                user_id uuid,
                identity_data jsonb,
                provider text,
                last_sign_in_at timestamptz,
                created_at timestamptz,
                updated_at timestamptz,
                email text
            );
            """).run()
    }

    func revert(on database: any Database) async throws {
        guard let sql = database as? any SQLDatabase else { return }
        try await sql.raw("DROP TABLE IF EXISTS auth.identities;").run()
    }
}
