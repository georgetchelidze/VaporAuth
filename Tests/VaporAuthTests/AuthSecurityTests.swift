@testable import VaporAuth
import XCTest

final class AuthSecurityTests: XCTestCase {
    func testPasswordGrantEligibilityRequiresConfirmationWhenConfigured() {
        let now = Date()
        let user = Auth.User()
        user.deletedAt = nil
        user.bannedUntil = nil
        user.confirmedAt = nil
        user.emailConfirmedAt = nil

        XCTAssertFalse(
            isUserEligibleForPasswordGrant(
                user,
                now: now,
                confirmationPolicy: .requireConfirmedEmail
            )
        )

        user.confirmedAt = now
        XCTAssertTrue(
            isUserEligibleForPasswordGrant(
                user,
                now: now,
                confirmationPolicy: .requireConfirmedEmail
            )
        )
    }

    func testPasswordGrantEligibilityRejectsDeletedAndBannedUsers() {
        let now = Date()
        let user = Auth.User()
        user.confirmedAt = now

        user.deletedAt = now
        XCTAssertFalse(
            isUserEligibleForPasswordGrant(
                user,
                now: now,
                confirmationPolicy: .none
            )
        )

        user.deletedAt = nil
        user.bannedUntil = now.addingTimeInterval(60)
        XCTAssertFalse(
            isUserEligibleForPasswordGrant(
                user,
                now: now,
                confirmationPolicy: .none
            )
        )

        user.bannedUntil = now.addingTimeInterval(-60)
        XCTAssertTrue(
            isUserEligibleForPasswordGrant(
                user,
                now: now,
                confirmationPolicy: .none
            )
        )
    }

    func testSessionExpiryDateFallsBackToCreatedAtPlusLifetime() {
        let now = Date()
        let session = Auth.Session()
        session.createdAt = now

        let computed = sessionExpiryDate(for: session, fallbackLifetimeSeconds: 120)
        XCTAssertNotNil(computed)
        XCTAssertEqual(
            computed?.timeIntervalSinceReferenceDate ?? 0,
            now.addingTimeInterval(120).timeIntervalSinceReferenceDate,
            accuracy: 0.001
        )

        session.notAfter = now.addingTimeInterval(30)
        let explicit = sessionExpiryDate(for: session, fallbackLifetimeSeconds: 120)
        XCTAssertNotNil(explicit)
        XCTAssertEqual(
            explicit?.timeIntervalSinceReferenceDate ?? 0,
            now.addingTimeInterval(30).timeIntervalSinceReferenceDate,
            accuracy: 0.001
        )
    }

    func testPasswordGrantRateLimitKeysNormalizeEmailAndIP() {
        let keys = passwordGrantRateLimitKeys(ipAddress: " 127.0.0.1 ", email: "USER@EXAMPLE.COM")
        XCTAssertEqual(keys, [
            "ip:127.0.0.1",
            "email:user@example.com",
            "ip_email:127.0.0.1:user@example.com"
        ])
    }
}
