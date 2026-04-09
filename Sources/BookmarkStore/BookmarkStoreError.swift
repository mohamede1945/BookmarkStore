import Foundation

public enum BookmarkStorageError: Error, Sendable, Equatable {
  case encodeFailed(type: String)
  case decodeFailed(type: String)
  case readFailed(fileURL: URL)
  case writeFailed(fileURL: URL)
  case createDirectoryFailed(directoryURL: URL)
  case removeFailed(fileURL: URL)
  case listFailed(directoryURL: URL)
}

public enum BookmarkStoreError: Error, Sendable, Equatable {
  case bookmark(Bookmark.BookmarkError)
  case storage(BookmarkStorageError)
}
