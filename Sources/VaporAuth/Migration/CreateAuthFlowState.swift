import Fluent
import FluentSQL

struct CreateAuthFlowState: AsyncMigration {
    func prepare(on database: any Database) async throws {
        guard let sql = database as? any SQLDatabase else { return }
        try await sql.raw("""
            CREATE TABLE IF NOT EXISTS auth.flow_state (
                id uuid PRIMARY KEY,
                user_id uuid,
                auth_code text,
                code_challenge_method auth.code_challenge_method,
                code_challenge text,
                provider_type text,
                provider_access_token text,
                provider_refresh_token text,
                created_at timestamptz,
                updated_at timestamptz,
                authentication_method text,
                auth_code_issued_at timestamptz
            );
            """).run()
    }

    func revert(on database: any Database) async throws {
        guard let sql = database as? any SQLDatabase else { return }
        try await sql.raw("DROP TABLE IF EXISTS auth.flow_state;").run()
    }
}
