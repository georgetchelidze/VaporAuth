import Crypto
import Fluent
import FluentSQL
import JWT
import Vapor

public enum AuthRoute: String, CaseIterable, Hashable, Sendable {
    case token
    case me
    case logout
}

public struct AuthRouteOptions: Sendable {
    public var tokenPath: PathComponent
    public var accessTokenTTLSeconds: Int
    public var sessionLifetimeSeconds: Int?
    public var refreshTokenIdleTimeoutSeconds: Int?
    public var audience: String
    public var issuer: String?
    public var confirmationPolicy: AuthConfirmationPolicy
    public var passwordGrantRateLimit: PasswordGrantRateLimitOptions
    public var enabledRoutes: Set<AuthRoute>

    public init(
        tokenPath: PathComponent = "token",
        accessTokenTTLSeconds: Int = 3600,
        sessionLifetimeSeconds: Int? = 2_592_000,
        refreshTokenIdleTimeoutSeconds: Int? = 2_592_000,
        audience: String = "authenticated",
        issuer: String? = nil,
        confirmationPolicy: AuthConfirmationPolicy = .requireConfirmedEmail,
        passwordGrantRateLimit: PasswordGrantRateLimitOptions = .init(),
        enabledRoutes: Set<AuthRoute> = Set(AuthRoute.allCases)
    ) {
        self.tokenPath = tokenPath
        self.accessTokenTTLSeconds = accessTokenTTLSeconds
        self.sessionLifetimeSeconds = sessionLifetimeSeconds
        self.refreshTokenIdleTimeoutSeconds = refreshTokenIdleTimeoutSeconds
        self.audience = audience
        self.issuer = issuer
        self.confirmationPolicy = confirmationPolicy
        self.passwordGrantRateLimit = passwordGrantRateLimit
        self.enabledRoutes = enabledRoutes
    }
}

public enum AuthRoutes {
    public static func register(
        on routes: any RoutesBuilder,
        enabledRoutes: Set<AuthRoute> = Set(AuthRoute.allCases)
    ) {
        var options = AuthRouteOptions()
        options.enabledRoutes = enabledRoutes
        register(on: routes, options: options)
    }

    public static func register(on routes: any RoutesBuilder, options: AuthRouteOptions = .init()) {
        let auth = routes.grouped("auth")
        if options.enabledRoutes.contains(.token) {
            auth.post(options.tokenPath) { req async throws in
                try await token(req: req, options: options)
            }
        }
        if options.enabledRoutes.contains(.logout) {
            auth.post("logout", use: logout)
        }

        if options.enabledRoutes.contains(.me) {
            let protected = auth.grouped(
                AuthJWTUserAuthenticator(
                    expectedIssuer: options.issuer,
                    expectedAudience: options.audience
                )
            )
            .grouped(AuthUserPayload.guardMiddleware())
            protected.get("me", use: me)
        }
    }
}

private struct AuthTokenRequest: Content {
    let grantType: String
    let email: String?
    let password: String?
    let refreshToken: String?

    enum CodingKeys: String, CodingKey {
        case grantType = "grant_type"
        case email
        case password
        case refreshToken = "refresh_token"
    }
}

private struct AuthLogoutRequest: Content {
    let refreshToken: String?

    enum CodingKeys: String, CodingKey {
        case refreshToken = "refresh_token"
    }
}

private struct AuthTokenResponse: Content {
    let accessToken: String
    let tokenType: String
    let expiresIn: Int
    let refreshToken: String
    let user: Auth.UserResponse

    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case tokenType = "token_type"
        case expiresIn = "expires_in"
        case refreshToken = "refresh_token"
        case user
    }
}

private extension Auth {
    struct UserResponse: Content {
        let id: UUID
        let email: String?
        let role: String?
        let aud: String?
        let createdAt: Date?
        let updatedAt: Date?

        enum CodingKeys: String, CodingKey {
            case id
            case email
            case role
            case aud
            case createdAt = "created_at"
            case updatedAt = "updated_at"
        }
    }
}

private struct RefreshTokenParts {
    let sessionID: UUID
    let counter: Int64
}

private struct RefreshTokenIssue {
    let rawToken: String
    let tokenHash: String
    let counter: Int64
}

private enum RefreshGrantFailure: Error {
    case invalid
    case replayDetected
}

private func token(req: Request, options: AuthRouteOptions) async throws -> AuthTokenResponse {
    let input = try req.content.decode(AuthTokenRequest.self)
    switch input.grantType {
    case "password":
        return try await passwordGrant(req: req, input: input, options: options)
    case "refresh_token":
        return try await refreshGrant(req: req, input: input, options: options)
    default:
        throw Abort(.badRequest, reason: "Unsupported grant_type")
    }
}

private func passwordGrant(
    req: Request,
    input: AuthTokenRequest,
    options: AuthRouteOptions
) async throws -> AuthTokenResponse {
    guard let email = input.email?.trimmingCharacters(in: .whitespacesAndNewlines).lowercased(),
          !email.isEmpty,
          let password = input.password,
          !password.isEmpty
    else {
        throw Abort(.badRequest, reason: "email and password are required")
    }

    let rateLimitKeys = passwordGrantRateLimitKeys(
        ipAddress: req.remoteAddress?.ipAddress,
        email: email
    )

    let rateLimitCheckTime = Date()
    if await req.application.vaporAuthPasswordGrantRateLimiter.isBlocked(
        keys: rateLimitKeys,
        now: rateLimitCheckTime,
        options: options.passwordGrantRateLimit
    ) {
        throw Abort(.tooManyRequests, reason: "Too many login attempts. Try again later.")
    }

    guard let user = try await Auth.User.query(on: req.db)
        .filter(\.$email == email)
        .first()
    else {
        await registerPasswordGrantFailure(req: req, keys: rateLimitKeys, options: options)
        throw Abort(.unauthorized, reason: "Invalid credentials")
    }

    guard let userID = user.id,
          let hash = user.encryptedPassword
    else {
        await registerPasswordGrantFailure(req: req, keys: rateLimitKeys, options: options)
        throw Abort(.unauthorized, reason: "Invalid credentials")
    }

    let passwordMatches: Bool
    do {
        passwordMatches = try Bcrypt.verify(password, created: hash)
    } catch {
        passwordMatches = false
    }

    guard passwordMatches else {
        await registerPasswordGrantFailure(req: req, keys: rateLimitKeys, options: options)
        throw Abort(.unauthorized, reason: "Invalid credentials")
    }

    let now = Date()
    guard isUserEligibleForPasswordGrant(user, now: now, confirmationPolicy: options.confirmationPolicy) else {
        await registerPasswordGrantFailure(req: req, keys: rateLimitKeys, options: options)
        throw Abort(.unauthorized, reason: "Invalid credentials")
    }

    let refreshTokenValue = try await req.db.transaction { db in
        user.lastSignInAt = now
        user.updatedAt = now
        try await user.save(on: db)

        let session = Auth.Session()
        session.id = UUID()
        session.userId = userID
        session.createdAt = now
        session.updatedAt = now
        session.refreshedAt = now
        session.aal = .aal1
        session.ip = nil
        session.userAgent = req.headers.first(name: .userAgent)
        session.refreshTokenHmacKey = randomTokenSecret()
        session.refreshTokenCounter = 0
        if let sessionLifetimeSeconds = options.sessionLifetimeSeconds,
           sessionLifetimeSeconds > 0 {
            session.notAfter = now.addingTimeInterval(TimeInterval(sessionLifetimeSeconds))
        }
        try await session.save(on: db)

        if let ipAddress = req.remoteAddress?.ipAddress,
           let sessionID = session.id,
           let sql = db as? any SQLDatabase {
            do {
                try await sql.raw("UPDATE auth.sessions SET ip = \(bind: ipAddress)::inet WHERE id = \(bind: sessionID)").run()
            } catch {
                req.logger.debug("VaporAuth: failed to persist session ip as inet: \(error)")
            }
        }

        guard let sessionID = session.id,
              let hmacKey = session.refreshTokenHmacKey,
              let currentCounter = session.refreshTokenCounter
        else {
            throw Abort(.internalServerError, reason: "Session refresh state missing")
        }

        let issued = issueRefreshToken(sessionID: sessionID, hmacKey: hmacKey, previousCounter: currentCounter)

        let refreshToken = Auth.RefreshToken()
        refreshToken.token = issued.tokenHash
        refreshToken.userId = userID.uuidString
        refreshToken.revoked = false
        refreshToken.createdAt = now
        refreshToken.updatedAt = now
        refreshToken.sessionId = sessionID
        try await refreshToken.save(on: db)

        session.refreshTokenCounter = issued.counter
        session.updatedAt = now
        try await session.save(on: db)

        return issued.rawToken
    }

    await req.application.vaporAuthPasswordGrantRateLimiter.recordSuccess(keys: rateLimitKeys)

    return try await buildTokenResponse(
        req: req,
        user: user,
        refreshTokenValue: refreshTokenValue,
        options: options
    )
}

private func refreshGrant(
    req: Request,
    input: AuthTokenRequest,
    options: AuthRouteOptions
) async throws -> AuthTokenResponse {
    guard let rawToken = input.refreshToken?.trimmingCharacters(in: .whitespacesAndNewlines),
          !rawToken.isEmpty
    else {
        throw Abort(.badRequest, reason: "refresh_token is required")
    }

    guard let parts = parseRefreshToken(rawToken) else {
        throw Abort(.unauthorized, reason: "Invalid refresh token")
    }

    do {
        let result = try await req.db.transaction { db in
            guard let sql = db as? any SQLDatabase else {
                throw Abort(.internalServerError, reason: "SQL database required")
            }

            try await sql.raw("SELECT pg_advisory_xact_lock(hashtext(\(bind: parts.sessionID.uuidString)))").run()

            guard let session = try await Auth.Session.find(parts.sessionID, on: db),
                  let sessionUserID = session.userId,
                  let hmacKey = session.refreshTokenHmacKey,
                  let currentCounter = session.refreshTokenCounter
            else {
                throw RefreshGrantFailure.invalid
            }

            let now = Date()
            let resolvedNotAfter = sessionExpiryDate(
                for: session,
                fallbackLifetimeSeconds: options.sessionLifetimeSeconds
            )
            if let resolvedNotAfter,
               resolvedNotAfter <= now {
                throw RefreshGrantFailure.invalid
            }
            if session.notAfter == nil,
               let resolvedNotAfter {
                session.notAfter = resolvedNotAfter
            }

            let providedTokenHash = hashRefreshToken(rawToken, hmacKey: hmacKey)
            guard let existing = try await Auth.RefreshToken.query(on: db)
                .filter(\.$sessionId == parts.sessionID)
                .filter(\.$token == providedTokenHash)
                .first()
            else {
                // If this token is older than the latest issued one, treat as replay and burn the whole session.
                if parts.counter < currentCounter {
                    try await revokeSessionRefreshTokens(sessionID: parts.sessionID, now: now, on: db)
                    session.notAfter = now
                    session.updatedAt = now
                    try await session.save(on: db)
                    throw RefreshGrantFailure.replayDetected
                }
                throw RefreshGrantFailure.invalid
            }

            if existing.revoked == true || parts.counter < currentCounter {
                try await revokeSessionRefreshTokens(sessionID: parts.sessionID, now: now, on: db)
                session.notAfter = now
                session.updatedAt = now
                try await session.save(on: db)
                throw RefreshGrantFailure.replayDetected
            }

            guard parts.counter == currentCounter else {
                throw RefreshGrantFailure.invalid
            }

            if let refreshTokenIdleTimeoutSeconds = options.refreshTokenIdleTimeoutSeconds,
               refreshTokenIdleTimeoutSeconds > 0 {
                guard let refreshCreatedAt = existing.createdAt,
                      refreshCreatedAt.addingTimeInterval(TimeInterval(refreshTokenIdleTimeoutSeconds)) > now
                else {
                    try await revokeSessionRefreshTokens(sessionID: parts.sessionID, now: now, on: db)
                    session.notAfter = now
                    session.updatedAt = now
                    try await session.save(on: db)
                    throw RefreshGrantFailure.invalid
                }
            }

            guard let user = try await Auth.User.find(sessionUserID, on: db),
                  let userID = user.id,
                  isUserActiveForSessionIssuance(user, now: now)
            else {
                try await revokeSessionRefreshTokens(sessionID: parts.sessionID, now: now, on: db)
                session.notAfter = now
                session.updatedAt = now
                try await session.save(on: db)
                throw RefreshGrantFailure.invalid
            }

            existing.revoked = true
            existing.updatedAt = now
            try await existing.save(on: db)

            let issued = issueRefreshToken(sessionID: parts.sessionID, hmacKey: hmacKey, previousCounter: currentCounter)

            let newToken = Auth.RefreshToken()
            newToken.token = issued.tokenHash
            newToken.userId = userID.uuidString
            newToken.revoked = false
            newToken.createdAt = now
            newToken.updatedAt = now
            newToken.parent = providedTokenHash
            newToken.sessionId = parts.sessionID
            try await newToken.save(on: db)

            session.refreshTokenCounter = issued.counter
            session.refreshedAt = now
            session.updatedAt = now
            try await session.save(on: db)

            return (user, issued.rawToken)
        }

        return try await buildTokenResponse(
            req: req,
            user: result.0,
            refreshTokenValue: result.1,
            options: options
        )
    } catch let failure as RefreshGrantFailure {
        switch failure {
        case .invalid, .replayDetected:
            throw Abort(.unauthorized, reason: "Invalid refresh token")
        }
    }
}

private func buildTokenResponse(
    req: Request,
    user: Auth.User,
    refreshTokenValue: String,
    options: AuthRouteOptions
) async throws -> AuthTokenResponse {
    guard let userID = user.id else {
        throw Abort(.internalServerError, reason: "User has no id")
    }

    let expiresAt = Date(timeIntervalSinceNow: TimeInterval(options.accessTokenTTLSeconds))
    let payload = AuthUserPayload(
        subject: .init(value: userID.uuidString),
        email: user.email,
        expiration: .init(value: expiresAt),
        audience: .init(value: [options.audience]),
        issuer: options.issuer.map { .init(value: $0) },
        role: user.role
    )

    let accessToken = try await req.jwt.sign(payload)

    return AuthTokenResponse(
        accessToken: accessToken,
        tokenType: "bearer",
        expiresIn: options.accessTokenTTLSeconds,
        refreshToken: refreshTokenValue,
        user: .init(
            id: userID,
            email: user.email,
            role: user.role,
            aud: user.aud,
            createdAt: user.createdAt,
            updatedAt: user.updatedAt
        )
    )
}

private func me(req: Request) async throws -> Auth.UserResponse {
    let payload = try req.auth.require(AuthUserPayload.self)
    guard let userID = UUID(uuidString: payload.subject.value),
          let user = try await Auth.User.find(userID, on: req.db),
          let resolvedID = user.id
    else {
        throw Abort(.unauthorized, reason: "User not found")
    }

    guard isUserActiveForSessionIssuance(user, now: Date()) else {
        throw Abort(.unauthorized, reason: "User not found")
    }

    return .init(
        id: resolvedID,
        email: user.email,
        role: user.role,
        aud: user.aud,
        createdAt: user.createdAt,
        updatedAt: user.updatedAt
    )
}

private func logout(req: Request) async throws -> HTTPStatus {
    let input = try req.content.decode(AuthLogoutRequest.self)
    guard let rawToken = input.refreshToken?.trimmingCharacters(in: .whitespacesAndNewlines),
          !rawToken.isEmpty
    else {
        return .noContent
    }

    guard let parts = parseRefreshToken(rawToken) else {
        return .noContent
    }

    try await req.db.transaction { db in
        guard let session = try await Auth.Session.find(parts.sessionID, on: db),
              let hmacKey = session.refreshTokenHmacKey
        else {
            return
        }

        let tokenHash = hashRefreshToken(rawToken, hmacKey: hmacKey)
        guard let token = try await Auth.RefreshToken.query(on: db)
            .filter(\.$sessionId == parts.sessionID)
            .filter(\.$token == tokenHash)
            .first()
        else {
            return
        }

        let now = Date()
        token.revoked = true
        token.updatedAt = now
        try await token.save(on: db)

        try await revokeSessionRefreshTokens(sessionID: parts.sessionID, now: now, on: db)
        session.notAfter = now
        session.updatedAt = now
        try await session.save(on: db)
    }

    return .noContent
}

private func randomTokenSecret() -> String {
    [UUID().uuidString.replacingOccurrences(of: "-", with: ""), UUID().uuidString.replacingOccurrences(of: "-", with: "")]
        .joined()
}

private func issueRefreshToken(sessionID: UUID, hmacKey: String, previousCounter: Int64) -> RefreshTokenIssue {
    let nextCounter = previousCounter + 1
    let nonce = randomTokenSecret()
    let rawToken = "v1.\(sessionID.uuidString).\(nextCounter).\(nonce)"
    return .init(
        rawToken: rawToken,
        tokenHash: hashRefreshToken(rawToken, hmacKey: hmacKey),
        counter: nextCounter
    )
}

private func parseRefreshToken(_ rawToken: String) -> RefreshTokenParts? {
    let parts = rawToken.split(separator: ".", omittingEmptySubsequences: false)
    guard parts.count == 4,
          parts[0] == "v1",
          let sessionID = UUID(uuidString: String(parts[1])),
          let counter = Int64(parts[2]),
          counter > 0,
          !parts[3].isEmpty
    else {
        return nil
    }

    return .init(sessionID: sessionID, counter: counter)
}

private func hashRefreshToken(_ rawToken: String, hmacKey: String) -> String {
    let key = SymmetricKey(data: Data(hmacKey.utf8))
    let digest = HMAC<SHA256>.authenticationCode(for: Data(rawToken.utf8), using: key)
    return Data(digest).hexString
}

private func revokeSessionRefreshTokens(sessionID: UUID, now: Date, on db: any Database) async throws {
    try await Auth.RefreshToken.query(on: db)
        .filter(\.$sessionId == sessionID)
        .set(\.$revoked, to: true)
        .set(\.$updatedAt, to: now)
        .update()
}

private func registerPasswordGrantFailure(
    req: Request,
    keys: [String],
    options: AuthRouteOptions
) async {
    await req.application.vaporAuthPasswordGrantRateLimiter.recordFailure(
        keys: keys,
        now: Date(),
        options: options.passwordGrantRateLimit
    )
}

private extension Data {
    var hexString: String {
        map { String(format: "%02x", $0) }.joined()
    }
}
