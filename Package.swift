// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "VaporAuth",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .library(name: "VaporAuth", targets: ["VaporAuth"])
    ],
    dependencies: [
        .package(url: "https://github.com/vapor/vapor.git", from: "4.115.0"),
        .package(url: "https://github.com/vapor/fluent.git", from: "4.9.0"),
        .package(url: "https://github.com/vapor/fluent-postgres-driver.git", from: "2.8.0"),
        .package(url: "https://github.com/vapor/jwt.git", from: "5.0.0")
    ],
    targets: [
        .target(
            name: "VaporAuth",
            dependencies: [
                .product(name: "Vapor", package: "vapor"),
                .product(name: "Fluent", package: "fluent"),
                .product(name: "FluentPostgresDriver", package: "fluent-postgres-driver"),
                .product(name: "JWT", package: "jwt")
            ],
            path: "Sources/VaporAuth",
            swiftSettings: [
                .enableUpcomingFeature("ExistentialAny")
            ]
        ),
        .testTarget(
            name: "VaporAuthTests",
            dependencies: [
                "VaporAuth"
            ],
            path: "Tests/VaporAuthTests"
        )
    ]
)
