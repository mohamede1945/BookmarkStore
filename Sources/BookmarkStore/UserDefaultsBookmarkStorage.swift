import Foundation

public actor UserDefaultsBookmarkStorage: BookmarkStorage {
  public let userDefaults: UserDefaults
  public let keyPrefix: String

  public init(userDefaults: UserDefaults = .standard, keyPrefix: String = "bookmarks.") {
    self.userDefaults = userDefaults
    self.keyPrefix = keyPrefix
  }

  public func bookmark(for key: BookmarkKey) async throws -> Bookmark? {
    guard let data = self.userDefaults.data(forKey: self.storageKey(for: key)) else {
      return nil
    }
    return try Self.decodeBookmark(from: data)
  }

  public func setBookmark(_ bookmark: Bookmark, for key: BookmarkKey) async throws {
    let data = try Self.encodeBookmark(bookmark)

    self.userDefaults.set(data, forKey: self.storageKey(for: key))
    var keys = self.loadKeys()
    keys.insert(key)
    self.saveKeys(keys)
  }

  public func removeBookmark(for key: BookmarkKey) async throws {
    self.userDefaults.removeObject(forKey: self.storageKey(for: key))
    var keys = self.loadKeys()
    keys.remove(key)
    self.saveKeys(keys)
  }

  public func removeAllBookmarks() async throws {
    let keys = self.loadKeys()
    for key in keys {
      self.userDefaults.removeObject(forKey: self.storageKey(for: key))
    }
    self.userDefaults.removeObject(forKey: self.indexKey)
  }

  public func bookmarkKeys() async throws -> [BookmarkKey] {
    return self.loadKeys().sorted { $0.rawValue < $1.rawValue }
  }

  private var indexKey: String { "\(self.keyPrefix)__keys" }

  private func storageKey(for key: BookmarkKey) -> String {
    "\(self.keyPrefix)\(key.rawValue)"
  }

  private func loadKeys() -> Set<BookmarkKey> {
    let rawKeys = self.userDefaults.stringArray(forKey: self.indexKey) ?? []
    return Set(rawKeys.map { BookmarkKey(rawValue: $0) })
  }

  private func saveKeys(_ keys: Set<BookmarkKey>) {
    self.userDefaults.set(keys.map(\.rawValue).sorted(), forKey: self.indexKey)
  }

  private static func encodeBookmark(_ bookmark: Bookmark) throws -> Data {
    try JSONEncoder().encode(bookmark)
  }

  private static func decodeBookmark(from data: Data) throws -> Bookmark {
    try JSONDecoder().decode(Bookmark.self, from: data)
  }
}
