# BookmarkStore

Modern Swift bookmarks; direct low-level `Bookmark` API plus hands-free persistence with `BookmarkManager`.

`BookmarkStore` keeps the original Foundation bookmark utility idea, then pushes it toward modern app code:

- `Bookmark` is a `struct`
- `Bookmark` is `Sendable`
- Swift 6.2 codebase
- direct bookmark access when you want full control
- higher-level manager API when you just want `URL` in, `URL` out
- built-in `UserDefaults` storage
- custom storage backends when `UserDefaults` is not enough

<p align="center">
    <img src="https://img.shields.io/badge/License-MIT-lightgrey" />
    <a href="https://swift.org/package-manager">
        <img src="https://img.shields.io/badge/spm-compatible-brightgreen.svg?style=flat" alt="Swift Package Manager" />
    </a>
</p>
<p align="center">
    <img src="https://img.shields.io/badge/macOS-10.11+-red" />
    <img src="https://img.shields.io/badge/iOS-11+-blue" />
    <img src="https://img.shields.io/badge/tvOS-11+-orange" />
    <img src="https://img.shields.io/badge/watchOS-4+-purple" />
</p>

## Why this package exists

This repository started from [dagronf/Bookmark](https://github.com/dagronf/Bookmark), then split into its own package with a different direction.

Current focus:

- value-type bookmark handling
- Swift 6.2-friendly APIs
- better concurrency ergonomics with `Sendable`
- persistence workflows
- macOS sandbox-friendly access

If you want the raw bookmark abstraction, use `Bookmark` directly.

If you want storage, retrieval, and stale auto-refresh without passing bookmark data around your app, use `BookmarkManager`.

## What you get

### `Bookmark`

Low-level Foundation bookmark wrapper.

Use it when you want:

- raw `bookmarkData`
- `Codable` models containing bookmarks
- explicit `valid` / `stale` / `invalid` state inspection
- manual stale rebuild control
- security-scoped bookmark creation on macOS

### `BookmarkManager`

High-level persistence API.

Use it when you want:

- `URL` in, `URL` out
- automatic bookmark creation
- persistent storage behind a key
- optional stale detection
- automatic stale refresh and write-back

### `UserDefaultsBookmarkStorage`

Built-in async storage backend for bookmark persistence in `UserDefaults`.

### `BookmarkStorage`

Public protocol for custom backends.

Use it if you want to store bookmarks in:

- a database
- SwiftData / Core Data
- files on disk
- cloud-backed storage
- app-specific secure storage

## Installation

```swift
.package(url: "https://github.com/mohamede1945/BookmarkStore.git", branch: "main")
```

Then add `"BookmarkStore"` to your target dependencies and:

```swift
import BookmarkStore
```

## Usage

### Direct `Bookmark` usage

```swift
import BookmarkStore

let fileURL = URL(fileURLWithPath: "/path/to/file")

let bookmark = try Bookmark(targetFileURL: fileURL)
let bookmarkFromURL = try fileURL.bookmark()

let resolved = try bookmark.resolved()
print(resolved.state)  // .valid / .stale / .invalid
print(resolved.url)
```

### Store bookmark data yourself

```swift
import BookmarkStore

let bookmark = try Bookmark(targetFileURL: fileURL)
let data = bookmark.bookmarkData

// Later
let restoredBookmark = try Bookmark(bookmarkData: data)
let restoredURL = try restoredBookmark.resolved().url
```

### Encode bookmarks inside your models

`Bookmark` is `Codable`, so it can live directly in your own persisted types.

```swift
import BookmarkStore

struct StoredFile: Codable, Sendable {
  let id: UUID
  let bookmark: Bookmark
}

let stored = StoredFile(
  id: UUID(),
  bookmark: try Bookmark(targetFileURL: fileURL)
)

let data = try JSONEncoder().encode(stored)
let decoded = try JSONDecoder().decode(StoredFile.self, from: data)
let resolvedURL = try decoded.bookmark.resolved().url
```

### Handle stale bookmarks manually

```swift
import BookmarkStore

let resolved = try bookmark.resolved()

if resolved.state == .stale {
  let rebuilt = try bookmark.rebuild()
  // Persist rebuilt.bookmarkData
}
```

### macOS sandboxing

For sandboxed macOS apps, create a security-scoped bookmark when the user grants access, then reuse it across launches.

```swift
import BookmarkStore

let bookmark = try Bookmark(
  targetFileURL: fileURL,
  security: .securityScopingReadWrite
)

try bookmark.resolving(options: .withSecurityScope) { resolved in
  print(resolved.url)
}
```

## Hands-free bookmark persistence

If you do not want to pass `Bookmark` values around your app, use `BookmarkManager`.

It lets your app work in terms of `URL` and stable keys while the storage layer keeps bookmark data for you.

### `UserDefaults` storage

```swift
import BookmarkStore

let storage = UserDefaultsBookmarkStorage(
  userDefaults: .standard,
  keyPrefix: "bookmarks."
)

let manager = BookmarkManager(storage: storage)
```

### Store and retrieve URLs

```swift
import BookmarkStore

try await manager.upsertBookmark(
  targetFileURL: fileURL,
  for: "downloads-folder"
)

if let result = try await manager.resolvedBookmark(for: "downloads-folder") {
  print(result.url)
  print(result.isStale)
}
```

### Auto-refresh stale bookmarks

`resolvedBookmark(for:)` refreshes stale bookmarks by default, stores the rebuilt bookmark, and returns the refreshed URL.

```swift
import BookmarkStore

if let result = try await manager.resolvedBookmark(for: "downloads-folder") {
  print(result.url)
  print(result.isStale)   // usually false after automatic refresh
}
```

If you want to inspect stale state without refreshing:

```swift
import BookmarkStore

if let result = try await manager.resolvedBookmark(
  for: "downloads-folder",
  refreshIfStale: false
) {
  print(result.url)
  print(result.isStale)   // true if the stored bookmark is stale
}
```

### Store security-scoped bookmarks through the manager

```swift
import BookmarkStore

try await manager.upsertBookmark(
  targetFileURL: fileURL,
  security: .securityScopingReadWrite,
  for: "picked-file"
)

let result = try await manager.resolvedBookmark(for: "picked-file")
```

### Manage stored entries

```swift
import BookmarkStore

let exists = try await manager.containsBookmark(for: "picked-file")
let keys = try await manager.bookmarkKeys()

try await manager.removeBookmark(for: "picked-file")
try await manager.removeAllBookmarks()
```

## Custom storage backend

If `UserDefaultsBookmarkStorage` is not the right fit, provide your own `BookmarkStorage`.

```swift
import BookmarkStore

struct DatabaseBookmarkStorage: BookmarkStorage {
  func bookmark(for key: BookmarkKey) async throws -> Bookmark? {
    fatalError("Implement database load")
  }

  func setBookmark(_ bookmark: Bookmark, for key: BookmarkKey) async throws {
    fatalError("Implement database save")
  }

  func removeBookmark(for key: BookmarkKey) async throws {
    fatalError("Implement database delete")
  }

  func removeAllBookmarks() async throws {
    fatalError("Implement delete all")
  }

  func bookmarkKeys() async throws -> [BookmarkKey] {
    fatalError("Implement key listing")
  }
}

let manager = BookmarkManager(storage: DatabaseBookmarkStorage())
```

This keeps app-facing code simple while letting you choose your own persistence strategy.

## Summary

Use `Bookmark` when you want explicit control.

Use `BookmarkManager` when you want:

- bookmark creation
- persistence
- retrieval
- stale detection
- stale auto-refresh

all behind a `URL`-focused API.

## Credit

Originally based on Darren Ford's [dagronf/Bookmark](https://github.com/dagronf/Bookmark), now maintained here with a Swift 6.2, value-type, persistence-oriented direction.

## License

MIT.
