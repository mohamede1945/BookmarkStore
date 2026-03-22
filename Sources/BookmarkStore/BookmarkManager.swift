import Foundation

/// Coordinates bookmark persistence and stale-refresh behavior.
public struct BookmarkManager {
  private let storage: any BookmarkStorage

  public init(storage: any BookmarkStorage) {
    self.storage = storage
  }

  public func containsBookmark(for key: BookmarkKey) async throws -> Bool {
    try await self.storage.containsBookmark(for: key)
  }

  public func upsertBookmark(
    targetFileURL: URL,
    security: Bookmark.SecurityScopeOptions = .none,
    includingResourceValuesForKeys keys: Set<URLResourceKey>? = nil,
    options: URL.BookmarkCreationOptions = [],
    for key: BookmarkKey
  ) async throws {
    let bookmark = try Bookmark(
      targetFileURL: targetFileURL,
      security: security,
      includingResourceValuesForKeys: keys,
      options: options
    )
    try await self.storage.setBookmark(bookmark, for: key)
  }

  public func removeBookmark(for key: BookmarkKey) async throws {
    try await self.storage.removeBookmark(for: key)
  }

  public func removeAllBookmarks() async throws {
    try await self.storage.removeAllBookmarks()
  }

  public func bookmarkKeys() async throws -> [BookmarkKey] {
    try await self.storage.bookmarkKeys()
  }

  /// Load a bookmark, resolve it, and optionally refresh stale data.
  public func resolvedBookmark(
    for key: BookmarkKey,
    resolutionOptions: NSURL.BookmarkResolutionOptions = [],
    refreshIfStale: Bool = true
  ) async throws -> (url: URL, isStale: Bool)? {
    guard let bookmark = try await self.storage.bookmark(for: key) else {
      return nil
    }

    let resolved = try bookmark.resolved(options: resolutionOptions)

    guard refreshIfStale, resolved.state == .stale else {
      return (resolved.url, resolved.state == .stale)
    }

    let refreshedBookmark = try bookmark.rebuild()
    try await self.storage.setBookmark(refreshedBookmark, for: key)
    let refreshedResolved = try refreshedBookmark.resolved(options: resolutionOptions)
    return (refreshedResolved.url, refreshedResolved.state == .stale)
  }
}
