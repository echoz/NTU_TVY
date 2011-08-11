//
//  StopsTableViewController.h
//  NTU_TVY
//
//  Created by Jeremy Foo on 8/11/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface StopsTableViewController : UITableViewController {

	UILabel *lastUpdate;
	
	NSMutableArray *stops;
	
	BOOL fillingCache;

	NSOperationQueue *workQueue;

}
@property (readonly) NSOperationQueue *workQueue;
-(void)freshen;
@end
