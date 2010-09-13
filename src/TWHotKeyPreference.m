//
//  TWHotKeyPreferences.m
//  TermWeaver
//
//  Created by Filip Krikava on 8/30/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "TWHotKeyPreference.h"
#import "TWHotKey.h"

NSString *const kTWHotKeyPrefKey = @"hotKey";
NSString *const kTWHotKeyEnabledPrefKey = @"enabled";

@implementation TWHotKeyPreference

@synthesize hotKey;
@synthesize enabled;

- (id)initWithCoder:(NSCoder *)aDecoder {

	if (![super init]) {
		return nil;
	}
		
	TWHotKey *aHotKey = [aDecoder decodeObjectForKey:kTWHotKeyPrefKey];
	BOOL aState = [aDecoder decodeBoolForKey:kTWHotKeyEnabledPrefKey];

	// TODO: check
	
	[self setHotKey:[aHotKey retain]];
	[self setEnabled:aState];
	
	return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
	[aCoder encodeObject:hotKey forKey:kTWHotKeyPrefKey];
	[aCoder encodeBool:enabled forKey:kTWHotKeyEnabledPrefKey];
}

@end
