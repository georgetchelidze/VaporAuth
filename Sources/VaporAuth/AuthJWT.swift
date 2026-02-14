import JWT
import Vapor

public struct AuthUserPayload: JWTPayload, Authenticatable, Content, Sendable {
    enum CodingKeys: String, CodingKey {
        case subject = "sub"
        case email
        case expiration = "exp"
        case audience = "aud"
        case issuer = "iss"
        case role
    }

    public var subject: SubjectClaim
    public var email: String?
    public var expiration: ExpirationClaim
    public var audience: AudienceClaim?
    public var issuer: IssuerClaim?
    public var role: String?

    public init(
        subject: SubjectClaim,
        email: String?,
        expiration: ExpirationClaim,
        audience: AudienceClaim?,
        issuer: IssuerClaim?,
        role: String?
    ) {
        self.subject = subject
        self.email = email
        self.expiration = expiration
        self.audience = audience
        self.issuer = issuer
        self.role = role
    }

    public func verify(using _: some JWTAlgorithm) async throws {
        try expiration.verifyNotExpired()
    }

    public func validateExpectedClaims(expectedIssuer: String?, expectedAudience: String?) throws {
        if let expectedIssuer {
            guard issuer?.value == expectedIssuer else {
                throw Abort(.unauthorized, reason: "Invalid token issuer")
            }
        }

        if let expectedAudience {
            guard let audiences = audience?.value,
                  audiences.contains(expectedAudience)
            else {
                throw Abort(.unauthorized, reason: "Invalid token audience")
            }
        }
    }
}

public struct AuthJWTUserAuthenticator: AsyncRequestAuthenticator {
    public typealias User = AuthUserPayload

    public var expectedIssuer: String?
    public var expectedAudience: String?

    public init(expectedIssuer: String? = nil, expectedAudience: String? = nil) {
        self.expectedIssuer = expectedIssuer
        self.expectedAudience = expectedAudience
    }

    public func authenticate(request: Request) async throws {
        guard request.headers.bearerAuthorization != nil else {
            return
        }

        do {
            let payload = try await request.jwt.verify(as: AuthUserPayload.self)
            try payload.validateExpectedClaims(
                expectedIssuer: expectedIssuer,
                expectedAudience: expectedAudience
            )
            request.auth.login(payload)
        } catch {
            request.auth.logout(AuthUserPayload.self)
            throw error
        }
    }
}

public enum AuthJWT {
    public static func configure(on app: Application, secret: String) async {
        await app.jwt.keys.add(
            hmac: HMACKey(from: secret),
            digestAlgorithm: .sha256
        )
    }
}
