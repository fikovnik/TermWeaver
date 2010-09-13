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

#import "TWTerminalAppCWDDriver.h"

#import "RegexKitLite.h"
#import "Terminal.h"

#import "TWDefines.h"

static NSString *const kTerminalAppBundeId = @"com.apple.Terminal"; 

@implementation TWTerminalAppCWDDriver

- (id) init {
	if (![super init]) {
		return nil;
	}
	
	mDateFormatter = [[NSDateFormatter alloc] init];
	[mDateFormatter setDateFormat:@"EEE MMM d HH:mm:ss yyyy"];	
	
	return self;
}

- (void) dealloc {
	[mDateFormatter release];
	
	[super dealloc];
}

	// TODO: modify == nil to !
- (NSString *) getCWDFromApplication:(AXUIElementRef)application error:(NSError **)error {
	
	TerminalApplication *terminalApp = [SBApplication applicationWithBundleIdentifier:kTerminalAppBundeId];
	
	if (![terminalApp isRunning]) {
		TWDevLog(@"Terminal is not running");		
		return nil;
	}
	
	TerminalWindow *frontWindow = [[terminalApp windows] objectAtIndex:0];
	
	if (frontWindow == nil) {
		TWDevLog(@"Unable to get the front window of Terminal.app");
		return nil;
	} else {
		TWDevLog(@"Using front-most window: %@ of Terminal.app", [frontWindow name]);
	}
	
	TerminalTab *activeTab = nil;
	
	for (TerminalTab *tab in [frontWindow tabs]) {
		if ([tab selected]) {
			activeTab = tab;
			break;
		}
	}
	
	if (activeTab == nil) {
		TWDevLog(@"Unable to get selected tab of the Terminal.app front window %@", [frontWindow name]);
		return nil;
	}
	
	NSString *tty = [activeTab tty];
	if (tty == nil) {
		TWDevLog(@"Unable to get associated tty for the selected tab %@ of the Terminal.app", activeTab);
		return nil;
	} else {
		TWDevLog(@"Using tty: %@", tty);
	}
	
	// TODO: rename
	int pid = [self getForegroundProcessPIDFromTTY:tty];
	if (pid == -1) {
		TWDevLog(@"Unable to get pid of the foreground process from the tty %@", tty);
		return nil;
	} else {
		TWDevLog(@"Using pid %d", pid);
	}
	
	NSString *cwd = [self getProcessCWDWithPID:pid];
	if (cwd == nil) {
		TWDevLog(@"Unable to cwd of the pid %d", pid);
		return nil;
	} else {
		TWDevLog(@"Using cwd %@ of the pid %d", cwd, pid);
		return cwd;
	}
}

- (NSString *) getProcessCWDWithPID:(NSInteger)pid {	
	// lsof -a -p 42677 -d cwd -Fn
	NSTask *lsofTask = [[NSTask alloc] init];
	[lsofTask setLaunchPath:@"/usr/sbin/lsof"];
	NSArray *args = [NSArray arrayWithObjects:@"-a", @"-p", TWStr(@"%d",pid), @"-d", @"cwd", @"-Fn", nil];
	[lsofTask setArguments:args];
	
	// sample output:
	// p42677
	// n/Users/krikava
	NSPipe *outPipe = [NSPipe pipe];
	[lsofTask setStandardOutput:outPipe];
	
	[lsofTask launch];
	[lsofTask waitUntilExit];
	int exitCode = [lsofTask terminationStatus];
	[lsofTask release];

	if (exitCode != 0) {
		TWDevLog(@"Failed to execute: exit %d: /usr/sbin/lsof -a -p %d -d cwd -Fn", exitCode, pid);
		return nil;
	}
		
	NSData *outputData = [[outPipe fileHandleForReading] readDataToEndOfFile];
	NSString *output = [[[NSString alloc] initWithData:outputData encoding:NSUTF8StringEncoding] autorelease];

	// trim
	output = [output stringByTrimmingCharactersInSet: [NSCharacterSet whitespaceAndNewlineCharacterSet]];
	NSArray *lines = [output componentsSeparatedByString:@"\n"];

	if ([lines count] != 2) {
		TWDevLog(@"Unrecognized output from lsof %@", output);
		return nil;
	}
		
	NSString *line = [lines objectAtIndex:0];
	if (![line hasPrefix:TWStr(@"p%d",pid)]) {
		TWDevLog(@"Unrecognized output from lsof %@ - invalid pid", output);			
		return nil;
	}

	line = [lines objectAtIndex:1];
	NSString *path = [line stringByMatching:@"^n(.+)$" capture:1];
	if (path == nil) {
		TWDevLog(@"Unrecognized output from lsof %@ - unable to parse cwd", output);			
		return nil;
	} else {
		TWDevLog(@"Parsed pid cwd: %@", path);
	}

	// TODO: extract
	// just to make sure
	NSFileManager *fileMng = [NSFileManager defaultManager];
	BOOL isDir = false;
	if (![fileMng fileExistsAtPath:path isDirectory:&isDir]) {
		TWDevLog(@"The path %@ does from the front window of Finder.app could not be used", path);
		return nil;
	}		
	
	if (!isDir) {
		TWDevLog(@"The path %@ is not a directory", path);
		
		// it is not a directory - get the part
		path = [path stringByDeletingLastPathComponent];
	}
	
	return path;	
}

- (int) getForegroundProcessPIDFromTTY:(NSString *)tty {

	TWAssert(tty != nil, @"tty must not be nil");
	
	NSTask *psTask = [[NSTask alloc] init];
	[psTask setLaunchPath:@"/bin/ps"];
	[psTask setArguments:[NSArray arrayWithObjects:@"-o", @"pid=,state=,lstart=", @"-t", tty, nil]];
	
	NSPipe *outPipe = [NSPipe pipe];
	[psTask setStandardOutput:outPipe];
	
	[psTask launch];
	[psTask waitUntilExit];
	int exitCode = [psTask terminationStatus];
	[psTask release];
	
	if (exitCode != 0) {
		TWDevLog(@"Failed to execute: exit %d: /bin/ps -o pid=,state=,lstart= -t %@", exitCode, tty);
		return -1;
	}

	// examle output:
	// columns as follow: PID STAT STARTED
	// 42342 Ss   Mon Aug 23 14:28:52 2010    
	// 42343 S    Mon Aug 23 14:28:53 2010
	
	
	NSData *outputData = [[outPipe fileHandleForReading] readDataToEndOfFile];
	NSString *output = [[[NSString alloc] initWithData:outputData encoding:NSUTF8StringEncoding] autorelease];

	int newestProcessPID = -1;
	NSDate *newestProcessStart = [NSDate dateWithTimeIntervalSince1970:0];

	for (NSString *line in [output componentsSeparatedByString:@"\n"]) {
		if ([[line stringByTrimmingCharactersInSet: [NSCharacterSet whitespaceCharacterSet]] length] == 0) {
			// ignore empty lines - in fact there shoudl be just one at the very end
			continue;
		}
		
		NSArray *a = [line captureComponentsMatchedByRegex:@"^(\\d+)\\s+([IRSTUZAELNSsVWX+><]+)\\s+(.+)$"];
		if ([a count] != 4) {
			TWDevLog(@"Unrecognized output from ps command: \"%@\"", line);
			return -1;
		}
		
		NSString *status = [a objectAtIndex:2];
		
		if (![status hasPrefix:@"S"]) {
			// only interested in processes that is sleeping for less than about 20 seconds
			continue;
		} else if ([status isEqualToString:@"Ss"]) {
			// we are not interested in session leaders
			continue;
		}
		
		int pid = [[a objectAtIndex:1] integerValue];

		// TODO: exteravt
		NSString *daTWString = [[a objectAtIndex:3] stringByTrimmingCharactersInSet: [NSCharacterSet whitespaceCharacterSet]];
		NSDate *date = [mDateFormatter dateFromString:daTWString];
		
		if (date == nil) {
			TWDevLog(@"Unrecognized output from ps command: %@ - unable to parse the date", line);
			return -1;
		}
		
		if ([newestProcessStart laterDate:date] != newestProcessStart) {
			newestProcessStart = date;
			newestProcessPID = pid;
		}
	}
	
	return newestProcessPID;	
}


@end
