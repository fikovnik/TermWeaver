//
//  TWPreferencesController.h
//  TermWeaver
//
//  Created by Filip Krikava on 8/25/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

// TODO: extract somewhere
extern NSString *const kTermWaverPreferencesPaneBundleId;
extern NSString *const kTermWaverAgentBundleId;

// TODO: change to use "key".{enabled|flags|code}
extern NSString *const kHotKeyNewTerminalWindowEnabled;
extern NSString *const kHotKeyNewTerminalWindowCode;
extern NSString *const kHotKeyNewTerminalWindowFlags;
extern NSString *const kHotKeyNewTerminalTabEnabled;
extern NSString *const kHotKeyNewTerminalTabCode;
extern NSString *const kHotKeyNewTerminalTabFlags;

extern NSString *const kTermWeaverShutdownRequest;
extern NSString *const kTermWeaverPreferencesChanged;

// TODO: make a general class
@interface TWPreferencesController : NSObject {

}

// add as category
@property(assign) BOOL shouldStartTermWeaverAtLogin;

// TODO: add here bundleId
+ (TWPreferencesController *) sharedPreferences;

- (void) registerDefaults:(NSDictionary *)inDefaults;

// Key-Value-Code Complient
- (id) valueForKey:(NSString *)key;
- (void) setValue:(id)value forKey:(NSString *)key;

- (NSNumber *) numberForKey:(NSString *)key;
- (BOOL) boolForKey:(NSString *)key;

@end
