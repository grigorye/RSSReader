// swift-tools-version:4.0
import PackageDescription

let package = Package(
	name: "CwlUtils",
	products: [.library(name: "CwlUtils", targets: ["CwlUtils", "CwlFrameAddress"])],
	dependencies: [
		.package(url: "/Users/matt/Projects/CwlPreconditionTesting", .revision("daa6e033b8106bed90fed2558e7586675ff63288")),
	],
	targets: [
		.target(name: "ReferenceRandomGenerators"),
		.target(name: "CwlFrameAddress"),
		.target(name: "CwlUtils", dependencies: ["CwlFrameAddress"]),
		.testTarget(name: "CwlUtilsTests", dependencies: ["CwlUtils", "CwlFrameAddress", "ReferenceRandomGenerators", "CwlPreconditionTesting"]),
	]
)
