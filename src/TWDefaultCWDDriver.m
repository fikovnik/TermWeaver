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

#import "TWDefaultCWDDriver.h"

#import "TWAgentAppDelegate.h"

#import "TWAgentConstants.h"
#import "TWAXUtils.h"
#import "TWDefines.h"

@implementation TWDefaultCWDDriver

- (NSString *) getCWDFromApplication:(AXUIElementRef)appRef error:(NSError **)error {
	
	AXUIElementRef focusedWindowRef = nil;
	AXError axerror = AXUIElementCopyAttributeValue(appRef,
												  (CFStringRef)kAXFocusedWindowAttribute,
												  (CFTypeRef*)&focusedWindowRef);
	
	if (axerror != kAXErrorSuccess) {
		TWAXLogError(axerror, TWStr(@"Unable to retrive focused window of application %@", appRef));
	} else {
		TWDevLog(@"Using focused window %@ of %@", focusedWindowRef, appRef);
	}
	
	CFTypeRef pathRef = nil;
	NSString *path = nil;
	
	for (NSString *e in [NSArray arrayWithObjects:(NSString *)kAXDocumentAttribute, (NSString *)kAXURLAttribute, (NSString *)kAXFilenameAttribute, nil]) {
		axerror = AXUIElementCopyAttributeValue(focusedWindowRef,
													  (CFStringRef)e,
													  (CFTypeRef*)&pathRef);
		
		if (axerror != kAXErrorSuccess) {
			TWAXLogError(axerror, TWStr(@"Unable to retrive %@ attribute of focused window %@", e, focusedWindowRef));
		} else {
			if (CFGetTypeID(pathRef) == CFStringGetTypeID()) {
				path = (NSString *)pathRef;				
				TWDevLog(@"Trying to use %@ value %@", e, path);
			} else {
				TWDevLog(@"Unexpected type of %@ attribute value %ld", e, CFGetTypeID(pathRef));
			}			
		}
		
		if (path != nil) {
			// process path - remove localhost and stuff
			
			// trim
			path = [path stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
			
			// handle URL
			NSURL* pathURL = [NSURL URLWithString: path];
			if (pathURL != nil) {
				TWDevLog(@"Selected path item URL: %@", pathURL);
				path = [pathURL path];
			}
			
			// TODO: check if it is a valid path
			NSFileManager *fileMng = [NSFileManager defaultManager];
			BOOL isDir = false;
			if (![fileMng fileExistsAtPath:path isDirectory:&isDir]) {
				// path does not exists
				TWDevLog(@"Path does not exist: %@ - skiping", path);
				continue;
			}
			
			if (!isDir) {
				// it is not a directory - get the part
				path = [path stringByDeletingLastPathComponent];
			}
			
			break;
		} else {
			continue;
		}
	}
	
	return path;
}

@end
