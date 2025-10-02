// swift-tools-version: 5.9
import PackageDescription

// Version is set during release process
// When developing locally in monorepo, the version is read from package.json/info.json
// When published to GitHub, the version must be hardcoded
let version = "7.6.1"

let package = Package(
    name: "scandit-datacapture-frameworks-barcode",
    platforms: [.iOS(.v15)],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "ScanditFrameworksBarcode",
            targets: ["ScanditFrameworksBarcode"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/Scandit/scandit-datacapture-frameworks-core.git", exact: Version(stringLiteral: version)),
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "ScanditFrameworksBarcode",
            dependencies: [
                .product(name: "ScanditFrameworksCore", package: "scandit-datacapture-frameworks-core"),
                "ScanditBarcodeCapture",
                "_ScanditFrameworksBarcodePrivate"
            ]
        ),
        .target(
            name: "_ScanditFrameworksBarcodePrivate",
            path: "Sources/ScanditFrameworksBarcodePrivate",
            publicHeadersPath: "include"
        ),
        .binaryTarget(
            name: "ScanditBarcodeCapture",
            path: "Frameworks/ScanditBarcodeCapture.xcframework"
        ),
    ]
)
