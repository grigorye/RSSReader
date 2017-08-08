import PackageDescription

let package = Package(
	name: "CwlUtils",
	targets: [
		Target(name: "CwlUtils", dependencies: ["CwlFrameAddress", "ReferenceRandomGenerators"]),
		Target(name: "CwlFrameAddress"),
		Target(name: "CwlUtilsConcat"),
		Target(name: "ReferenceRandomGenerators")
	],
	dependencies: [
		.Package(url: "https://github.com/mattgallagher/CwlPreconditionTesting.git", Version(1, 1, 0, prereleaseIdentifiers: ["beta", "11"])),
	],
	exclude: [
		"Sources/CwlUtils_iOSHarness",
		"Sources/CwlUtils_macOSHarness",
		"Tests/CwlUtils_macOSTestApp",
		"Tests/CwlUtils_macOSTestAppUITests",
		"Tests/CwlUtils_iOSTestApp",
		"Tests/CwlUtils_iOSTestAppUITests",
		"Tests/CwlUtilsPerformanceTests"
	]
)
