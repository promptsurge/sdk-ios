import Foundation

struct PromptText: Codable {
    let title: String
    let body: String
    let positiveButton: String
    let negativeButton: String
    let locale: String
}

struct DialogTheme: Codable {
    let backgroundColor: String?
    let textColor: String?
    let positiveButtonColor: String?
    let negativeButtonColor: String?
    let borderRadius: Double?
}

struct PromptResponse: Codable {
    let promptId: String
    let appPromptNumber: Int?
    let text: PromptText
    let theme: DialogTheme?
}

let defaultPromptText = PromptText(
    title: "Enjoying the app?",
    body: "We'd love to hear your feedback! Would you like to leave a quick review?",
    positiveButton: "Sure!",
    negativeButton: "Not now",
    locale: "en"
)
