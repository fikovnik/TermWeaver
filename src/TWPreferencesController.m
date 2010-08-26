//
//  TWPreferencesController.m
//  TermWeaver
//
//  Created by Filip Krikava on 8/25/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "TWPreferencesController.h"

#import "TWDefines.h"

// TODO: rename
// TODO: move somewhere else
NSString *const kTermWaverPreferencesPaneBundleId = @"net.nkuyu.apps.termweaver";
NSString *const kTermWaverAgentBundleId = @"net.nkuyu.app.termweaver.agent";

NSString *const kHotKeyNewTerminalWindowEnabled = @"hotKeyNewTerminalWindowEnabled";
NSString *const kHotKeyNewTerminalWindowCode = @"hotKeyNewTerminalWindowCode";
NSString *const kHotKeyNewTerminalWindowFlags = @"hotKeyNewTerminalWindowFlags";

NSString *const kHotKeyNewTerminalTabEnabled = @"hotKeyNewTerminalTabEnabled";
NSString *const kHotKeyNewTerminalTabCode = @"hotKeyNewTerminalTabCode";
NSString *const kHotKeyNewTerminalTabFlags = @"hotKeyNewTerminalTabFlags";

NSString *const kTermWeaverPreferencesChanged = @"kTermWeaverPreferencesChanged";
NSString *const kTermWeaverShutdownRequest = @"kTermWeaverShutdownRequest";



// TODO: extract some methods to some utility class
@implementation TWPreferencesController

@dynamic shouldStartTermWeaverAtLogin;

SINGLETON_BOILERPLATE(TWPreferencesController, sharedPreferences);

- (id) valueForKey:(NSString *)key {
	id value = (id)CFPreferencesCopyAppValue((CFStringRef)key, (CFStringRef)kTermWaverAgentBundleId);
	if(value)
		CFMakeCollectable(value);
	return [value autorelease];
}

- (void) setValue:(id)value forKey:(NSString *)key {
	CFPreferencesSetAppValue((CFStringRef)key,
							 (CFPropertyListRef)value,
							 (CFStringRef)kTermWaverAgentBundleId);
	
	CFPreferencesAppSynchronize((CFStringRef)kTermWaverAgentBundleId);
		
	[[NSDistributedNotificationCenter defaultCenter] postNotificationName:kTermWeaverPreferencesChanged object:nil];
}

- (BOOL) boolForKey:(NSString *)key {
	NSNumber *value = [self numberForKey:key];\
	if (value) {
		return [value boolValue];
	}
	return NO;
}

- (NSNumber *) numberForKey:(NSString *)key {
	id valueObject = [self valueForKey:key];
	if (valueObject
		&& [valueObject isKindOfClass:[NSNumber class]]) {
		return (NSNumber *)valueObject;
	}
	return nil;
}

- (void) registerDefaults:(NSDictionary *)inDefaults {
	NSUserDefaults *agentAppDefaults = [[NSUserDefaults alloc] init];
	[agentAppDefaults addSuiteNamed:kTermWaverAgentBundleId];
	
	NSDictionary *existing = [agentAppDefaults persistentDomainForName:kTermWaverAgentBundleId];
	if (existing) {
		NSMutableDictionary *domain = [inDefaults mutableCopy];
		[domain addEntriesFromDictionary:existing];
		[agentAppDefaults setPersistentDomain:domain forName:kTermWaverAgentBundleId];
		[domain release];
	} else {
		[agentAppDefaults setPersistentDomain:inDefaults forName:kTermWaverAgentBundleId];
	}
	[agentAppDefaults release];
	
	CFPreferencesAppSynchronize((CFStringRef)kTermWaverAgentBundleId);
}


// TODO: following two should be merged
// inspired from Growl
- (BOOL) shouldStartTermWeaverAtLogin {
	Boolean    foundIt = false;
	
	//get the prefpane bundle and find TWA within it.
	NSBundle *prefPaneBundle = [NSBundle bundleWithIdentifier:kTermWaverPreferencesPaneBundleId];
	NSString *pathToTWA      = [prefPaneBundle pathForResource:@"TermWeaverAgent" ofType:@"app"];
	
	if(!pathToTWA) {
		NSLog(@"TermWeaver install is corrupt, you will need to reinstall\nyour prefpane bundle is:%@\n your pathToTWA is:%@", prefPaneBundle, pathToTWA);
		return false;
	}
	
	//get the file url to TWA.
	CFURLRef urlToTWA = CFURLCreateWithFileSystemPath(kCFAllocatorDefault, (CFStringRef)pathToTWA, kCFURLPOSIXPathStyle, true);
	
	UInt32 seed = 0U;
	LSSharedFileListRef loginItems = LSSharedFileListCreate(NULL,kLSSharedFileListSessionLoginItems, NULL);
	NSArray *currentLoginItems = [NSMakeCollectable(LSSharedFileListCopySnapshot(loginItems, &seed)) autorelease];
	for (id itemObject in currentLoginItems) {
		LSSharedFileListItemRef item = (LSSharedFileListItemRef)itemObject;
		
		UInt32 resolutionFlags = kLSSharedFileListNoUserInteraction | kLSSharedFileListDoNotMountVolumes;
		CFURLRef URL = NULL;
		OSStatus err = LSSharedFileListItemResolve(item, resolutionFlags, &URL, /*outRef*/ NULL);
		if (err == noErr) {
			foundIt = CFEqual(URL, urlToTWA);
			CFRelease(URL);
			
			if (foundIt)
				break;
		}
	}
	
	CFRelease(urlToTWA);

	return foundIt;
}

- (void) setShouldStartTermWeaverAtLogin:(BOOL)enabled {
	//get the prefpane bundle and find TWA within it.
	NSBundle *prefPaneBundle = [NSBundle bundleWithIdentifier:kTermWaverPreferencesPaneBundleId];
	NSString *pathToTWA      = [prefPaneBundle pathForResource:@"TermWeaverAgent" ofType:@"app"];
	
	if(!pathToTWA) {
		NSLog(@"TermWeaver install is corrupt, you will need to reinstall\nyour prefpane bundle is:%@\n your pathToTWA is:%@", prefPaneBundle, pathToTWA);
		return;
	}
	
	OSStatus status;
	CFURLRef URLToToggle = (CFURLRef)[NSURL fileURLWithPath:pathToTWA];
	LSSharedFileListItemRef existingItem = NULL;
	
	UInt32 seed = 0U;
	LSSharedFileListRef loginItems = LSSharedFileListCreate(NULL,kLSSharedFileListSessionLoginItems, NULL);
	NSArray *currentLoginItems = [NSMakeCollectable(LSSharedFileListCopySnapshot(loginItems, &seed)) autorelease];
	for (id itemObject in currentLoginItems) {
		LSSharedFileListItemRef item = (LSSharedFileListItemRef)itemObject;
		
		UInt32 resolutionFlags = kLSSharedFileListNoUserInteraction | kLSSharedFileListDoNotMountVolumes;
		CFURLRef URL = NULL;
		OSStatus err = LSSharedFileListItemResolve(item, resolutionFlags, &URL, /*outRef*/ NULL);
		if (err == noErr) {
			Boolean foundIt = CFEqual(URL, URLToToggle);
			CFRelease(URL);
			
			if (foundIt) {
				existingItem = item;
				break;
			}
		}
	}
	
	if (enabled && (existingItem == NULL)) {
		NSString *displayName = [[NSFileManager defaultManager] displayNameAtPath:pathToTWA];
		IconRef icon = NULL;
		FSRef ref;
		Boolean gotRef = CFURLGetFSRef(URLToToggle, &ref);
		if (gotRef) {
			status = GetIconRefFromFileInfo(&ref,
											/*fileNameLength*/ 0, /*fileName*/ NULL,
											kFSCatInfoNone, /*catalogInfo*/ NULL,
											kIconServicesNormalUsageFlag,
											&icon,
											/*outLabel*/ NULL);
			if (status != noErr)
				icon = NULL;
		}
		
		LSSharedFileListInsertItemURL(loginItems, kLSSharedFileListItemBeforeFirst, (CFStringRef)displayName, icon, URLToToggle, /*propertiesToSet*/ NULL, /*propertiesToClear*/ NULL);
	} else if (!enabled && (existingItem != NULL)) {
		LSSharedFileListItemRemove(loginItems, existingItem);
	}
}

@end
