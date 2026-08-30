// swift-tools-version: 6.0

import PackageDescription

// FoPost — the official Swift SDK for the FoPost API.
//
//   Version:    0.1.0
//   Homepage:   https://fopost.com
//   Docs:       https://fopost.com/docs
//   Repository: https://github.com/fopost/fopost-swift
//   Author:     Porter Bridge, LLC
//   License:    MIT
//   Keywords:   fopost, social-media, scheduling, publishing, analytics, api, sdk
//
// Swift Package Manager has no manifest fields for this metadata; the Swift
// Package Index reads it from .spi.yml and the README instead.

let package = Package(
  name: "FoPost",
  platforms: [
    .iOS(.v15),
    .macOS(.v12),
    .tvOS(.v15),
    .watchOS(.v8),
  ],
  products: [
    .library(name: "FoPost", targets: ["FoPost"]),
    .executable(name: "fopost-example", targets: ["FoPostExample"]),
  ],
  targets: [
    .target(
      name: "FoPost",
      swiftSettings: [.swiftLanguageMode(.v6)]
    ),
    .executableTarget(
      name: "FoPostExample",
      dependencies: ["FoPost"],
      path: "examples/create-post",
      swiftSettings: [.swiftLanguageMode(.v6)]
    ),
    .testTarget(
      name: "FoPostTests",
      dependencies: ["FoPost"],
      swiftSettings: [.swiftLanguageMode(.v6)]
    ),
  ]
)
