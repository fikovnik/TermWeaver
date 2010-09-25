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

#import "TWPreferencePane.h"
#import "TWPreferencesController.h"
#import "TWHotKeyPreference.h"
#import "TWLoginItems.h"
#import "TWHotKey+SRKeyCombo.h"
#import "TWUtils.h"
#import "TWConstants.h"
#import "TWDefines.h"

@interface TWPreferencePane (Private)

- (BOOL) loadHotKeyPref_:(NSString *)prefKey recorder:(SRRecorderControl *)recorder stateButton:(NSButton *)stateButton;
- (void) setHotKeyPref_:(NSString *)prefKey fromRecorder:(SRRecorderControl *)recorder;
- (void) handleAgentAppNotFound_;

@end

@implementation TWPreferencePane

@synthesize preferences;

#pragma mark Preference pane overwritten methods

- (id) initWithBundle:(NSBundle *)bundle {
	
	if (![super initWithBundle:bundle]) {
		return nil;
	}
	
	preferences = [TWPreferencesController sharedPreferences];	     
	
	return self;
}

- (void) mainViewDidLoad
{
	[self loadDefaults];
	
	//	[aboutTermWeaverText setDrawsBackground:NO];
	NSString *path = [[self bundle] pathForResource:@"About" ofType:@"html"]; 
	NSAttributedString *aboutText = [[NSAttributedString alloc] initWithPath:path documentAttributes:nil];
    [aboutText autorelease];
	[aboutTermWeaverText setAttributedStringValue:aboutText];
	
	
	NSNotificationCenter *notificationCenter = [NSDistributedNotificationCenter defaultCenter];
	
	[notificationCenter addObserver:self 
						   selector:@selector(termWeaverLaunched:)   
							   name:kTWAgentLaunchedNotification 
							 object:nil];
	
	[notificationCenter addObserver:self 
						   selector:@selector(termWeaverTerminated:) 
							   name:kTWAgentTerminatedNotification 
							 object:nil];
}

- (void) willSelect {	
	[self checkTermWeaverRunning];
	
	// should start at login
	NSString *path = GetBundleResourcePath([NSBundle bundleWithIdentifier:kTWPreferencesPaneBundleId], kTWAgenAppName, @"app");	
	[shouldStartAtLoginButton setState:(path && [[TWLoginItems sharedLoginItems] isInLoginItemsApplicationWithPath:path])];
	
	[self loadHotKeyPref_:kTWNewWindowHotKeyKey recorder:newWindowHotKeyRecorder stateButton:newWindowHotKeyEnabledButton];
	[self loadHotKeyPref_:kTWNewTabHotKeyKey recorder:newTabHotKeyRecorder stateButton:newWindowHotKeyEnabledButton];
}

- (void) loadDefaults {
	NSMutableDictionary *defaults = [NSMutableDictionary dictionaryWithCapacity:2];
	
	TWHotKeyPreference *hotKeyPref = [[TWHotKeyPreference alloc] init];
	
	// version info
	[defaults setObject:kTWVersion forKey:kTWVersionKey];	
	
	[hotKeyPref setEnabled:YES];
	[hotKeyPref setHotKey:[[[TWHotKey alloc] initWithKeyCode:kTWDefaultNewWindowHotKeyCode flags:kTWDefaultNewWindowHotKeyFlags] autorelease]];
	[defaults setObject:[NSKeyedArchiver archivedDataWithRootObject:hotKeyPref] forKey:kTWNewWindowHotKeyKey];
	[hotKeyPref autorelease];
	
	hotKeyPref = [[TWHotKeyPreference alloc] init];
	[hotKeyPref setEnabled:YES];
	[hotKeyPref setHotKey:[[[TWHotKey alloc] initWithKeyCode:kTWDefaultNewTabHotKeyCode flags:kTWDefaultNewTabHotKeyFlags] autorelease]];
	[defaults setObject:[NSKeyedArchiver archivedDataWithRootObject:hotKeyPref] forKey:kTWNewTabHotKeyKey];
	[hotKeyPref autorelease];
	
	[preferences registerDefaults:defaults];	
}

#pragma mark TermWeaver lifecycle handling methods

- (void) checkTermWeaverRunning {
	[startStopTermWeaverButton setEnabled:YES];
	
	if ([self isTermWeaverRunning]) {
		[startStopTermWeaverButton setTitle:@"Stop TermWeaver"];
		[termWeaverRunningStatusText setStringValue:@"TermWeaver is running"];
	} else {
		[startStopTermWeaverButton setTitle:@"Start TermWeaver"];
		[termWeaverRunningStatusText setStringValue:@"TermWeaver is stopped"];	
	}
	
	[termWeaverRunningProgress stopAnimation:self];
}

- (void) termWeaverLaunched:(NSNotification *)notification {
	TWDevLog(@"Received %@ notification", notification);
	
	[self checkTermWeaverRunning];	
}

- (void) termWeaverTerminated:(NSNotification *)notification {
	TWDevLog(@"Received %@ notification", notification);
	
	[self checkTermWeaverRunning];	
}

- (BOOL) isTermWeaverRunning {
	return IsProcessWithBundleIdRunning(kTWAgentAppBundleId);
}

/*!
 * @brief Launches TermWeaverHelperApp.
 */
- (void) launchTermWeaver {
	TWDevLog(@"Launching TermWeaver Agent");
	
	NSURL *agentURL = GetBundleResourceURL([NSBundle bundleWithIdentifier:kTWPreferencesPaneBundleId], kTWAgenAppName, @"app");
	if (!agentURL) {
		[self handleAgentAppNotFound_];
		return;
	}
	
	// don't allow the button to be clicked while we update
	[startStopTermWeaverButton setEnabled:NO];
	
	// start animation
	[termWeaverRunningProgress startAnimation:self];
	
	// update our status visible to the user
	[termWeaverRunningStatusText setStringValue:@"Launching TermWeaver..."];
	
	unsigned options = NSWorkspaceLaunchWithoutAddingToRecents 
	| NSWorkspaceLaunchWithoutActivation 
	| NSWorkspaceLaunchAsync;
	
	[[NSWorkspace sharedWorkspace] openURLs:[NSArray arrayWithObject:agentURL]
	                withAppBundleIdentifier:nil
	                                options:options
	         additionalEventParamDescriptor:nil
	                      launchIdentifiers:NULL];
	
	// After 6 seconds force a status update, in case TermWeaver didn't start/stop
	[self performSelector:@selector(checkTermWeaverRunning)
			   withObject:nil
			   afterDelay:6.0];
}

/*!
 * @brief Terminates running TermWeaverHelperApp instances.
 */
- (void) terminateTermWeaver {
	TWDevLog(@"Terminating TermWeaver Agent");
	
	// Don't allow the button to be clicked while we update
	[startStopTermWeaverButton setEnabled:NO];
	[termWeaverRunningProgress startAnimation:self];
	
	// Update our status visible to the user
	[termWeaverRunningStatusText setStringValue:@"Terminating TermWeaver..."];
	
	// Ask the TermWeaver Helper App to shutdown
	[[NSDistributedNotificationCenter defaultCenter] postNotificationName:kTWAgentShutdownRequestNotification 
																   object:nil];
	
	// After 6 seconds force a status update, in case termWeaver didn't start/stop
	[self performSelector:@selector(checkTermWeaverRunning)
			   withObject:nil
			   afterDelay:6.0];
}

#pragma mark UI actions

- (IBAction) hotKeyEnablementChangedAction:(id)sender {
	NSString *key = nil;
	SRRecorderControl *recorder = nil;
	
	if (sender == newWindowHotKeyEnabledButton) {
		key = kTWNewWindowHotKeyKey;
		recorder = newWindowHotKeyRecorder;
	} else if (sender == newTabHotKeyEnabledButton) {
		key = kTWNewTabHotKeyKey;
		recorder = newTabHotKeyRecorder;
	} else {
		// TODO: handle this
	}
	
	[self setHotKeyPref_:key fromRecorder:recorder stateButton:sender];
}

- (IBAction) startStopTermWeaverAction:(id) __unused sender {	
	// Our desired state is a toggle of the current state;
	if ([self isTermWeaverRunning]) {
		[self terminateTermWeaver];
	} else {
		[self launchTermWeaver];
	}
}

- (IBAction) shouldStartAtLoginAction:(id) __unused sender {
	BOOL enabled = [shouldStartAtLoginButton state];
	
	TWDevLog(@"TermWeaver should start at login: %d", enabled);
	
	//get the prefpane bundle and find TWA within it.
	NSString *path = GetBundleResourcePath([NSBundle bundleWithIdentifier:kTWPreferencesPaneBundleId], kTWAgenAppName, @"app");
	
	if(!path && enabled) {
		[self handleAgentAppNotFound_];
		[shouldStartAtLoginButton setState:NO];
		
		return;
	} 
	
	[[TWLoginItems sharedLoginItems] toggleApplicationInLoginItemsWithPath:path enabled:enabled];
}

- (IBAction) gotoHomePageAction:(id) __unused sender {
	BOOL res = [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:kTWHomePageURL]];
	
	if (!res) {
		[[NSAlert alertWithMessageText:@"Unable to launch browser" 
						 defaultButton:@"OK" 
					   alternateButton:nil
						   otherButton:nil
			 informativeTextWithFormat:TWStr(@"Unable to launch browser. Please visit the URL manually: %@", kTWHomePageURL)] runModal];		
	}
}

#pragma mark ShortcutRecorder delegated methods

- (BOOL)shortcutRecorder:(SRRecorderControl *)aRecorder isKeyCode:(NSInteger)keyCode andFlagsTaken:(NSUInteger)flags reason:(NSString **)aReason {
	
	SRRecorderControl *other = aRecorder == newWindowHotKeyRecorder ? newTabHotKeyRecorder : newWindowHotKeyRecorder;
	KeyCombo otherHotKey = [other keyCombo];
	
	// check for duplicates
	if ((keyCode != -1 && otherHotKey.code != -1) 
		&& (keyCode == otherHotKey.code 
			&& flags == otherHotKey.flags)) {
			
			*aReason = TWStr(@"it is already used by the %@ hotkey", aRecorder == newWindowHotKeyRecorder ? @"new terminal tab" : @"new window tab");
			
			return YES;
		}
	
	return NO;
}

- (void)shortcutRecorder:(SRRecorderControl *)aRecorder keyComboDidChange:(KeyCombo)newKeyCombo {	
	NSString *key = nil;
	NSButton *stateButton = nil;
	
	if (aRecorder == newWindowHotKeyRecorder) {		
		key = kTWNewWindowHotKeyKey;
		stateButton = newWindowHotKeyEnabledButton;
	} else if (aRecorder == newTabHotKeyRecorder) {
		key = kTWNewTabHotKeyKey;
		stateButton = newTabHotKeyEnabledButton;
	} else {
		// TODO: handle this
	}
	
	[stateButton setState:(newKeyCombo.code == -1 ? 0 : 1)];
	
	[self setHotKeyPref_:key fromRecorder:aRecorder stateButton:stateButton];			
}

#pragma mark Private methods

- (BOOL) loadHotKeyPref_:(NSString *)prefKey recorder:(SRRecorderControl *)recorder stateButton:(NSButton *)stateButton {
	TWAssertNotNil(prefKey);
	TWAssertNotNil(recorder);
	TWAssertNotNil(stateButton);
	
	TWHotKeyPreference *pref = [preferences objectForKey:prefKey];
	
	if (!pref || ![pref isKindOfClass:[TWHotKeyPreference class]]) {
		NSLog(@"No valied preference found for key: %@ - value: %@", prefKey, pref);
		return NO;
	}
	
	// key
	KeyCombo hotKey = [[pref hotKey] asKeyCombo];
	[recorder setKeyCombo:hotKey];
	
	// enabled state
	[stateButton setState:[pref enabled]];
	
	return YES;
}

- (void) setHotKeyPref_:(NSString *)prefKey fromRecorder:(SRRecorderControl *)recorder stateButton:(NSButton *)stateButton {
	TWAssertNotNil(prefKey);
	TWAssertNotNil(recorder);
	TWAssertNotNil(stateButton);
	
	KeyCombo hotKey = [recorder keyCombo];
	
	if (hotKey.code == -1) {
		// TODO: better message
		NSLog(@"No hotkey to be set for pref %@", prefKey);
		return;
	}
	
	TWHotKeyPreference *pref = [[TWHotKeyPreference alloc] init];
	[pref setHotKey:[TWHotKey hotKey:hotKey]];
	[pref setEnabled:[stateButton state]];	
	
	[preferences setObject:pref forKey:prefKey];
}

- (void) handleAgentAppNotFound_ {
	NSString *path = [[NSBundle bundleWithIdentifier:kTWPreferencesPaneBundleId] bundlePath];
	NSString *message = TWStr(@"Unable to locate TermWeaver Agent application. Your TermWeaver installation is corrupt. Unable to find agent application %@.app in preference pane bundle %@. Please reinstall TermWeaver and try again.", kTWAgenAppName, path);
	
	NSLog(@"%@", message);
	
	NSAlert *alert = [NSAlert alertWithMessageText:@"Unable to locate TermWeaver" 
									 defaultButton:@"OK" 
								   alternateButton:nil
									   otherButton:nil
						 informativeTextWithFormat:message];
	
	[alert beginSheetModalForWindow:[[self mainView] window]
					  modalDelegate:nil 
					 didEndSelector:nil 
						contextInfo:nil];	
}

@end
