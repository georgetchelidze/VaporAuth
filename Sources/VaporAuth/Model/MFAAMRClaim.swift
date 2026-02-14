import Fluent
import Vapor

extension Auth {
    public final class MFAAMRClaim: Model, Content, @unchecked Sendable {
        public static let schema = "mfa_amr_claims"
        public static let space: String? = Auth.space

        @ID(custom: "id", generatedBy: .user)
        public var id: UUID?

        @OptionalField(key: "session_id")
        public var sessionId: UUID?

        @OptionalField(key: "created_at")
        public var createdAt: Date?

        @OptionalField(key: "updated_at")
        public var updatedAt: Date?

        @OptionalField(key: "authentication_method")
        public var authenticationMethod: String?

        public init() {}
    }
}
