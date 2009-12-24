/***************************************************************************
 *  Copyright 2009 Nevo Hua  <nevo.hua@playxiangqi.com>                    *
 *                                                                         * 
 *  This file is part of NevoChess.                                        *
 *                                                                         *
 *  NevoChess is free software: you can redistribute it and/or modify      *
 *  it under the terms of the GNU General Public License as published by   *
 *  the Free Software Foundation, either version 3 of the License, or      *
 *  (at your option) any later version.                                    *
 *                                                                         *
 *  NevoChess is distributed in the hope that it will be useful,           *
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of         *
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the          *
 *  GNU General Public License for more details.                           *
 *                                                                         *
 *  You should have received a copy of the GNU General Public License      *
 *  along with NevoChess.  If not, see <http://www.gnu.org/licenses/>.     *
 ***************************************************************************/

#import "AISelectionViewController.h"
#import "QuartzUtils.h"
#import "NevoChessAppDelegate.h"
#define ENABLE_XQWLIGHT_OBJC
static char ai_selections[][128] = {
    "XQWLight",
    "HaQiKiD",
#ifdef ENABLE_XQWLIGHT_OBJC
    "XQWLightObjc"
#endif
};

@implementation AISelectionViewController

/*
- (id)initWithStyle:(UITableViewStyle)style {
    // Override initWithStyle: if you create the controller programmatically and want to perform customization that is not appropriate for viewDidLoad.
    if (self = [super initWithStyle:style]) {
    }
    return self;
}
*/


- (void)viewDidLoad 
{
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor colorWithCGColor:GetCGPatternNamed(@"board_320x480.png")];
    self.title = NSLocalizedString(@"AI", @"");
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}



- (void)viewWillAppear:(BOOL)animated 
{
    [super viewWillAppear:animated];
    [((NevoChessAppDelegate*)[[UIApplication sharedApplication] delegate]).navigationController setNavigationBarHidden:NO animated:YES];
}


/*
- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
}
*/


- (void)viewWillDisappear:(BOOL)animated 
{
	[super viewWillDisappear:animated];
    //[((NevoChessAppDelegate*)[[UIApplication sharedApplication] delegate]).navigationController setNavigationBarHidden:YES animated:YES];
}

/*
- (void)viewDidDisappear:(BOOL)animated {
	[super viewDidDisappear:animated];
}
*/


/*
// Override to allow orientations other than the default portrait orientation.
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}
*/

- (void)didReceiveMemoryWarning 
{
	// Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
	
	// Release any cached data, images, etc that aren't in use.
}

- (void)viewDidUnload 
{
	// Release any retained subviews of the main view.
	// e.g. self.myOutlet = nil;
}

- (void)clearCheckMarkState
{
    NSArray *cells = [(UITableView *)self.view visibleCells];
    for(UITableViewCell* cell in cells) {
        cell.accessoryType = UITableViewCellAccessoryNone;
    }
}

#pragma mark Table view methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView 
{
    return 1;
}


// Customize the number of rows in the table view.
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section 
{
    return sizeof(ai_selections) / sizeof(ai_selections[0]);
}


// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath 
{
    NSString *user_select = [[NSUserDefaults standardUserDefaults] objectForKey:@"AI"];
    NSString *CellIdentifier = [NSString stringWithUTF8String:ai_selections[indexPath.row]];
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1  reuseIdentifier:CellIdentifier] autorelease];
        cell.textLabel.font = [UIFont fontWithName:@"Marker Felt" size:24.0f];
    }
    
    // Set up the cell...
	cell.textLabel.text = CellIdentifier;
    
    //mark select state
    if([CellIdentifier compare:user_select] == NSOrderedSame) {
        cell.accessoryType = UITableViewCellAccessoryCheckmark;    
    }
    
    return cell;
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath 
{
    [self clearCheckMarkState];
    UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    cell.accessoryType = UITableViewCellAccessoryCheckmark;
    [[NSUserDefaults standardUserDefaults] setObject:[NSString stringWithUTF8String:ai_selections[indexPath.row]] forKey:@"AI"];
}


/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/


/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:YES];
    }   
    else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/


/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath {
}
*/


/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/


- (void)dealloc 
{
    [super dealloc];
}


@end

