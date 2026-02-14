import Fluent
import Vapor

extension Auth {
    public final class Identity: Model, @unchecked Sendable {
        public static let schema = "identities"
        public static let space: String? = Auth.space

        @ID(custom: "id", generatedBy: .user)
        public var id: UUID?

        @OptionalField(key: "provider_id")
        public var providerId: String?

        @OptionalField(key: "user_id")
        public var userId: UUID?

        @OptionalField(key: "identity_data")
        public var identityData: [String: DynamicJSON]?

        @OptionalField(key: "provider")
        public var provider: String?

        @OptionalField(key: "last_sign_in_at")
        public var lastSignInAt: Date?

        @OptionalField(key: "created_at")
        public var createdAt: Date?

        @OptionalField(key: "updated_at")
        public var updatedAt: Date?

        @OptionalField(key: "email")
        public var email: String?

        public init() {}
    }
}
