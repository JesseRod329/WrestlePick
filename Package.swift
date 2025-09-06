// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "WrestlePick",
    platforms: [
        .iOS(.v15)
    ],
    products: [
        .library(
            name: "WrestlePick",
            targets: ["WrestlePick"]),
    ],
    dependencies: [
        .package(url: "https://github.com/firebase/firebase-ios-sdk.git", from: "10.0.0"),
        .package(url: "https://github.com/onevcat/Kingfisher.git", from: "7.0.0"),
        .package(url: "https://github.com/realm/realm-swift.git", from: "10.0.0"),
        .package(url: "https://github.com/SwiftyJSON/SwiftyJSON.git", from: "5.0.0"),
        .package(url: "https://github.com/Alamofire/Alamofire.git", from: "5.0.0"),
        .package(url: "https://github.com/SwiftUIX/SwiftUIX.git", from: "0.1.0"),
    ],
    targets: [
        .target(
            name: "WrestlePick",
            dependencies: [
                .product(name: "FirebaseAuth", package: "firebase-ios-sdk"),
                .product(name: "FirebaseFirestore", package: "firebase-ios-sdk"),
                .product(name: "FirebaseMessaging", package: "firebase-ios-sdk"),
                .product(name: "FirebaseAnalytics", package: "firebase-ios-sdk"),
                .product(name: "FirebaseCrashlytics", package: "firebase-ios-sdk"),
                .product(name: "FirebaseStorage", package: "firebase-ios-sdk"),
                .product(name: "FirebaseFunctions", package: "firebase-ios-sdk"),
                .product(name: "Kingfisher", package: "Kingfisher"),
                .product(name: "RealmSwift", package: "realm-swift"),
                .product(name: "SwiftyJSON", package: "SwiftyJSON"),
                .product(name: "Alamofire", package: "Alamofire"),
                .product(name: "SwiftUIX", package: "SwiftUIX"),
            ]),
        .testTarget(
            name: "WrestlePickTests",
            dependencies: ["WrestlePick"]),
    ]
)
