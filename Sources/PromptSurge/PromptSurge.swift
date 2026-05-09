import UIKit

/// Entry point for the PromptSurge iOS SDK.
///
/// Call `initialize(apiKey:)` once at app launch, then call `requestReview(in:)`
/// at a natural moment in the user journey (e.g. after completing a level or purchase).
public final class PromptSurge {
    private static var shared: PromptSurge?

    private let repository: PromptTextRepository
    private let telemetry: Telemetry
    private let rateLimiter: RateLimiter
    private let holdoutManager: HoldoutManager

    private init(apiKey: String, apiBaseUrl: String) {
        let holdout = HoldoutManager()
        self.holdoutManager = holdout
        self.repository = PromptTextRepository(apiKey: apiKey, apiBaseUrl: apiBaseUrl)
        self.telemetry = Telemetry(apiKey: apiKey, apiBaseUrl: apiBaseUrl, holdoutManager: holdout)
        self.rateLimiter = RateLimiter()
    }

    // MARK: - Public API

    public static func initialize(apiKey: String, apiBaseUrl: String = "https://api.promptsurge.me") {
        shared = PromptSurge(apiKey: apiKey, apiBaseUrl: apiBaseUrl)
    }

    /// Presents the pre-prompt dialog from `viewController` if rate limits and holdout allow.
    /// Does nothing (silently) if `initialize` has not been called.
    public static func requestReview(in viewController: UIViewController) {
        shared?.showDialog(from: viewController)
    }

    // MARK: - Internal

    private func showDialog(from presenter: UIViewController) {
        guard !holdoutManager.isHoldout, rateLimiter.canShow else { return }

        repository.fetch { [weak self] response in
            DispatchQueue.main.async {
                guard let self else { return }

                let effectiveResponse = response ?? PromptResponse(
                    promptId: "default",
                    appPromptNumber: nil,
                    text: defaultPromptText,
                    theme: nil
                )

                let vc = PrePromptViewController(
                    promptResponse: effectiveResponse,
                    onAccept: { [weak self] in
                        guard let self else { return }
                        self.rateLimiter.recordShown()
                        self.telemetry.send(
                            eventType: EventTypes.prePromptAccepted,
                            payload: self.promptPayload(effectiveResponse)
                        )
                        self.telemetry.send(eventType: EventTypes.reviewRequested)
                    },
                    onDismiss: { [weak self] in
                        guard let self else { return }
                        self.rateLimiter.recordDismissed()
                        self.telemetry.send(
                            eventType: EventTypes.prePromptDismissed,
                            payload: self.promptPayload(effectiveResponse)
                        )
                    }
                )

                // Fire shown event once before presenting.
                self.rateLimiter.recordShown()
                self.telemetry.send(
                    eventType: EventTypes.prePromptShown,
                    payload: self.promptPayload(effectiveResponse)
                )

                presenter.present(vc, animated: true)
            }
        }
    }

    private func promptPayload(_ response: PromptResponse) -> [String: String] {
        var payload: [String: String] = ["promptId": response.promptId]
        if let n = response.appPromptNumber {
            payload["servedPromptNumber"] = String(n)
        }
        return payload
    }
}
