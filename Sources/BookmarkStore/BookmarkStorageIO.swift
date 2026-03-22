import Foundation

enum BookmarkStorageIO {
  static func encode<T: Encodable>(_ value: T) throws -> Data {
    try JSONEncoder().encode(value)
  }

  static func decode<T: Decodable>(_ type: T.Type, from data: Data) throws -> T {
    try JSONDecoder().decode(type, from: data)
  }

  static func write(_ data: Data, to fileURL: URL) throws {
    let directoryURL = fileURL.deletingLastPathComponent()
    try FileManager.default.createDirectory(
      at: directoryURL,
      withIntermediateDirectories: true
    )
    try data.write(to: fileURL, options: .atomic)
  }
}
