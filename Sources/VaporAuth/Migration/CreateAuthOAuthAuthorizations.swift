import Fluent
import FluentSQL

struct CreateAuthOAuthAuthorizations: AsyncMigration {
    func prepare(on database: any Database) async throws {
        guard let sql = database as? any SQLDatabase else { return }
        try await sql.raw("""
            CREATE TABLE IF NOT EXISTS auth.oauth_authorizations (
                id uuid PRIMARY KEY,
                authorization_id text,
                client_id uuid,
                user_id uuid,
                redirect_uri text,
                scope text,
                state text,
                resource text,
                code_challenge text,
                code_challenge_method auth.code_challenge_method,
                response_type auth.oauth_response_type,
                status auth.oauth_authorization_status,
                authorization_code text,
                created_at timestamptz,
                expires_at timestamptz,
                approved_at timestamptz
            );
            """).run()
    }

    func revert(on database: any Database) async throws {
        guard let sql = database as? any SQLDatabase else { return }
        try await sql.raw("DROP TABLE IF EXISTS auth.oauth_authorizations;").run()
    }
}
