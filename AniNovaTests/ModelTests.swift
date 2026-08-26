import XCTest
@testable import AniNova

final class ModelTests: XCTestCase {
    func testReleaseDecodesSnakeCaseAndMissingImage() throws {
        let data = #"{"code":0,"release":{"id":101,"title_ru":"Тест","grade":4.5,"image":null}}"#.data(using: .utf8)!
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
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
        XCTAssertEqual(progress.id, "10_3_7")
    }

    func testProgressPercentage() {
        let progress = WatchProgress(releaseID: 1, episodePosition: 1, sourceID: 1, seconds: 50, duration: 100, updatedAt: .now)
        XCTAssertEqual(progress.percentage, 0.5, accuracy: 0.001)
    }

    func testProgressPercentageZeroDuration() {
        let progress = WatchProgress(releaseID: 1, episodePosition: 1, sourceID: 1, seconds: 0, duration: 0, updatedAt: .now)
        XCTAssertEqual(progress.percentage, 0)
    }

    func testBookmarkStatusTitles() {
        XCTAssertEqual(BookmarkStatus.watching.title, "Смотрю")
        XCTAssertEqual(BookmarkStatus.planned.title, "Запланировано")
        XCTAssertEqual(BookmarkStatus.completed.title, "Просмотрено")
        XCTAssertEqual(BookmarkStatus.onHold.title, "Отложено")
        XCTAssertEqual(BookmarkStatus.dropped.title, "Брошено")
    }

    func testBookmarkStatusRawValues() {
        XCTAssertEqual(BookmarkStatus(rawValue: 1), .watching)
        XCTAssertEqual(BookmarkStatus(rawValue: 2), .planned)
        XCTAssertEqual(BookmarkStatus(rawValue: 3), .completed)
        XCTAssertEqual(BookmarkStatus(rawValue: 4), .onHold)
        XCTAssertEqual(BookmarkStatus(rawValue: 5), .dropped)
        XCTAssertNil(BookmarkStatus(rawValue: 99))
    }

    func testReleaseTitleFallback() throws {
        let json = #"{"id":1,"title_ru":null,"title_original":"Original","title_alt":"Alt"}"#
        let data = json.data(using: .utf8)!
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        let release = try decoder.decode(Release.self, from: data)
        XCTAssertEqual(release.title, "Original")
    }

    func testReleaseScreenshotOrImages() throws {
        let json = #"{"id":1,"screenshots":["a.jpg"],"screenshot_images":["b.jpg"]}"#
        let data = json.data(using: .utf8)!
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        let release = try decoder.decode(Release.self, from: data)
        XCTAssertEqual(release.screenshotImagesOrScreenshots, ["b.jpg"])
    }

    func testReleaseScreenshotFallback() throws {
        let json = #"{"id":1,"screenshots":["a.jpg"],"screenshot_images":[]}"#
        let data = json.data(using: .utf8)!
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        let release = try decoder.decode(Release.self, from: data)
        XCTAssertEqual(release.screenshotImagesOrScreenshots, ["a.jpg"])
    }

    func testPageDecoding() throws {
        let json = #"{"code":0,"content":[{"id":1,"title_ru":"Test"}],"totalCount":1,"totalPageCount":1,"currentPage":0}"#
        let data = json.data(using: .utf8)!
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        let page = try decoder.decode(Page<Release>.self, from: data)
        XCTAssertEqual(page.content.count, 1)
        XCTAssertEqual(page.totalCount, 1)
    }

    func testEpisodeIframeDefault() throws {
        let json = #"{"position":1,"url":"http://example.com","iframe":null}"#
        let data = json.data(using: .utf8)!
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        let episode = try decoder.decode(Episode.self, from: data)
        XCTAssertFalse(episode.iframeOrFalse)
    }

    func testProgressStoreSaveAndRetrieve() {
        let store = ProgressStore()
        store.removeAll()
        let progress = WatchProgress(releaseID: 999, episodePosition: 1, sourceID: 1, seconds: 42, duration: 120, updatedAt: .now)
        store.save(progress)
        let retrieved = store.progress(for: 999, episodePosition: 1, sourceID: 1)
        XCTAssertNotNil(retrieved)
        XCTAssertEqual(retrieved?.seconds, 42)
        store.removeAll()
    }

    func testProgressStoreDuplicateReplacement() {
        let store = ProgressStore()
        store.removeAll()
        let p1 = WatchProgress(releaseID: 100, episodePosition: 1, sourceID: 1, seconds: 10, duration: 100, updatedAt: .now)
        store.save(p1)
        let p2 = WatchProgress(releaseID: 100, episodePosition: 1, sourceID: 1, seconds: 50, duration: 100, updatedAt: .now)
        store.save(p2)
        let all = store.all().filter { $0.releaseID == 100 }
        XCTAssertEqual(all.count, 1)
        XCTAssertEqual(all.first?.seconds, 50)
        store.removeAll()
    }

    // MARK: - VideoFormat detection

    func testVideoFormatHLS() {
        XCTAssertEqual(VideoFormat.detect(from: "https://example.com/video.m3u8", iframe: false), .hls)
        XCTAssertEqual(VideoFormat.detect(from: "https://cdn.hls.example.com/manifest", iframe: false), .hls)
    }

    func testVideoFormatMP4() {
        XCTAssertEqual(VideoFormat.detect(from: "https://example.com/video.mp4", iframe: false), .mp4)
        XCTAssertEqual(VideoFormat.detect(from: "https://googlevideo.com/videoplayback", iframe: false), .mp4)
    }

    func testVideoFormatIframe() {
        XCTAssertEqual(VideoFormat.detect(from: "https://example.com/embed", iframe: true), .iframe)
    }

    func testVideoFormatUnknown() {
        XCTAssertEqual(VideoFormat.detect(from: "https://example.com/video", iframe: false), .unknown)
    }

    func testVideoFormatPlayableByAVPlayer() {
        XCTAssertTrue(VideoFormat.hls.playableByAVPlayer)
        XCTAssertTrue(VideoFormat.mp4.playableByAVPlayer)
        XCTAssertFalse(VideoFormat.iframe.playableByAVPlayer)
        XCTAssertFalse(VideoFormat.unknown.playableByAVPlayer)
    }

    // MARK: - Episode playable state

    func testEpisodeIsPlayable() {
        let ep = Episode(position: 1, name: nil, url: "https://example.com/video.m3u8", iframe: false, isWatched: false, source: SourceReference(id: 1), addedDate: nil, isFilter: nil)
        XCTAssertTrue(ep.isPlayable)
        XCTAssertTrue(ep.videoFormat == .hls)
    }

    func testEpisodeIsNotPlayableIframe() {
        let ep = Episode(position: 1, name: nil, url: "https://example.com/embed", iframe: true, isWatched: false, source: SourceReference(id: 1), addedDate: nil, isFilter: nil)
        XCTAssertFalse(ep.isPlayable)
    }

    func testEpisodeIsNotPlayableNoURL() {
        let ep = Episode(position: 1, name: nil, url: nil, iframe: false, isWatched: false, source: nil, addedDate: nil, isFilter: nil)
        XCTAssertFalse(ep.isPlayable)
    }

    // MARK: - SourceReference dual decoding

    func testSourceReferenceDecodesFromInt() throws {
        let json = #"{"position":1,"url":"http://x.com/v.mp4","iframe":false,"source":42}"#
        let data = json.data(using: .utf8)!
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        let episode = try decoder.decode(Episode.self, from: data)
        XCTAssertEqual(episode.source?.id, 42)
    }

    func testSourceReferenceDecodesFromObject() throws {
        let json = #"{"position":1,"url":"http://x.com/v.mp4","iframe":false,"source":{"id":42,"name":"Kodik","episode_count":12,"quality":720}}"#
        let data = json.data(using: .utf8)!
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        let episode = try decoder.decode(Episode.self, from: data)
        XCTAssertEqual(episode.source?.id, 42)
        XCTAssertEqual(episode.source?.name, "Kodik")
        XCTAssertEqual(episode.source?.quality, 720)
    }

    // MARK: - Dubber optional fields

    func testDubberDecodesWithOptionalFields() throws {
        let json = #"{"id":1,"name":"AniLibria","episode_count":24,"quality":1080,"icon":"icon.png","workers":"Worker1","is_sub":true,"pinned":true,"view_count":500}"#
        let data = json.data(using: .utf8)!
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        let dubber = try decoder.decode(Dubber.self, from: data)
        XCTAssertEqual(dubber.name, "AniLibria")
        XCTAssertEqual(dubber.isSub, true)
        XCTAssertEqual(dubber.pinned, true)
        XCTAssertEqual(dubber.workers, "Worker1")
    }

    func testDubberDecodesMinimal() throws {
        let json = #"{"id":1,"name":"Test"}"#
        let data = json.data(using: .utf8)!
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        let dubber = try decoder.decode(Dubber.self, from: data)
        XCTAssertEqual(dubber.name, "Test")
        XCTAssertNil(dubber.isSub)
        XCTAssertNil(dubber.pinned)
    }

    // MARK: - Full episode chain decoding

    func testEpisodesResponseDecoding() throws {
        let json = #"{"code":0,"episodes":[{"position":1,"name":"Episode 1","url":"https://example.com/v.m3u8","iframe":false,"is_watched":false,"source":5},{"position":2,"name":"Episode 2","url":"https://example.com/embed","iframe":true,"is_watched":true,"source":5}]}"#
        let data = json.data(using: .utf8)!
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        let response = try decoder.decode(EpisodesResponse.self, from: data)
        XCTAssertEqual(response.episodes.count, 2)
        XCTAssertTrue(response.episodes[0].isPlayable)
        XCTAssertFalse(response.episodes[1].isPlayable)
    }

    func testSourcesResponseDecoding() throws {
        let json = #"{"code":0,"sources":[{"id":5,"name":"Sibnet","episode_count":24,"quality":720}]}"#
        let data = json.data(using: .utf8)!
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        let response = try decoder.decode(SourcesResponse.self, from: data)
        XCTAssertEqual(response.sources.count, 1)
        XCTAssertEqual(response.sources[0].name, "Sibnet")
    }

    func testDubberTypesResponseDecoding() throws {
        let json = #"{"code":0,"types":[{"id":1,"name":"AniLibria","episode_count":24}]}"#
        let data = json.data(using: .utf8)!
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        let response = try decoder.decode(EpisodeTypesResponse.self, from: data)
        XCTAssertEqual(response.types.count, 1)
        XCTAssertEqual(response.types[0].name, "AniLibria")
    }
}
