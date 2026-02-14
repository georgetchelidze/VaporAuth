import Vapor

public enum AuthConfirmationPolicy: Sendable {
    case none
    case requireConfirmedEmail
}

public struct PasswordGrantRateLimitOptions: Sendable {
    public var maxAttempts: Int
    public var windowSeconds: Int
    public var blockSeconds: Int

    public init(maxAttempts: Int = 10, windowSeconds: Int = 60, blockSeconds: Int = 300) {
        self.maxAttempts = maxAttempts
        self.windowSeconds = windowSeconds
        self.blockSeconds = blockSeconds
    }

    public var isEnabled: Bool {
        maxAttempts > 0 && windowSeconds > 0 && blockSeconds > 0
    }
}

actor PasswordGrantRateLimiter {
    private struct Bucket {
        var attempts: [Date] = []
        var blockedUntil: Date?
    }

    private var buckets: [String: Bucket] = [:]

    func isBlocked(keys: [String], now: Date, options: PasswordGrantRateLimitOptions) -> Bool {
        guard options.isEnabled else {
            return false
        }

        var blocked = false
        for key in keys {
            var bucket = buckets[key] ?? Bucket()
            prune(&bucket, now: now, windowSeconds: options.windowSeconds)
            if let blockedUntil = bucket.blockedUntil,
               blockedUntil > now {
                blocked = true
            }
            persist(bucket, forKey: key)
        }

        return blocked
    }

    func recordFailure(keys: [String], now: Date, options: PasswordGrantRateLimitOptions) {
        guard options.isEnabled else {
            return
        }

        for key in keys {
            var bucket = buckets[key] ?? Bucket()
            prune(&bucket, now: now, windowSeconds: options.windowSeconds)

            if let blockedUntil = bucket.blockedUntil,
               blockedUntil > now {
                persist(bucket, forKey: key)
                continue
            }

            bucket.attempts.append(now)
            if bucket.attempts.count >= options.maxAttempts {
                bucket.blockedUntil = now.addingTimeInterval(TimeInterval(options.blockSeconds))
                bucket.attempts.removeAll(keepingCapacity: true)
            }

            persist(bucket, forKey: key)
        }
    }

    func recordSuccess(keys: [String]) {
        for key in keys {
            buckets.removeValue(forKey: key)
        }
    }

    private func prune(_ bucket: inout Bucket, now: Date, windowSeconds: Int) {
        if let blockedUntil = bucket.blockedUntil,
           blockedUntil <= now {
            bucket.blockedUntil = nil
        }

        let cutoff = now.addingTimeInterval(-TimeInterval(windowSeconds))
        bucket.attempts.removeAll { $0 < cutoff }
    }

    private func persist(_ bucket: Bucket, forKey key: String) {
        if bucket.attempts.isEmpty,
           bucket.blockedUntil == nil {
            buckets.removeValue(forKey: key)
        } else {
            buckets[key] = bucket
        }
    }
}

private struct PasswordGrantRateLimiterKey: StorageKey {
    typealias Value = PasswordGrantRateLimiter
}

extension Application {
    var vaporAuthPasswordGrantRateLimiter: PasswordGrantRateLimiter {
        if let existing = storage[PasswordGrantRateLimiterKey.self] {
            return existing
        }

        let created = PasswordGrantRateLimiter()
        storage[PasswordGrantRateLimiterKey.self] = created
        return created
    }
}

func passwordGrantRateLimitKeys(ipAddress: String?, email: String) -> [String] {
    let normalizedIP = ipAddress?.trimmingCharacters(in: .whitespacesAndNewlines)
        .lowercased()
        .nilIfEmpty ?? "unknown"
    let normalizedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
        .lowercased()

    return [
        "ip:\(normalizedIP)",
        "email:\(normalizedEmail)",
        "ip_email:\(normalizedIP):\(normalizedEmail)"
    ]
}

func isUserEligibleForPasswordGrant(_ user: Auth.User, now: Date, confirmationPolicy: AuthConfirmationPolicy) -> Bool {
    guard isUserActiveForSessionIssuance(user, now: now) else {
        return false
    }

    switch confirmationPolicy {
    case .none:
        return true
    case .requireConfirmedEmail:
        return user.confirmedAt != nil || user.emailConfirmedAt != nil
    }
}

func isUserActiveForSessionIssuance(_ user: Auth.User, now: Date) -> Bool {
    if user.deletedAt != nil {
        return false
    }

    if let bannedUntil = user.bannedUntil,
       bannedUntil > now {
        return false
    }

    return true
}

func sessionExpiryDate(for session: Auth.Session, fallbackLifetimeSeconds: Int?) -> Date? {
    if let notAfter = session.notAfter {
        return notAfter
    }

    guard let fallbackLifetimeSeconds,
          fallbackLifetimeSeconds > 0,
          let createdAt = session.createdAt
    else {
        return nil
    }

    return createdAt.addingTimeInterval(TimeInterval(fallbackLifetimeSeconds))
}

private extension String {
    var nilIfEmpty: String? {
        isEmpty ? nil : self
    }
}
