import Foundation
import Testing

@testable import BookmarkStore

@Suite struct DirectoryBookmarkStorageTests {
  @Test func bookmarkStoreRoundTrip() async throws {
    try await verifyBookmarkStoreRoundTrip(try self.makeHarness())
  }

  @Test func bookmarkStoreRemoveBookmark() async throws {
    try await verifyBookmarkStoreRemoveBookmark(try self.makeHarness())
  }

  @Test func bookmarkStoreRemoveAllBookmarks() async throws {
    try await verifyBookmarkStoreRemoveAllBookmarks(try self.makeHarness())
  }

  @Test func bookmarkStoreRefreshesStaleBookmarks() async throws {
    try await verifyBookmarkStoreRefreshesStaleBookmarks(try self.makeHarness())
  }

  @Test func bookmarkStoreCanResolveStaleBookmarkWithoutRefreshing() async throws {
    try await verifyBookmarkStoreCanResolveStaleBookmarkWithoutRefreshing(try self.makeHarness())
  }

  @Test func bookmarkStoreCanRefreshAfterPreviousStaleReadWithoutRefresh() async throws {
    try await verifyBookmarkStoreCanRefreshAfterPreviousStaleReadWithoutRefresh(try self.makeHarness())
  }

  private func makeHarness() throws -> BookmarkStoreHarness {
    let directoryURL = try makeTemporaryDirectoryURL()
    let storageBackend = DirectoryBookmarkStorage(directoryURL: directoryURL)

    return BookmarkStoreHarness(
      store: BookmarkStore(storageBackend: storageBackend),
      cleanup: { try? FileManager.default.removeItem(at: directoryURL) }
    )
  }
}
