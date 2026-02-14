import Fluent
import FluentSQL

struct CreateAuthOneTimeTokens: AsyncMigration {
    func prepare(on database: any Database) async throws {
        guard let sql = database as? any SQLDatabase else { return }
        try await sql.raw("""
            CREATE TABLE IF NOT EXISTS auth.one_time_tokens (
                id uuid PRIMARY KEY,
                user_id uuid,
                token_type auth.one_time_token_type,
                token_hash text,
                relates_to text,
                created_at timestamptz,
                updated_at timestamptz
            );
            """).run()
    }

    func revert(on database: any Database) async throws {
        guard let sql = database as? any SQLDatabase else { return }
        try await sql.raw("DROP TABLE IF EXISTS auth.one_time_tokens;").run()
    }
}
