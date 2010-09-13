//
//  TWLoginItems.h
//  TermWeaver
//
//  Created by Filip Krikava on 8/27/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface TWLoginItems : NSObject {
	
}

+ (TWLoginItems *) sharedLoginItems;

- (BOOL) isInLoginItemsApplicationWithPath:(NSString *)path;
- (void) toggleApplicationInLoginItemsWithPath:(NSString *)path enabled:(BOOL)enabled;

@end
