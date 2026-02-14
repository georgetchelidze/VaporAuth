import Fluent
import Vapor

extension Auth {
    public final class SSOProvider: Model, @unchecked Sendable {
        public static let schema = "sso_providers"
        public static let space: String? = Auth.space

        @ID(custom: "id", generatedBy: .user)
        public var id: UUID?

        @OptionalField(key: "resource_id")
        public var resourceId: String?

        @OptionalField(key: "created_at")
        public var createdAt: Date?

        @OptionalField(key: "updated_at")
        public var updatedAt: Date?

        @OptionalField(key: "disabled")
        public var disabled: Bool?

        public init() {}
    }
}
