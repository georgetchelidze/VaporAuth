import Fluent
import Vapor

extension Auth {
    public final class Session: Model, @unchecked Sendable {
        public static let schema = "sessions"
        public static let space: String? = Auth.space

        @ID(custom: "id", generatedBy: .user)
        public var id: UUID?

        @OptionalField(key: "user_id")
        public var userId: UUID?

        @OptionalField(key: "created_at")
        public var createdAt: Date?

        @OptionalField(key: "updated_at")
        public var updatedAt: Date?

        @OptionalField(key: "factor_id")
        public var factorId: UUID?

        @OptionalEnum(key: "aal")
        public var aal: Auth.AALLevel?

        @OptionalField(key: "not_after")
        public var notAfter: Date?

        @OptionalField(key: "refreshed_at")
        public var refreshedAt: Date?

        @OptionalField(key: "user_agent")
        public var userAgent: String?

        @OptionalField(key: "ip")
        public var ip: String?

        @OptionalField(key: "tag")
        public var tag: String?

        @OptionalField(key: "oauth_client_id")
        public var oauthClientId: UUID?

        @OptionalField(key: "refresh_token_hmac_key")
        public var refreshTokenHmacKey: String?

        @OptionalField(key: "refresh_token_counter")
        public var refreshTokenCounter: Int64?

        public init() {}
    }
}
