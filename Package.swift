// swift-tools-version:4.2
import PackageDescription

let package = Package(
  name: "SystemKit",
  products: [
    .library(name: "SystemKit", targets: ["SystemKit"]),
  ],
  dependencies: [],
  targets: [
    .target(name: "SystemKit", dependencies: []),
    .testTarget(name: "SystemKitTests", dependencies: ["SystemKit"]),
  ]
)
