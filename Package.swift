// swift-tools-version:4.0
import PackageDescription

let package = Package(
	name: "CwlUtils",
   products: [
   	.library(name: "CwlUtils", type: .dynamic, targets: ["CwlUtils"]),
	],
	dependencies: [
		.package(url: "https://github.com/mattgallagher/CwlPreconditionTesting.git", .revision("ce96cb1d81644b92c66fd2b622260905526a7c5f")),
	],
	targets: [
		.target(
			name: "CwlUtils",
			dependencies: [
				.target(name: "CwlFrameAddress"),
				.target(name: "ReferenceRandomGenerators")
			]
		),
		.testTarget(
			name: "CwlUtilsTests",
			dependencies: [
				.target(name: "CwlUtils"),
				.product(name: "CwlPreconditionTesting")
			]
		),
		.target(name: "CwlFrameAddress"),
		.target(name: "CwlUtilsConcat"),
		.target(name: "ReferenceRandomGenerators")
	]
)
