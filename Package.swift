// swift-tools-version: 6.0

import PackageDescription

let package = Package(
  name: "BookmarkStore",
  platforms: [
    .macOS(.v10_15),
    .iOS(.v13),
    .tvOS(.v13),
    .watchOS(.v6),
  ],
  products: [
    .library(name: "BookmarkStore", targets: ["BookmarkStore"])
  ],
  targets: [
    .target(
      name: "BookmarkStore",
      dependencies: []),
    .testTarget(
      name: "BookmarkStoreTests",
      dependencies: ["BookmarkStore"]),
  ]
)
