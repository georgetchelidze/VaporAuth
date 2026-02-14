import Fluent
import Vapor

/// One-line registration helper for Auth schema migrations.
public enum AuthMigrationMode {
    /// Register only initial schema/table creation migrations.
    case createOnly
    /// Register creation + all follow-up auth migrations (Add/Alter/Drop/Rename).
    case all
}

public enum AuthMigrations {
    public static func register(on app: Application, mode: AuthMigrationMode = .all) {
        registerCreate(on: app)

        guard mode == .all else { return }
        registerAdditions(on: app)
    }

    public static func registerCreate(on app: Application) {
        app.migrations.add(CreateAuthSchema())
        app.migrations.add(CreateAuthEnums())

        app.migrations.add(CreateAuthUsers())
        app.migrations.add(CreateAuthSessions())
        app.migrations.add(CreateAuthRefreshTokens())
        app.migrations.add(CreateAuthOneTimeTokens())
        app.migrations.add(CreateAuthIdentities())
        app.migrations.add(CreateAuthFlowState())
        app.migrations.add(CreateAuthInstances())
        app.migrations.add(CreateAuthMFAFactors())
        app.migrations.add(CreateAuthMFAChallenges())
        app.migrations.add(CreateAuthMFAAMRClaims())
        app.migrations.add(CreateAuthOAuthClients())
        app.migrations.add(CreateAuthOAuthAuthorizations())
        app.migrations.add(CreateAuthOAuthConsents())
        app.migrations.add(CreateAuthSSOProviders())
        app.migrations.add(CreateAuthSSODomains())
        app.migrations.add(CreateAuthSAMLProviders())
        app.migrations.add(CreateAuthSAMLRelayStates())
        app.migrations.add(CreateAuthAuditLogEntries())
    }

    /// Keep all non-create auth migrations here (Add*/Alter*/Drop*/Rename*).
    /// This lets the call site stay a single line: `AuthMigrations.register(on: app)`.
    public static func registerAdditions(on app: Application) {
        app.migrations.add(AlterAuthSessionsIPToInetIfNeeded())
        app.migrations.add(HardenAuthRefreshTokens())
        app.migrations.add(HardenAuthUsersIndexes())
        app.migrations.add(HardenAuthSchemaSecurity())
    }
}
