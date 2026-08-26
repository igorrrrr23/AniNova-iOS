import Foundation

enum HTTPMethod: String { case get = "GET", post = "POST" }

enum APIError: LocalizedError, Equatable {
    case invalidURL, transport(String), http(Int), emptyResponse, decoding, server(code: Int)

    var errorDescription: String? {
        switch self {
        case .invalidURL: return "Некорректный адрес сервера."
        case .transport: return "Не удалось подключиться к серверу."
        case .http: return "Сервер вернул ошибку."
        case .emptyResponse: return "Сервер вернул пустой ответ."
        case .decoding: return "Сервер вернул непонятный ответ."
        case .server(let code): return "Ошибка API (код \(code))."
        }
    }
}

protocol TokenProviding: AnyObject { var token: String? { get } }

final class APIClient {
    struct Configuration {
        var baseURL = URL(string: "https://api-s.anixsekai.com")!
        var timeout: TimeInterval = 25
        var userAgent = "AniNova/1.0 (iOS)"
    }

    private let configuration: Configuration
    private let session: URLSession
    private weak var tokenProvider: TokenProviding?
    private let decoder: JSONDecoder

    init(configuration: Configuration = .init(), session: URLSession = .shared, tokenProvider: TokenProviding? = nil) {
        self.configuration = configuration
        self.session = session
        self.tokenProvider = tokenProvider
        decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
    }

    func send<Response: Decodable, Body: Encodable>(
        _ path: String,
        method: HTTPMethod = .get,
        query: [String: String] = [:],
        body: Body? = nil,
        apiV2: Bool = false,
        authenticated: Bool = false
    ) async throws -> Response {
        var components = URLComponents(url: configuration.baseURL.appending(path: path), resolvingAgainstBaseURL: false)
        var items = query.map { URLQueryItem(name: $0.key, value: $0.value) }
        if authenticated, let token = tokenProvider?.token { items.append(URLQueryItem(name: "token", value: token)) }
        components?.queryItems = items.isEmpty ? nil : items
        guard let url = components?.url else { throw APIError.invalidURL }
        var request = URLRequest(url: url, timeoutInterval: configuration.timeout)
        request.httpMethod = method.rawValue
        request.setValue(configuration.userAgent, forHTTPHeaderField: "User-Agent")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        if apiV2 { request.setValue("v2", forHTTPHeaderField: "API-Version") }
        if let body {
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = try JSONEncoder().encode(body)
        }
        return try await perform(request, retryable: method == .get)
    }

    func form<Response: Decodable>(_ path: String, values: [String: String]) async throws -> Response {
        var request = URLRequest(url: configuration.baseURL.appending(path: path), timeoutInterval: configuration.timeout)
        request.httpMethod = HTTPMethod.post.rawValue
        request.setValue(configuration.userAgent, forHTTPHeaderField: "User-Agent")
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.httpBody = values.map { "\($0.key.urlEncoded)=\($0.value.urlEncoded)" }.sorted().joined(separator: "&").data(using: .utf8)
        return try await perform(request, retryable: false)
    }

    private func perform<Response: Decodable>(_ request: URLRequest, retryable: Bool) async throws -> Response {
        for attempt in 0...(retryable ? 1 : 0) {
            do {
                let (data, response) = try await session.data(for: request)
                guard let http = response as? HTTPURLResponse else { throw APIError.transport("invalid response") }
                guard (200..<300).contains(http.statusCode) else { throw APIError.http(http.statusCode) }
                guard !data.isEmpty else { throw APIError.emptyResponse }
                do { return try decoder.decode(Response.self, from: data) }
                catch { throw APIError.decoding }
            } catch let error as APIError {
                if attempt == 1 || !retryable || error != .transport("") { throw error }
            } catch {
                if attempt == 1 || !retryable { throw APIError.transport(error.localizedDescription) }
            }
        }
        throw APIError.transport("retry exhausted")
    }
}

private extension String {
    var urlEncoded: String { addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? self }
}

