import Fluent
import Vapor

extension Auth {
    public final class SAMLProvider: Model, @unchecked Sendable {
        public static let schema = "saml_providers"
        public static let space: String? = Auth.space

        @ID(custom: "id", generatedBy: .user)
        public var id: UUID?

        @OptionalField(key: "sso_provider_id")
        public var ssoProviderId: UUID?

        @OptionalField(key: "entity_id")
        public var entityId: String?

        @OptionalField(key: "metadata_xml")
        public var metadataXml: String?

        @OptionalField(key: "metadata_url")
        public var metadataUrl: String?

        @OptionalField(key: "attribute_mapping")
        public var attributeMapping: [String: DynamicJSON]?

        @OptionalField(key: "created_at")
        public var createdAt: Date?

        @OptionalField(key: "updated_at")
        public var updatedAt: Date?

        @OptionalField(key: "name_id_format")
        public var nameIdFormat: String?

        public init() {}
    }
}
