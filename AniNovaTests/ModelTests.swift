import XCTest
@testable import AniNova

final class ModelTests: XCTestCase {
    func testReleaseDecodesSnakeCaseAndMissingImage() throws {
        let data = #"{"code":0,"release":{"id":101,"title_ru":"Тест","grade":4.5,"image":null}}"#.data(using: .utf8)!
        let decoder = JSONDecoder(); decoder.keyDecodingStrategy = .convertFromSnakeCase
        let response = try decoder.decode(ReleaseResponse.self, from: data)
        XCTAssertEqual(response.release?.title, "Тест")
        XCTAssertNil(response.release?.artworkURL)
    }
    func testExpiredTokenCodeIsRepresentable() throws {
        let response = try JSONDecoder().decode(APIResponse.self, from: #"{"code":401}"#.data(using: .utf8)!)
        XCTAssertEqual(response.code, 401)
    }
    func testProgressUsesStableCompositeIdentity() {
        let progress = WatchProgress(releaseID: 10, episodePosition: 3, sourceID: 7, seconds: 20, duration: 100, updatedAt: .now)
        XCTAssertEqual(progress.id, "10-3-7")
    }
}

