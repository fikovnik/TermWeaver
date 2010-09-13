//
//  TWHotKeyPreferences.h
//  TermWeaver
//
//  Created by Filip Krikava on 8/30/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

extern NSString *const kTWHotKeyPrefKey;
extern NSString *const kTWHotKeyEnabledPrefKey;

@class TWHotKey;

@interface TWHotKeyPreference : NSObject <NSCoding> {
	@private
	TWHotKey *hotKey;
	BOOL enabled;
}

@property(retain) TWHotKey *hotKey;
@property(assign) BOOL enabled;

@end
