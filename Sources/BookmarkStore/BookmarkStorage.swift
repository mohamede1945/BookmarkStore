import Foundation

/// A stable key for a persisted bookmark entry.
public struct BookmarkKey: RawRepresentable, Hashable, Codable, ExpressibleByStringLiteral {
  public let rawValue: String

  public init(rawValue: String) {
    self.rawValue = rawValue
  }

  public init(stringLiteral value: StringLiteralType) {
    self.init(rawValue: value)
  }
}

/// Storage surface for bookmark persistence backends.
public protocol BookmarkStorage {
  func bookmark(for key: BookmarkKey) async throws -> Bookmark?
  func setBookmark(_ bookmark: Bookmark, for key: BookmarkKey) async throws
  func removeBookmark(for key: BookmarkKey) async throws
  func removeAllBookmarks() async throws
  func bookmarkKeys() async throws -> [BookmarkKey]
}

extension BookmarkStorage {
  public func containsBookmark(for key: BookmarkKey) async throws -> Bool {
    try await self.bookmark(for: key) != nil
  }
}
