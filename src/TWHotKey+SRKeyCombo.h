//
//  TWHotKey+SRKeyCombo.h
//  TermWeaver
//
//  Created by Filip Krikava on 8/31/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import <ShortcutRecorder/SRCommon.h>

#import "TWHotKey.h"

@interface TWHotKey (SRKeyCombo)

+ (TWHotKey *) hotKey:(KeyCombo)keyCombo;
- (KeyCombo) asKeyCombo;

@end
