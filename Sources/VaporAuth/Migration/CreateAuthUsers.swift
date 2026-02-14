import Fluent
import FluentSQL

struct CreateAuthUsers: AsyncMigration {
    func prepare(on database: any Database) async throws {
        guard let sql = database as? any SQLDatabase else { return }
        try await sql.raw("""
            CREATE TABLE IF NOT EXISTS auth.users (
                id uuid PRIMARY KEY,
                instance_id uuid,
                aud text,
                role text,
                email text,
                encrypted_password text,
                email_confirmed_at timestamptz,
                invited_at timestamptz,
                confirmation_token text,
                confirmation_sent_at timestamptz,
                recovery_token text,
                recovery_sent_at timestamptz,
                email_change_token_new text,
                email_change text,
                email_change_sent_at timestamptz,
                last_sign_in_at timestamptz,
                raw_app_meta_data jsonb,
                raw_user_meta_data jsonb,
                is_super_admin boolean,
                created_at timestamptz,
                updated_at timestamptz,
                phone text,
                phone_confirmed_at timestamptz,
                phone_change text,
                phone_change_token text,
                phone_change_sent_at timestamptz,
                confirmed_at timestamptz,
                email_change_token_current text,
                email_change_confirm_status smallint,
                banned_until timestamptz,
                reauthentication_token text,
                reauthentication_sent_at timestamptz,
                is_sso_user boolean,
                deleted_at timestamptz,
                is_anonymous boolean
            );

            CREATE UNIQUE INDEX IF NOT EXISTS users_email_partial_key
                ON auth.users (email)
                WHERE is_sso_user = false;
            CREATE INDEX IF NOT EXISTS users_instance_id_email_idx
                ON auth.users (instance_id, lower(email));
            CREATE INDEX IF NOT EXISTS users_instance_id_idx
                ON auth.users (instance_id);
            CREATE INDEX IF NOT EXISTS users_is_anonymous_idx
                ON auth.users (is_anonymous);
            """).run()
    }

    func revert(on database: any Database) async throws {
        guard let sql = database as? any SQLDatabase else { return }
        try await sql.raw("DROP TABLE IF EXISTS auth.users;").run()
    }
}
