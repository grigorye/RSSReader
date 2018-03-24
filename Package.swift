// swift-tools-version:4.0
import PackageDescription

let package = Package(
	name: "CwlUtils",
   products: [
   	.library(name: "CwlUtils", type: .dynamic, targets: ["CwlUtils"]),
	],
	dependencies: [
		.package(url: "https://github.com/mattgallagher/CwlPreconditionTesting.git", .revision("2bff14d4cdd3d7ed4a1aa61b3e63afdba1d098c4")),
	],
	targets: [
		.target(
			name: "CwlUtils",
			dependencies: [
				.target(name: "CwlFrameAddress"),
				.target(name: "ReferenceRandomGenerators")
			]
		),
		.target(name: "CwlFrameAddress"),
		.target(name: "CwlUtilsConcat"),
		.target(name: "ReferenceRandomGenerators")
	]
)
