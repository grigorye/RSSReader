//
//  NSObject+BadInstructionAwareTestCaseLoading.m
//  GEXCTest
//
//  Created by Grigory Entin on 16.01.2018.
//  Copyright © 2018 Grigory Entin. All rights reserved.
//

#import "NSObject+BadInstructionAwareTestCaseLoading.h"
#import "GEXCTest-Swift.h"
#import <objc/runtime.h>

@implementation XCTestCase (BadInstructionAwareTestCaseLoading)

#define let __auto const

+ (void)load {
	
	SEL oldSelector = @selector(invokeTest);
	SEL newSelector = @selector(badInstructionAwareInvokeTest);
	
	Method oldMethod = class_getInstanceMethod(self, oldSelector);
	Method newMethod = class_getInstanceMethod(self, newSelector);
	
	BOOL didAddMethod = class_addMethod(self, oldSelector, method_getImplementation(newMethod), method_getTypeEncoding(newMethod));
	
	if (didAddMethod) {
		class_replaceMethod(self, newSelector, method_getImplementation(oldMethod), method_getTypeEncoding(oldMethod));
	} else {
		method_exchangeImplementations(oldMethod, newMethod);
	}
}

@end
