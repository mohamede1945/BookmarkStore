import Foundation

public actor FileBookmarkStorage: BookmarkStorage {
  public let fileURL: URL

  public init(fileURL: URL) {
    self.fileURL = fileURL
  }

  public func bookmark(for key: BookmarkKey) async throws -> Bookmark? {
    let snapshot = try self.loadSnapshot()
    return snapshot.bookmarks[key.rawValue]
  }

  public func setBookmark(_ bookmark: Bookmark, for key: BookmarkKey) async throws {
    var snapshot = try self.loadSnapshot()
    snapshot.bookmarks[key.rawValue] = bookmark
    try self.saveSnapshot(snapshot)
  }

  public func removeBookmark(for key: BookmarkKey) async throws {
    var snapshot = try self.loadSnapshot()
    snapshot.bookmarks.removeValue(forKey: key.rawValue)
    try self.saveSnapshot(snapshot)
  }

  public func removeAllBookmarks() async throws {
    guard FileManager.default.fileExists(atPath: self.fileURL.path) else {
      return
    }
    try FileManager.default.removeItem(at: self.fileURL)
  }

  public func bookmarkKeys() async throws -> [BookmarkKey] {
    let snapshot = try self.loadSnapshot()
    return snapshot.bookmarks.keys
      .map(BookmarkKey.init(rawValue:))
      .sorted { $0.rawValue < $1.rawValue }
  }

  private struct Snapshot: Codable {
    var bookmarks: [String: Bookmark] = [:]
  }

  private func loadSnapshot() throws -> Snapshot {
    guard FileManager.default.fileExists(atPath: self.fileURL.path) else {
      return Snapshot()
    }

    let data = try Data(contentsOf: self.fileURL)
    return try BookmarkStorageIO.decode(Snapshot.self, from: data)
  }

  private func saveSnapshot(_ snapshot: Snapshot) throws {
    guard snapshot.bookmarks.isEmpty == false else {
      if FileManager.default.fileExists(atPath: self.fileURL.path) {
        try FileManager.default.removeItem(at: self.fileURL)
      }
      return
    }

    let data = try BookmarkStorageIO.encode(snapshot)
    try BookmarkStorageIO.write(data, to: self.fileURL)
  }
}
