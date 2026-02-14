import Fluent
import FluentSQL

struct CreateAuthSAMLProviders: AsyncMigration {
    func prepare(on database: any Database) async throws {
        guard let sql = database as? any SQLDatabase else { return }
        try await sql.raw("""
            CREATE TABLE IF NOT EXISTS auth.saml_providers (
                id uuid PRIMARY KEY,
                sso_provider_id uuid,
                entity_id text,
                metadata_xml text,
                metadata_url text,
                attribute_mapping jsonb,
                created_at timestamptz,
                updated_at timestamptz,
                name_id_format text
            );
            """).run()
    }

    func revert(on database: any Database) async throws {
        guard let sql = database as? any SQLDatabase else { return }
        try await sql.raw("DROP TABLE IF EXISTS auth.saml_providers;").run()
    }
}
