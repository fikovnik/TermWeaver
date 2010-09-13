//
//  TWHotKey+SRKeyCombo.m
//  TermWeaver
//
//  Created by Filip Krikava on 8/31/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "TWHotKey+SRKeyCombo.h"

#import "TWDefines.h"

@implementation TWHotKey (SRKeyCombo)

+ (TWHotKey *) hotKey:(KeyCombo)keyCombo {
	TWHotKey *hotKey = [[TWHotKey alloc] initWithKeyCode:keyCombo.code flags:keyCombo.flags];
	
	return hotKey;
}

- (KeyCombo) asKeyCombo {
	KeyCombo keyCombo = SRMakeKeyCombo(keyCode, flags);

	return keyCombo;
}

@end
