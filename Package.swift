import PackageDescription

let package = Package(
	name: "CwlUtils",
	targets: [
		Target(name: "CwlUtils", dependencies: ["CwlFrameAddress"]),
		Target(name: "CwlFrameAddress"),
		Target(name: "ReferenceRandomGenerators")
	],
	dependencies: [
		.Package(url: "https://github.com/mattgallagher/CwlPreconditionTesting.git", majorVersion: 1),
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
