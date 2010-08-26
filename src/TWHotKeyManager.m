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

#import "TWHotKeyManager.h"

static NSMutableDictionary *hotKeys = nil;
static int hotKeyIdSequence = 1;

@implementation TWHotKeyManager

OSStatus hotKeyHandler(EventHandlerCallRef inHandlerCallRef,EventRef inEvent,
					   void *userData)
{
	EventHotKeyID hotKeyID;
	GetEventParameter(inEvent,kEventParamDirectObject,typeEventHotKeyID,NULL,
					  sizeof(hotKeyID),NULL,&hotKeyID);
	
	NSNumber *id = [NSNumber numberWithInt:hotKeyID.id];
	
	TWHotKey* hotKey = [hotKeys objectForKey:id];
	
	if (hotKey != nil) {
		objc_msgSend([hotKey provider], [hotKey handler], [hotKey userData]);
		return noErr;
	} else {
		return eventNotHandledErr;
	}
	
	
}

+ (void) initialize {
	hotKeys = [[NSMutableDictionary alloc] init];
	
	EventTypeSpec eventType;
	eventType.eventClass=kEventClassKeyboard;
	eventType.eventKind=kEventHotKeyPressed;
	
	InstallApplicationEventHandler(&hotKeyHandler, 1, &eventType, NULL, NULL);
}

// TODO: modify to propagate error
+ (void) unregisterHotKey:(EventHotKeyRef)hotKey {
	// TODO: assert
	
	UnregisterEventHotKey(hotKey);
}

+ (EventHotKeyRef) registerHotKey:(TWHotKey *)hotKey {
	// TODO: assert
	
	// TODO: id should be already part of hotKey
	int id=hotKeyIdSequence++;
	EventHotKeyID hotKeyID;
	// TODO: extract
	hotKeyID.signature='TWHT';
	// TODO: make sure it is thread safe
	hotKeyID.id=id;
	[hotKey setId:id];
	
	EventHotKeyRef hotKeyRef;
	
	RegisterEventHotKey([hotKey keyCode], [hotKey modifiers], hotKeyID,
						GetApplicationEventTarget(), 0, &hotKeyRef);
	
	[hotKeys setObject:[hotKey retain] forKey:[NSNumber numberWithInt:id]];
	
	return hotKeyRef;
}

@end
