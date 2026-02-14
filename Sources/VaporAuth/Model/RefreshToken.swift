import Fluent
import Vapor

extension Auth {
    public final class RefreshToken: Model, Content, @unchecked Sendable {
        public static let schema = "refresh_tokens"
        public static let space: String? = Auth.space

        @ID(custom: "id")
        public var id: Int64?

        @OptionalField(key: "instance_id")
        public var instanceId: UUID?

        @OptionalField(key: "token")
        public var token: String?

        @OptionalField(key: "user_id")
        public var userId: String?

        @OptionalField(key: "revoked")
        public var revoked: Bool?

        @OptionalField(key: "created_at")
        public var createdAt: Date?

        @OptionalField(key: "updated_at")
        public var updatedAt: Date?

        @OptionalField(key: "parent")
        public var parent: String?

        @OptionalField(key: "session_id")
        public var sessionId: UUID?

        public init() {}
    }
}
