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

#import "TWDefines.h"

#import <ShortcutRecorder/SRCommon.h>

@interface TWHotKey (Private)

- (NSInteger) carbonFlags;

@end

@implementation TWHotKey (Private) 

- (NSInteger) carbonFlags {
	return SRCocoaToCarbonFlags([self flags]);
}

@end

@interface TWHotKeyRegistartion : NSObject
{
	TWHotKey *hotKey;
	SEL handler;
	id provider;
	id userData;
	EventHotKeyRef ref;
}

@property (readonly) TWHotKey *hotKey;
@property (readonly) SEL handler;
@property (readonly) id provider;
@property (readonly) id userData;
@property (readonly) EventHotKeyRef ref;

- (id) initWithHotKey:(TWHotKey *)aHotKey handler:(SEL)aHandler provider:(id)aProvider userData:(id)aUserData ref:(EventHotKeyRef)aRef;

@end

@implementation TWHotKeyRegistartion

@synthesize hotKey;
@synthesize handler;
@synthesize provider;
@synthesize userData;
@synthesize ref;

- (id) initWithHotKey:(TWHotKey *)aHotKey handler:(SEL)aHandler provider:(id)aProvider userData:(id)aUserData ref:(EventHotKeyRef)aRef {
	if (![super init]) {
		return nil;
	}
	
	TWAssertNotNil(aHotKey);
	TWAssertNotNil(aHandler);
	TWAssertNotNil(aProvider);
	TWAssertNotNil(aRef);
	
	hotKey = [aHotKey retain];
	handler = aHandler;
	provider = [aProvider retain];
	userData = [aUserData retain];
	ref = aRef;
	
	return self;
}

- (void) dealloc {
	[hotKey release];
	[provider release];
	[userData release];
	
	[super dealloc];
}

@end

static NSMutableDictionary *hotKeys;

OSStatus hotKeyHandler(EventHandlerCallRef inHandlerCallRef,EventRef inEvent,
					   void *userData)
{
	EventHotKeyID hotKeyID;
	GetEventParameter(inEvent,kEventParamDirectObject,typeEventHotKeyID,NULL,
					  sizeof(hotKeyID),NULL,&hotKeyID);
	
	NSNumber *id = [NSNumber numberWithInt:hotKeyID.id];
	
	TWHotKeyRegistartion* hotKeyReg = [hotKeys objectForKey:id];
	
	if (hotKeyReg != nil) {
		objc_msgSend([hotKeyReg provider], [hotKeyReg handler], [hotKeyReg userData]);
		return noErr;
	} else {
		return eventNotHandledErr;
	}
}

@implementation TWHotKeyManager

SINGLETON_BOILERPLATE(TWHotKeyManager, sharedHotKeyManager);

- (id) init {
	if (![super init]) {
		return nil;
	}
	
	hotKeys = [[NSMutableDictionary alloc] init];
	hotKeyIdSequence = 1;
	
	EventTypeSpec eventType;
	eventType.eventClass=kEventClassKeyboard;
	eventType.eventKind=kEventHotKeyPressed;
	
	InstallApplicationEventHandler(&hotKeyHandler, 1, &eventType, NULL, NULL);	
	
	return self;
}

- (void) dealloc {
	[hotKeys release];
	
	[super dealloc];
}

// TODO: modify to propagate error
- (void) unregisterHotKey:(TWHotKey *)hotKey {
	TWAssertNotNil(hotKey);
	
	TWDevLog(@"Unregistering hotKey %@", hotKey);
	
	// search for the registration
	TWHotKeyRegistartion *hotKeyReg;
	for (TWHotKeyRegistartion *e in [hotKeys allValues]) {
		if ([hotKey isEqualTo:[e hotKey]]) {
			hotKeyReg = e;
			break;
		}
	}
	
	if (hotKeyReg) {
		UnregisterEventHotKey([hotKeyReg ref]);
	} else {
		// no registration found
		TWDevLog(@"Unable to unregister hotKey: %@ - it has not been registered by this HotKeyManager", hotKey);
	}

}

- (void) registerHotKey:(TWHotKey *)hotKey handler:(SEL)handler provider:(id)provider userData:(id)userData {

	TWAssertNotNil(hotKey);
	TWAssertNotNil(handler);
	TWAssertNotNil(provider);
	
	TWDevLog(@"Registering hotKey %@", hotKey);

	EventHotKeyID hotKeyID;
	// TODO: extract
	hotKeyID.signature='TWHT';
	// TODO: make sure it is thread safe
	hotKeyID.id=hotKeyIdSequence++;
	
	EventHotKeyRef hotKeyRef;
	RegisterEventHotKey([hotKey keyCode], [hotKey carbonFlags], hotKeyID,
						GetApplicationEventTarget(), 0, &hotKeyRef);
	
	if (!hotKeyRef) {
		NSLog(@"Unable to register hotKey: %@", hotKey);
		return;
	}
	
	// safe
	TWHotKeyRegistartion *hotKeyReg = [[TWHotKeyRegistartion alloc] initWithHotKey:hotKey 
																		   handler:handler 
																		  provider:provider
																		  userData:userData
																			   ref:hotKeyRef];
	[hotKeys setObject:hotKeyReg forKey:[NSNumber numberWithInt:hotKeyID.id]];	
}

@end
