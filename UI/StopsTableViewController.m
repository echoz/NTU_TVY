//
//  StopsTableViewController.m
//  NTU_TVY
//
//  Created by Jeremy Foo on 8/11/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "StopsTableViewController.h"
#import "JONTUBusEngine.h"
#import "CacheOperation.h"

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
	
	lastUpdate = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 190, 20)];
	lastUpdate.backgroundColor = [UIColor clearColor];
	lastUpdate.textAlignment = UITextAlignmentCenter;
	lastUpdate.textColor = [UIColor whiteColor];
	lastUpdate.shadowColor = [UIColor grayColor];
	lastUpdate.shadowOffset = CGSizeMake(0, -1);
	lastUpdate.font = [UIFont fontWithName:@"Helvetica-Bold" size:12.0];
	lastUpdate.text = @"";
	
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

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
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
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

#pragma mark - Miscellaeous selectors

-(void)engineStarted {
	
}

-(void)titleTap:(id)sender {
	
}

#pragma mark - Data Source stuff

-(void)freshen {
	JONTUBusEngine *engine = [JONTUBusEngine sharedJONTUBusEngine];	
	[stops release];
	stops = [[engine stops] mutableCopy];	
	
	NSDateFormatter *f = [[NSDateFormatter alloc] init];
	[f setDateStyle:NSDateFormatterShortStyle];
	[f setTimeStyle:NSDateFormatterShortStyle];
	
	lastUpdate.text = [NSString stringWithFormat:@"Last updated: %@", [f stringFromDate:engine.lastGetIndexPage]]; // comment for taking of default images
	[f release];
	
	[self.tableView reloadData];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
	return 0;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	return [stops count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
    }
    
    // Configure the cell...
    
    return cell;
}

-(void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
	cell.textLabel.text = [[stops objectAtIndex:indexPath.row] roadName];
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
    // Navigation logic may go here. Create and push another view controller.
    /*
     <#DetailViewController#> *detailViewController = [[<#DetailViewController#> alloc] initWithNibName:@"<#Nib name#>" bundle:nil];
     // ...
     // Pass the selected object to the new view controller.
     [self.navigationController pushViewController:detailViewController animated:YES];
     [detailViewController release];
     */
}

@end
