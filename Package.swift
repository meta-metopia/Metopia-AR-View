// swift-tools-version: 5.7
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "MetopiaARView",
    platforms: [
      .iOS(.v15)
    ],
    products: [
        // Products define the executables and libraries a package produces, and make them visible to other packages.
        .library(
            name: "MetopiaARView",
            targets: ["MetopiaARView"]),
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        // .package(url: /* package url */, from: "1.0.0"),
      .package(url: "https://github.com/sirily11/ARCore", from: "1.34.0"),
      .package(url: "https://github.com/MetaMetopia/Metopia-AR-Creator-Common", exact: "1.0.5"),
      .package(url: "https://github.com/maxxfrazer/FocusEntity", exact: "2.3.0"),
      .package(url: "https://github.com/danielsaidi/WebViewKit", exact: "0.2.1")
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .target(
            name: "MetopiaARView",
            dependencies: [
              .product(name: "ARCoreBase", package: "ARCore"),
              .product(name: "ARCoreGARSession", package: "ARCore"),
              .product(name: "ARCoreCloudAnchors", package: "ARCore"),
              .product(name: "MetopiaARCreatorCommon", package: "Metopia-AR-Creator-Common"),
              .product(name: "FocusEntity", package: "FocusEntity"),
              .product(name: "WebViewKit", package: "WebViewKit")
            ]),
        .testTarget(
            name: "MetopiaARViewTests",
            dependencies: ["MetopiaARView"]),
    ]
)
