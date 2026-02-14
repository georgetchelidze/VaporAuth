import Fluent
import FluentSQL

struct CreateAuthMFAFactors: AsyncMigration {
    func prepare(on database: any Database) async throws {
        guard let sql = database as? any SQLDatabase else { return }
        try await sql.raw("""
            CREATE TABLE IF NOT EXISTS auth.mfa_factors (
                id uuid PRIMARY KEY,
                user_id uuid,
                friendly_name text,
                factor_type auth.factor_type,
                status auth.factor_status,
                created_at timestamptz,
                updated_at timestamptz,
                secret text,
                phone text,
                last_challenged_at timestamptz,
                web_authn_credential jsonb,
                web_authn_aaguid uuid,
                last_webauthn_challenge_data jsonb
            );
            """).run()
    }

    func revert(on database: any Database) async throws {
        guard let sql = database as? any SQLDatabase else { return }
        try await sql.raw("DROP TABLE IF EXISTS auth.mfa_factors;").run()
    }
}
