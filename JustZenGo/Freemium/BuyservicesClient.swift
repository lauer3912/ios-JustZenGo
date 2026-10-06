//
//  BuyservicesClient.swift
//  JustZenGo
//
//  Freemium-first Buyservices-web client (credits.techidaily.com)
//  Aligned with TechIDaily Western-First & Freemium Standards
//

import Foundation

actor BuyservicesClient {
    let baseURL: URL
    let appId: String
    let appSecret: String

    init(baseURL: URL = URL(string: "https://credits.techidaily.com")!,
         appId: String = "com.ggsheng.JustZen",
         appSecret: String = "client_guest_token") {
        self.baseURL = baseURL
        self.appId = appId
        self.appSecret = appSecret
    }

    struct FreeTier {
        let creditsOnRegister = 100
        let signinDaily = 10
        let signinWeekly = 50
        let signinStreak = 100
        let vipLevelAuto = 1
        let vipModeAuto = "quota"
    }

    static let freeTier = FreeTier()

    private var cache: [String: (timestamp: Date, value: Any)] = [:]
    private let positiveTTL: TimeInterval = 300
    private let negativeTTL: TimeInterval = 60

    private func getCached<T: Any>(_ key: String, ttl: TimeInterval) -> T? {
        guard let entry = cache[key] else { return nil }
        let elapsed = Date().timeIntervalSince(entry.timestamp)
        return elapsed < ttl ? entry.value as? T : nil
    }

    private func setCached(_ key: String, value: Any) {
        cache[key] = (Date(), value)
    }

    func purchaseCredits(amount: Int, priceCents: Int) async throws -> Order {
        let reqBody = PurchaseCreditsRequest(
            app_id: appId,
            product_id: "credits-\(amount)",
            amount: amount,
            price_cents: priceCents,
            provider: "paypal"
        )
        let body = try JSONEncoder().encode(reqBody)
        return try await request("/api/v1/orders", method: "POST", body: body)
    }

    func purchaseSubscription(productId: String) async throws -> Order {
        let reqBody = PurchaseSubscriptionRequest(
            app_id: appId,
            product_id: productId,
            provider: "paypal"
        )
        let body = try JSONEncoder().encode(reqBody)
        return try await request("/api/v1/orders", method: "POST", body: body)
    }

    func subscribeVIP(level: Int) async throws -> Subscription {
        let reqBody = SubscribeVIPRequest(
            app_id: appId,
            vip_level: level
        )
        let body = try JSONEncoder().encode(reqBody)
        return try await request("/api/v1/vip/subscribe", method: "POST", body: body)
    }

    func setUserOpenAIKey(_ key: String) async throws {
        let reqBody = SetOpenAIKeyRequest(api_key: key)
        let body = try JSONEncoder().encode(reqBody)
        let _: EmptyResponse = try await request("/api/v1/user/openai-key", method: "PUT", body: body)
    }

    func getEntitlements(userId: String) async throws -> Entitlements {
        return try await request("/api/v1/entitlements?user_id=\(userId)", method: "GET")
    }

    func verifyLicense(_ license: String) async throws -> LicenseInfo {
        let reqBody = VerifyLicenseRequest(license: license)
        let body = try JSONEncoder().encode(reqBody)
        return try await request("/api/v1/licenses/verify", method: "POST", body: body)
    }

    private func request<T: Decodable>(_ path: String, method: String, body: Data? = nil) async throws -> T {
        let url = baseURL.appendingPathComponent(path)
        var req = URLRequest(url: url)
        req.httpMethod = method
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.setValue("Bearer \(appSecret)", forHTTPHeaderField: "Authorization")
        req.httpBody = body

        let (data, response) = try await URLSession.shared.data(for: req)
        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            throw BuyservicesError.httpError
        }
        return try JSONDecoder().decode(T.self, from: data)
    }
}

private struct PurchaseCreditsRequest: Encodable {
    let app_id: String
    let product_id: String
    let amount: Int
    let price_cents: Int
    let provider: String
}

private struct PurchaseSubscriptionRequest: Encodable {
    let app_id: String
    let product_id: String
    let provider: String
}

private struct SubscribeVIPRequest: Encodable {
    let app_id: String
    let vip_level: Int
}

private struct SetOpenAIKeyRequest: Encodable {
    let api_key: String
}

private struct VerifyLicenseRequest: Encodable {
    let license: String
}

struct Order: Codable {
    let orderId: String
    let approvalUrl: String?

    enum CodingKeys: String, CodingKey {
        case orderId = "order_id"
        case approvalUrl = "approval_url"
    }
}

struct Subscription: Codable {
    let subscriptionId: String
    let vipLevel: Int

    enum CodingKeys: String, CodingKey {
        case subscriptionId = "subscription_id"
        case vipLevel = "vip_level"
    }
}

struct Entitlements: Codable {
    let credits: Int
    let vipLevel: Int
    let subscriptions: [Subscription]

    enum CodingKeys: String, CodingKey {
        case credits
        case vipLevel = "vip_level"
        case subscriptions
    }
}

struct LicenseInfo: Codable {
    let valid: Bool
    let userId: String?
    let expiresAt: Date?

    enum CodingKeys: String, CodingKey {
        case valid
        case userId = "user_id"
        case expiresAt = "expires_at"
    }
}

struct EmptyResponse: Codable {}

enum BuyservicesError: Error {
    case httpError
}
