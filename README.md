# PromptSurge iOS SDK

Swift Package Manager SDK for iOS 14+. Shows a pre-prompt dialog before triggering `SKStoreReviewController`, increasing review tap-through rates.

## Installation

In Xcode: **File → Add Package Dependencies**, paste your repo URL, select the `PromptSurge` product.

Or in `Package.swift`:
```swift
.package(url: "https://github.com/promptsurge/sdk-ios.git", from: "1.0.0")
```

## Usage

```swift
// AppDelegate / @main
import PromptSurge

PromptSurge.initialize(apiKey: "ps_live_xxxx")

// At a natural moment (level complete, purchase success, etc.)
PromptSurge.requestReview(in: self) // self = UIViewController
```

## Behaviour

- **Holdout group:** 10% of devices are silently skipped (control group for measuring lift). Assignment is random and persists for the device's lifetime.
- **Rate limiting:** After a "shown" event, the dialog won't reappear for 90 days. After a dismiss, 7 days.
- **Impression limit:** When your plan's monthly cap is reached the API returns `402`. The SDK stores this flag in `UserDefaults` and on the next `requestReview()` call suppresses the dialog and fires `SKStoreReviewController` directly. Clears automatically when the next billing period begins.
- **Fallback:** If the API is unreachable, a bundled English default prompt is shown.
- **No sentiment gating:** Both buttons lead to `SKStoreReviewController` — required for Apple App Store Review guideline 5.6.1 compliance.

## Requirements

- iOS 14+
- Xcode 14+
