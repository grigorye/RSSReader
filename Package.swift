// swift-tools-version:4.0
import PackageDescription

let package = Package(
	name: "CwlUtils",
	products: [.library(name: "CwlUtils", targets: ["CwlUtils", "CwlFrameAddress"])],
	dependencies: [
		.package(url: "/Users/matt/Projects/CwlPreconditionTesting", .revision("17db9e179a764608f07d215694e0b4d8abea9cf7")),
	],
	targets: [
		.target(name: "ReferenceRandomGenerators"),
		.target(name: "CwlFrameAddress"),
		.target(name: "CwlUtils", dependencies: ["CwlFrameAddress"]),
		.testTarget(name: "CwlUtilsTests", dependencies: ["CwlUtils", "CwlFrameAddress", "ReferenceRandomGenerators", "CwlPreconditionTesting"]),
	]
)
