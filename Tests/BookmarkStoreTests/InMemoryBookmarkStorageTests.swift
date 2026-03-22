import Testing

@testable import BookmarkStore

@Suite struct InMemoryBookmarkStorageTests {
  @Test func bookmarkManagerRoundTrip() async throws {
    try await verifyBookmarkManagerRoundTrip(self.makeHarness())
  }

  @Test func bookmarkManagerRemoveBookmark() async throws {
    try await verifyBookmarkManagerRemoveBookmark(self.makeHarness())
  }

  @Test func bookmarkManagerRemoveAllBookmarks() async throws {
    try await verifyBookmarkManagerRemoveAllBookmarks(self.makeHarness())
  }

  @Test func bookmarkManagerRefreshesStaleBookmarks() async throws {
    try await verifyBookmarkManagerRefreshesStaleBookmarks(self.makeHarness())
  }

  @Test func bookmarkManagerCanResolveStaleBookmarkWithoutRefreshing() async throws {
    try await verifyBookmarkManagerCanResolveStaleBookmarkWithoutRefreshing(self.makeHarness())
  }

  @Test func bookmarkManagerCanRefreshAfterPreviousStaleReadWithoutRefresh() async throws {
    try await verifyBookmarkManagerCanRefreshAfterPreviousStaleReadWithoutRefresh(self.makeHarness())
  }

  private func makeHarness() -> BookmarkManagerStorageHarness {
    BookmarkManagerStorageHarness(
      manager: BookmarkManager(storage: InMemoryBookmarkStorage()),
      cleanup: {}
    )
  }
}
