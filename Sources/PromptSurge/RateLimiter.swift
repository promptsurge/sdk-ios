import Foundation

final class RateLimiter {
    private static let shownKey = "ps_last_shown_at"
    private static let dismissedKey = "ps_last_dismissed_at"

    private static let shownCooldown: TimeInterval = 90 * 24 * 3600
    private static let dismissedCooldown: TimeInterval = 7 * 24 * 3600

    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    var canShow: Bool {
        let now = Date()
        if let shown = defaults.object(forKey: Self.shownKey) as? Date,
           now.timeIntervalSince(shown) < Self.shownCooldown {
            return false
        }
        if let dismissed = defaults.object(forKey: Self.dismissedKey) as? Date,
           now.timeIntervalSince(dismissed) < Self.dismissedCooldown {
            return false
        }
        return true
    }

    func recordShown() {
        defaults.set(Date(), forKey: Self.shownKey)
    }

    func recordDismissed() {
        defaults.set(Date(), forKey: Self.dismissedKey)
    }
}
