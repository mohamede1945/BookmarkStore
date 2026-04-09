import Foundation

enum BookmarkStorageIO: Sendable {
  static func encode<T: Encodable>(_ value: T) throws(BookmarkStorageError) -> Data {
    do {
      return try JSONEncoder().encode(value)
    }
    catch {
      throw .encodeFailed(type: String(reflecting: T.self))
    }
  }

  static func decode<T: Decodable>(_ type: T.Type, from data: Data) throws(BookmarkStorageError) -> T {
    do {
      return try JSONDecoder().decode(type, from: data)
    }
    catch {
      throw .decodeFailed(type: String(reflecting: type))
    }
  }

  static func read(from fileURL: URL) throws(BookmarkStorageError) -> Data {
    do {
      return try Data(contentsOf: fileURL)
    }
    catch {
      throw .readFailed(fileURL: fileURL)
    }
  }

  static func write(_ data: Data, to fileURL: URL) throws(BookmarkStorageError) {
    let directoryURL = fileURL.deletingLastPathComponent()
    do {
      try FileManager.default.createDirectory(
        at: directoryURL,
        withIntermediateDirectories: true
      )
    }
    catch {
      throw .createDirectoryFailed(directoryURL: directoryURL)
    }

    do {
      try data.write(to: fileURL, options: .atomic)
    }
    catch {
      throw .writeFailed(fileURL: fileURL)
    }
  }

  static func removeItem(at fileURL: URL) throws(BookmarkStorageError) {
    do {
      try FileManager.default.removeItem(at: fileURL)
    }
    catch {
      throw .removeFailed(fileURL: fileURL)
    }
  }

  static func contentsOfDirectory(at directoryURL: URL) throws(BookmarkStorageError) -> [URL] {
    do {
      return try FileManager.default.contentsOfDirectory(
        at: directoryURL,
        includingPropertiesForKeys: nil
      )
    }
    catch {
      throw .listFailed(directoryURL: directoryURL)
    }
  }
}
