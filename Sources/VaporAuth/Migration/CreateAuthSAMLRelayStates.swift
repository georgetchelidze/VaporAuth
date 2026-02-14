import Fluent
import FluentSQL

struct CreateAuthSAMLRelayStates: AsyncMigration {
    func prepare(on database: any Database) async throws {
        guard let sql = database as? any SQLDatabase else { return }
        try await sql.raw("""
            CREATE TABLE IF NOT EXISTS auth.saml_relay_states (
                id uuid PRIMARY KEY,
                sso_provider_id uuid,
                request_id text,
                for_email text,
                redirect_to text,
                created_at timestamptz,
                updated_at timestamptz,
                flow_state_id uuid
            );
            """).run()
    }

    func revert(on database: any Database) async throws {
        guard let sql = database as? any SQLDatabase else { return }
        try await sql.raw("DROP TABLE IF EXISTS auth.saml_relay_states;").run()
    }
}
