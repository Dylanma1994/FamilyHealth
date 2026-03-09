import Foundation

/// Base API client for remote mode
actor APIClient {
    private let baseURL: String
    private var token: String?

    init(baseURL: String) {
        self.baseURL = baseURL.hasSuffix("/") ? String(baseURL.dropLast()) : baseURL
        self.token = KeychainManager.getAuthToken()
    }

    func setToken(_ token: String) {
        self.token = token
        try? KeychainManager.saveAuthToken(token)
    }

    private let encoder: JSONEncoder = {
        let e = JSONEncoder()
        e.dateEncodingStrategy = .iso8601
        return e
    }()

    private let decoder: JSONDecoder = {
        let d = JSONDecoder()
        d.dateDecodingStrategy = .iso8601
        return d
    }()

    // MARK: - Execute

    func request<T: Decodable>(
        _ method: String,
        _ path: String,
        body: Encodable? = nil,
        query: [String: String] = [:]
    ) async throws -> T {
        var components = URLComponents(string: baseURL + path)!
        if !query.isEmpty {
            components.queryItems = query.map { URLQueryItem(name: $0.key, value: $0.value) }
        }

        var request = URLRequest(url: components.url!)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if let token { request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization") }
        if let body { request.httpBody = try encoder.encode(body) }

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let http = response as? HTTPURLResponse else {
            throw RemoteError.invalidResponse
        }

        if http.statusCode == 401 {
            throw RemoteError.unauthorized
        }

        guard (200...299).contains(http.statusCode) else {
            if let errorBody = try? decoder.decode(ErrorBody.self, from: data) {
                throw RemoteError.serverError(errorBody.error)
            }
            throw RemoteError.httpError(http.statusCode)
        }

        return try decoder.decode(T.self, from: data)
    }

    func get<T: Decodable>(_ path: String, query: [String: String] = [:]) async throws -> T {
        try await request("GET", path, query: query)
    }

    func post<T: Decodable>(_ path: String, body: Encodable? = nil) async throws -> T {
        try await request("POST", path, body: body)
    }

    func put<T: Decodable>(_ path: String, body: Encodable? = nil) async throws -> T {
        try await request("PUT", path, body: body)
    }

    func delete(_ path: String) async throws {
        let _: EmptyResponse = try await request("DELETE", path)
    }
}

struct ErrorBody: Decodable { let error: String }
struct EmptyResponse: Decodable {}

enum RemoteError: LocalizedError {
    case invalidResponse
    case unauthorized
    case httpError(Int)
    case serverError(String)

    var errorDescription: String? {
        switch self {
        case .invalidResponse: return "无效的服务器响应"
        case .unauthorized: return "登录已过期，请重新登录"
        case .httpError(let code): return "HTTP 错误: \(code)"
        case .serverError(let msg): return msg
        }
    }
}
