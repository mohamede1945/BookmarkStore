import Foundation
import Testing

@testable import BookmarkStore

struct BookmarkManagerStorageHarness {
  let manager: BookmarkManager
  let cleanup: () -> Void
}

func verifyBookmarkManagerRoundTrip(_ harness: BookmarkManagerStorageHarness) async throws {
  defer { harness.cleanup() }

  let file = try TemporaryFile("book.txt", contents: Data("test".utf8))

  try await harness.manager.upsertBookmark(targetFileURL: file.fileURL, for: "book")

  let restored = try await harness.manager.resolvedBookmark(for: "book")
  let keys = try await harness.manager.bookmarkKeys()

  #expect(restored?.url.standardizedFileURL == file.fileURL.standardizedFileURL)
  #expect(restored?.isStale == false)
  #expect(keys.map { $0.rawValue } == ["book"])
}

func verifyBookmarkManagerRemoveBookmark(_ harness: BookmarkManagerStorageHarness) async throws {
  defer { harness.cleanup() }

  let file = try TemporaryFile("book.txt", contents: Data("test".utf8))

  try await harness.manager.upsertBookmark(targetFileURL: file.fileURL, for: "book")
  try await harness.manager.removeBookmark(for: "book")

  let restored = try await harness.manager.resolvedBookmark(for: "book")
  let keys = try await harness.manager.bookmarkKeys()

  #expect(restored == nil)
  #expect(keys.isEmpty)
}

func verifyBookmarkManagerRemoveAllBookmarks(_ harness: BookmarkManagerStorageHarness) async throws {
  defer { harness.cleanup() }

  let file1 = try TemporaryFile("book1.txt", contents: Data("test1".utf8))
  let file2 = try TemporaryFile("book2.txt", contents: Data("test2".utf8))

  try await harness.manager.upsertBookmark(targetFileURL: file1.fileURL, for: "book1")
  try await harness.manager.upsertBookmark(targetFileURL: file2.fileURL, for: "book2")
  try await harness.manager.removeAllBookmarks()

  let keys = try await harness.manager.bookmarkKeys()
  let book1 = try await harness.manager.resolvedBookmark(for: "book1")
  let book2 = try await harness.manager.resolvedBookmark(for: "book2")

  #expect(keys.isEmpty)
  #expect(book1 == nil)
  #expect(book2 == nil)
}

func verifyBookmarkManagerRefreshesStaleBookmarks(_ harness: BookmarkManagerStorageHarness) async throws {
  defer { harness.cleanup() }

  let originalFile = try TemporaryFile("book.txt", contents: Data("test".utf8))
  let originalURL = originalFile.fileURL.standardizedFileURL
  try await harness.manager.upsertBookmark(targetFileURL: originalURL, for: "book")

  let movedURL = originalURL
    .deletingLastPathComponent()
    .appendingPathComponent("renamed-\(UUID().uuidString).txt")
  try FileManager.default.moveItem(at: originalURL, to: movedURL)

  let resolved = try await harness.manager.resolvedBookmark(for: "book")
  let stored = try await harness.manager.resolvedBookmark(for: "book", refreshIfStale: false)

  #expect(resolved?.url.standardizedFileURL == movedURL.standardizedFileURL)
  #expect(resolved?.isStale == false)
  #expect(stored?.url.standardizedFileURL == movedURL.standardizedFileURL)
  #expect(stored?.isStale == false)
}

func verifyBookmarkManagerCanResolveStaleBookmarkWithoutRefreshing(
  _ harness: BookmarkManagerStorageHarness
) async throws {
  defer { harness.cleanup() }

  let originalFile = try TemporaryFile("book.txt", contents: Data("test".utf8))
  let originalURL = originalFile.fileURL.standardizedFileURL
  try await harness.manager.upsertBookmark(targetFileURL: originalURL, for: "book")

  let movedURL = originalURL
    .deletingLastPathComponent()
    .appendingPathComponent("renamed-\(UUID().uuidString).txt")
  try FileManager.default.moveItem(at: originalURL, to: movedURL)

  let firstResolved = try await harness.manager.resolvedBookmark(for: "book", refreshIfStale: false)
  let secondResolved = try await harness.manager.resolvedBookmark(for: "book", refreshIfStale: false)

  #expect(firstResolved?.url.standardizedFileURL == movedURL.standardizedFileURL)
  #expect(firstResolved?.isStale == true)
  #expect(secondResolved?.url.standardizedFileURL == movedURL.standardizedFileURL)
  #expect(secondResolved?.isStale == true)
}

func verifyBookmarkManagerCanRefreshAfterPreviousStaleReadWithoutRefresh(
  _ harness: BookmarkManagerStorageHarness
) async throws {
  defer { harness.cleanup() }

  let originalFile = try TemporaryFile("book.txt", contents: Data("test".utf8))
  let originalURL = originalFile.fileURL.standardizedFileURL
  try await harness.manager.upsertBookmark(targetFileURL: originalURL, for: "book")

  let movedURL = originalURL
    .deletingLastPathComponent()
    .appendingPathComponent("renamed-\(UUID().uuidString).txt")
  try FileManager.default.moveItem(at: originalURL, to: movedURL)

  let staleResolved = try await harness.manager.resolvedBookmark(for: "book", refreshIfStale: false)
  let refreshed = try await harness.manager.resolvedBookmark(for: "book", refreshIfStale: true)
  let persisted = try await harness.manager.resolvedBookmark(for: "book", refreshIfStale: false)

  #expect(staleResolved?.url.standardizedFileURL == movedURL.standardizedFileURL)
  #expect(staleResolved?.isStale == true)
  #expect(refreshed?.url.standardizedFileURL == movedURL.standardizedFileURL)
  #expect(refreshed?.isStale == false)
  #expect(persisted?.url.standardizedFileURL == movedURL.standardizedFileURL)
  #expect(persisted?.isStale == false)
}

func makeTemporaryDirectoryURL() throws -> URL {
  let directoryURL = try FileManager.default.url(
    for: .itemReplacementDirectory,
    in: .userDomainMask,
    appropriateFor: URL(fileURLWithPath: NSTemporaryDirectory()),
    create: true
  )
  .appendingPathComponent(ProcessInfo.processInfo.globallyUniqueString, isDirectory: true)

  try FileManager.default.createDirectory(at: directoryURL, withIntermediateDirectories: true)
  return directoryURL
}
