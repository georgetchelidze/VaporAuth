import Fluent
import Vapor
import JSONValue

extension Auth {
    public final class MFAFactor: Model, @unchecked Sendable {
        public static let schema = "mfa_factors"
        public static let space: String? = Auth.space

        @ID(custom: "id", generatedBy: .user)
        public var id: UUID?

        @OptionalField(key: "user_id")
        public var userId: UUID?

        @OptionalField(key: "friendly_name")
        public var friendlyName: String?

        @OptionalEnum(key: "factor_type")
        public var factorType: Auth.FactorType?

        @OptionalEnum(key: "status")
        public var status: Auth.FactorStatus?

        @OptionalField(key: "created_at")
        public var createdAt: Date?

        @OptionalField(key: "updated_at")
        public var updatedAt: Date?

        @OptionalField(key: "secret")
        public var secret: String?

        @OptionalField(key: "phone")
        public var phone: String?

        @OptionalField(key: "last_challenged_at")
        public var lastChallengedAt: Date?

        @OptionalField(key: "web_authn_credential")
        public var webAuthnCredential: [String: JSONValue]?

        @OptionalField(key: "web_authn_aaguid")
        public var webAuthnAaguid: UUID?

        @OptionalField(key: "last_webauthn_challenge_data")
        public var lastWebauthnChallengeData: [String: JSONValue]?

        public init() {}
    }
}
