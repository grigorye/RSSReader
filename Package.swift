import PackageDescription

let package = Package(
	name: "CwlUtils",
	targets: [
		Target(name: "CwlUtils", dependencies: ["CwlFrameAddress", "ReferenceRandomGenerators"]),
		Target(name: "CwlFrameAddress"),
		Target(name: "ReferenceRandomGenerators")
	],
	dependencies: [
		.Package(url: "/Users/matt/Projects/CwlPreconditionTesting", Version(1, 0, 3)),
	],
	exclude: [
		"LICENSE.txt",
		"Sources/CwlUtils.h",
		"Sources/CwlUtils_iOSHarness",
		"Sources/CwlUtils_macOSHarness",
		"Tests/CwlUtilsTests-BridgingHeader.h",
		"Tests/CwlUtils_macOSTestApp",
		"Tests/CwlUtils_macOSTestAppUITests",
		"Tests/CwlUtils_iOSTestApp",
		"Tests/CwlUtils_iOSTestAppUITests",
		"Tests/CwlUtilsPerformanceTests"
	]
)
