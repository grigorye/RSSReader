// swift-tools-version:4.0
import PackageDescription

let package = Package(
	name: "CwlUtils",
   products: [
   	.library(name: "CwlUtils", type: .dynamic, targets: ["CwlUtils"]),
	],
	dependencies: [
		.package(url: "https://github.com/mattgallagher/CwlPreconditionTesting.git", .revision("cb7ab89273cfd0725a7a2f865cc6fc560a9b9083")),
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
