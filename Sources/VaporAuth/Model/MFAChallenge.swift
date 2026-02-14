import Fluent
import Vapor

extension Auth {
    public final class MFAChallenge: Model, Content, @unchecked Sendable {
        public static let schema = "mfa_challenges"
        public static let space: String? = Auth.space

        @ID(custom: "id", generatedBy: .user)
        public var id: UUID?

        @OptionalField(key: "factor_id")
        public var factorId: UUID?

        @OptionalField(key: "created_at")
        public var createdAt: Date?

        @OptionalField(key: "verified_at")
        public var verifiedAt: Date?

        @OptionalField(key: "ip_address")
        public var ipAddress: String?

        @OptionalField(key: "otp_code")
        public var otpCode: String?

        @OptionalField(key: "web_authn_session_data")
        public var webAuthnSessionData: [String: DynamicJSON]?

        public init() {}
    }
}
