import Foundation

import GETracing

public func $<T>(file: String = #file, line: Int = #line, column: Int = #column, function: String = #function, _ valueClosure: @autoclosure () -> T ) -> T
{
	let value = valueClosure()
	traceAsNecessary(value, file: file, line: line, column: column, function: function, moduleReference: .playground, traceFunctionName: "$")
	return value
}

public func log(record: LogRecord) {
	let text = defaultLoggedTextWithThread(for: record)
	print(text)
}

public func defaultLoggedTextWithThread(for record: LogRecord) -> String {
	let text = defaultLoggedText(for: record)
	let threadDescription = Thread.isMainThread ? "-" : "\(DispatchQueue.global().label)"
	let textWithThread = "[\(threadDescription)] \(text)"
	return textWithThread
}

public func defaultLoggedText(for record: LogRecord) -> String {
	let location = record.location
	let locationDescription = "\(location.function), \(record.playgroundName ?? location.fileURL.lastPathComponent):\(location.line)"
	guard let label = record.label else {
		return "\(locationDescription) ◾︎ \(record.message)"
	}
	return "\(locationDescription) ◾︎ \(label): \(record.message)"
}

public func configTracing() {
	traceEnabledEnforced = true
	sourceLabelsEnabledEnforced = true
	sourceLabelClosuresEnabled = false

	loggers = [log]
}
