import Fluent
import FluentSQL

/// Adds additive constraints/indexes/FKs to move closer to GoTrue's hardened schema.
struct HardenAuthSchemaSecurity: AsyncMigration {
    func prepare(on database: any Database) async throws {
        guard let sql = database as? any SQLDatabase else { return }

        let normalizationStatements = [
            "UPDATE auth.users SET is_sso_user = false WHERE is_sso_user IS NULL;",
            "UPDATE auth.users SET is_anonymous = false WHERE is_anonymous IS NULL;",
            "UPDATE auth.users SET email_change_confirm_status = 0 WHERE email_change_confirm_status IS NULL;",
            "ALTER TABLE auth.users ALTER COLUMN is_sso_user SET DEFAULT false;",
            "ALTER TABLE auth.users ALTER COLUMN is_anonymous SET DEFAULT false;",
            "ALTER TABLE auth.users ALTER COLUMN email_change_confirm_status SET DEFAULT 0;",
            "ALTER TABLE auth.users ALTER COLUMN is_sso_user SET NOT NULL;",
            "ALTER TABLE auth.users ALTER COLUMN is_anonymous SET NOT NULL;"
        ]

        for statement in normalizationStatements {
            try await sql.raw("\(unsafeRaw: statement)").run()
        }

        try await sql.raw(
            """
            DO $$
            BEGIN
                IF NOT EXISTS (
                    SELECT 1
                    FROM pg_constraint
                    WHERE conname = 'users_email_change_confirm_status_check'
                      AND connamespace = 'auth'::regnamespace
                ) THEN
                    ALTER TABLE auth.users
                        ADD CONSTRAINT users_email_change_confirm_status_check
                        CHECK (((email_change_confirm_status >= 0) AND (email_change_confirm_status <= 2))) NOT VALID;
                END IF;

                IF NOT EXISTS (
                    SELECT 1
                    FROM pg_constraint
                    WHERE conname = 'users_phone_key'
                      AND connamespace = 'auth'::regnamespace
                ) THEN
                    BEGIN
                        ALTER TABLE auth.users
                            ADD CONSTRAINT users_phone_key UNIQUE (phone);
                    EXCEPTION
                        WHEN unique_violation THEN
                            RAISE NOTICE 'Skipping users_phone_key because duplicate phone values exist.';
                    END;
                END IF;

                IF NOT EXISTS (
                    SELECT 1
                    FROM pg_constraint
                    WHERE conname = 'one_time_tokens_token_hash_check'
                      AND connamespace = 'auth'::regnamespace
                ) THEN
                    ALTER TABLE auth.one_time_tokens
                        ADD CONSTRAINT one_time_tokens_token_hash_check
                        CHECK ((char_length(token_hash) > 0)) NOT VALID;
                END IF;

                IF NOT EXISTS (
                    SELECT 1
                    FROM pg_constraint
                    WHERE conname = 'identities_provider_id_provider_unique'
                      AND connamespace = 'auth'::regnamespace
                ) THEN
                    BEGIN
                        ALTER TABLE auth.identities
                            ADD CONSTRAINT identities_provider_id_provider_unique
                            UNIQUE (provider_id, provider);
                    EXCEPTION
                        WHEN unique_violation THEN
                            RAISE NOTICE 'Skipping identities_provider_id_provider_unique because duplicate identities exist.';
                    END;
                END IF;

                IF NOT EXISTS (
                    SELECT 1
                    FROM pg_constraint
                    WHERE conname = 'mfa_amr_claims_session_id_authentication_method_pkey'
                      AND connamespace = 'auth'::regnamespace
                ) THEN
                    BEGIN
                        ALTER TABLE auth.mfa_amr_claims
                            ADD CONSTRAINT mfa_amr_claims_session_id_authentication_method_pkey
                            UNIQUE (session_id, authentication_method);
                    EXCEPTION
                        WHEN unique_violation THEN
                            RAISE NOTICE 'Skipping mfa_amr_claims_session_id_authentication_method_pkey because duplicate claims exist.';
                    END;
                END IF;

                IF NOT EXISTS (
                    SELECT 1
                    FROM pg_constraint
                    WHERE conname = 'oauth_authorizations_authorization_code_key'
                      AND connamespace = 'auth'::regnamespace
                ) THEN
                    BEGIN
                        ALTER TABLE auth.oauth_authorizations
                            ADD CONSTRAINT oauth_authorizations_authorization_code_key UNIQUE (authorization_code);
                    EXCEPTION
                        WHEN unique_violation THEN
                            RAISE NOTICE 'Skipping oauth_authorizations_authorization_code_key because duplicate codes exist.';
                    END;
                END IF;

                IF NOT EXISTS (
                    SELECT 1
                    FROM pg_constraint
                    WHERE conname = 'oauth_authorizations_authorization_id_key'
                      AND connamespace = 'auth'::regnamespace
                ) THEN
                    BEGIN
                        ALTER TABLE auth.oauth_authorizations
                            ADD CONSTRAINT oauth_authorizations_authorization_id_key UNIQUE (authorization_id);
                    EXCEPTION
                        WHEN unique_violation THEN
                            RAISE NOTICE 'Skipping oauth_authorizations_authorization_id_key because duplicate authorization IDs exist.';
                    END;
                END IF;

                IF NOT EXISTS (
                    SELECT 1
                    FROM pg_constraint
                    WHERE conname = 'oauth_consents_user_client_unique'
                      AND connamespace = 'auth'::regnamespace
                ) THEN
                    BEGIN
                        ALTER TABLE auth.oauth_consents
                            ADD CONSTRAINT oauth_consents_user_client_unique UNIQUE (user_id, client_id);
                    EXCEPTION
                        WHEN unique_violation THEN
                            RAISE NOTICE 'Skipping oauth_consents_user_client_unique because duplicate consent rows exist.';
                    END;
                END IF;

                IF NOT EXISTS (
                    SELECT 1
                    FROM pg_constraint
                    WHERE conname = 'saml_providers_entity_id_key'
                      AND connamespace = 'auth'::regnamespace
                ) THEN
                    BEGIN
                        ALTER TABLE auth.saml_providers
                            ADD CONSTRAINT saml_providers_entity_id_key UNIQUE (entity_id);
                    EXCEPTION
                        WHEN unique_violation THEN
                            RAISE NOTICE 'Skipping saml_providers_entity_id_key because duplicate entity IDs exist.';
                    END;
                END IF;

                IF NOT EXISTS (
                    SELECT 1
                    FROM pg_constraint
                    WHERE conname = 'identities_user_id_fkey'
                      AND connamespace = 'auth'::regnamespace
                ) THEN
                    ALTER TABLE auth.identities
                        ADD CONSTRAINT identities_user_id_fkey
                        FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE NOT VALID;
                END IF;

                IF NOT EXISTS (
                    SELECT 1
                    FROM pg_constraint
                    WHERE conname = 'mfa_amr_claims_session_id_fkey'
                      AND connamespace = 'auth'::regnamespace
                ) THEN
                    ALTER TABLE auth.mfa_amr_claims
                        ADD CONSTRAINT mfa_amr_claims_session_id_fkey
                        FOREIGN KEY (session_id) REFERENCES auth.sessions(id) ON DELETE CASCADE NOT VALID;
                END IF;

                IF NOT EXISTS (
                    SELECT 1
                    FROM pg_constraint
                    WHERE conname = 'mfa_challenges_auth_factor_id_fkey'
                      AND connamespace = 'auth'::regnamespace
                ) THEN
                    ALTER TABLE auth.mfa_challenges
                        ADD CONSTRAINT mfa_challenges_auth_factor_id_fkey
                        FOREIGN KEY (factor_id) REFERENCES auth.mfa_factors(id) ON DELETE CASCADE NOT VALID;
                END IF;

                IF NOT EXISTS (
                    SELECT 1
                    FROM pg_constraint
                    WHERE conname = 'mfa_factors_user_id_fkey'
                      AND connamespace = 'auth'::regnamespace
                ) THEN
                    ALTER TABLE auth.mfa_factors
                        ADD CONSTRAINT mfa_factors_user_id_fkey
                        FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE NOT VALID;
                END IF;

                IF NOT EXISTS (
                    SELECT 1
                    FROM pg_constraint
                    WHERE conname = 'oauth_authorizations_client_id_fkey'
                      AND connamespace = 'auth'::regnamespace
                ) THEN
                    ALTER TABLE auth.oauth_authorizations
                        ADD CONSTRAINT oauth_authorizations_client_id_fkey
                        FOREIGN KEY (client_id) REFERENCES auth.oauth_clients(id) ON DELETE CASCADE NOT VALID;
                END IF;

                IF NOT EXISTS (
                    SELECT 1
                    FROM pg_constraint
                    WHERE conname = 'oauth_authorizations_user_id_fkey'
                      AND connamespace = 'auth'::regnamespace
                ) THEN
                    ALTER TABLE auth.oauth_authorizations
                        ADD CONSTRAINT oauth_authorizations_user_id_fkey
                        FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE NOT VALID;
                END IF;

                IF NOT EXISTS (
                    SELECT 1
                    FROM pg_constraint
                    WHERE conname = 'oauth_consents_client_id_fkey'
                      AND connamespace = 'auth'::regnamespace
                ) THEN
                    ALTER TABLE auth.oauth_consents
                        ADD CONSTRAINT oauth_consents_client_id_fkey
                        FOREIGN KEY (client_id) REFERENCES auth.oauth_clients(id) ON DELETE CASCADE NOT VALID;
                END IF;

                IF NOT EXISTS (
                    SELECT 1
                    FROM pg_constraint
                    WHERE conname = 'oauth_consents_user_id_fkey'
                      AND connamespace = 'auth'::regnamespace
                ) THEN
                    ALTER TABLE auth.oauth_consents
                        ADD CONSTRAINT oauth_consents_user_id_fkey
                        FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE NOT VALID;
                END IF;

                IF NOT EXISTS (
                    SELECT 1
                    FROM pg_constraint
                    WHERE conname = 'one_time_tokens_user_id_fkey'
                      AND connamespace = 'auth'::regnamespace
                ) THEN
                    ALTER TABLE auth.one_time_tokens
                        ADD CONSTRAINT one_time_tokens_user_id_fkey
                        FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE NOT VALID;
                END IF;

                IF NOT EXISTS (
                    SELECT 1
                    FROM pg_constraint
                    WHERE conname = 'saml_providers_sso_provider_id_fkey'
                      AND connamespace = 'auth'::regnamespace
                ) THEN
                    ALTER TABLE auth.saml_providers
                        ADD CONSTRAINT saml_providers_sso_provider_id_fkey
                        FOREIGN KEY (sso_provider_id) REFERENCES auth.sso_providers(id) ON DELETE CASCADE NOT VALID;
                END IF;

                IF NOT EXISTS (
                    SELECT 1
                    FROM pg_constraint
                    WHERE conname = 'saml_relay_states_flow_state_id_fkey'
                      AND connamespace = 'auth'::regnamespace
                ) THEN
                    ALTER TABLE auth.saml_relay_states
                        ADD CONSTRAINT saml_relay_states_flow_state_id_fkey
                        FOREIGN KEY (flow_state_id) REFERENCES auth.flow_state(id) ON DELETE CASCADE NOT VALID;
                END IF;

                IF NOT EXISTS (
                    SELECT 1
                    FROM pg_constraint
                    WHERE conname = 'saml_relay_states_sso_provider_id_fkey'
                      AND connamespace = 'auth'::regnamespace
                ) THEN
                    ALTER TABLE auth.saml_relay_states
                        ADD CONSTRAINT saml_relay_states_sso_provider_id_fkey
                        FOREIGN KEY (sso_provider_id) REFERENCES auth.sso_providers(id) ON DELETE CASCADE NOT VALID;
                END IF;

                IF NOT EXISTS (
                    SELECT 1
                    FROM pg_constraint
                    WHERE conname = 'sessions_oauth_client_id_fkey'
                      AND connamespace = 'auth'::regnamespace
                ) THEN
                    ALTER TABLE auth.sessions
                        ADD CONSTRAINT sessions_oauth_client_id_fkey
                        FOREIGN KEY (oauth_client_id) REFERENCES auth.oauth_clients(id) ON DELETE CASCADE NOT VALID;
                END IF;

                IF NOT EXISTS (
                    SELECT 1
                    FROM pg_constraint
                    WHERE conname = 'sessions_user_id_fkey'
                      AND connamespace = 'auth'::regnamespace
                ) THEN
                    ALTER TABLE auth.sessions
                        ADD CONSTRAINT sessions_user_id_fkey
                        FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE NOT VALID;
                END IF;

                IF NOT EXISTS (
                    SELECT 1
                    FROM pg_constraint
                    WHERE conname = 'sso_domains_sso_provider_id_fkey'
                      AND connamespace = 'auth'::regnamespace
                ) THEN
                    ALTER TABLE auth.sso_domains
                        ADD CONSTRAINT sso_domains_sso_provider_id_fkey
                        FOREIGN KEY (sso_provider_id) REFERENCES auth.sso_providers(id) ON DELETE CASCADE NOT VALID;
                END IF;
            END
            $$;
            """
        ).run()

        let indexStatements = [
            "CREATE INDEX IF NOT EXISTS audit_logs_instance_id_idx ON auth.audit_log_entries USING btree (instance_id);",
            "CREATE UNIQUE INDEX IF NOT EXISTS confirmation_token_idx ON auth.users USING btree (confirmation_token) WHERE ((confirmation_token)::text !~ '^[0-9 ]*$'::text);",
            "CREATE UNIQUE INDEX IF NOT EXISTS email_change_token_current_idx ON auth.users USING btree (email_change_token_current) WHERE ((email_change_token_current)::text !~ '^[0-9 ]*$'::text);",
            "CREATE UNIQUE INDEX IF NOT EXISTS email_change_token_new_idx ON auth.users USING btree (email_change_token_new) WHERE ((email_change_token_new)::text !~ '^[0-9 ]*$'::text);",
            "CREATE INDEX IF NOT EXISTS factor_id_created_at_idx ON auth.mfa_factors USING btree (user_id, created_at);",
            "CREATE INDEX IF NOT EXISTS flow_state_created_at_idx ON auth.flow_state USING btree (created_at DESC);",
            "CREATE INDEX IF NOT EXISTS identities_email_idx ON auth.identities USING btree (email text_pattern_ops);",
            "CREATE INDEX IF NOT EXISTS identities_user_id_idx ON auth.identities USING btree (user_id);",
            "CREATE INDEX IF NOT EXISTS idx_auth_code ON auth.flow_state USING btree (auth_code);",
            "CREATE INDEX IF NOT EXISTS idx_user_id_auth_method ON auth.flow_state USING btree (user_id, authentication_method);",
            "CREATE INDEX IF NOT EXISTS mfa_challenge_created_at_idx ON auth.mfa_challenges USING btree (created_at DESC);",
            "CREATE UNIQUE INDEX IF NOT EXISTS mfa_factors_user_friendly_name_unique ON auth.mfa_factors USING btree (friendly_name, user_id) WHERE (TRIM(BOTH FROM friendly_name) <> ''::text);",
            "CREATE INDEX IF NOT EXISTS mfa_factors_user_id_idx ON auth.mfa_factors USING btree (user_id);",
            "CREATE INDEX IF NOT EXISTS oauth_auth_pending_exp_idx ON auth.oauth_authorizations USING btree (expires_at) WHERE (status = 'pending'::auth.oauth_authorization_status);",
            "CREATE INDEX IF NOT EXISTS oauth_clients_deleted_at_idx ON auth.oauth_clients USING btree (deleted_at);",
            "CREATE INDEX IF NOT EXISTS oauth_consents_active_client_idx ON auth.oauth_consents USING btree (client_id) WHERE (revoked_at IS NULL);",
            "CREATE INDEX IF NOT EXISTS oauth_consents_active_user_client_idx ON auth.oauth_consents USING btree (user_id, client_id) WHERE (revoked_at IS NULL);",
            "CREATE INDEX IF NOT EXISTS oauth_consents_user_order_idx ON auth.oauth_consents USING btree (user_id, granted_at DESC);",
            "CREATE INDEX IF NOT EXISTS one_time_tokens_relates_to_hash_idx ON auth.one_time_tokens USING hash (relates_to);",
            "CREATE INDEX IF NOT EXISTS one_time_tokens_token_hash_hash_idx ON auth.one_time_tokens USING hash (token_hash);",
            "CREATE UNIQUE INDEX IF NOT EXISTS one_time_tokens_user_id_token_type_key ON auth.one_time_tokens USING btree (user_id, token_type);",
            "CREATE UNIQUE INDEX IF NOT EXISTS reauthentication_token_idx ON auth.users USING btree (reauthentication_token) WHERE ((reauthentication_token)::text !~ '^[0-9 ]*$'::text);",
            "CREATE UNIQUE INDEX IF NOT EXISTS recovery_token_idx ON auth.users USING btree (recovery_token) WHERE ((recovery_token)::text !~ '^[0-9 ]*$'::text);",
            "CREATE INDEX IF NOT EXISTS refresh_tokens_instance_id_idx ON auth.refresh_tokens USING btree (instance_id);",
            "CREATE INDEX IF NOT EXISTS refresh_tokens_instance_id_user_id_idx ON auth.refresh_tokens USING btree (instance_id, user_id);",
            "CREATE INDEX IF NOT EXISTS refresh_tokens_parent_idx ON auth.refresh_tokens USING btree (parent);",
            "CREATE INDEX IF NOT EXISTS refresh_tokens_session_id_revoked_idx ON auth.refresh_tokens USING btree (session_id, revoked);",
            "CREATE INDEX IF NOT EXISTS refresh_tokens_updated_at_idx ON auth.refresh_tokens USING btree (updated_at DESC);",
            "CREATE INDEX IF NOT EXISTS saml_providers_sso_provider_id_idx ON auth.saml_providers USING btree (sso_provider_id);",
            "CREATE INDEX IF NOT EXISTS saml_relay_states_created_at_idx ON auth.saml_relay_states USING btree (created_at DESC);",
            "CREATE INDEX IF NOT EXISTS saml_relay_states_for_email_idx ON auth.saml_relay_states USING btree (for_email);",
            "CREATE INDEX IF NOT EXISTS saml_relay_states_sso_provider_id_idx ON auth.saml_relay_states USING btree (sso_provider_id);",
            "CREATE INDEX IF NOT EXISTS sessions_not_after_idx ON auth.sessions USING btree (not_after DESC);",
            "CREATE INDEX IF NOT EXISTS sessions_oauth_client_id_idx ON auth.sessions USING btree (oauth_client_id);",
            "CREATE INDEX IF NOT EXISTS sessions_user_id_idx ON auth.sessions USING btree (user_id);",
            "CREATE UNIQUE INDEX IF NOT EXISTS sso_domains_domain_idx ON auth.sso_domains USING btree (lower(domain));",
            "CREATE INDEX IF NOT EXISTS sso_domains_sso_provider_id_idx ON auth.sso_domains USING btree (sso_provider_id);",
            "CREATE UNIQUE INDEX IF NOT EXISTS sso_providers_resource_id_idx ON auth.sso_providers USING btree (lower(resource_id));",
            "CREATE INDEX IF NOT EXISTS sso_providers_resource_id_pattern_idx ON auth.sso_providers USING btree (resource_id text_pattern_ops);",
            "CREATE UNIQUE INDEX IF NOT EXISTS unique_phone_factor_per_user ON auth.mfa_factors USING btree (user_id, phone);",
            "CREATE INDEX IF NOT EXISTS user_id_created_at_idx ON auth.sessions USING btree (user_id, created_at);",
            "CREATE UNIQUE INDEX IF NOT EXISTS users_email_partial_key ON auth.users USING btree (email) WHERE (is_sso_user = false);",
            "CREATE INDEX IF NOT EXISTS users_instance_id_email_idx ON auth.users USING btree (instance_id, lower(email));",
            "CREATE INDEX IF NOT EXISTS users_instance_id_idx ON auth.users USING btree (instance_id);",
            "CREATE INDEX IF NOT EXISTS users_is_anonymous_idx ON auth.users USING btree (is_anonymous);"
        ]

        for statement in indexStatements {
            try await sql.raw("\(unsafeRaw: statement)").run()
        }
    }

    func revert(on _: any Database) async throws {
        // Security hardening migration is intentionally non-reversible.
    }
}
