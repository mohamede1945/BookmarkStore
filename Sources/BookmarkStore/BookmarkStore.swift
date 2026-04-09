import Foundation

/// Coordinates bookmark persistence and stale-refresh behavior.
public struct BookmarkStore: Sendable {
  private let storageBackend: any BookmarkStorageBackend

  public init(storageBackend: any BookmarkStorageBackend) {
    self.storageBackend = storageBackend
  }

  public func containsBookmark(for key: BookmarkKey) async throws(BookmarkStoreError) -> Bool {
    do {
      return try await self.storageBackend.containsBookmark(for: key)
    }
    catch {
      throw .storage(error)
    }
  }

  public func upsertBookmark(
    targetFileURL: URL,
    security: Bookmark.SecurityScopeOptions = .none,
    includingResourceValuesForKeys keys: Set<URLResourceKey>? = nil,
    options: URL.BookmarkCreationOptions = [],
    for key: BookmarkKey
  ) async throws(BookmarkStoreError) {
    let bookmark: Bookmark

    do {
      bookmark = try Bookmark(
        targetFileURL: targetFileURL,
        security: security,
        includingResourceValuesForKeys: keys,
        options: options
      )
    }
    catch {
      throw .bookmark(error)
    }

    do {
      try await self.storageBackend.setBookmark(bookmark, for: key)
    }
    catch {
      throw .storage(error)
    }
  }

  public func removeBookmark(for key: BookmarkKey) async throws(BookmarkStoreError) {
    do {
      try await self.storageBackend.removeBookmark(for: key)
    }
    catch {
      throw .storage(error)
    }
  }

  public func removeAllBookmarks() async throws(BookmarkStoreError) {
    do {
      try await self.storageBackend.removeAllBookmarks()
    }
    catch {
      throw .storage(error)
    }
  }

  public func bookmarkKeys() async throws(BookmarkStoreError) -> [BookmarkKey] {
    do {
      return try await self.storageBackend.bookmarkKeys()
    }
    catch {
      throw .storage(error)
    }
  }

  /// Load a bookmark, resolve it, and optionally refresh stale data.
  public func resolvedBookmark(
    for key: BookmarkKey,
    resolutionOptions: NSURL.BookmarkResolutionOptions = [],
    refreshIfStale: Bool = true
  ) async throws(BookmarkStoreError) -> (url: URL, isStale: Bool)? {
    let bookmark: Bookmark

    do {
      guard let storedBookmark = try await self.storageBackend.bookmark(for: key) else {
        return nil
      }
      bookmark = storedBookmark
    }
    catch {
      throw .storage(error)
    }

    let resolved: Bookmark.Resolved
    do {
      resolved = try bookmark.resolved(options: resolutionOptions)
    }
    catch {
      throw .bookmark(error)
    }

    guard refreshIfStale, resolved.state == .stale else {
      return (resolved.url, resolved.state == .stale)
    }

    let refreshedBookmark: Bookmark
    do {
      refreshedBookmark = try bookmark.rebuild()
    }
    catch {
      throw .bookmark(error)
    }

    do {
      try await self.storageBackend.setBookmark(refreshedBookmark, for: key)
    }
    catch {
      throw .storage(error)
    }

    do {
      let refreshedResolved = try refreshedBookmark.resolved(options: resolutionOptions)
      return (refreshedResolved.url, refreshedResolved.state == .stale)
    }
    catch {
      throw .bookmark(error)
    }
  }
}
