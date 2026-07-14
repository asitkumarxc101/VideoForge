// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "VideoEditorPipeline",
    platforms: [
        .iOS("26")
    ],
    products: [
        .library(
            name: "VideoEditorPipeline",
            targets: ["VideoEditorPipeline"]),
    ],
    dependencies: [],
    targets: [
        .target(
            name: "VideoEditorPipeline",
            dependencies: [],
            path: "VideoEditor/VideoEditorPipeline")
    ]
)
