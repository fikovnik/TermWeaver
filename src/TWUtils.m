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

#import "TWUtils.h"
#import "TWDefines.h"

NSString *const kSystemPreferencesAppBundeId = @"com.apple.systempreferences";

NSString *GetBundleResourcePath(NSBundle *bundle, NSString *resourceName, NSString *resourceType) {
	TWAssertNotNil(bundle);
	TWAssertNotNil(resourceName);
	TWAssertNotNil(resourceType);
	
	NSString *path = [bundle pathForResource:resourceName ofType:resourceType];
	if ([[NSFileManager defaultManager] fileExistsAtPath:path]) {
		return path;
	} else {
		return nil;
	}
}

NSURL *GetBundleResourceURL(NSBundle *bundle, NSString *resourceName, NSString *resourceType) {	
	NSString *path = GetBundleResourcePath(bundle, resourceName, resourceType);
	
	if (path) {
		return [NSURL fileURLWithPath:path];
	} else {
		return nil;
	}
}

BOOL OpenSystemPreferencePane(NSString *prefPaneId) {
	TWAssertNotNil(prefPaneId);
	
	NSString *source = TWStr(@"tell application \"System Preferences\"\n"
							"activate\n"
							"set current pane to pane \"%@\"\n"
							"end tell\n", prefPaneId);
	
	NSAppleScript *script = [[NSAppleScript alloc] initWithSource:source];
	
	NSDictionary *dict = nil;
	NSAppleEventDescriptor *event = [script executeAndReturnError:&dict];

	if (dict) {
		TWDevLog(@"Compilation of AppleScript: %@ failed: %@", source, dict);
	}
	
	[script release];	
	
	return event != nil;
}

NSInteger NumberOfRunningProcessesWithBundleId(NSString *bundleId) {
	TWAssertNotNil(bundleId);
	
	NSInteger n = 0;
	ProcessSerialNumber PSN = { kNoProcess, kNoProcess };
	
	while (GetNextProcess(&PSN) == noErr) {
		NSDictionary *infoDict = (NSDictionary *)ProcessInformationCopyDictionary(&PSN, kProcessDictionaryIncludeAllInformationMask);
		if(infoDict) {
			NSString *processBundleID = [infoDict objectForKey:(NSString *)kCFBundleIdentifierKey];
			if (processBundleID && [processBundleID isEqualToString:bundleId]) {
				n++;
			}
			
			CFMakeCollectable(infoDict);
			[infoDict release];
		}
	}
	
	return n;
}

BOOL IsProcessWithBundleIdRunning(NSString *bundleId) {
	return NumberOfRunningProcessesWithBundleId(bundleId) >= 1;
}