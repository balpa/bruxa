// swift-tools-version: 5.10
import PackageDescription

let package = Package(
    name: "BruxaCore",
    platforms: [
        .iOS(.v17),
        .watchOS(.v10),
        .macOS(.v13)
    ],
    products: [
        .library(name: "BruxaCore", targets: ["BruxaCore"])
    ],
    targets: [
        .target(
            name: "BruxaCore",
            resources: [
                .process("BruxaModel.xcdatamodeld"),
                .copy("BruxaModel.momd")
            ]
        ),
        .testTarget(name: "BruxaCoreTests", dependencies: ["BruxaCore"])
    ]
)
