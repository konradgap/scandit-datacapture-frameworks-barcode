// swift-tools-version: 5.7
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription
import Foundation

// Read version from info.json
func getVersion() -> String {
    let infoJSONPath = Context.packageDirectory + "/../info.json"
    guard let data = try? Data(contentsOf: URL(fileURLWithPath: infoJSONPath)),
          let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
          let version = json["version"] as? String else {
        fatalError("Could not read version from info.json at \(infoJSONPath)")
    }
    return version
}

let version = getVersion()

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
