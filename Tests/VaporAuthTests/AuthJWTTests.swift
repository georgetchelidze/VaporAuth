@testable import VaporAuth
import JWT
import XCTest

final class AuthJWTTests: XCTestCase {
    func testValidateExpectedClaimsAcceptsMatchingIssuerAndAudience() throws {
        let payload = AuthUserPayload(
            subject: .init(value: UUID().uuidString),
            email: "user@example.com",
            expiration: .init(value: Date().addingTimeInterval(3600)),
            audience: .init(value: ["authenticated"]),
            issuer: .init(value: "https://issuer.example"),
            role: "authenticated"
        )

        XCTAssertNoThrow(
            try payload.validateExpectedClaims(
                expectedIssuer: "https://issuer.example",
                expectedAudience: "authenticated"
            )
        )
    }

    func testValidateExpectedClaimsRejectsIssuerMismatch() {
        let payload = AuthUserPayload(
            subject: .init(value: UUID().uuidString),
            email: nil,
            expiration: .init(value: Date().addingTimeInterval(3600)),
            audience: .init(value: ["authenticated"]),
            issuer: .init(value: "https://issuer.example"),
            role: nil
        )

        XCTAssertThrowsError(
            try payload.validateExpectedClaims(
                expectedIssuer: "https://other.example",
                expectedAudience: "authenticated"
            )
        )
    }

    func testValidateExpectedClaimsRejectsAudienceMismatch() {
        let payload = AuthUserPayload(
            subject: .init(value: UUID().uuidString),
            email: nil,
            expiration: .init(value: Date().addingTimeInterval(3600)),
            audience: .init(value: ["authenticated"]),
            issuer: .init(value: "https://issuer.example"),
            role: nil
        )

        XCTAssertThrowsError(
            try payload.validateExpectedClaims(
                expectedIssuer: "https://issuer.example",
                expectedAudience: "service_role"
            )
        )
    }
}
