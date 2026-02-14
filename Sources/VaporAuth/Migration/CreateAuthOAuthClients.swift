import Fluent
import FluentSQL

struct CreateAuthOAuthClients: AsyncMigration {
    func prepare(on database: any Database) async throws {
        guard let sql = database as? any SQLDatabase else { return }
        try await sql.raw("""
            CREATE TABLE IF NOT EXISTS auth.oauth_clients (
                id uuid PRIMARY KEY,
                client_secret_hash text,
                registration_type auth.oauth_registration_type,
                redirect_uris text,
                grant_types text,
                client_name text,
                client_uri text,
                logo_uri text,
                created_at timestamptz,
                updated_at timestamptz,
                deleted_at timestamptz,
                client_type auth.oauth_client_type
            );
            """).run()
    }

    func revert(on database: any Database) async throws {
        guard let sql = database as? any SQLDatabase else { return }
        try await sql.raw("DROP TABLE IF EXISTS auth.oauth_clients;").run()
    }
}
