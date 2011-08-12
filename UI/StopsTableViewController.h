//
//  StopsTableViewController.h
//  NTU_TVY
//
//  Created by Jeremy Foo on 8/11/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreLocation/CoreLocation.h>

@interface StopsTableViewController : UITableViewController <CLLocationManagerDelegate> {
    UIBarButtonItem *genericDisplay;
	UILabel *lastUpdate;
    UIBarButtonItem *refreshCache;
    UIBarButtonItem *refreshError;
	
	NSMutableArray *stops;
	
	BOOL fillingCache;
    BOOL scheduleWatcher;

    CLLocation *currentLocation;
    CLLocationManager *locationManager;
	NSOperationQueue *workQueue;

}
@property (readonly) NSOperationQueue *workQueue;
-(IBAction)refreshCacheTapped:(id)sender;
-(void)cacheRefresh;
-(void)freshen;
NSInteger compareStops(id stop1, id stop2, void *context);
@end
