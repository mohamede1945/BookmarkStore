import Testing

@testable import BookmarkStore

@Suite struct FileBookmarkStorageTests {
  @Test func bookmarkManagerRoundTrip() async throws {
    try await verifyBookmarkManagerRoundTrip(try self.makeHarness())
  }

  @Test func bookmarkManagerRemoveBookmark() async throws {
    try await verifyBookmarkManagerRemoveBookmark(try self.makeHarness())
  }

  @Test func bookmarkManagerRemoveAllBookmarks() async throws {
    try await verifyBookmarkManagerRemoveAllBookmarks(try self.makeHarness())
  }

  @Test func bookmarkManagerRefreshesStaleBookmarks() async throws {
    try await verifyBookmarkManagerRefreshesStaleBookmarks(try self.makeHarness())
  }

  @Test func bookmarkManagerCanResolveStaleBookmarkWithoutRefreshing() async throws {
    try await verifyBookmarkManagerCanResolveStaleBookmarkWithoutRefreshing(try self.makeHarness())
  }

  @Test func bookmarkManagerCanRefreshAfterPreviousStaleReadWithoutRefresh() async throws {
    try await verifyBookmarkManagerCanRefreshAfterPreviousStaleReadWithoutRefresh(try self.makeHarness())
  }

  private func makeHarness() throws -> BookmarkManagerStorageHarness {
    let file = try TemporaryFile(prefix: "bookmark-store", fileExtension: "json")
    let storage = FileBookmarkStorage(fileURL: file.fileURL)

    return BookmarkManagerStorageHarness(
      manager: BookmarkManager(storage: storage),
      cleanup: { try? file.remove() }
    )
  }
}
