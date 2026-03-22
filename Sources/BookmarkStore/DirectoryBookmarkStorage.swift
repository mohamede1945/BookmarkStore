import Foundation

public actor DirectoryBookmarkStorage: BookmarkStorageBackend {
  public let directoryURL: URL

  public init(directoryURL: URL) {
    self.directoryURL = directoryURL
  }

  public func bookmark(for key: BookmarkKey) async throws -> Bookmark? {
    let fileURL = self.fileURL(for: key)
    guard FileManager.default.fileExists(atPath: fileURL.path) else {
      return nil
    }

    let data = try Data(contentsOf: fileURL)
    return try BookmarkStorageIO.decode(Bookmark.self, from: data)
  }

  public func setBookmark(_ bookmark: Bookmark, for key: BookmarkKey) async throws {
    let data = try BookmarkStorageIO.encode(bookmark)
    try BookmarkStorageIO.write(data, to: self.fileURL(for: key))
  }

  public func removeBookmark(for key: BookmarkKey) async throws {
    let fileURL = self.fileURL(for: key)
    guard FileManager.default.fileExists(atPath: fileURL.path) else {
      return
    }
    try FileManager.default.removeItem(at: fileURL)
  }

  public func removeAllBookmarks() async throws {
    guard FileManager.default.fileExists(atPath: self.directoryURL.path) else {
      return
    }
    try FileManager.default.removeItem(at: self.directoryURL)
  }

  public func bookmarkKeys() async throws -> [BookmarkKey] {
    guard FileManager.default.fileExists(atPath: self.directoryURL.path) else {
      return []
    }

    return try FileManager.default
      .contentsOfDirectory(at: self.directoryURL, includingPropertiesForKeys: nil)
      .compactMap(Self.key(from:))
      .sorted { $0.rawValue < $1.rawValue }
  }

  private func fileURL(for key: BookmarkKey) -> URL {
    self.directoryURL
      .appendingPathComponent(Self.storageFileName(for: key))
      .appendingPathExtension("json")
  }

  private static func storageFileName(for key: BookmarkKey) -> String {
    let base64 = Data(key.rawValue.utf8).base64EncodedString()
    return base64
      .replacingOccurrences(of: "+", with: "-")
      .replacingOccurrences(of: "/", with: "_")
      .replacingOccurrences(of: "=", with: "")
  }

  private static func key(from fileURL: URL) -> BookmarkKey? {
    guard fileURL.pathExtension == "json" else {
      return nil
    }

    var base64 = fileURL.deletingPathExtension().lastPathComponent
      .replacingOccurrences(of: "-", with: "+")
      .replacingOccurrences(of: "_", with: "/")

    let remainder = base64.count % 4
    if remainder != 0 {
      base64 += String(repeating: "=", count: 4 - remainder)
    }

    guard
      let data = Data(base64Encoded: base64),
      let rawValue = String(data: data, encoding: .utf8)
    else {
      return nil
    }

    return BookmarkKey(rawValue: rawValue)
  }
}
