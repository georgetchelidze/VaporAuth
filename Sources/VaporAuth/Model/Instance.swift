import Fluent
import Vapor

extension Auth {
    public final class Instance: Model, Content, @unchecked Sendable {
        public static let schema = "instances"
        public static let space: String? = Auth.space

        @ID(custom: "id", generatedBy: .user)
        public var id: UUID?

        @OptionalField(key: "uuid")
        public var uuid: UUID?

        @OptionalField(key: "raw_base_config")
        public var rawBaseConfig: String?

        @OptionalField(key: "created_at")
        public var createdAt: Date?

        @OptionalField(key: "updated_at")
        public var updatedAt: Date?

        public init() {}
    }
}
