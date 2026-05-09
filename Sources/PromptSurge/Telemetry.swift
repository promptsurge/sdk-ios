import Foundation
import CryptoKit
import UIKit

struct EventDto: Encodable {
    let eventType: String
    let eventId: String
    let timestamp: String
    let sessionId: String
    let deviceId: String
    let appVersion: String
    let sdkVersion: String
    let locale: String
    let platform: String
    let holdout: Bool
    let payload: [String: String]
}

final class Telemetry {
    static let sdkVersion = "1.0.0"
    private static let platform = "ios"

    private let apiKey: String
    private let apiBaseUrl: String
    private let sessionId: String
    private let holdoutManager: HoldoutManager
    private let session: URLSession

    init(apiKey: String, apiBaseUrl: String, holdoutManager: HoldoutManager) {
        self.apiKey = apiKey
        self.apiBaseUrl = apiBaseUrl
        self.sessionId = UUID().uuidString
        self.holdoutManager = holdoutManager
        self.session = URLSession(configuration: .ephemeral)
    }

    func send(eventType: String, payload: [String: String] = [:]) {
        let dto = EventDto(
            eventType: eventType,
            eventId: UUID().uuidString,
            timestamp: ISO8601DateFormatter().string(from: Date()),
            sessionId: sessionId,
            deviceId: deviceId(),
            appVersion: appVersion(),
            sdkVersion: Self.sdkVersion,
            locale: Locale.current.identifier,
            platform: Self.platform,
            holdout: holdoutManager.isHoldout,
            payload: payload
        )

        guard let url = URL(string: "\(apiBaseUrl)/v1/events"),
              let body = try? JSONEncoder().encode(dto) else { return }

        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.httpBody = body

        session.dataTask(with: req).resume()
    }

    // SHA-256(vendorId + bundleId) → stable, non-reversible device fingerprint.
    private func deviceId() -> String {
        let vendorId = UIDevice.current.identifierForVendor?.uuidString ?? "unknown"
        let bundleId = Bundle.main.bundleIdentifier ?? "unknown"
        let raw = vendorId + bundleId
        let digest = SHA256.hash(data: Data(raw.utf8))
        return digest.map { String(format: "%02x", $0) }.joined()
    }

    private func appVersion() -> String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "unknown"
    }
}
