//
//  TermWeaverPrefPref.m
//  TermWeaverPref
//
//  Created by Filip Krikava on 8/25/10.
//  Copyright (c) 2010 __MyCompanyName__. All rights reserved.
//

#import "TWPreferencePane.h"

#import "TWPreferencesController.h"

#import "TWDefines.h"

@implementation TWPreferencePane

@synthesize preferences;

- (id) initWithBundle:(NSBundle *)bundle {

	if (![super initWithBundle:bundle]) {
		return nil;
	}

	// TODO: is this the best place
	[self initializeDefaults];
	
	return self;
	
}

- (void) mainViewDidLoad
{
	NSLog(@"mainViewDidLoad");
	//	NSNotificationCenter *nc = [NSDistributedNotificationCenter defaultCenter];
	//	[nc addObserver:self selector:@selector(termWeaverLaunched:)   name:GROWL_IS_READY object:nil];
	//	[nc addObserver:self selector:@selector(termWeaverTerminated:) name:GROWL_SHUTDOWN object:nil];
	//	[nc addObserver:self selector:@selector(reloadPrefs:)     name:TermWeaverPreferencesChanged object:nil];
	
}

- (void) willSelect {
	NSLog(@"willSelect");
	[self checkTermWeaverRunning];
	
	NSNumber *code = [preferences numberForKey:kHotKeyNewTerminalWindowCode];
	NSNumber *flags = [preferences numberForKey:kHotKeyNewTerminalWindowFlags];

	if (code && flags) {
		KeyCombo hotKey = SRMakeKeyCombo([code integerValue], [flags integerValue]);
		[newWindowHotKey setKeyCombo:hotKey];
	} else {
		NSLog(@"Invalid defaults for kHotKeyNewTerminalWindowCode/Flags");
		[newWindowHotKeyEnabled setState:0];
	}
	
	code = [preferences numberForKey:kHotKeyNewTerminalTabCode];
	flags = [preferences numberForKey:kHotKeyNewTerminalTabFlags];

	if (code && flags) {
		KeyCombo hotKey = SRMakeKeyCombo([code integerValue], [flags integerValue]);
		[newTabHotKey setKeyCombo:hotKey];
	} else {
		NSLog(@"Invalid defaults for kHotKeyNewTerminalTabCode/Flags");
		[newTabHotKeyEnabled setState:0];
	}
	
}

- (void) initializeDefaults {
	preferences = [TWPreferencesController sharedPreferences];
	
	NSString *path = [[NSBundle mainBundle] pathForResource:@"TermWaverDefaults" ofType:@"plist"];
	
	if (!path) {
		// TODO: handle
	}
	
	NSDictionary *defaultDefaults = [NSDictionary dictionaryWithContentsOfFile:path];
	
	if (!defaultDefaults) {
		// handle
	}
	
	[preferences registerDefaults:defaultDefaults];	
}

- (void) checkTermWeaverRunning {
	[startStopTermWeaver setEnabled:YES];
	
	if ([self isTermWeaverRunning]) {
		[startStopTermWeaver setTitle:@"Stop TermWeaver"];
		[termWeaverRunningStatus setStringValue:@"TermWeaver is running"];
	} else {
		[startStopTermWeaver setTitle:@"Start TermWeaver"];
		[termWeaverRunningStatus setStringValue:@"TermWeaver is stopped"];	
	}

	[termWeaverRunningProgress stopAnimation:self];
}

- (BOOL) isTermWeaverRunning {
	BOOL isRunning = NO;
	ProcessSerialNumber PSN = { kNoProcess, kNoProcess };
	
	while (GetNextProcess(&PSN) == noErr) {
		NSDictionary *infoDict = (NSDictionary *)ProcessInformationCopyDictionary(&PSN, kProcessDictionaryIncludeAllInformationMask);
		if(infoDict) {
			NSString *bundleID = [infoDict objectForKey:(NSString *)kCFBundleIdentifierKey];
			isRunning = bundleID && [bundleID isEqualToString:kTermWaverAgentBundleId];
			CFMakeCollectable(infoDict);
			[infoDict release];
		}
		if (isRunning)
			break;
	}
	
	return isRunning;
}

- (IBAction) startStopTermWeaverAction:(id)sender {
#pragma unused(sender)
	// Our desired state is a toggle of the current state;
	if ([self isTermWeaverRunning])
		[self terminateTermWeaver];
	else
		[self launchTermWeaver];
}

/*!
 * @brief Launches TermWeaverHelperApp.
 */
- (void) launchTermWeaver {
	// Don't allow the button to be clicked while we update
	[startStopTermWeaver setEnabled:NO];
	[termWeaverRunningProgress startAnimation:self];
	
	// Update our status visible to the user
	[termWeaverRunningStatus setStringValue:@"Launching TermWeaver..."];
	
	NSBundle *prefPaneBundle = [NSBundle bundleWithIdentifier:kTermWaverPreferencesPaneBundleId];
	NSString *agentPath      = [prefPaneBundle pathForResource:@"TermWeaverAgent" ofType:@"app"];
	NSURL *agentURL = [NSURL fileURLWithPath:agentPath];
	
	unsigned options = NSWorkspaceLaunchWithoutAddingToRecents | NSWorkspaceLaunchWithoutActivation | NSWorkspaceLaunchAsync;
	
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
	// Don't allow the button to be clicked while we update
	[startStopTermWeaver setEnabled:NO];
	[termWeaverRunningProgress startAnimation:self];
	
	// Update our status visible to the user
	[termWeaverRunningStatus setStringValue:@"Terminating TermWeaver..."];
	
	// Ask the TermWeaver Helper App to shutdown
	[[NSDistributedNotificationCenter defaultCenter] postNotificationName:kTermWeaverShutdownRequest object:nil];
	
	// After 6 seconds force a status update, in case termWeaver didn't start/stop
	[self performSelector:@selector(checkTermWeaverRunning)
			   withObject:nil
			   afterDelay:6.0];
}

- (BOOL)shortcutRecorder:(SRRecorderControl *)aRecorder isKeyCode:(NSInteger)keyCode andFlagsTaken:(NSUInteger)flags reason:(NSString **)aReason {

	NSLog(@"shortcut: %@ %d %d",aRecorder,keyCode,flags); 

	SRRecorderControl *other = aRecorder == newWindowHotKey ?newTabHotKey : newWindowHotKey;
	KeyCombo otherHotKey = [other keyCombo];
	
	if ((keyCode != -1 && otherHotKey.code != -1) 
		&& (keyCode == otherHotKey.code 
			&& flags == otherHotKey.flags)) {
			
		*aReason = TWStr(@"it is already used by the %@ hotkey", aRecorder == newWindowHotKey ? @"new terminal tab" : @"new window tab");
		
		return YES;
	}
	
	return NO;
}

- (void)shortcutRecorder:(SRRecorderControl *)aRecorder keyComboDidChange:(KeyCombo)newKeyCombo {
#pragma unused(newKeyCombo)
	
	if (aRecorder == newTabHotKey) {		
		KeyCombo hotKey = [newTabHotKey keyCombo];
		
		[newTabHotKeyEnabled setState:(hotKey.code == -1 ? 0 : 1)];
		if (hotKey.code != -1) {
			[preferences setValue:[NSNumber numberWithInt:hotKey.code] forKey:kHotKeyNewTerminalTabCode];
			[preferences setValue:[NSNumber numberWithInt:hotKey.flags] forKey:kHotKeyNewTerminalTabFlags];
		}
	} else if (aRecorder == newWindowHotKey) {
		KeyCombo hotKey = [newWindowHotKey keyCombo];
		
		[newWindowHotKeyEnabled setState:(hotKey.code == -1 ? 0 : 1)];		
		if (hotKey.code != -1) {
			[preferences setValue:[NSNumber numberWithInt:hotKey.code] forKey:kHotKeyNewTerminalWindowCode];
			[preferences setValue:[NSNumber numberWithInt:hotKey.flags] forKey:kHotKeyNewTerminalWindowFlags];
		}
	} else {
		// TODO: handle this
	}	
}

@end
