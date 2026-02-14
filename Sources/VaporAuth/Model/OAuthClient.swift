import Fluent
import Vapor

extension Auth {
    public final class OAuthClient: Model, @unchecked Sendable {
        public static let schema = "oauth_clients"
        public static let space: String? = Auth.space

        @ID(custom: "id", generatedBy: .user)
        public var id: UUID?

        @OptionalField(key: "client_secret_hash")
        public var clientSecretHash: String?

        @OptionalEnum(key: "registration_type")
        public var registrationType: Auth.OAuthRegistrationType?

        @OptionalField(key: "redirect_uris")
        public var redirectUris: String?

        @OptionalField(key: "grant_types")
        public var grantTypes: String?

        @OptionalField(key: "client_name")
        public var clientName: String?

        @OptionalField(key: "client_uri")
        public var clientUri: String?

        @OptionalField(key: "logo_uri")
        public var logoUri: String?

        @OptionalField(key: "created_at")
        public var createdAt: Date?

        @OptionalField(key: "updated_at")
        public var updatedAt: Date?

        @OptionalField(key: "deleted_at")
        public var deletedAt: Date?

        @OptionalEnum(key: "client_type")
        public var clientType: Auth.OAuthClientType?

        public init() {}
    }
}
