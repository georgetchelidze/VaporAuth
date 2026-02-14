import Fluent
import Vapor

extension Auth {
    public final class SSODomain: Model, Content, @unchecked Sendable {
        public static let schema = "sso_domains"
        public static let space: String? = Auth.space

        @ID(custom: "id", generatedBy: .user)
        public var id: UUID?

        @OptionalField(key: "sso_provider_id")
        public var ssoProviderId: UUID?

        @OptionalField(key: "domain")
        public var domain: String?

        @OptionalField(key: "created_at")
        public var createdAt: Date?

        @OptionalField(key: "updated_at")
        public var updatedAt: Date?

        public init() {}
    }
}
