import Foundation

public actor FileBookmarkStorage: BookmarkStorageBackend {
  public let fileURL: URL

  public init(fileURL: URL) {
    self.fileURL = fileURL
  }

  public func bookmark(for key: BookmarkKey) async throws(BookmarkStorageError) -> Bookmark? {
    let snapshot = try self.loadSnapshot()
    return snapshot.bookmarks[key.rawValue]
  }

  public func setBookmark(_ bookmark: Bookmark, for key: BookmarkKey) async throws(BookmarkStorageError) {
    var snapshot = try self.loadSnapshot()
    snapshot.bookmarks[key.rawValue] = bookmark
    try self.saveSnapshot(snapshot)
  }

  public func removeBookmark(for key: BookmarkKey) async throws(BookmarkStorageError) {
    var snapshot = try self.loadSnapshot()
    snapshot.bookmarks.removeValue(forKey: key.rawValue)
    try self.saveSnapshot(snapshot)
  }

  public func removeAllBookmarks() async throws(BookmarkStorageError) {
    guard FileManager.default.fileExists(atPath: self.fileURL.path) else {
      return
    }
    try BookmarkStorageIO.removeItem(at: self.fileURL)
  }

  public func bookmarkKeys() async throws(BookmarkStorageError) -> [BookmarkKey] {
    let snapshot = try self.loadSnapshot()
    return snapshot.bookmarks.keys
      .map(BookmarkKey.init(rawValue:))
      .sorted { $0.rawValue < $1.rawValue }
  }

  private struct Snapshot: Codable, Sendable {
    var bookmarks: [String: Bookmark] = [:]
  }

  private func loadSnapshot() throws(BookmarkStorageError) -> Snapshot {
    guard FileManager.default.fileExists(atPath: self.fileURL.path) else {
      return Snapshot()
    }

    let data = try BookmarkStorageIO.read(from: self.fileURL)
    return try BookmarkStorageIO.decode(Snapshot.self, from: data)
  }

  private func saveSnapshot(_ snapshot: Snapshot) throws(BookmarkStorageError) {
    guard snapshot.bookmarks.isEmpty == false else {
      if FileManager.default.fileExists(atPath: self.fileURL.path) {
        try BookmarkStorageIO.removeItem(at: self.fileURL)
      }
      return
    }

    let data = try BookmarkStorageIO.encode(snapshot)
    try BookmarkStorageIO.write(data, to: self.fileURL)
  }
}
