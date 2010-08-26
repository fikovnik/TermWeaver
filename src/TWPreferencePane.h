//
//  TermWeaverPrefPref.h
//  TermWeaverPref
//
//  Created by Filip Krikava on 8/25/10.
//  Copyright (c) 2010 __MyCompanyName__. All rights reserved.
//

#import <PreferencePanes/PreferencePanes.h>

#import <ShortcutRecorder/SRRecorderControl.h>

#import "TWPreferencesController.h"

@interface TWPreferencePane : NSPreferencePane 
{
	TWPreferencesController *preferences;
	
	IBOutlet NSButton *startStopTermWeaver;
	IBOutlet NSTextField *termWeaverRunningStatus;
	IBOutlet NSProgressIndicator *termWeaverRunningProgress;

	IBOutlet NSButton *newWindowHotKeyEnabled;
	IBOutlet NSButton *newTabHotKeyEnabled;
	IBOutlet SRRecorderControl *newWindowHotKey;
	IBOutlet SRRecorderControl *newTabHotKey;
}

@property(readonly) TWPreferencesController *preferences;

- (id)initWithBundle:(NSBundle *)bundle;

- (void) mainViewDidLoad;
- (void) willSelect;


- (void) initializeDefaults;
- (void) checkTermWeaverRunning;
- (BOOL) isTermWeaverRunning;
- (void) launchTermWeaver;
- (void) terminateTermWeaver;

- (IBAction) startStopTermWeaverAction:(id)sender;

@end
