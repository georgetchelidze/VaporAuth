@testable import VaporAuth
import XCTest

final class PasswordGrantRateLimiterTests: XCTestCase {
    func testRateLimiterBlocksAfterConfiguredAttempts() async {
        let limiter = PasswordGrantRateLimiter()
        let options = PasswordGrantRateLimitOptions(maxAttempts: 2, windowSeconds: 60, blockSeconds: 300)
        let now = Date()
        let keys = ["ip:127.0.0.1"]

        let initiallyBlocked = await limiter.isBlocked(keys: keys, now: now, options: options)
        XCTAssertFalse(initiallyBlocked)

        await limiter.recordFailure(keys: keys, now: now, options: options)
        let blockedAfterOneFailure = await limiter.isBlocked(keys: keys, now: now, options: options)
        XCTAssertFalse(blockedAfterOneFailure)

        await limiter.recordFailure(keys: keys, now: now, options: options)
        let blockedAfterTwoFailures = await limiter.isBlocked(keys: keys, now: now, options: options)
        XCTAssertTrue(blockedAfterTwoFailures)
    }

    func testRateLimiterUnblocksAfterBlockWindow() async {
        let limiter = PasswordGrantRateLimiter()
        let options = PasswordGrantRateLimitOptions(maxAttempts: 1, windowSeconds: 60, blockSeconds: 30)
        let now = Date()
        let keys = ["ip:127.0.0.1"]

        await limiter.recordFailure(keys: keys, now: now, options: options)
        let blockedAtStart = await limiter.isBlocked(keys: keys, now: now, options: options)
        XCTAssertTrue(blockedAtStart)

        let blockedAfterWindow = await limiter.isBlocked(
            keys: keys,
            now: now.addingTimeInterval(31),
            options: options
        )
        XCTAssertFalse(blockedAfterWindow)
    }

    func testRateLimiterRecordSuccessClearsState() async {
        let limiter = PasswordGrantRateLimiter()
        let options = PasswordGrantRateLimitOptions(maxAttempts: 1, windowSeconds: 60, blockSeconds: 300)
        let now = Date()
        let keys = ["ip:127.0.0.1", "email:user@example.com"]

        await limiter.recordFailure(keys: keys, now: now, options: options)
        let blockedAfterFailure = await limiter.isBlocked(keys: keys, now: now, options: options)
        XCTAssertTrue(blockedAfterFailure)

        await limiter.recordSuccess(keys: keys)
        let blockedAfterSuccess = await limiter.isBlocked(keys: keys, now: now, options: options)
        XCTAssertFalse(blockedAfterSuccess)
    }
}
