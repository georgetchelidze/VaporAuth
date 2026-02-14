import Fluent
import FluentSQL

struct CreateAuthMFAAMRClaims: AsyncMigration {
    func prepare(on database: any Database) async throws {
        guard let sql = database as? any SQLDatabase else { return }
        try await sql.raw("""
            CREATE TABLE IF NOT EXISTS auth.mfa_amr_claims (
                id uuid PRIMARY KEY,
                session_id uuid,
                created_at timestamptz,
                updated_at timestamptz,
                authentication_method text
            );
            """).run()
    }

    func revert(on database: any Database) async throws {
        guard let sql = database as? any SQLDatabase else { return }
        try await sql.raw("DROP TABLE IF EXISTS auth.mfa_amr_claims;").run()
    }
}
