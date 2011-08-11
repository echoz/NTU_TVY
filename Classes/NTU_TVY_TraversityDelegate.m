//
//  NTU_TVY_TraversityDelegate.m
//  NTU_TVY
//
//  Created by Jeremy Foo on 8/11/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "NTU_TVY_TraversityDelegate.h"
#import "JONTUBusEngine.h"
#import "StopsTableViewController.h"

#define CACHE_FILE @"JONTUBusData.stuff"

@implementation NTU_TVY_TraversityDelegate
@synthesize nav;

-(void)saveState {
	NSLog(@"Writing to cache");
	NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
	NSString *cachePath = [[paths objectAtIndex:0] stringByAppendingPathComponent:CACHE_FILE];
	
	[JONTUBusEngine saveState:cachePath];
	
}

-(UIViewController *)rootView {
	return self.nav;
}

-(void)applicationFirstLaunch {
	NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
	NSString *cachePath = [[paths objectAtIndex:0] stringByAppendingPathComponent:CACHE_FILE];
	
	if ([[NSFileManager defaultManager] fileExistsAtPath:cachePath]) {
		NSLog(@"Loading from cache");
		[JONTUBusEngine loadState:cachePath];		
	} 
	
	JONTUBusEngine *engine = [JONTUBusEngine sharedJONTUBusEngine];
	
	[engine setHoldCache:-1];
	
	if (![[NSFileManager defaultManager] fileExistsAtPath:cachePath]) {
		NSLog(@"No cache load");
		//		[engine start];
	}

	StopsTableViewController *stops = [[StopsTableViewController alloc] initWithStyle:UITableViewStylePlain];
	nav = [[UINavigationController alloc] initWithRootViewController:stops];
	[stops release];
	
}

-(void)applicationWillHide {
	[self saveState];

}

-(void)applicationWillEnterForeground {
	[self saveState];
}

-(void)dealloc {
	[nav release], nav = nil;
	[super dealloc];
}

@end
