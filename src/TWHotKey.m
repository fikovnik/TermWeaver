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

#import "TWHotKey.h"

#import "TWDefines.h"

NSString *const kTWHotKeyCodePrefKey = @"keyCode"; 
NSString *const kTWHotKeyFlagsPrefKey = @"flags";

@implementation TWHotKey

@synthesize keyCode;
@synthesize flags;

- (id) initWithKeyCode:(NSInteger)aKeyCode flags:(NSInteger)aFlags {
	
	if (![super init]) {
		return nil;
	}

	// TODO: assert that the code and modifiers make sense
	
	keyCode = aKeyCode;
	flags = aFlags;
	
	return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder {
	
	NSInteger aKeyCode = [aDecoder decodeIntegerForKey:kTWHotKeyCodePrefKey];
	NSInteger aFlags = [aDecoder decodeIntegerForKey:kTWHotKeyFlagsPrefKey];

	// TODO: check

	if (![self initWithKeyCode:aKeyCode flags:aFlags]) {
		return nil;
	}
	
	return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
	[aCoder encodeInteger:keyCode forKey:kTWHotKeyCodePrefKey];
	[aCoder encodeInteger:flags forKey:kTWHotKeyFlagsPrefKey];
}


- (NSString *) description {
	return TWStr(@"code: %d flags: %d", keyCode, flags);
}

- (BOOL) isEqualTo:(id)object {

	if ([object isKindOfClass:[self class]] == NO) {
		return NO;
	}
	
	TWHotKey *other = (TWHotKey *) object;
	return (keyCode == [other keyCode]
			&& flags == [other flags]);
}

// TODO: add hash

@end
