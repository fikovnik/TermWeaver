//
//  TWPreferencesController.h
//  TermWeaver
//
//  Created by Filip Krikava on 8/31/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "TWAbstractPreferencesController.h"

extern NSString *const kTWNewWindowHotKeyKey;
extern NSString *const kTWNewTabHotKeyKey;

@interface TWPreferencesController : TWAbstractPreferencesController

@property(assign) BOOL shouldStartTermWeaverAtLogin;

+ (TWPreferencesController *) sharedPreferences;

@end
