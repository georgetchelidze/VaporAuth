import Fluent
import FluentSQL

struct CreateAuthEnums: AsyncMigration {
    func prepare(on database: any Database) async throws {
        guard let sql = database as? any SQLDatabase else { return }

        try await sql.raw("""
            DO $$
            BEGIN
                IF NOT EXISTS (SELECT 1 FROM pg_type t JOIN pg_namespace n ON n.oid = t.typnamespace WHERE n.nspname = 'auth' AND t.typname = 'aal_level') THEN
                    CREATE TYPE auth.aal_level AS ENUM ('aal1', 'aal2', 'aal3');
                END IF;
                IF NOT EXISTS (SELECT 1 FROM pg_type t JOIN pg_namespace n ON n.oid = t.typnamespace WHERE n.nspname = 'auth' AND t.typname = 'code_challenge_method') THEN
                    CREATE TYPE auth.code_challenge_method AS ENUM ('s256', 'plain');
                END IF;
                IF NOT EXISTS (SELECT 1 FROM pg_type t JOIN pg_namespace n ON n.oid = t.typnamespace WHERE n.nspname = 'auth' AND t.typname = 'factor_status') THEN
                    CREATE TYPE auth.factor_status AS ENUM ('unverified', 'verified');
                END IF;
                IF NOT EXISTS (SELECT 1 FROM pg_type t JOIN pg_namespace n ON n.oid = t.typnamespace WHERE n.nspname = 'auth' AND t.typname = 'factor_type') THEN
                    CREATE TYPE auth.factor_type AS ENUM ('totp', 'webauthn', 'phone');
                END IF;
                IF NOT EXISTS (SELECT 1 FROM pg_type t JOIN pg_namespace n ON n.oid = t.typnamespace WHERE n.nspname = 'auth' AND t.typname = 'oauth_authorization_status') THEN
                    CREATE TYPE auth.oauth_authorization_status AS ENUM ('pending', 'approved', 'denied', 'expired');
                END IF;
                IF NOT EXISTS (SELECT 1 FROM pg_type t JOIN pg_namespace n ON n.oid = t.typnamespace WHERE n.nspname = 'auth' AND t.typname = 'oauth_client_type') THEN
                    CREATE TYPE auth.oauth_client_type AS ENUM ('public', 'confidential');
                END IF;
                IF NOT EXISTS (SELECT 1 FROM pg_type t JOIN pg_namespace n ON n.oid = t.typnamespace WHERE n.nspname = 'auth' AND t.typname = 'oauth_registration_type') THEN
                    CREATE TYPE auth.oauth_registration_type AS ENUM ('dynamic', 'manual');
                END IF;
                IF NOT EXISTS (SELECT 1 FROM pg_type t JOIN pg_namespace n ON n.oid = t.typnamespace WHERE n.nspname = 'auth' AND t.typname = 'oauth_response_type') THEN
                    CREATE TYPE auth.oauth_response_type AS ENUM ('code');
                END IF;
                IF NOT EXISTS (SELECT 1 FROM pg_type t JOIN pg_namespace n ON n.oid = t.typnamespace WHERE n.nspname = 'auth' AND t.typname = 'one_time_token_type') THEN
                    CREATE TYPE auth.one_time_token_type AS ENUM (
                        'confirmation_token',
                        'reauthentication_token',
                        'recovery_token',
                        'email_change_token_new',
                        'email_change_token_current',
                        'phone_change_token'
                    );
                END IF;
            END
            $$;
            """).run()
    }

    func revert(on database: any Database) async throws {
        guard let sql = database as? any SQLDatabase else { return }
        try await sql.raw("DROP TYPE IF EXISTS auth.one_time_token_type;").run()
        try await sql.raw("DROP TYPE IF EXISTS auth.oauth_response_type;").run()
        try await sql.raw("DROP TYPE IF EXISTS auth.oauth_registration_type;").run()
        try await sql.raw("DROP TYPE IF EXISTS auth.oauth_client_type;").run()
        try await sql.raw("DROP TYPE IF EXISTS auth.oauth_authorization_status;").run()
        try await sql.raw("DROP TYPE IF EXISTS auth.factor_type;").run()
        try await sql.raw("DROP TYPE IF EXISTS auth.factor_status;").run()
        try await sql.raw("DROP TYPE IF EXISTS auth.code_challenge_method;").run()
        try await sql.raw("DROP TYPE IF EXISTS auth.aal_level;").run()
    }
}
