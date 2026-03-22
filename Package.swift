// swift-tools-version: 6.0

import PackageDescription

let package = Package(
  name: "BookmarkStore",
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
