import Foundation

final class PromptTextRepository {
    private static let cacheKey = "ps_cached_prompt"
    private static let cacheExpiry: TimeInterval = 6 * 3600
    private static let impressionLimitKey = "ps_impression_limit_exceeded"

    private let apiKey: String
    private let apiBaseUrl: String
    private let defaults: UserDefaults
    private let session: URLSession

    init(apiKey: String, apiBaseUrl: String, defaults: UserDefaults = .standard) {
        self.apiKey = apiKey
        self.apiBaseUrl = apiBaseUrl
        self.defaults = defaults
        self.session = URLSession(configuration: .ephemeral)
    }

    var isImpressionLimitExceeded: Bool {
        defaults.bool(forKey: Self.impressionLimitKey)
    }

    func fetch(completion: @escaping (PromptResponse?) -> Void) {
        if let cached = loadCache() {
            completion(cached)
            fetchAndCache { _ in }
            return
        }
        fetchAndCache(completion: completion)
    }

    private func fetchAndCache(completion: @escaping (PromptResponse?) -> Void) {
        guard let url = URL(string: "\(apiBaseUrl)/v1/prompts") else {
            completion(nil)
            return
        }
        var req = URLRequest(url: url)
        req.setValue(apiKey, forHTTPHeaderField: "X-PromptSurge-Key")
        req.setValue(Locale.current.identifier, forHTTPHeaderField: "Accept-Language")

        session.dataTask(with: req) { [weak self] data, response, _ in
            let statusCode = (response as? HTTPURLResponse)?.statusCode
            if statusCode == 402 {
                self?.defaults.set(true, forKey: Self.impressionLimitKey)
                completion(nil)
                return
            }
            guard let data = data,
                  let apiResp = try? JSONDecoder().decode(APIPromptResponse.self, from: data) else {
                completion(nil)
                return
            }
            let mapped = mapAPIResponse(apiResp)
            self?.defaults.set(false, forKey: Self.impressionLimitKey)
            self?.saveCache(mapped)
            completion(mapped)
        }.resume()
    }

    private func loadCache() -> PromptResponse? {
        guard let data = defaults.data(forKey: Self.cacheKey),
              let wrapper = try? JSONDecoder().decode(CacheWrapper.self, from: data),
              Date().timeIntervalSince(wrapper.savedAt) < Self.cacheExpiry else { return nil }
        return wrapper.response
    }

    private func saveCache(_ response: PromptResponse) {
        let wrapper = CacheWrapper(response: response, savedAt: Date())
        if let data = try? JSONEncoder().encode(wrapper) {
            defaults.set(data, forKey: Self.cacheKey)
        }
    }

    private struct CacheWrapper: Codable {
        let response: PromptResponse
        let savedAt: Date
    }
}
