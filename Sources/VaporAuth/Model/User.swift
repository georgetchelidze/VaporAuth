import Fluent
import Vapor

extension Auth {
    public final class User: Model, @unchecked Sendable {
        public static let schema = "users"
        public static let space: String? = Auth.space

        @ID(custom: "id", generatedBy: .user)
        public var id: UUID?

        @OptionalField(key: "instance_id")
        public var instanceId: UUID?

        @OptionalField(key: "aud")
        public var aud: String?

        @OptionalField(key: "role")
        public var role: String?

        @OptionalField(key: "email")
        public var email: String?

        @OptionalField(key: "encrypted_password")
        public var encryptedPassword: String?

        @OptionalField(key: "email_confirmed_at")
        public var emailConfirmedAt: Date?

        @OptionalField(key: "invited_at")
        public var invitedAt: Date?

        @OptionalField(key: "confirmation_token")
        public var confirmationToken: String?

        @OptionalField(key: "confirmation_sent_at")
        public var confirmationSentAt: Date?

        @OptionalField(key: "recovery_token")
        public var recoveryToken: String?

        @OptionalField(key: "recovery_sent_at")
        public var recoverySentAt: Date?

        @OptionalField(key: "email_change_token_new")
        public var emailChangeTokenNew: String?

        @OptionalField(key: "email_change")
        public var emailChange: String?

        @OptionalField(key: "email_change_sent_at")
        public var emailChangeSentAt: Date?

        @OptionalField(key: "last_sign_in_at")
        public var lastSignInAt: Date?

        @OptionalField(key: "raw_app_meta_data")
        public var rawAppMetaData: [String: DynamicJSON]?

        @OptionalField(key: "raw_user_meta_data")
        public var rawUserMetaData: [String: DynamicJSON]?

        @OptionalField(key: "is_super_admin")
        public var isSuperAdmin: Bool?

        @OptionalField(key: "created_at")
        public var createdAt: Date?

        @OptionalField(key: "updated_at")
        public var updatedAt: Date?

        @OptionalField(key: "phone")
        public var phone: String?

        @OptionalField(key: "phone_confirmed_at")
        public var phoneConfirmedAt: Date?

        @OptionalField(key: "phone_change")
        public var phoneChange: String?

        @OptionalField(key: "phone_change_token")
        public var phoneChangeToken: String?

        @OptionalField(key: "phone_change_sent_at")
        public var phoneChangeSentAt: Date?

        @OptionalField(key: "confirmed_at")
        public var confirmedAt: Date?

        @OptionalField(key: "email_change_token_current")
        public var emailChangeTokenCurrent: String?

        @OptionalField(key: "email_change_confirm_status")
        public var emailChangeConfirmStatus: Int16?

        @OptionalField(key: "banned_until")
        public var bannedUntil: Date?

        @OptionalField(key: "reauthentication_token")
        public var reauthenticationToken: String?

        @OptionalField(key: "reauthentication_sent_at")
        public var reauthenticationSentAt: Date?

        @OptionalField(key: "is_sso_user")
        public var isSsoUser: Bool?

        @OptionalField(key: "deleted_at")
        public var deletedAt: Date?

        @OptionalField(key: "is_anonymous")
        public var isAnonymous: Bool?

        public init() {}
    }
}
