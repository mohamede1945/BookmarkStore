import Testing

@testable import BookmarkStore

@Suite struct FileBookmarkStorageTests {
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
    let file = try TemporaryFile(prefix: "bookmark-store", fileExtension: "json")
    let storageBackend = FileBookmarkStorage(fileURL: file.fileURL)

    return BookmarkStoreHarness(
      store: BookmarkStore(storageBackend: storageBackend),
      cleanup: { try? file.remove() }
    )
  }
}
