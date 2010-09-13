/*
 Copyright (c) 2010 Filip Krikava
 
 Permission is hereby granted, free of charge, to any person obtaining a copy
 of this software and associated documentation files (the "Software"), to deal
 in the Software without restriction, including without limitation the rights
 to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 copies of the Software, and to permit persons to whom the Software is
 furnished to do so, subject to the following conditions:
 
 The above copyright notice and this permission notice shall be included in
 all copies or substantial portions of the Software.
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 THE SOFTWARE.
 */

#import "TWAXUtils.h"

#import "TWDefines.h"

void TWAXLogError(AXError error, NSString *message) {
	NSString *detail = nil;
	
	switch (error) {
		case kAXErrorNoValue:
			detail = @"The requested value or AXUIElementRef does not exist.";
			break;
		case kAXErrorAttributeUnsupported:
			detail = @"The specified AXUIElementRef does not support the specified attribute.";
			break;
		case kAXErrorIllegalArgument:
			detail = @"One or more of the arguments is an illegal value.";
			break;
		case kAXErrorInvalidUIElement:
			detail = @"The AXUIElementRef is invalid.";
			break;
		case kAXErrorCannotComplete:
			detail = @"The function cannot complete because messaging has failed in some way.";
			break;
		case kAXErrorNotImplemented:
			detail = @"The process does not fully support the accessibility API.";
			break;
		default:
			detail = TWStr(@"Unexpected type of problem with AX: %d", error);
			break;
	}
	
	TWDevLog(@"AX problem - %@ (%@)", message, detail);
}
