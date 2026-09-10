import Foundation

enum APIConfiguration {
    static let defaultModel = "gpt-4o"
    static let visionModel = "gpt-4o"

    static var apiKey: String {
        ProcessInfo.processInfo.environment["THINKNOTES_API_KEY"]
            ?? UserDefaults.standard.string(forKey: "thinknotes_api_key")
            ?? ""
    }

    static var isConfigured: Bool {
        !apiKey.isEmpty
    }

    static func saveAPIKey(_ key: String) {
        UserDefaults.standard.set(key, forKey: "thinknotes_api_key")
    }
}

struct OpenAIChatRequest: Encodable {
    struct Message: Encodable {
        struct ContentPart: Encodable {
            let type: String
            let text: String?
            let image_url: ImageURL?

            struct ImageURL: Encodable {
                let url: String
            }

            static func text(_ value: String) -> ContentPart {
                ContentPart(type: "text", text: value, image_url: nil)
            }

            static func image(base64PNG: String) -> ContentPart {
                ContentPart(
                    type: "image_url",
                    text: nil,
                    image_url: ImageURL(url: "data:image/png;base64,\(base64PNG)")
                )
            }
        }

        let role: String
        let content: [ContentPart]
    }

    let model: String
    let messages: [Message]
    let temperature: Double
    let max_tokens: Int
}

struct OpenAIChatResponse: Decodable {
    struct Choice: Decodable {
        struct Message: Decodable {
            let content: String?
        }
        let message: Message
    }
    let choices: [Choice]
}

enum AIServiceError: LocalizedError {
    case notConfigured
    case invalidResponse
    case network(String)

    var errorDescription: String? {
        switch self {
        case .notConfigured:
            return "Add your API key in Settings to enable the thinking assistant."
        case .invalidResponse:
            return "The assistant returned an unexpected response."
        case .network(let message):
            return message
        }
    }
}
