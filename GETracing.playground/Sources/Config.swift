import Foundation

import GETracing

private class BundleTag : NSObject {}

// #file for playgrounds is currently (Swift 4/Xcode 9.2) passed as a playground name, without any reference to the path. I don't know a way to figure out its path.
// Below is a workaround for the above, based on two facts:
// 1. The playground always seems to have Content.swift as the main source.
// 2. For macOS "Resources" folder of a (running) playground (auxilarly) framework seem to be a reference to Resources folder of the playground source itself.
// As a workaround, (relative) symbolic link Content.swift is placed into Resources of playground. And given two above facts, the playground might be referenced through the bundle of the running playground (auxilarly) source.
private let bundle: Bundle = Bundle(for: BundleTag.self)
private let playgroundFile = bundle.url(forResource: "Contents", withExtension: "swift")!.path

/// - Tag: Tracing-Function-Sample

public func x$<T>(file: String = #file, line: Int = #line, column: Int = #column, function: String = #function, _ valueClosure: @autoclosure () -> T ) -> T
{
	let value = valueClosure()
	// Substitute something more humane-readable for #function of top level code of the playground, that is otherwise something like "__lldb_expr_xxx"
	let playgroundAwareFunction = function.hasPrefix("__lldb_expr_") ? "<top-level>" : function
	traceAsNecessary(value, file: playgroundFile, line: line, column: column, function: playgroundAwareFunction, moduleReference: .playground(name: file), traceFunctionName: "x$")
	return value
}

public func configTracing() {
	
	// Ignore - used just for debugging.
	traceEnabledEnforced = true
	sourceLabelsEnabledEnforced = true
}
