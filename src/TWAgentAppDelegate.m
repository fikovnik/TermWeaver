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
#import "TWUtils.h"

#import <ShortcutRecorder/SRRecorderControl.h>

NSString *const kTerminalAppBundeId = @"com.apple.Terminal";
NSString *const kSystemEventsAppBundleId = @"com.apple.systemevents";
NSString *const kFinderAppBundeId = @"com.apple.finder";

NSString *const kUniversalAccessPreferencePanePath = @"com.apple.preference.universalaccess";

@interface TWAgentAppDelegate(Private)
- (void) openNewTerminalInNewWindow_ : (NSNumber *) newWindow;
- (TWHotKey *) reregisterHotKey_:(TWHotKey *) hotKey fromPrefKey:(NSString *) prefKey handler:(SEL) handler userData:(id) userData;

- (void) reregisterNewTabHotKey_;
- (void) reregisterNewWindowHotKey_;

@end

@implementation TWAgentAppDelegate

- (void) dealloc {
	[drivers release];
	[defaultDriver release];
	[operationQueue release];
	
	[newTabHotKey release];
	[newWindowHotKey release];
	
	[super dealloc];
}

- (void) applicationDidFinishLaunching : (NSNotification *) aNotification {
	NSLog(@"Starting TermWeaverAgent...");
	
	// only one instance
	if (NumberOfRunningProcessesWithBundleId(kTWAgentAppBundleId) > 1) {
		[[NSAlert alertWithMessageText:@"TermWeaver Agent already running" 
						 defaultButton:@"Quit"
					   alternateButton:nil
						   otherButton:nil 
			 informativeTextWithFormat:@"TermWeaver Agent is already running. This instance will now quit."] runModal];
		
		[NSApp terminate:nil];			
	}
	
	// check if we can actually do our business - use the accessibility API
	if (!AXAPIEnabled() && !AXIsProcessTrusted()) {
		NSLog(@"TermWeaver is not a trusted process");
		
		NSAlert *alert = [NSAlert alertWithMessageText:@"Unable to access accessibility API" 
										 defaultButton:@"Configure" 
									   alternateButton:@"Quit" 
										   otherButton:@"Later" 
							 informativeTextWithFormat:@"TermWeaver cannot access the accssibility API. Without this it will not be able to get the current directory of an application. You can give the access by checking the \"Enable access for assistive devices\" in Universal access preference pane. Do you want to do it now?"];
		
		NSInteger action = [alert runModal];
		
		if (action == NSAlertDefaultReturn) {
			if (!OpenSystemPreferencePane(kUniversalAccessPreferencePanePath)) {
				if ([[NSAlert alertWithMessageText:@"Unable to lunch Universal Access preference panel" 
									 defaultButton:@"OK" 
								   alternateButton:@"Quit"
									   otherButton:nil
						 informativeTextWithFormat:@"Unable to lunch Universal Access preference panel. Please enable the access for assistive devices manualy by going to the System Preferences Universal Access pane."] runModal] == NSAlertAlternateReturn) {
					[NSApp terminate:nil];			
				}
			}
		} else if (action == NSAlertAlternateReturn) {
			[NSApp terminate:nil];			
		} else if (action == NSAlertOtherReturn) {
			// continue
		}
		
		// we will not be able to run the drivers
		// right now all of them have to be disabled
		drivers = nil;
	} else {
		// get the accessibility object that provides access to system attributes.
		axSystemWideElement = AXUIElementCreateSystemWide();
		
		// intialize drivers
		NSMutableDictionary *d = [NSMutableDictionary dictionary];
		[d setObject: [[TWFinderAppCWDDriver alloc] init] forKey:@"Finder"];
		[d setObject: [[TWTerminalAppCWDDriver alloc] init] forKey:@"Terminal"];
		
		drivers =[[NSDictionary alloc] initWithDictionary:d];
	}
	
	// initialize default driver
	defaultDriver =[[TWDefaultCWDDriver alloc] init];
	
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
	
	[notificationCenter postNotificationName: kTWAgentLaunchedNotification object:nil];
	
	// prepare queue
	operationQueue = [[NSOperationQueue alloc] init];
	// to make sure only one operation at the time
	[operationQueue setMaxConcurrentOperationCount:1];
	
	// register hot keys
	NSNumber *bYes = [NSNumber numberWithBool:YES];
	NSDictionary *fullConfDict = [NSDictionary dictionaryWithObjects:[NSArray arrayWithObjects:bYes, bYes, nil] 
															 forKeys:[NSArray arrayWithObjects:kTWNewWindowHotKeyKey, kTWNewTabHotKeyKey, nil ]];
	[self preferencesChanged:[NSNotification notificationWithName:kTWPreferencesChangedNotification object:self userInfo:fullConfDict]];
}

- (void) applicationWillTerminate:(NSNotification *)aNotification {
	NSLog(@"Shutting down TermWeaverAgent...");
	
	// unregister hotkeys
	TWHotKeyManager *hotKeyManager =[TWHotKeyManager sharedHotKeyManager];
	[hotKeyManager unregisterHotKey: newWindowHotKey];
	[hotKeyManager unregisterHotKey: newTabHotKey];
	
	// remove all tasks
	[operationQueue cancelAllOperations];
		
	// notify
	[[NSDistributedNotificationCenter defaultCenter] postNotificationName: kTWAgentTerminatedNotification object:nil];
	
	return;
}


/**
 * This method is called from the hot key handler
 *
 * @param newWindow {@code 0} opens new tab otherwise new window 
 *
 */
- (void) openNewTerminalInNewWindow_:(NSNumber *) newWindow {
	[operationQueue addOperationWithBlock: ^{
		[self openNewTerminalInNewWindow:[newWindow boolValue]];
    }];	
}

- (void) openNewTerminalInNewWindow:(BOOL) newWindow {	
	if (!axSystemWideElement) {
		//open terminal in home directory
		[self openNewTerminalInNewWindow: newWindow initialDirectory:NSHomeDirectory()];
		
		return;
	}
	
	//the focused application
	AXUIElementRef focusedAppRef = nil;
	
	//get the focused application
	AXError axerror = AXUIElementCopyAttributeValue(axSystemWideElement,
													(CFStringRef) kAXFocusedApplicationAttribute,
													(CFTypeRef *) &focusedAppRef);
	
	if (axerror != kAXErrorSuccess) {
		//problem
		TWAXLogError(axerror, @"Unable to get focused application");
		
		//open terminal in home directory
		[self openNewTerminalInNewWindow: newWindow initialDirectory:NSHomeDirectory()];
		return;
	}
	
	TWAssert(focusedAppRef != nil, @"Focused application reference must not be nil.");
	
	//get the name of the application
	CFTypeRef appNameRef = nil;
	
	axerror = AXUIElementCopyAttributeValue(focusedAppRef,
											(CFStringRef) kAXTitleAttribute,
											(CFTypeRef *) &appNameRef);
	
	NSObject < TWCWDDriver > *driver = nil;
	
	if (axerror != kAXErrorSuccess) {
		//cannot deterimine the name of the application
		TWAXLogError(axerror, TWStr(@"Unable to determine the title of the focused app %@", focusedAppRef));
	} else {
		// we have the name of the application
		// try to find the driver
		
		TWAssert(appNameRef != nil, @"Application name reference must not be nil.");
		
		NSString       *appName = nil;
		
		if (CFGetTypeID(appNameRef) == CFStringGetTypeID()) {
			appName = (NSString *) appNameRef;
		} else {
			TWDevLog(@"Unexpected type of application name reference %ld", CFGetTypeID(appNameRef));
		}
		
		TWDevLog(@"Focused application %@ is %@ - looking for driver", focusedAppRef, appName);
		
		//find the corresponding driver
		driver =[drivers objectForKey:appName];
	}
	
	if (driver == nil) {
		// no driver so use default
		
		TWDevLog(@"No driver found so far - using default");
		driver = defaultDriver;
	}
	
	NSError *error;
	NSString *path = [driver getCWDFromApplication:focusedAppRef error:&error];
	
	if (path == nil) {
		TWDevLog(@"Driver could not find applications CWD, using home");
		path = NSHomeDirectory();
	}
	
	[self openNewTerminalInNewWindow: newWindow initialDirectory:path];
}

- (void) openNewTerminalInNewWindow:(BOOL) newWindow initialDirectory:(NSString *) path {
	NSLog(@"Opening terminal with path: %@ %d", path, newWindow);
	
	// script bridge to Terminal.app
	TerminalApplication *terminalApp =[SBApplication applicationWithBundleIdentifier:kTerminalAppBundeId];	
	if (terminalApp == nil) {
		NSLog(@"Unable to get the scripting bridge to Terminal.app %@", kTerminalAppBundeId);
		
		return;
	}
	
	BOOL wasRunning = [terminalApp isRunning];
	
	[terminalApp activate];
	
	if (wasRunning) {
		
		// script bridge to SystemEvents.app
		SystemEventsApplication *systemEventsApp =[SBApplication applicationWithBundleIdentifier:kSystemEventsAppBundleId];	
		if (systemEventsApp == nil) {
			NSLog(@"Unable to get the scripting bridge to SystemEvents.app %@", kSystemEventsAppBundleId);
			
			return;
		}
		
		// Terminal.app process - in order to access its menu
		SystemEventsProcess *terminalProc =[[systemEventsApp processes] objectWithName:@"Terminal"];
		if (![terminalProc exists]) {
			NSLog(@"Unable to get the Terminal.app process, unable to access its menu");
			
			return;
		}
		
		SystemEventsMenuBar *terminalMenuBar =[[terminalProc menuBars] objectAtIndex:0];
		SystemEventsMenuItem *shellMenu =[[[[terminalMenuBar menuBarItems] objectWithName:@"Shell"] menus] objectWithName:@"Shell"];
		
		//either "New Window" or "New Tab"
		SystemEventsMenuItem * menu = nil;
		
		if (newWindow) {
			menu =[[[[shellMenu menuItems] objectWithName: @"New Window"] menus] objectWithName:@"New Window"];
		} else {
			menu =[[[[shellMenu menuItems] objectWithName: @"New Tab"] menus] objectWithName:@"New Tab"];
		}
		
		//default profile menu item
		SystemEventsMenuItem * menuItem =[[menu menuItems] objectAtIndex:
										  0];
		if (menuItem == nil) {
			TWDevLog(@"Unable to get menu item for new %@", (newWindow ? @"window" : @"tab"));
		} else {
			TWDevLog(@"Opening new %@ using profile: %@", (newWindow ? @"window" : @"tab"),[menuItem name]);
			
			[menuItem select];
			[menuItem clickAt:nil];
		}
	} else {
		// the activate function will already open a new window
	}
	
	TerminalWindow *frontWindow =[[terminalApp windows] objectAtIndex:0];
	[terminalApp doScript: TWStr(@"cd \"%@\"", path) in:frontWindow];
}

- (void) preferencesChanged:(NSNotification *) notification {	
	TWDevLog(@"Received preferences changed natification - reconfiguring...");
	
	NSDictionary *userInfo = [notification userInfo];
	
	if ([userInfo objectForKey:kTWNewWindowHotKeyKey]) {
		[self reregisterNewWindowHotKey_];	
	}
	
	if ([userInfo objectForKey:kTWNewTabHotKeyKey]) {
		[self reregisterNewTabHotKey_];			
	}
	
	if (!newWindowHotKey && !newTabHotKey) {
		if ([notification object] == self) {
			// our own notification from the startup 
			NSAlert *alert = [NSAlert alertWithMessageText:@"No hot keys configured" 
											 defaultButton:@"Configure" 
										   alternateButton:@"Quit" 
											   otherButton:@"Later" 
								 informativeTextWithFormat:@"No hotkeys are configured. You can do this in the TermWeaver preference pane. If you press the button configure a the TermWeaver preference pane will open and defult settings will be used."];
			
			NSInteger action = [alert runModal];
			
			if (action == NSAlertDefaultReturn) {
				if (!OpenSystemPreferencePane(kTWPreferencesPaneBundleId)) {
					if ([[NSAlert alertWithMessageText:@"Unable to lunch TermWeaver preference panel" 
										 defaultButton:@"OK" 
									   alternateButton:@"Quit"
										   otherButton:nil
							 informativeTextWithFormat:@"Unable to lunch TermWeaver preference panel. It is probably not properly installed. Please reinstall it, by double clicling on the TermWeaver.prefpane file in the downloaded disk image."] runModal] == NSAlertAlternateReturn) {
						[NSApp terminate:nil];			
					}
					
				}
			} else if (action == NSAlertAlternateReturn) {
				[NSApp terminate:nil];			
			} else if (action == NSAlertOtherReturn) {
				// continue
			}
		}
	}
}

- (void) shutdown:(NSNotification *) __unused notification {
	NSLog(@"Received shutdown notification - terminating...");
	
	[NSApp terminate:nil];
}

#pragma mark Private methods

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

- (TWHotKey *) reregisterHotKey_:(TWHotKey *) hotKey fromPrefKey:(NSString *) prefKey handler:(SEL) handler userData:(id) userData {
	
	TWAssertNotNil(prefKey);
	TWAssertNotNil(handler);
	TWAssertNotNil(userData);
	
	TWDevLog(@"Reregistering hotKey %@ from prefKey: %@", hotKey, prefKey);
	
	TWPreferencesController *preferences = [TWPreferencesController sharedPreferences];
	TWHotKeyManager *hotKeyManager = [TWHotKeyManager sharedHotKeyManager];
	
	//reload preferences
	[preferences synchronize];
	
	TWHotKeyPreference *pref = [preferences objectForKey:prefKey];
	
	if (!pref) {
		TWDevLog(@"No preferences for hotKey: %@", prefKey);
		return nil;
	}
	
	TWHotKey *newHotKey = [pref hotKey];
	BOOL enabled = [pref enabled];
	
	if (enabled &&[newHotKey isEqualTo:hotKey]) {
		TWDevLog(@"Keys appear to be the same for prefKey: %@", prefKey);
		return hotKey;
	}
	
	if (hotKey) {
		//unregister first
		TWDevLog(@"Unregistering hotKey: %@ (%@)", prefKey, hotKey);
		[hotKeyManager unregisterHotKey:hotKey];
		[hotKey release];
	}
	
	if (!enabled) {
		TWDevLog(@"HotKey %@ (%@) is not enabled", prefKey, newHotKey);
		return nil;
	}
	
	[hotKeyManager registerHotKey:newHotKey
						  handler:@selector(openNewTerminalInNewWindow_:)
						 provider:self
						 userData:userData];
	
	return newHotKey;
}

@end
