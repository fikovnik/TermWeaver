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

#import "TWAgentAppDelegate.h"

#import "TWFinderAppCWDDriver.h"
#import "TWTerminalAppCWDDriver.h"
#import "TWDefaultCWDDriver.h"
#import "TWHotKeyManager.h"
#import "TWPreferencesController.h"

#import "Terminal.h"
#import "SystemEvents.h"

#import "TWHotKeyPreference.h"
#import "TWConstants.h"
#import "TWAgentConstants.h"
#import "TWAXUtils.h"
#import "TWDefines.h"

#import <ShortcutRecorder/SRRecorderControl.h>

NSString *const kTerminalAppBundeId = @"com.apple.Terminal"; 
NSString *const kSystemEventsAppBundleId = @"com.apple.systemevents";
NSString *const kFinderAppBundeId = @"com.apple.finder"; 

// TODO: self-aware stuff

@interface TWAgentAppDelegate (Private)

- (void) openNewTerminalInNewWindow_:(NSNumber *)newWindow;

- (TWHotKey *) reregisterHotKey_:(TWHotKey *)hotKey fromPrefKey:(NSString *)prefKey handler:(SEL)handler userData:(id)userData;

- (void) reregisterNewTabHotKey_;
- (void) reregisterNewWindowHotKey_;

@end


@implementation TWAgentAppDelegate

OSStatus hotKeyHandler(EventHandlerCallRef inHandlerCallRef,EventRef inEvent,
					   void *userData);


// Introduction to Scripting Bridge Programming Guide for Cocoa
// http://developer.apple.com/mac/library/documentation/Cocoa/Conceptual/ScriptingBridgeConcepts/Introduction/Introduction.html

	// TODO: which one? awakeFromNib?
- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
	NSLog(@"Configuring TermWeaverAgent...");

	// check if we can actually do our business - use the accessibility API
	if (! AXAPIEnabled() && ! AXIsProcessTrusted())	{
		NSLog(@"Not authorized!");
		// TODO: handle this
		
		return;
	}
	
	// get the accessibility object that provides access to system attributes.
	axSystemWideElement = AXUIElementCreateSystemWide();
	
	// intialize drivers
	// use just calls
	NSMutableDictionary *d = [NSMutableDictionary dictionary];
	[d setObject:[[TWFinderAppCWDDriver alloc] init] forKey:@"Finder"];
	[d setObject:[[TWTerminalAppCWDDriver alloc] init] forKey:@"Terminal"];
	
	drivers = [[NSDictionary alloc] initWithDictionary:d];
	
	// initialize default driver
	defaultDriver = [[TWDefaultCWDDriver alloc] init];
	
	// register hot keys
	// TODO: if there is no settings - quit
	[self reregisterNewWindowHotKey_];
	[self reregisterNewTabHotKey_];
	
	// TODO: gracefull shtudown - UnregisterEventHotKey
	
	// register notifications
	NSNotificationCenter *notificationCenter = [NSDistributedNotificationCenter defaultCenter];
	
	[notificationCenter addObserver:self
			  selector:@selector(preferencesChanged:)
				  name:kTWPreferencesChangedNotification
				object:nil];
	
	[notificationCenter addObserver:self
			  selector:@selector(shutdown:)
				  name:kTWAgentShutdownRequestNotification
				object:nil];
	
	[notificationCenter postNotificationName:kTWAgentLaunchedNotification object:nil];
}

- (void) dealloc {
	[drivers release];
	[defaultDriver release];
	
	[newTabHotKey release];
	[newWindowHotKey release];
	
	[super dealloc];
}

- (void) openNewTerminalInNewWindow_:(NSNumber *)newWindow {
	// as a task
	[self openNewTerminalInNewWindow:[newWindow boolValue]];
}

- (void) openNewTerminalInNewWindow:(BOOL)newWindow {
	
	// the focused application
	AXUIElementRef focusedAppRef = nil;	
    
	// get the focused application
	AXError axerror = AXUIElementCopyAttributeValue(axSystemWideElement,
												  (CFStringRef)kAXFocusedApplicationAttribute,
												  (CFTypeRef*)&focusedAppRef);
	
	if (axerror != kAXErrorSuccess) {
		// problem
		TWAXLogError(axerror, @"Unable to get focused application");			
		
		// open terminal in home directory
		[self openNewTerminalInNewWindow:newWindow initialDirectory:NSHomeDirectory()];
		return;
	}
	
	TWAssert(focusedAppRef != nil, @"Focused application reference must not be nil.");

	// get the name of the application
	CFTypeRef appNameRef = nil;
	
	axerror = AXUIElementCopyAttributeValue(focusedAppRef,
												  (CFStringRef)kAXTitleAttribute,
												  (CFTypeRef*)&appNameRef);
	
	NSObject<TWCWDDriver> *driver = nil;
	
	if (axerror != kAXErrorSuccess) {
		// cannot deterimine the name of the application
		TWAXLogError(axerror, TWStr(@"Unable to determine the title of the focused app %@", focusedAppRef));
	} else {
		TWAssert(appNameRef != nil, @"Application name reference must not be nil.");

		NSString *appName = nil;

		if (CFGetTypeID(appNameRef) == CFStringGetTypeID()) {
			appName = (NSString *)appNameRef;
		} else {
			TWDevLog(@"Unexpected type of application name reference %ld", CFGetTypeID(appNameRef));
		}

		TWDevLog(@"Focused application %@ is %@ - looking for driver", focusedAppRef, appName);
		
		// find the corresponding driver
		driver = [drivers objectForKey:appName];
	}
		
	if (driver == nil) {
		TWDevLog(@"No driver found so far - using default");
		driver = defaultDriver;
	}


	// TODO: following should go to a separate task
	NSError *error;
	NSString *path = [driver getCWDFromApplication:focusedAppRef error:&error];
	
	if (path == nil) {
		TWDevLog(@"Driver could not find applications CWD, using home");
		path = NSHomeDirectory();
	}
	
	[self openNewTerminalInNewWindow:newWindow initialDirectory:path];
}

- (void) openNewTerminalInNewWindow:(BOOL)newWindow initialDirectory:(NSString *)path {
	NSLog(@"Opening terminal with path: %@ %d", path, newWindow);
	
	TerminalApplication *terminalApp = [SBApplication applicationWithBundleIdentifier:kTerminalAppBundeId];
	
	if (terminalApp == nil) {
		// TODO: handle this
	}
	
	[terminalApp activate];
				
	SystemEventsApplication *systemEventsApp = [SBApplication applicationWithBundleIdentifier:kSystemEventsAppBundleId];
	
	if (systemEventsApp == nil) {
		// TODO: handle this
	}
	
	SystemEventsProcess *terminalProc =[[systemEventsApp processes] objectWithName:@"Terminal"];
	if (![terminalProc exists]) {
		TWDevLog(@"Unable to get the Terminal.app process");
	}
	
	SystemEventsMenuBar *terminalMenuBar = [[terminalProc menuBars] objectAtIndex:0];	
	SystemEventsMenuItem *shellMenu = [[[[terminalMenuBar menuBarItems] objectWithName:@"Shell"] menus] objectWithName:@"Shell"];
	
	// either "New Window" or "New Tab"
	SystemEventsMenuItem *menu = nil;
	
	if (newWindow) {
		menu = [[[[shellMenu menuItems] objectWithName:@"New Window"] menus] objectWithName:@"New Window"];
	} else {
		menu = [[[[shellMenu menuItems] objectWithName:@"New Tab"] menus] objectWithName:@"New Tab"];		
	}
	
	// default profile menu item
	SystemEventsMenuItem *menuItem = [[menu menuItems] objectAtIndex:0];
	if (menuItem == nil) {
		TWDevLog(@"Unable to get menu item for new %@",(newWindow ? @"window" : @"tab"));
	} else {
		TWDevLog(@"Opening new %@ using profile: %@",(newWindow ? @"window" : @"tab"), [menuItem name]);

		[menuItem select];
		[menuItem clickAt:nil];
	}

//		// this code shoudl add new tab directly using the scripting bridge
//		TerminalTab *tab = [[[terminalApp classForScriptingClass:@"tab"] alloc] init];
//		[[[[terminalApp windows] objectAtIndex:0] tabs] addObject:tab];
//		NSLog(@"%@", [tab tty]); 
	
	TerminalWindow *frontWindow = [[terminalApp windows] objectAtIndex:0];
	[terminalApp doScript:TWStr(@"cd \"%@\"", path) in:frontWindow];
}

- (void) preferencesChanged:(NSNotification *) notification {
	NSLog(@"Received preferences changed natification - reconfiguring...");

	NSDictionary *userInfo = [notification userInfo];
	
	NSLog(@"%@", userInfo);
}

- (void) shutdown:(NSNotification *) __unused notification {
	NSLog(@"Received shutdown notification - terminating...");
	
	[NSApp terminate:nil];
}

- (void)applicationWillTerminate:(NSNotification *) notification {
	
	[[NSDistributedNotificationCenter defaultCenter] postNotificationName:kTWAgentTerminatedNotification object:nil];
}

- (void) reregisterNewWindowHotKey_ {
	newWindowHotKey = [self reregisterHotKey_:newWindowHotKey 
				fromPrefKey:kTWNewWindowHotKeyKey 
					handler:@selector(openNewTerminalInNewWindow_:) 
				   userData:[NSNumber numberWithBool:YES]];	
}

- (void) reregisterNewTabHotKey_ {
	newTabHotKey = [self reregisterHotKey_:newTabHotKey 
				fromPrefKey:kTWNewTabHotKeyKey 
					handler:@selector(openNewTerminalInNewWindow_:) 
				   userData:[NSNumber numberWithBool:NO]];	
}

- (TWHotKey *) reregisterHotKey_:(TWHotKey *)hotKey fromPrefKey:(NSString *)prefKey handler:(SEL)handler userData:(id)userData {

	TWAssertNotNil(prefKey);
	TWAssertNotNil(handler);
	TWAssertNotNil(userData);

	TWDevLog(@"Reregistering hotKey %@ from prefKey: %@", hotKey, prefKey);
	
	TWPreferencesController *preferences = [TWPreferencesController sharedPreferences];
	TWHotKeyManager *hotKeyManager = [TWHotKeyManager sharedHotKeyManager];

	// reload preferences
	[preferences synchronize];

	TWHotKeyPreference *pref = [preferences objectForKey:prefKey];
	
	if (!pref) {
		TWDevLog(@"No preferences for hotKey: %@", prefKey);
		return nil;
	}
	
	TWHotKey *newHotKey = [pref hotKey];
	BOOL enabled = [pref enabled];
	
	if (enabled && [newHotKey isEqualTo:hotKey]) {
		TWDevLog(@"Keys appear to be the same for prefKey: %@", prefKey);
		return hotKey;
	}
	
	if (hotKey) {
		// unregister first
		TWDevLog(@"Unregistering hotKey: %@ (%@)", prefKey, hotKey);
		[hotKeyManager unregisterHotKey:hotKey];
		[hotKey release];
	}

	if (!enabled) {
		TWDevLog(@"HotKey %@ (%@) is not enabled", prefKey, newHotKey);
		return nil;
	}
	
	NSLog(@"Registering hotKey: %@ (%@)", prefKey, newHotKey);
	[hotKeyManager registerHotKey:newHotKey 
						  handler:@selector(openNewTerminalInNewWindow_:) 
						 provider:self 
						 userData:userData];
	
	return newHotKey;
}

@end
