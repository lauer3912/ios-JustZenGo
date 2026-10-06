//
//  HuggingFaceClient.swift
//  JustZenGo
//
//  Free HF API client for mindfulness reflections
//

import Foundation

actor HuggingFaceClient {
    let apiKey: String
    let baseURL = URL(string: "https://api-inference.huggingface.co/models/")!
    static let defaultModel = "mistralai/Mistral-7B-Instruct-v0.2"

    private var cache: [String: (timestamp: Date, value: Any)] = [:]
    private let positiveTTL: TimeInterval = 300
    private let negativeTTL: TimeInterval = 60

    init(apiKey: String = "hf_public_tier_guest") {
        self.apiKey = apiKey
    }

    func chat(model: String = defaultModel, messages: [ChatMessage]) async throws -> String {
        let cacheKey = "chat:\(model):\(messages.hashValue)"

        if let cached: String = getCached(cacheKey, ttl: positiveTTL) {
            return cached
        }

        let url = baseURL.appendingPathComponent(model)
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: Any] = [
            "inputs": messages.map { ["role": $0.role, "content": $0.content] },
            "parameters": [
                "max_new_tokens": 512,
                "temperature": 0.7,
                "top_p": 0.95,
                "return_full_text": false
            ]
        ]
        req.httpBody = try JSONSerialization.data(withJSONObject: body)

        do {
            let (data, response) = try await URLSession.shared.data(for: req)
            guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
                setCached(cacheKey, value: "")
                throw HuggingFaceError.httpError
            }

            let result = try JSONDecoder().decode([HFResponse].self, from: data)
            let text = result.first?.generatedText ?? ""
            setCached(cacheKey, value: text)
            return text
        } catch {
            setCached(cacheKey, value: "")
            throw error
        }
    }

    private func getCached<T: Any>(_ key: String, ttl: TimeInterval) -> T? {
        guard let entry = cache[key] else { return nil }
        let elapsed = Date().timeIntervalSince(entry.timestamp)
        return elapsed < ttl ? entry.value as? T : nil
    }

    private func setCached(_ key: String, value: Any) {
        cache[key] = (Date(), value)
    }
}

struct ChatMessage: Codable, Hashable {
    let role: String
    let content: String
}

struct HFResponse: Codable {
    let generatedText: String

    enum CodingKeys: String, CodingKey {
        case generatedText = "generated_text"
    }
}

enum HuggingFaceError: Error {
    case httpError
    case coldStart
}
