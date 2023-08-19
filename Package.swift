// swift-tools-version:4.2
import PackageDescription

let package = Package(
  name: "Server",products: [
    .executable(name: "Server", targets: ["Server"]),
    ],
  dependencies: [
    .package(url: "https://github.com/PerfectlySoft/Perfect-Notifications.git", .exact("4.0.0")),
    .package(url: "https://github.com/apple/swift-nio.git", from: "1.0.0"),
    .package(url: "https://github.com/apple/swift-nio-ssl.git", from: "1.4.0"),
    .package(url: "https://github.com/vapor/vapor.git", from: "3.0.0"),
    ],
  targets: [
    .target(name: "SomeFunctions", dependencies: []),
    .target(name: "SomeData", dependencies: ["SomeFunctions"]),
    .target(name: "SomeBridge", dependencies: ["SomeFunctions", "SomeData"]),
    .target(name: "Server", dependencies: ["SomeFunctions", "SomeData", "SomeBridge", "PerfectNotifications", "NIO", "NIOFoundationCompat", "NIOOpenSSL", "Vapor"]),
    ]
)
