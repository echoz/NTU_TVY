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
    IBOutlet UIBarButtonItem *refreshCache;
	
	NSMutableArray *stops;
	
	BOOL fillingCache;

    CLLocation *currentLocation;
    CLLocationManager *locationManager;
	NSOperationQueue *workQueue;

}
@property (readonly) NSOperationQueue *workQueue;
- (IBAction)refreshCacheTapped:(id)sender;
-(void)freshen;
@end
