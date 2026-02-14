import Fluent
import Vapor

extension Auth {
    public final class OAuthAuthorization: Model, Content, @unchecked Sendable {
        public static let schema = "oauth_authorizations"
        public static let space: String? = Auth.space

        @ID(custom: "id", generatedBy: .user)
        public var id: UUID?

        @OptionalField(key: "authorization_id")
        public var authorizationId: String?

        @OptionalField(key: "client_id")
        public var clientId: UUID?

        @OptionalField(key: "user_id")
        public var userId: UUID?

        @OptionalField(key: "redirect_uri")
        public var redirectUri: String?

        @OptionalField(key: "scope")
        public var scope: String?

        @OptionalField(key: "state")
        public var state: String?

        @OptionalField(key: "resource")
        public var resource: String?

        @OptionalField(key: "code_challenge")
        public var codeChallenge: String?

        @OptionalEnum(key: "code_challenge_method")
        public var codeChallengeMethod: Auth.CodeChallengeMethod?

        @OptionalEnum(key: "response_type")
        public var responseType: Auth.OAuthResponseType?

        @OptionalEnum(key: "status")
        public var status: Auth.OAuthAuthorizationStatus?

        @OptionalField(key: "authorization_code")
        public var authorizationCode: String?

        @OptionalField(key: "created_at")
        public var createdAt: Date?

        @OptionalField(key: "expires_at")
        public var expiresAt: Date?

        @OptionalField(key: "approved_at")
        public var approvedAt: Date?

        public init() {}
    }
}
