import Fluent
import FluentSQL

struct CreateAuthMFAChallenges: AsyncMigration {
    func prepare(on database: any Database) async throws {
        guard let sql = database as? any SQLDatabase else { return }
        try await sql.raw("""
            CREATE TABLE IF NOT EXISTS auth.mfa_challenges (
                id uuid PRIMARY KEY,
                factor_id uuid,
                created_at timestamptz,
                verified_at timestamptz,
                ip_address text,
                otp_code text,
                web_authn_session_data jsonb
            );
            """).run()
    }

    func revert(on database: any Database) async throws {
        guard let sql = database as? any SQLDatabase else { return }
        try await sql.raw("DROP TABLE IF EXISTS auth.mfa_challenges;").run()
    }
}
