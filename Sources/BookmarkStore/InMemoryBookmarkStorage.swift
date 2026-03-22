import Foundation

public actor InMemoryBookmarkStorage: BookmarkStorageBackend {
  private var bookmarks: [BookmarkKey: Bookmark] = [:]

  public init() {}

  public func bookmark(for key: BookmarkKey) async throws -> Bookmark? {
    self.bookmarks[key]
  }

  public func setBookmark(_ bookmark: Bookmark, for key: BookmarkKey) async throws {
    self.bookmarks[key] = bookmark
  }

  public func removeBookmark(for key: BookmarkKey) async throws {
    self.bookmarks.removeValue(forKey: key)
  }

  public func removeAllBookmarks() async throws {
    self.bookmarks.removeAll()
  }

  public func bookmarkKeys() async throws -> [BookmarkKey] {
    self.bookmarks.keys.sorted { $0.rawValue < $1.rawValue }
  }
}
