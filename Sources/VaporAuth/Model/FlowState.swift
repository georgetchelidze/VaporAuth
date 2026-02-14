import Fluent
import Vapor

extension Auth {
    public final class FlowState: Model, @unchecked Sendable {
        public static let schema = "flow_state"
        public static let space: String? = Auth.space

        @ID(custom: "id", generatedBy: .user)
        public var id: UUID?

        @OptionalField(key: "user_id")
        public var userId: UUID?

        @OptionalField(key: "auth_code")
        public var authCode: String?

        @OptionalEnum(key: "code_challenge_method")
        public var codeChallengeMethod: Auth.CodeChallengeMethod?

        @OptionalField(key: "code_challenge")
        public var codeChallenge: String?

        @OptionalField(key: "provider_type")
        public var providerType: String?

        @OptionalField(key: "provider_access_token")
        public var providerAccessToken: String?

        @OptionalField(key: "provider_refresh_token")
        public var providerRefreshToken: String?

        @OptionalField(key: "created_at")
        public var createdAt: Date?

        @OptionalField(key: "updated_at")
        public var updatedAt: Date?

        @OptionalField(key: "authentication_method")
        public var authenticationMethod: String?

        @OptionalField(key: "auth_code_issued_at")
        public var authCodeIssuedAt: Date?

        public init() {}
    }
}
