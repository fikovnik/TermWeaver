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

#import "TWPreferencesController.h"

#import "TWConstants.h"
#import "TWUtils.h"
#import "TWLoginItems.h"
#import "TWDefines.h"

@interface TWPreferencesController (Private)

+ (void) handleAgentAppNotFound;

@end


@implementation TWPreferencesController

@dynamic shouldStartTermWeaverAtLogin;

SINGLETON_BOILERPLATE(TWPreferencesController, sharedPreferences);

// inspired from Growl
- (BOOL) shouldStartTermWeaverAtLogin {
	//get the prefpane bundle and find TWA within it.
	NSString *path = GetBundleResourcePath([NSBundle bundleWithIdentifier:kTWPreferencesPaneBundleId], kTWAgenAppName, @"app");
	
	if(!path) {
		[TWPreferencesController handleAgentAppNotFound];
		return false;
	}
	
	return [[TWLoginItems sharedLoginItems] isInLoginItemsApplicationWithPath:path];
}

- (void) setShouldStartTermWeaverAtLogin:(BOOL)enabled {
	TWDevLog(@"TermWeaver should start at login: %d", enabled);
	
	//get the prefpane bundle and find TWA within it.
	NSString *path = GetBundleResourcePath([NSBundle bundleWithIdentifier:kTWPreferencesPaneBundleId], kTWAgenAppName, @"app");
	
	if(!path) {
		[TWPreferencesController handleAgentAppNotFound];
		return;
	}
	
	[[TWLoginItems sharedLoginItems] toggleApplicationInLoginItemsWithPath:path enabled:enabled];
}

#pragma mark Helper methods

+ (void) handleAgentAppNotFound {
	NSString *path = GetBundleResourcePath([NSBundle bundleWithIdentifier:kTWPreferencesPaneBundleId], kTWAgenAppName, @"app");
	
	NSLog(@"TermWeaver install is corrupt, you will need to reinstall\nUnable to find agent application %@.app in preference pane bundle %@", kTWAgenAppName, path);
	
	NSMutableDictionary *d = [NSMutableDictionary dictionary];
	[d setObject:@"TermWeaver install is corrupt, you will need to reinstall" forKey:NSLocalizedDescriptionKey];
	[d setObject:TWStr(@"Unable to find agent application %@.app in preference pane bundle %@", kTWAgenAppName, path) forKey:NSLocalizedFailureReasonErrorKey];
	
	NSError *e = [NSError errorWithDomain:kTWErrorDomain code:101 userInfo:d];
	[NSAlert alertWithError:e];
}

@end
