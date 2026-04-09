import Foundation

/// A stable key for a persisted bookmark entry.
public struct BookmarkKey: RawRepresentable, Hashable, Codable, ExpressibleByStringLiteral, Sendable
{
  public let rawValue: String

  public init(rawValue: String) {
    self.rawValue = rawValue
  }

  public init(stringLiteral value: StringLiteralType) {
    self.init(rawValue: value)
  }
}

/// Storage surface for bookmark persistence backends.
public protocol BookmarkStorageBackend: Sendable {
  func bookmark(for key: BookmarkKey) async throws(BookmarkStorageError) -> Bookmark?
  func setBookmark(_ bookmark: Bookmark, for key: BookmarkKey) async throws(BookmarkStorageError)
  func removeBookmark(for key: BookmarkKey) async throws(BookmarkStorageError)
  func removeAllBookmarks() async throws(BookmarkStorageError)
  func bookmarkKeys() async throws(BookmarkStorageError) -> [BookmarkKey]
}

extension BookmarkStorageBackend {
  public func containsBookmark(for key: BookmarkKey) async throws(BookmarkStorageError) -> Bool {
    try await self.bookmark(for: key) != nil
  }
}
