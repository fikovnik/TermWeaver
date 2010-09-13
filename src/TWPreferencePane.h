//
//  TermWeaverPrefPref.h
//  TermWeaverPref
//
//  Created by Filip Krikava on 8/25/10.
//  Copyright (c) 2010 __MyCompanyName__. All rights reserved.
//

#import <PreferencePanes/PreferencePanes.h>

#import <ShortcutRecorder/SRRecorderControl.h>

@class TWPreferencesController;

@interface TWPreferencePane : NSPreferencePane 
{
	@private
	
	TWPreferencesController *preferences;
	
	IBOutlet NSButton *startStopTermWeaverButton;
	IBOutlet NSTextField *termWeaverRunningStatusText;
	IBOutlet NSProgressIndicator *termWeaverRunningProgress;

	IBOutlet NSButton *newWindowHotKeyEnabledButton;
	IBOutlet NSButton *newTabHotKeyEnabledButton;
	IBOutlet SRRecorderControl *newWindowHotKeyRecorder;
	IBOutlet SRRecorderControl *newTabHotKeyRecorder;
}

@property(readonly) TWPreferencesController *preferences;

- (id) initWithBundle:(NSBundle *)bundle;

- (void) mainViewDidLoad;
- (void) willSelect;

- (void) loadDefaults;

- (void) checkTermWeaverRunning;
- (BOOL) isTermWeaverRunning;
- (void) launchTermWeaver;
- (void) terminateTermWeaver;
- (void) termWeaverLaunched:(NSNotification *)notification;
- (void) termWeaverTerminated:(NSNotification *)notification;

- (IBAction) startStopTermWeaverAction:(id)sender;
- (IBAction) hotKeyEnablementChangedAction:(id)sender;

@end
