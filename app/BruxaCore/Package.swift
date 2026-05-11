// swift-tools-version: 5.10
import PackageDescription

let package = Package(
    name: "BruxaCore",
    platforms: [
        .iOS(.v17),
        .watchOS(.v10),
        .macOS(.v13)  // required to run `swift test` on a macOS host
    ],
    products: [
        .library(name: "BruxaCore", targets: ["BruxaCore"])
    ],
    targets: [
        .target(
            name: "BruxaCore",
            // Regenerate BruxaModel.momd via scripts/compile-model.sh after editing the xcdatamodeld.
            resources: [
                .process("BruxaModel.xcdatamodeld"),
                .copy("BruxaModel.momd")
            ]
        ),
        .testTarget(name: "BruxaCoreTests", dependencies: ["BruxaCore"])
    ]
)
