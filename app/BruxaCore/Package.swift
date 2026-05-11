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
            // The .xcdatamodeld is the editable source; the runtime ships only the pre-compiled .momd.
            // Excluding the source keeps Xcode from auto-compiling it (which would collide with the
            // shipped .momd). Regenerate BruxaModel.momd via scripts/compile-model.sh after edits.
            exclude: ["BruxaModel.xcdatamodeld"],
            resources: [.copy("BruxaModel.momd")]
        ),
        .testTarget(name: "BruxaCoreTests", dependencies: ["BruxaCore"])
    ]
)
