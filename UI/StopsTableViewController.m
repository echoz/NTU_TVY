//
//  StopsTableViewController.m
//  NTU_TVY
//
//  Created by Jeremy Foo on 8/11/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "StopsTableViewController.h"
#import "JONTUBusEngine.h"
#import "JONTUBusStop.h"
#import "CacheOperation.h"
#import "NSString+htmlentitiesaddition.h"
#import "Friendly.h"
#import "UIDevice-Reachability.h"

@implementation StopsTableViewController
@synthesize workQueue;

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];

	UIButton *titleLabel = [UIButton buttonWithType:UIButtonTypeCustom];
	[titleLabel setTitle:@"Traversity" forState:UIControlStateNormal];
	titleLabel.frame = CGRectMake(0, 0, 100, 44);
	titleLabel.titleLabel.font = [UIFont boldSystemFontOfSize:19];
	titleLabel.titleLabel.shadowColor = [UIColor grayColor];
	titleLabel.titleLabel.shadowOffset = CGSizeMake(0, -1);
	titleLabel.showsTouchWhenHighlighted = YES;
	[titleLabel addTarget:self action:@selector(titleTap:) forControlEvents:UIControlEventTouchUpInside];
	self.navigationItem.titleView = titleLabel;
    [titleLabel sizeToFit];
    
    refreshCache = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh target:self action:@selector(refreshCacheTapped:)];
    refreshError = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"NTU_TVY_Traversity_alert.png"] style:UIBarButtonItemStyleBordered target:self action:@selector(refreshCacheTapped:)];
	
	lastUpdate = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 190, 20)];
	lastUpdate.backgroundColor = [UIColor clearColor];
	lastUpdate.textAlignment = UITextAlignmentCenter;
	lastUpdate.textColor = [UIColor whiteColor];
	lastUpdate.shadowColor = [UIColor grayColor];
	lastUpdate.shadowOffset = CGSizeMake(0, -1);
	lastUpdate.font = [UIFont fontWithName:@"Helvetica-Bold" size:12.0];
	lastUpdate.text = @"";
    
    genericDisplay = [[UIBarButtonItem alloc] initWithCustomView:lastUpdate];
	
	self.toolbarItems = [NSArray arrayWithObjects:
						 [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil] autorelease],
						 genericDisplay,
						 [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil] autorelease],
						 nil];
	
	workQueue = [[NSOperationQueue alloc] init];
    
    locationManager = [[CLLocationManager alloc] init];
    locationManager.delegate = self;
	
	if ([JONTUBusEngine sharedJONTUBusEngine].brandNew) {
		CacheOperation *fillCache = [[CacheOperation alloc] initWithDelegate:self];
		[self.workQueue addOperation:fillCache];
		[fillCache release];
		[UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
		lastUpdate.text = @"Updating cache...";	// comment for taking of default images
		fillingCache = YES;
		/*		
		 genericDisplay.customView = progressLoad;
		 progressLoad.progress = 0.0;
		 */		
		
	} else {
		[self freshen];
	}
}

-(void)dealloc {
    [refreshError release], refreshError = nil;
    [refreshCache release], refreshCache = nil;
    [currentLocation release], currentLocation = nil;
    [genericDisplay release], genericDisplay = nil;
    [stops release], stops = nil;
    [locationManager release], locationManager = nil;
    [lastUpdate release], lastUpdate = nil;
    [workQueue release], workQueue = nil;
    
    [refreshCache release];
    [super dealloc];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    [self.navigationController setToolbarHidden:NO animated:YES];
    [self.navigationController setNavigationBarHidden:NO animated:YES];
    
    [self.navigationItem setRightBarButtonItem:refreshCache animated:YES];

    if ([locationManager locationServicesEnabled]) {        
        [locationManager performSelector:@selector(stopUpdatingLocation) withObject:nil afterDelay:30];
        [locationManager startUpdatingLocation];

    }
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    if ([locationManager locationServicesEnabled]) {        
        [locationManager stopUpdatingLocation];
    }
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

#pragma mark - Miscellaeous selectors

-(void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error {
	if ([error code] == kCLErrorDenied) {
		[locationManager stopUpdatingLocation];
		NSLog(@"%@", error);
	}
	
}

-(void)locationManager:(CLLocationManager *)manager didUpdateToLocation:(CLLocation *)newLocation fromLocation:(CLLocation *)oldLocation {
#if TARGET_IPHONE_SIMULATOR
    [currentLocation release];
    currentLocation = [[CLLocation alloc] initWithLatitude:1.39949846 longitude:103.74898910];
#else
    
    NSTimeInterval locationAge = -[newLocation.timestamp timeIntervalSinceNow];
    if (locationAge > 5.0) return;
    
    if (newLocation.horizontalAccuracy < 0) return;
    
    if ((!currentLocation) || (newLocation.horizontalAccuracy < currentLocation.horizontalAccuracy)) {
        
		[currentLocation release];
		currentLocation = [newLocation copy];
		
        if (newLocation.horizontalAccuracy <= locationManager.desiredAccuracy) {
            [locationManager stopUpdatingLocation];
            [NSObject cancelPreviousPerformRequestsWithTarget:locationManager selector:@selector(stopUpdatingLocation) object:nil];
        } 
      
        [self cacheRefresh];
    }
    
#endif
}

-(void)titleTap:(id)sender {
	
}

#pragma mark - Data Source stuff

-(void)promptForPossibleError {
	UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"NTU Web Services" message:@"There is a possiblity that NTU Web Services is down. If you do not see results/data and think that there should be, this is most likely the case. Do a cache refresh when everything is back up." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
	[alert show];
	[alert release];
}

-(void)reachabilityChanged {
	self.navigationItem.rightBarButtonItem = refreshError;
    
	[UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
	[workQueue cancelAllOperations];
	
	[self.tableView setAlpha:1];
	[self.tableView setScrollEnabled:YES];
	[self.tableView setAllowsSelection:YES];	
	
	if (scheduleWatcher) {
		[[UIDevice currentDevice] unscheduleReachabilityWatcher];
		scheduleWatcher = NO;
	}	
}

-(void)showNetworkErrorAlert {
	UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Network Error" message:@"Traversity needs an active internet connection to reload the cache." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
	[alert show];
	[alert release];
}

-(void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
	if ((alertView.title == @"Reload Cache") && ([[alertView buttonTitleAtIndex:buttonIndex] isEqualToString:@"Yes"])) {
		
		if ([[UIDevice currentDevice] hostAvailable:@"campusbus.ntu.edu.sg"]) {
			NSLog(@"Refreshing Cache");
			[[JONTUBusEngine sharedJONTUBusEngine] setHoldCache:20];
			CacheOperation *fillCache = [[CacheOperation alloc] initWithDelegate:self];
			[self.workQueue addOperation:fillCache];
			[fillCache release];
			
			[[UIDevice currentDevice] scheduleReachabilityWatcher:self];
			scheduleWatcher = YES;
            
			lastUpdate.text = @"Updating cache...";	
			
			[UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
			[UIView beginAnimations:nil context:nil];
			[UIView setAnimationDuration:0.75];
			[UIView setAnimationCurve:UIViewAnimationCurveEaseInOut];
			[self.tableView setAlpha:0.5];
			[self.tableView setScrollEnabled:NO];
			[self.tableView setAllowsSelection:NO];
			[UIView commitAnimations];		
			
		} else {
			[self showNetworkErrorAlert];
			[self reachabilityChanged];
		}
	}
}

- (IBAction)refreshCacheTapped:(id)sender {
	if ([[UIDevice currentDevice] hostAvailable:@"campusbus.ntu.edu.sg"]) 	{
        
        self.navigationItem.rightBarButtonItem = refreshCache;
		
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Reload Cache" 
														message:@"Are you sure you want to reload the entire Shuttle Bus Database?" 
													   delegate:self 
											  cancelButtonTitle:@"No"
											  otherButtonTitles:@"Yes",nil];
		[alert setDelegate:self];
		[alert show];
		[alert release];
	} else {
		[self showNetworkErrorAlert];
		[self reachabilityChanged];
	}
}

-(void)freshen {
	JONTUBusEngine *engine = [JONTUBusEngine sharedJONTUBusEngine];	
	[stops release];
	stops = [[engine stops] mutableCopy];	
	    
	NSDateFormatter *f = [[NSDateFormatter alloc] init];
	[f setDateStyle:NSDateFormatterShortStyle];
	[f setTimeStyle:NSDateFormatterShortStyle];
	
	lastUpdate.text = [NSString stringWithFormat:@"Last updated: %@", [f stringFromDate:engine.lastGetIndexPage]]; // comment for taking of default images
	[f release];
	
    [self cacheRefresh];
}

NSInteger compareStops(id stop1, id stop2, void *context){

	CLLocation *stop1loc = [[CLLocation alloc] initWithLatitude:[[stop1 lat] doubleValue] longitude:[[stop1 lon] doubleValue]];	
	CLLocation *stop2loc = [[CLLocation alloc] initWithLatitude:[[stop2 lat] doubleValue] longitude:[[stop2 lon] doubleValue]];
    
    NSComparisonResult togo;

    CLLocation *currentLoc = (CLLocation *)context;
    
	if ([currentLoc distanceFromLocation:stop1loc] < [currentLoc distanceFromLocation:stop2loc]) {
		togo = NSOrderedAscending;
	} else if ([currentLoc distanceFromLocation:stop1loc] > [currentLoc distanceFromLocation:stop2loc]) {
		togo = NSOrderedDescending;
	} else {
		togo = NSOrderedSame;
	}
	
	[stop1loc release];
	[stop2loc release];
	return togo;

}

-(void)cacheRefresh {
    [stops sortUsingFunction:compareStops context:currentLocation];
    [self.tableView reloadData];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
	return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	return [stops count];
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 50.0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier] autorelease];
    }
    
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    
    return cell;
}

-(void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    JONTUBusStop *stop = [stops objectAtIndex:indexPath.row];
    CLLocation *stoploc = [[CLLocation alloc] initWithLatitude:[stop.lat doubleValue] longitude:[stop.lon doubleValue]];
    
	cell.textLabel.text = [stop.desc removeHTMLEntities];
    cell.detailTextLabel.text = [NSString stringWithFormat:@"(%@) %@", [Friendly distanceString:[currentLocation distanceFromLocation:stoploc]], [stop.roadName removeHTMLEntities]];

    [stoploc release];
}

/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/

/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
    }   
    else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
{
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

@end
