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
