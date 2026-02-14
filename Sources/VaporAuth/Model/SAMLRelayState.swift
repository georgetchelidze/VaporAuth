import Fluent
import Vapor

extension Auth {
    public final class SAMLRelayState: Model, @unchecked Sendable {
        public static let schema = "saml_relay_states"
        public static let space: String? = Auth.space

        @ID(custom: "id", generatedBy: .user)
        public var id: UUID?

        @OptionalField(key: "sso_provider_id")
        public var ssoProviderId: UUID?

        @OptionalField(key: "request_id")
        public var requestId: String?

        @OptionalField(key: "for_email")
        public var forEmail: String?

        @OptionalField(key: "redirect_to")
        public var redirectTo: String?

        @OptionalField(key: "created_at")
        public var createdAt: Date?

        @OptionalField(key: "updated_at")
        public var updatedAt: Date?

        @OptionalField(key: "flow_state_id")
        public var flowStateId: UUID?

        public init() {}
    }
}
