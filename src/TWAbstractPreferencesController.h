//
//  TWPreferencesController.h
//  TermWeaver
//
//  Created by Filip Krikava on 8/25/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

// TODO: KVO compliant?
@interface TWAbstractPreferencesController : NSObject {

}

- (void) registerDefaults:(NSDictionary *)defaults;
- (void) synchronize;

- (void) setObject:(id)value forKey:(NSString *)key;

- (id) objectForKey:(NSString *)key;
- (NSNumber *) numberForKey:(NSString *)key;
- (BOOL) boolForKey:(NSString *)key;

@end
