//: Playground - noun: a place where people can play

import Foundation

configTracing()

func foo(_ x: Int) -> Int {
	return $($(x) + 1)
}

$(0)
$("foo")
$(foo(1))
