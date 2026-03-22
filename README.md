# BookmarkStore

Standalone Swift package for file bookmarks with persistence-friendly APIs.

`BookmarkStore` keeps the package focused on two things:

- reliable file-location recovery after moves/renames
- easy persistence of bookmark data across app launches
- macOS sandbox-friendly file access via security-scoped bookmarks

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

## Why this repo exists

This repository is now an independent continuation of the original `dagronf/Bookmark` package.

Current focus:

- persistence-first bookmark workflows
- cleaner app/storage integration
- future evolution toward value-type ergonomics

## What it does

`Bookmark` wraps Foundation URL bookmark data.

A bookmark is opaque `Data` that can usually resolve the original file URL even after the file is moved or renamed. This makes it a better storage format than raw file paths for long-lived references.

Useful when storing file references in:

- app state
- JSON
- databases
- Core Data / SwiftData payloads
- config files

On macOS, this also helps with App Sandbox workflows. Security-scoped bookmarks let sandboxed apps regain access to user-selected files and folders across launches without relying on fragile absolute paths.

Apple docs:

- [Locating Files Using Bookmarks](https://developer.apple.com/library/archive/documentation/FileManagement/Conceptual/FileSystemProgrammingGuide/AccessingFilesandDirectories/AccessingFilesandDirectories.html#//apple_ref/doc/uid/TP40010672-CH3-SW10)
- [Enabling Security-Scoped Bookmark and URL Access](https://developer.apple.com/documentation/professional_video_applications/fcpxml_reference/asset/media-rep/bookmark/enabling_security-scoped_bookmark_and_url_access)
- [Bookmarks and Security Scope](https://developer.apple.com/documentation/foundation/nsurl#1663783)

## Features

- create bookmarks from file URLs or file paths
- resolve bookmarks and inspect `valid` / `stale` / `invalid` state
- optional security-scoped bookmark support
- useful for macOS App Sandbox file/folder re-access
- `Codable` support for direct serialization
- raw `Data` access via `bookmarkData`
- rebuild stale bookmarks
- write bookmark data or Finder alias files

## Usage

### Create and resolve

```swift
import BookmarkStore

let originalURL = URL(fileURLWithPath: "/path/to/file")

let bookmark = try Bookmark(targetFileURL: originalURL)
let bookmarkFromURL = try originalURL.bookmark()

let resolved = try bookmark.resolved()
print(resolved.state) // .valid / .stale / .invalid
print(resolved.url)

try bookmark.resolving { item in
  print(item.url)
}
```

### Persist bookmark data

```swift
import BookmarkStore

let fileURL = URL(fileURLWithPath: "/path/to/file")
let bookmark = try Bookmark(targetFileURL: fileURL)

// Raw bytes for disk/database storage
let data = bookmark.bookmarkData

// Later...
let restored = try Bookmark(bookmarkData: data)
let restoredURL = try restored.resolved().url
```

### macOS sandboxing

For sandboxed macOS apps, create a security-scoped bookmark when the user grants access, then persist it for later launches.

```swift
import BookmarkStore

let bookmark = try Bookmark(
  targetFileURL: fileURL,
  security: .securityScopingReadWrite
)

try bookmark.resolving(options: .withSecurityScope) { item in
  print(item.url)
}
```

### Encode inside your models

`Bookmark` conforms to `Codable`, so it can live directly inside persisted models.

```swift
import BookmarkStore

struct StoredFile: Codable {
  let id: UUID
  let bookmark: Bookmark
}

let stored = StoredFile(
  id: UUID(),
  bookmark: try Bookmark(targetFileURL: URL(fileURLWithPath: "/path/to/file"))
)

let encoded = try JSONEncoder().encode(stored)
let decoded = try JSONDecoder().decode(StoredFile.self, from: encoded)

let resolvedURL = try decoded.bookmark.resolved().url
```

### Rebuild stale bookmarks

When a bookmark resolves as `.stale`, rebuild and persist the new one.

```swift
let resolved = try bookmark.resolved()

if resolved.state == .stale {
  let rebuilt = try bookmark.rebuild()
  // save rebuilt.bookmarkData
}
```

## Installation

```swift
.package(url: "https://github.com/mohamede1945/BookmarkStore.git", branch: "main")
```

Then add `"BookmarkStore"` to your target dependencies and `import BookmarkStore` in code.

## Credit

Originally based on Darren Ford's `Bookmark` package, now maintained here as a separate repository with a persistence-oriented direction.

## License

MIT.
