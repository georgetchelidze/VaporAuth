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
    public var audience: String
    public var issuer: String?
    public var enabledRoutes: Set<AuthRoute>

    public init(
        tokenPath: PathComponent = "token",
        accessTokenTTLSeconds: Int = 3600,
        audience: String = "authenticated",
        issuer: String? = nil,
        enabledRoutes: Set<AuthRoute> = Set(AuthRoute.allCases)
    ) {
        self.tokenPath = tokenPath
        self.accessTokenTTLSeconds = accessTokenTTLSeconds
        self.audience = audience
        self.issuer = issuer
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
            let protected = auth.grouped(AuthJWTUserAuthenticator())
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

    guard let user = try await Auth.User.query(on: req.db)
        .filter(\.$email == email)
        .first()
    else {
        throw Abort(.unauthorized, reason: "Invalid credentials")
    }

    guard let userID = user.id,
          let hash = user.encryptedPassword,
          try Bcrypt.verify(password, created: hash)
    else {
        throw Abort(.unauthorized, reason: "Invalid credentials")
    }

    let now = Date()
    user.lastSignInAt = now
    user.updatedAt = now
    try await user.save(on: req.db)

    let session = Auth.Session()
    session.id = UUID()
    session.userId = userID
    session.createdAt = now
    session.updatedAt = now
    session.refreshedAt = now
    session.aal = .aal1
    session.ip = nil
    session.userAgent = req.headers.first(name: .userAgent)
    try await session.save(on: req.db)

    if let ipAddress = req.remoteAddress?.ipAddress,
       let sessionID = session.id,
       let sql = req.db as? any SQLDatabase {
        do {
            try await sql.raw("UPDATE auth.sessions SET ip = \(bind: ipAddress)::inet WHERE id = \(bind: sessionID)").run()
        } catch {
            req.logger.debug("VaporAuth: failed to persist session ip as inet: \(error)")
        }
    }

    let refreshToken = Auth.RefreshToken()
    refreshToken.token = [UUID().uuidString, UUID().uuidString].joined()
    refreshToken.userId = userID.uuidString
    refreshToken.revoked = false
    refreshToken.createdAt = now
    refreshToken.updatedAt = now
    refreshToken.sessionId = session.id
    try await refreshToken.save(on: req.db)

    return try await buildTokenResponse(
        req: req,
        user: user,
        refreshToken: refreshToken,
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

    guard let existing = try await Auth.RefreshToken.query(on: req.db)
        .filter(\.$token == rawToken)
        .first(),
          existing.revoked != true
    else {
        throw Abort(.unauthorized, reason: "Invalid refresh token")
    }

    guard let userIDString = existing.userId,
          let userID = UUID(uuidString: userIDString),
          let user = try await Auth.User.find(userID, on: req.db)
    else {
        throw Abort(.unauthorized, reason: "Invalid refresh token")
    }

    existing.revoked = true
    existing.updatedAt = Date()
    try await existing.save(on: req.db)

    let newToken = Auth.RefreshToken()
    newToken.token = [UUID().uuidString, UUID().uuidString].joined()
    newToken.userId = userID.uuidString
    newToken.revoked = false
    newToken.createdAt = Date()
    newToken.updatedAt = Date()
    newToken.parent = rawToken
    newToken.sessionId = existing.sessionId
    try await newToken.save(on: req.db)

    if let sessionID = existing.sessionId,
       let session = try await Auth.Session.find(sessionID, on: req.db) {
        session.refreshedAt = Date()
        session.updatedAt = Date()
        try await session.save(on: req.db)
    }

    return try await buildTokenResponse(
        req: req,
        user: user,
        refreshToken: newToken,
        options: options
    )
}

private func buildTokenResponse(
    req: Request,
    user: Auth.User,
    refreshToken: Auth.RefreshToken,
    options: AuthRouteOptions
) async throws -> AuthTokenResponse {
    guard let userID = user.id else {
        throw Abort(.internalServerError, reason: "User has no id")
    }
    guard let refreshTokenValue = refreshToken.token else {
        throw Abort(.internalServerError, reason: "Refresh token missing")
    }

    let expiresAt = Date(timeIntervalSinceNow: TimeInterval(options.accessTokenTTLSeconds))
    let payload = AuthUserPayload(
        subject: .init(value: userID.uuidString),
        email: user.email,
        expiration: .init(value: expiresAt),
        audience: .init(value: [user.aud ?? options.audience]),
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

    if let token = try await Auth.RefreshToken.query(on: req.db)
        .filter(\.$token == rawToken)
        .first() {
        token.revoked = true
        token.updatedAt = Date()
        try await token.save(on: req.db)
    }

    return .noContent
}
