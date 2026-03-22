import XCTest

@testable import BookmarkStore

final class UserDefaultsBookmarkStorageTests: XCTestCase {
  private var manager: BookmarkManager!
  private var userDefaults: UserDefaults!
  private var suiteName: String!

  override func setUpWithError() throws {
    try super.setUpWithError()
    self.suiteName = "BookmarkStoreTests.\(UUID().uuidString)"
    self.userDefaults = try XCTUnwrap(UserDefaults(suiteName: self.suiteName))
    let storage = UserDefaultsBookmarkStorage(userDefaults: self.userDefaults, keyPrefix: "test.")
    self.manager = BookmarkManager(storage: storage)
  }

  override func tearDownWithError() throws {
    if let userDefaults = self.userDefaults, let suiteName = self.suiteName {
      userDefaults.removePersistentDomain(forName: suiteName)
    }
    self.manager = nil
    self.userDefaults = nil
    self.suiteName = nil
    try super.tearDownWithError()
  }

  func testBookmarkManagerRoundTrip() async throws {
    let file = try XCTTemporaryFile("book.txt", contents: Data("test".utf8))

    try await self.manager.upsertBookmark(targetFileURL: file.fileURL, for: "book")

    let restored = try await self.manager.resolvedBookmark(for: "book")
    let keys = try await self.manager.bookmarkKeys()

    XCTAssertEqual(restored?.url.standardizedFileURL, file.fileURL.standardizedFileURL)
    XCTAssertEqual(restored?.isStale, false)
    XCTAssertEqual(keys.map(\.rawValue), ["book"])
  }

  func testBookmarkManagerRemoveBookmark() async throws {
    let file = try XCTTemporaryFile("book.txt", contents: Data("test".utf8))

    try await self.manager.upsertBookmark(targetFileURL: file.fileURL, for: "book")
    try await self.manager.removeBookmark(for: "book")

    let restored = try await self.manager.resolvedBookmark(for: "book")
    let keys = try await self.manager.bookmarkKeys()
    XCTAssertNil(restored)
    XCTAssertEqual(keys, [])
  }

  func testBookmarkManagerRemoveAllBookmarks() async throws {
    let file1 = try XCTTemporaryFile("book1.txt", contents: Data("test1".utf8))
    let file2 = try XCTTemporaryFile("book2.txt", contents: Data("test2".utf8))

    try await self.manager.upsertBookmark(targetFileURL: file1.fileURL, for: "book1")
    try await self.manager.upsertBookmark(targetFileURL: file2.fileURL, for: "book2")

    try await self.manager.removeAllBookmarks()

    let keys = try await self.manager.bookmarkKeys()
    let book1 = try await self.manager.resolvedBookmark(for: "book1")
    let book2 = try await self.manager.resolvedBookmark(for: "book2")
    XCTAssertEqual(keys, [])
    XCTAssertNil(book1)
    XCTAssertNil(book2)
  }

  func testBookmarkManagerRefreshesStaleBookmarks() async throws {
    let originalFile = try XCTTemporaryFile("book.txt", contents: Data("test".utf8))
    let originalURL = originalFile.fileURL.standardizedFileURL
    try await self.manager.upsertBookmark(targetFileURL: originalURL, for: "book")

    let movedURL = originalURL
      .deletingLastPathComponent()
      .appendingPathComponent("renamed-book.txt")
    try FileManager.default.moveItem(at: originalURL, to: movedURL)

    let resolved = try await self.manager.resolvedBookmark(for: "book")
    let stored = try await self.manager.resolvedBookmark(for: "book", refreshIfStale: false)

    XCTAssertEqual(resolved?.url.standardizedFileURL, movedURL)
    XCTAssertEqual(resolved?.isStale, false)
    XCTAssertEqual(stored?.url.standardizedFileURL, movedURL)
    XCTAssertEqual(stored?.isStale, false)
  }

  func testBookmarkManagerCanResolveStaleBookmarkWithoutRefreshing() async throws {
    let originalFile = try XCTTemporaryFile("book.txt", contents: Data("test".utf8))
    let originalURL = originalFile.fileURL.standardizedFileURL
    try await self.manager.upsertBookmark(targetFileURL: originalURL, for: "book")

    let movedURL = originalURL
      .deletingLastPathComponent()
      .appendingPathComponent("renamed-book.txt")
    try FileManager.default.moveItem(at: originalURL, to: movedURL)

    let firstResolved = try await self.manager.resolvedBookmark(for: "book", refreshIfStale: false)
    let secondResolved = try await self.manager.resolvedBookmark(for: "book", refreshIfStale: false)

    XCTAssertEqual(firstResolved?.url.standardizedFileURL, movedURL)
    XCTAssertEqual(firstResolved?.isStale, true)
    XCTAssertEqual(secondResolved?.url.standardizedFileURL, movedURL)
    XCTAssertEqual(secondResolved?.isStale, true)
  }

  func testBookmarkManagerCanRefreshAfterPreviousStaleReadWithoutRefresh() async throws {
    let originalFile = try XCTTemporaryFile("book.txt", contents: Data("test".utf8))
    let originalURL = originalFile.fileURL.standardizedFileURL
    try await self.manager.upsertBookmark(targetFileURL: originalURL, for: "book")

    let movedURL = originalURL
      .deletingLastPathComponent()
      .appendingPathComponent("renamed-book.txt")
    try FileManager.default.moveItem(at: originalURL, to: movedURL)

    let staleResolved = try await self.manager.resolvedBookmark(for: "book", refreshIfStale: false)
    let refreshed = try await self.manager.resolvedBookmark(for: "book", refreshIfStale: true)
    let persisted = try await self.manager.resolvedBookmark(for: "book", refreshIfStale: false)

    XCTAssertEqual(staleResolved?.url.standardizedFileURL, movedURL)
    XCTAssertEqual(staleResolved?.isStale, true)
    XCTAssertEqual(refreshed?.url.standardizedFileURL, movedURL)
    XCTAssertEqual(refreshed?.isStale, false)
    XCTAssertEqual(persisted?.url.standardizedFileURL, movedURL)
    XCTAssertEqual(persisted?.isStale, false)
  }

}
