import Foundation
import Testing

@testable import BookmarkStore

@Suite struct UserDefaultsBookmarkStorageTests {
  @Test func bookmarkManagerRoundTrip() async throws {
    let (manager, suiteName) = try self.makeManager()
    defer { UserDefaults(suiteName: suiteName)?.removePersistentDomain(forName: suiteName) }
    let file = try TemporaryFile("book.txt", contents: Data("test".utf8))

    try await manager.upsertBookmark(targetFileURL: file.fileURL, for: "book")

    let restored = try await manager.resolvedBookmark(for: "book")
    let keys = try await manager.bookmarkKeys()

    #expect(restored?.url.standardizedFileURL == file.fileURL.standardizedFileURL)
    #expect(restored?.isStale == false)
    #expect(keys.map { $0.rawValue } == ["book"])
  }

  @Test func bookmarkManagerRemoveBookmark() async throws {
    let (manager, suiteName) = try self.makeManager()
    defer { UserDefaults(suiteName: suiteName)?.removePersistentDomain(forName: suiteName) }
    let file = try TemporaryFile("book.txt", contents: Data("test".utf8))

    try await manager.upsertBookmark(targetFileURL: file.fileURL, for: "book")
    try await manager.removeBookmark(for: "book")

    let restored = try await manager.resolvedBookmark(for: "book")
    let keys = try await manager.bookmarkKeys()
    #expect(restored == nil)
    #expect(keys.isEmpty)
  }

  @Test func bookmarkManagerRemoveAllBookmarks() async throws {
    let (manager, suiteName) = try self.makeManager()
    defer { UserDefaults(suiteName: suiteName)?.removePersistentDomain(forName: suiteName) }
    let file1 = try TemporaryFile("book1.txt", contents: Data("test1".utf8))
    let file2 = try TemporaryFile("book2.txt", contents: Data("test2".utf8))

    try await manager.upsertBookmark(targetFileURL: file1.fileURL, for: "book1")
    try await manager.upsertBookmark(targetFileURL: file2.fileURL, for: "book2")

    try await manager.removeAllBookmarks()

    let keys = try await manager.bookmarkKeys()
    let book1 = try await manager.resolvedBookmark(for: "book1")
    let book2 = try await manager.resolvedBookmark(for: "book2")
    #expect(keys.isEmpty)
    #expect(book1 == nil)
    #expect(book2 == nil)
  }

  @Test func bookmarkManagerRefreshesStaleBookmarks() async throws {
    let (manager, suiteName) = try self.makeManager()
    defer { UserDefaults(suiteName: suiteName)?.removePersistentDomain(forName: suiteName) }
    let originalFile = try TemporaryFile("book.txt", contents: Data("test".utf8))
    let originalURL = originalFile.fileURL.standardizedFileURL
    try await manager.upsertBookmark(targetFileURL: originalURL, for: "book")

    let movedURL =
      originalURL
      .deletingLastPathComponent()
      .appendingPathComponent("renamed-book.txt")
    try FileManager.default.moveItem(at: originalURL, to: movedURL)

    let resolved = try await manager.resolvedBookmark(for: "book")
    let stored = try await manager.resolvedBookmark(for: "book", refreshIfStale: false)

    #expect(resolved?.url.standardizedFileURL == movedURL)
    #expect(resolved?.isStale == false)
    #expect(stored?.url.standardizedFileURL == movedURL)
    #expect(stored?.isStale == false)
  }

  @Test func bookmarkManagerCanResolveStaleBookmarkWithoutRefreshing() async throws {
    let (manager, suiteName) = try self.makeManager()
    defer { UserDefaults(suiteName: suiteName)?.removePersistentDomain(forName: suiteName) }
    let originalFile = try TemporaryFile("book.txt", contents: Data("test".utf8))
    let originalURL = originalFile.fileURL.standardizedFileURL
    try await manager.upsertBookmark(targetFileURL: originalURL, for: "book")

    let movedURL =
      originalURL
      .deletingLastPathComponent()
      .appendingPathComponent("renamed-book.txt")
    try FileManager.default.moveItem(at: originalURL, to: movedURL)

    let firstResolved = try await manager.resolvedBookmark(for: "book", refreshIfStale: false)
    let secondResolved = try await manager.resolvedBookmark(for: "book", refreshIfStale: false)

    #expect(firstResolved?.url.standardizedFileURL == movedURL)
    #expect(firstResolved?.isStale == true)
    #expect(secondResolved?.url.standardizedFileURL == movedURL)
    #expect(secondResolved?.isStale == true)
  }

  @Test func bookmarkManagerCanRefreshAfterPreviousStaleReadWithoutRefresh() async throws {
    let (manager, suiteName) = try self.makeManager()
    defer { UserDefaults(suiteName: suiteName)?.removePersistentDomain(forName: suiteName) }
    let originalFile = try TemporaryFile("book.txt", contents: Data("test".utf8))
    let originalURL = originalFile.fileURL.standardizedFileURL
    try await manager.upsertBookmark(targetFileURL: originalURL, for: "book")

    let movedURL =
      originalURL
      .deletingLastPathComponent()
      .appendingPathComponent("renamed-book.txt")
    try FileManager.default.moveItem(at: originalURL, to: movedURL)

    let staleResolved = try await manager.resolvedBookmark(for: "book", refreshIfStale: false)
    let refreshed = try await manager.resolvedBookmark(for: "book", refreshIfStale: true)
    let persisted = try await manager.resolvedBookmark(for: "book", refreshIfStale: false)

    #expect(staleResolved?.url.standardizedFileURL == movedURL)
    #expect(staleResolved?.isStale == true)
    #expect(refreshed?.url.standardizedFileURL == movedURL)
    #expect(refreshed?.isStale == false)
    #expect(persisted?.url.standardizedFileURL == movedURL)
    #expect(persisted?.isStale == false)
  }

  func makeManager() throws -> (BookmarkManager, String) {
    let suiteName = "BookmarkStoreTests.\(UUID().uuidString)"
    let userDefaults = try #require(UserDefaults(suiteName: suiteName))
    let storage = UserDefaultsBookmarkStorage(userDefaults: userDefaults, keyPrefix: "test.")
    return (BookmarkManager(storage: storage), suiteName)
  }
}
