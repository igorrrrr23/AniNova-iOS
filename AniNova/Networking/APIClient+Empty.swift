import Foundation

private struct EmptyAPIBody: Encodable {}

extension APIClient {
    func sendEmpty<Response: Decodable>(_ path: String, method: HTTPMethod = .get, query: [String: String] = [:], apiV2: Bool = false, authenticated: Bool = false) async throws -> Response {
        try await send(path, method: method, query: query, body: Optional<EmptyAPIBody>.none, apiV2: apiV2, authenticated: authenticated)
    }
}

