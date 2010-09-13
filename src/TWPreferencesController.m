//
//  TWPreferencesController.m
//  TermWeaver
//
//  Created by Filip Krikava on 8/31/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

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
