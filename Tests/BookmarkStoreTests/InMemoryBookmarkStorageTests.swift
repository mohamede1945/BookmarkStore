import Testing

@testable import BookmarkStore

@Suite struct InMemoryBookmarkStorageTests {
  @Test func bookmarkStoreRoundTrip() async throws {
    try await verifyBookmarkStoreRoundTrip(self.makeHarness())
  }

  @Test func bookmarkStoreRemoveBookmark() async throws {
    try await verifyBookmarkStoreRemoveBookmark(self.makeHarness())
  }

  @Test func bookmarkStoreRemoveAllBookmarks() async throws {
    try await verifyBookmarkStoreRemoveAllBookmarks(self.makeHarness())
  }

  @Test func bookmarkStoreRefreshesStaleBookmarks() async throws {
    try await verifyBookmarkStoreRefreshesStaleBookmarks(self.makeHarness())
  }

  @Test func bookmarkStoreCanResolveStaleBookmarkWithoutRefreshing() async throws {
    try await verifyBookmarkStoreCanResolveStaleBookmarkWithoutRefreshing(self.makeHarness())
  }

  @Test func bookmarkStoreCanRefreshAfterPreviousStaleReadWithoutRefresh() async throws {
    try await verifyBookmarkStoreCanRefreshAfterPreviousStaleReadWithoutRefresh(self.makeHarness())
  }

  private func makeHarness() -> BookmarkStoreHarness {
    BookmarkStoreHarness(
      store: BookmarkStore(storageBackend: InMemoryBookmarkStorage()),
      cleanup: {}
    )
  }
}
