//
//  TWPreferencesController.m
//  TermWeaver
//
//  Created by Filip Krikava on 8/25/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "TWAbstractPreferencesController.h"

#import "TWHotKey+SRKeyCombo.h"
#import "TWConstants.h"
#import "TWDefines.h"

// TODO: extract
NSString *const kTWNewWindowHotKeyKey = @"newWindowHotKey";
NSString *const kTWNewTabHotKeyKey = @"newTabHotKey";


// TODO: extract some methods to some utility class
@implementation TWAbstractPreferencesController

- (id) objectForKey:(NSString *)key {
	TWAssertNotNil(key);

	id value = (id)CFPreferencesCopyAppValue((CFStringRef)key, (CFStringRef)kTWAgentAppBundleId);
	CFMakeCollectable(value);

	id value_ = nil;
	if ([value isKindOfClass:[NSData class]]) {
		value_ = [NSKeyedUnarchiver unarchiveObjectWithData:value];

		if (!value_) {
			NSLog(@"Unable to unarchive %@ for key %@", value, key);
			value_ = value;
		}		
	}
	
	TWDevLog(@"Getting from preferences: %@=%@", key, value_);
	
	// TODO: potential leak?
	return value_;
}

- (void) setObject:(id)value forKey:(NSString *)key {
	// value can be nil
	TWAssertNotNil(key);
		
	id value_ = nil;
	
	if ([value conformsToProtocol:@protocol(NSCoding)]) {
		value_ = [NSKeyedArchiver archivedDataWithRootObject:value];
		
		if (!value_) {
			NSLog(@"Unable to archive %@ for key %@", value, key);
			value_ = value;
		}		
	} else {
		value_ = value;
	}
	
	TWDevLog(@"Setting preference: %@=%@", key, value_);

	CFPreferencesSetAppValue((CFStringRef)key,
							 (CFPropertyListRef)value_,
							 (CFStringRef)kTWAgentAppBundleId);
	
	[self synchronize];
	
	[[NSDistributedNotificationCenter defaultCenter] postNotificationName:kTWPreferencesChangedNotification 
																   object:nil
																 userInfo:[NSDictionary dictionaryWithObject:[NSNumber numberWithBool:YES] 
																									  forKey:key]];
}

- (BOOL) boolForKey:(NSString *)key {
	TWAssertNotNil(key);

	NSNumber *value = [self numberForKey:key];
	
	if (value) {
		return [value boolValue];
	}
	
	return NO;
}

- (NSNumber *) numberForKey:(NSString *)key {
	TWAssertNotNil(key);

	id valueObject = [self objectForKey:key];
	
	if (valueObject
		&& [valueObject isKindOfClass:[NSNumber class]]) {
		return (NSNumber *)valueObject;
	}
	
	return nil;
}

- (void) registerDefaults:(NSDictionary *)defaults {
	TWAssertNotNil(defaults);

	TWDevLog(@"registering defaults: %@", defaults);
	
	NSUserDefaults *agentAppDefaults = [NSUserDefaults standardUserDefaults];
	[agentAppDefaults addSuiteNamed:kTWAgentAppBundleId];
	
	NSDictionary *existing = [agentAppDefaults persistentDomainForName:kTWAgentAppBundleId];
	
	if (existing) {
		NSMutableDictionary *domain = [defaults mutableCopy];
		
		[domain addEntriesFromDictionary:existing];
		[agentAppDefaults setPersistentDomain:domain forName:kTWAgentAppBundleId];
		[domain release];
	} else {
		[agentAppDefaults setPersistentDomain:defaults forName:kTWAgentAppBundleId];
	}
		
	[self synchronize];
}

- (void) synchronize {	
	if(!CFPreferencesAppSynchronize((CFStringRef)kTWAgentAppBundleId)) {
		NSLog(@"Unable to sync preferences %@", kTWAgentAppBundleId);
		// TODO: handle
	}
}


@end
