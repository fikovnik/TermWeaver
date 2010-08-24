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

#import "TWAppDelegate.h"

#import "TWFinderAppCWDDriver.h"
#import "TWTerminalAppCWDDriver.h"
#import "TWDefaultCWDDriver.h"

#import "Terminal.h"
#import "SystemEvents.h"

#import "TWDefines.h"

// TODO: externalize
static NSString *const TERMINAL_APP_ID = @"com.apple.Terminal"; 
static NSString *const SYSTEMEVENTS_APP_ID = @"com.apple.systemevents";

@implementation TWAppDelegate


// Introduction to Scripting Bridge Programming Guide for Cocoa
// http://developer.apple.com/mac/library/documentation/Cocoa/Conceptual/ScriptingBridgeConcepts/Introduction/Introduction.html

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {

	// check if we can actually do our business - use the accessibility API
	if (! AXAPIEnabled() && ! AXIsProcessTrusted())	{
		NSLog(@"Not authorized!");
		// TODO: handle this
		
		return;
	}
	
	// get the accessibility object that provides access to system attributes.
	mSystemWideElement = AXUIElementCreateSystemWide();
	
	// intialize drivers
	// use just calls
	NSMutableDictionary *d = [NSMutableDictionary dictionary];
	[d setObject:[[TWFinderAppCWDDriver alloc] init] forKey:@"Finder"];
	[d setObject:[[TWTerminalAppCWDDriver alloc] init] forKey:@"Terminal"];
	
	mDrivers = [[NSDictionary alloc] initWithDictionary:d];
	
	// initialize default driver
	mDefaultDriver = [[TWDefaultCWDDriver alloc] init];
	
	// register the key shortcut
	// TODO: register real shortcut
	[NSEvent addGlobalMonitorForEventsMatchingMask:NSKeyDownMask 
			   handler:^(NSEvent *event) {
				   //[NSApp activateIgnoringOtherApps:YES];
				   NSLog(@"%@", event);
				   
				   if ([event keyCode] == 42
					   && [event modifierFlags] & NSAlternateKeyMask
					   && [event modifierFlags] & NSControlKeyMask)  {
					   // TODO: measure how many operation do we do per time to prevent some major scew ups
					   // TODO: allow maximum call each 2 seconds
					   // TODO: use lock to make sure that only one operation runs at a time
					   // NSLock, NSOperationQueue (size=1), NSOperation
					   BOOL newWindow = !([event modifierFlags] & NSShiftKeyMask);
					   [self openNewTerminalInNewWindow:newWindow];
				   }
			   }
	];	
}

- (void) dealloc {
	[mDrivers release];
	[mDefaultDriver release];
	
	[super dealloc];
}

- (void) openNewTerminalInNewWindow:(BOOL)newWindow {
	
	// the focused application
	AXUIElementRef focusedAppRef = nil;	
    
	// get the focused application
	AXError axerror = AXUIElementCopyAttributeValue(mSystemWideElement,
												  (CFStringRef)kAXFocusedApplicationAttribute,
												  (CFTypeRef*)&focusedAppRef);
	
	if (axerror != kAXErrorSuccess) {
		// problem
		[TWAppDelegate logAXError:axerror withMessage:@"Unable to get focused application"];			
		
		// open terminal in home directory
		[self openNewTerminalInNewWindow:newWindow withInitialDirectory:NSHomeDirectory()];
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
		[TWAppDelegate logAXError:axerror withMessage:TWStr(@"Unable to determine the title of the focused app %@", focusedAppRef)];
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
		driver = [mDrivers objectForKey:appName];
	}
		
	if (driver == nil) {
		TWDevLog(@"No driver found so far - using default");
		driver = mDefaultDriver;
	}


	// TODO: following should go to a separate task
	NSError *error;
	NSString *path = [driver getCWDFromApplication:focusedAppRef error:&error];
	
	if (path == nil) {
		TWDevLog(@"Driver could not find applications CWD, using home");
		path = NSHomeDirectory();
	}
	
	[self openNewTerminalInNewWindow:newWindow withInitialDirectory:path];
}

- (void) openNewTerminalInNewWindow:(BOOL)newWindow withInitialDirectory:(NSString *)path {
	NSLog(@"Opening terminal with path: %@ %d", path, newWindow);
	
	TerminalApplication *terminalApp = [SBApplication applicationWithBundleIdentifier:TERMINAL_APP_ID];
	
	if (terminalApp == nil) {
		// TODO: handle this
	}
	
	[terminalApp activate];
				
	SystemEventsApplication *systemEventsApp = [SBApplication applicationWithBundleIdentifier:SYSTEMEVENTS_APP_ID];
	
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

+ (void) logAXError:(AXError)error withMessage:(NSString *)message {
	NSString *detail = nil;
	
	switch (error) {
		case kAXErrorNoValue:
			detail = @"The requested value or AXUIElementRef does not exist.";
			break;
		case kAXErrorAttributeUnsupported:
			detail = @"The specified AXUIElementRef does not support the specified attribute.";
			break;
		case kAXErrorIllegalArgument:
			detail = @"One or more of the arguments is an illegal value.";
			break;
		case kAXErrorInvalidUIElement:
			detail = @"The AXUIElementRef is invalid.";
			break;
		case kAXErrorCannotComplete:
			detail = @"The function cannot complete because messaging has failed in some way.";
			break;
		case kAXErrorNotImplemented:
			detail = @"The process does not fully support the accessibility API.";
			break;
		default:
			detail = TWStr(@"Unexpected type of problem with AX: %d", error);
			break;
	}
	
	TWDevLog(@"AX problem - %@ (%@)", message, detail);
}

@end
