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

#import "TWFinderAppCWDDriver.h"

#import "Finder.h"

#import "TWDefines.h"

static NSString *const FINDER_APP_ID = @"com.apple.finder"; 

@implementation TWFinderAppCWDDriver


- (NSString *) getCWDFromApplication:(AXUIElementRef)application error:(NSError **)error {

	FinderApplication *finderApp = [SBApplication applicationWithBundleIdentifier:FINDER_APP_ID];
	
	if (![finderApp isRunning]) {
		TWDevLog(@"Finder is not running");		
		return nil;
	}
	
	FinderWindow *frontWindow = [[finderApp FinderWindows] objectAtIndex:0];

	if (frontWindow == nil) {
		TWDevLog(@"Unable to get the front window of Finder.app");
		return nil;
	} else {
		TWDevLog(@"Using front-most window: %@ of Finder.app", [frontWindow name]);
	}
		
	FinderFinderWindow *finderFrontWindow = (FinderFinderWindow *)frontWindow;
	
	FinderItem *pathItem = [[finderFrontWindow target] get];
	if (pathItem == nil) {
		TWDevLog(@"No target property set on the front window of Finder.app");
		return nil;
	}

	if (pathItem == nil) {
		TWDevLog(@"Path item is not valid in the front window of Finder.app");
		return nil;		
	}
	
	NSURL* pathURL = [NSURL URLWithString: [pathItem URL]];
	TWDevLog(@"Selected path item URL: %@", pathURL);
		
	NSString* path = [pathURL path];
	TWDevLog(@"Selected path: %@", path);
		
	// just to make sure
	NSFileManager *fileMng = [NSFileManager defaultManager];
	BOOL isDir = false;
	if (![fileMng fileExistsAtPath:path isDirectory:&isDir]) {
		TWDevLog(@"The path %@ does from the front window of Finder.app could not be used", path);
		return nil;
	}		
	
	if (!isDir) {
		TWDevLog(@"The path %@ is not a directory", path);

		// it is not a directory - get the part
		path = [path stringByDeletingLastPathComponent];
	}
	
	return path;
}


@end
