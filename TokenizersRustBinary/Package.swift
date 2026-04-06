// swift-tools-version: 6.1

import PackageDescription

let localArtifactPath = Context.environment["TOKENIZERS_RUST_LOCAL_XCFRAMEWORK_PATH"]

let tokenizersRustTarget: Target =
    if let localArtifactPath {
        // Used by the Rust release workflow to validate the freshly built XCFramework
        // before publishing it as a remote binary artifact.
        .binaryTarget(name: "TokenizersRust", path: localArtifactPath)
    } else {
        .binaryTarget(
            name: "TokenizersRust",
            url: "https://github.com/DePasqualeOrg/swift-tokenizers/releases/download/tokenizers-rust-0.3.0/TokenizersRust-0.3.0.xcframework.zip",
            checksum: "a48abdf5328ad8d174579b80afce530a0a159f53ce9e659e13f6b3d506e4a433"
        )
    }

let package = Package(
    name: "TokenizersRustBinary",
    products: [
        .library(name: "TokenizersRust", targets: ["TokenizersRust"])
    ],
    targets: [tokenizersRustTarget]
)
