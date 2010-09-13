//
//  TWUtils.h
//  TermWeaver
//
//  Created by Filip Krikava on 8/27/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

NSString *GetBundleResourcePath(NSBundle *bundle, NSString *resourceName, NSString *resourceType);

NSURL *GetBundleResourceURL(NSBundle *bundle, NSString *resourceName, NSString *resourceType);