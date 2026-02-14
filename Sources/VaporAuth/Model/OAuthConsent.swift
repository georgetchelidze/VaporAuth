import Fluent
import Vapor

extension Auth {
    public final class OAuthConsent: Model, Content, @unchecked Sendable {
        public static let schema = "oauth_consents"
        public static let space: String? = Auth.space

        @ID(custom: "id", generatedBy: .user)
        public var id: UUID?

        @OptionalField(key: "user_id")
        public var userId: UUID?

        @OptionalField(key: "client_id")
        public var clientId: UUID?

        @OptionalField(key: "scopes")
        public var scopes: String?

        @OptionalField(key: "granted_at")
        public var grantedAt: Date?

        @OptionalField(key: "revoked_at")
        public var revokedAt: Date?

        public init() {}
    }
}
