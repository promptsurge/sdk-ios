import Foundation

final class HoldoutManager {
    private static let prefsKey = "ps_holdout"
    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    // Returns true once and persists; 10% of devices are in holdout.
    var isHoldout: Bool {
        if let stored = defaults.object(forKey: Self.prefsKey) as? Bool {
            return stored
        }
        let assigned = Double.random(in: 0..<1) < 0.10
        defaults.set(assigned, forKey: Self.prefsKey)
        return assigned
    }
}
