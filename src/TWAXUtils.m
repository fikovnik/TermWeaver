//
//  TWAXUtils.m
//  TermWeaver
//
//  Created by Filip Krikava on 8/26/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

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
