import Fluent
import Vapor

extension Auth {
    public final class OneTimeToken: Model, Content, @unchecked Sendable {
        public static let schema = "one_time_tokens"
        public static let space: String? = Auth.space

        @ID(custom: "id", generatedBy: .user)
        public var id: UUID?

        @OptionalField(key: "user_id")
        public var userId: UUID?

        @OptionalEnum(key: "token_type")
        public var tokenType: Auth.OneTimeTokenType?

        @OptionalField(key: "token_hash")
        public var tokenHash: String?

        @OptionalField(key: "relates_to")
        public var relatesTo: String?

        @OptionalField(key: "created_at")
        public var createdAt: Date?

        @OptionalField(key: "updated_at")
        public var updatedAt: Date?

        public init() {}
    }
}
