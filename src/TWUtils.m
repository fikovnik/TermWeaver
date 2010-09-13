//
//  TWUtils.m
//  TermWeaver
//
//  Created by Filip Krikava on 8/27/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "TWUtils.h"
#import "TWDefines.h"

NSString *GetBundleResourcePath(NSBundle *bundle, NSString *resourceName, NSString *resourceType) {
	TWAssertNotNil(bundle);
	TWAssertNotNil(resourceName);
	TWAssertNotNil(resourceType);
	
	NSString *path = [bundle pathForResource:resourceName ofType:resourceType];
	
	return path;
}

NSURL *GetBundleResourceURL(NSBundle *bundle, NSString *resourceName, NSString *resourceType) {	
	NSString *path = GetBundleResourcePath(bundle, resourceName, resourceType);
	NSURL *URL = [NSURL fileURLWithPath:path];
	
	return URL;
}
