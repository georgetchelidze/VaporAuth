import Fluent
import Vapor
import JSONValue

extension Auth {
    public final class AuditLogEntry: Model, @unchecked Sendable {
        public static let schema = "audit_log_entries"
        public static let space: String? = Auth.space

        @ID(custom: "id", generatedBy: .user)
        public var id: UUID?

        @OptionalField(key: "instance_id")
        public var instanceId: UUID?

        @OptionalField(key: "payload")
        public var payload: [String: JSONValue]?

        @OptionalField(key: "created_at")
        public var createdAt: Date?

        @OptionalField(key: "ip_address")
        public var ipAddress: String?

        public init() {}
    }
}
