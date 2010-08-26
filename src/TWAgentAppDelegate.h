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

#import <Cocoa/Cocoa.h>
#import <Carbon/Carbon.h>

#import "TWCWDDriver.h":

@interface TWAgentAppDelegate : NSObject <NSApplicationDelegate> {
	NSDictionary *mDrivers;
	NSObject<TWCWDDriver> *mDefaultDriver;
	AXUIElementRef mSystemWideElement;
	
	// TODO: make names to be consistent mHotKeyNewWindow
	EventHotKeyRef newTabHotKeyRef;
	EventHotKeyRef newWindowHotKeyRef;
}

- (void) openNewTerminalInNewWindow:(BOOL)newWindow;
- (void) openNewTerminalInNewWindow:(BOOL)newWindow withInitialDirectory:(NSString *)path;

- (void) preferencesChanged:(NSNotification *) notification;
- (void) shutdown:(NSNotification *) notification;

- (void) reconfigure;

+ (void) logAXError:(AXError)error withMessage:(NSString *)message;

@end
