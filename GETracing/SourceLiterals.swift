//
//  SourceLiterals.swift
//  GETracing
//
//  Created by Grigory Entin on 28/01/2019.
//

public func literalForArguments(of calleeName: StaticString, contents: String, line: Int, column: UInt, function: StaticString) -> String {
	let line = Int(line)
	let column = Int(column)
	let calleeName = calleeName.description
	let lineTexts = contents.components(separatedBy: "\n")
	let lineText = lineTexts[line - 1] + lineTexts[line...].joined(separator: "\n")
	let adjustedColumn: Int = {
		let columnIndex = lineText.index(lineText.startIndex, offsetBy: column - 1)
		let prefix = lineText[..<columnIndex]
		let prefixReversed = String(prefix.reversed())
		let traceFunctionNameReversed = String(calleeName.reversed())
		let rangeOfClosingBracket = prefixReversed.rangeOfClosingBracket("(", openingBracket: ")", followedBy: traceFunctionNameReversed)!
		let indexOfOpeningBracketInPrefixReversed = rangeOfClosingBracket.lowerBound
		return column - prefixReversed.distance(from: prefixReversed.startIndex, to: indexOfOpeningBracketInPrefixReversed)
	}()
	let columnIndex = lineText.index(lineText.startIndex, offsetBy: adjustedColumn - 1)
	let lineTextTail = String(lineText[columnIndex...])
	let (openingBracket, closingBracket) = ("(", ")")
	let indexOfClosingBracketInTail = lineTextTail.rangeOfClosingBracket(closingBracket, openingBracket: openingBracket)!.lowerBound
	let label = String(lineTextTail[..<indexOfClosingBracketInTail])
	return label
}

public func literalForArguments(of calleeName: StaticString, sourceFileURL: URL, line: Int, column: UInt, function: StaticString) throws -> String {
	let contents = try String(contentsOf: sourceFileURL, encoding: String.Encoding.utf8)
	return literalForArguments(of: calleeName, contents: contents, line: line, column: column, function: function)
}
