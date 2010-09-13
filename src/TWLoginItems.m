//
//  TWLoginItems.m
//  TermWeaver
//
//  Created by Filip Krikava on 8/27/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "TWLoginItems.h"

#import "TWDefines.h"

@interface TWLoginItems (Private)

- (LSSharedFileListItemRef) getApplicationLoginItemWithPath_:(NSString *)path;

@end


@implementation TWLoginItems

SINGLETON_BOILERPLATE(TWLoginItems, sharedLoginItems);

- (BOOL) isInLoginItemsApplicationWithPath:(NSString *)path {
	return [self getApplicationLoginItemWithPath_:path] != nil;	
}

- (void) toggleApplicationInLoginItemsWithPath:(NSString *)path enabled:(BOOL)enabled {
	OSStatus status;
	LSSharedFileListItemRef existingItem = [self getApplicationLoginItemWithPath_:path];
	CFURLRef URLToApp = CFURLCreateWithFileSystemPath(kCFAllocatorDefault, (CFStringRef)path, kCFURLPOSIXPathStyle, true);
	LSSharedFileListRef loginItems = LSSharedFileListCreate(NULL,kLSSharedFileListSessionLoginItems, NULL);
	
	if (enabled && (existingItem == NULL)) {
		NSString *displayName = [[NSFileManager defaultManager] displayNameAtPath:path];
		IconRef icon = NULL;
		FSRef ref;
		Boolean gotRef = CFURLGetFSRef(URLToApp, &ref);
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
		
		LSSharedFileListInsertItemURL(loginItems, kLSSharedFileListItemBeforeFirst, (CFStringRef)displayName, icon, URLToApp, /*propertiesToSet*/ NULL, /*propertiesToClear*/ NULL);
	} else if (!enabled && (existingItem != NULL)) {
		LSSharedFileListItemRemove(loginItems, existingItem);
	}	
}

- (LSSharedFileListItemRef) getApplicationLoginItemWithPath_:(NSString *)path {
	CFURLRef URLToApp = CFURLCreateWithFileSystemPath(kCFAllocatorDefault, (CFStringRef)path, kCFURLPOSIXPathStyle, true);
	
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
			Boolean foundIt = CFEqual(URL, URLToApp);
			CFRelease(URL);
			
			if (foundIt)
				existingItem = item;
			break;
		}
	}
	
	CFRelease(URLToApp);
	
	return existingItem;
}

@end
