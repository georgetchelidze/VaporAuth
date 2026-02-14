extension Auth {
    public enum AALLevel: String, Codable, CaseIterable, @unchecked Sendable {
        case aal1 = "aal1"
        case aal2 = "aal2"
        case aal3 = "aal3"
    }

    public enum CodeChallengeMethod: String, Codable, CaseIterable, @unchecked Sendable {
        case s256 = "s256"
        case plain = "plain"
    }

    public enum FactorStatus: String, Codable, CaseIterable, @unchecked Sendable {
        case unverified = "unverified"
        case verified = "verified"
    }

    public enum FactorType: String, Codable, CaseIterable, @unchecked Sendable {
        case totp = "totp"
        case webauthn = "webauthn"
        case phone = "phone"
    }

    public enum OAuthAuthorizationStatus: String, Codable, CaseIterable, @unchecked Sendable {
        case pending = "pending"
        case approved = "approved"
        case denied = "denied"
        case expired = "expired"
    }

    public enum OAuthClientType: String, Codable, CaseIterable, @unchecked Sendable {
        case `public` = "public"
        case confidential = "confidential"
    }

    public enum OAuthRegistrationType: String, Codable, CaseIterable, @unchecked Sendable {
        case dynamic = "dynamic"
        case manual = "manual"
    }

    public enum OAuthResponseType: String, Codable, CaseIterable, @unchecked Sendable {
        case code = "code"
    }

    public enum OneTimeTokenType: String, Codable, CaseIterable, @unchecked Sendable {
        case confirmationToken = "confirmation_token"
        case reauthenticationToken = "reauthentication_token"
        case recoveryToken = "recovery_token"
        case emailChangeTokenNew = "email_change_token_new"
        case emailChangeTokenCurrent = "email_change_token_current"
        case phoneChangeToken = "phone_change_token"
    }

}
