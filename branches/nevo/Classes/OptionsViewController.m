/***************************************************************************
 *  Copyright 2009-2010 Nevo Hua  <nevo.hua@playxiangqi.com>               *
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

#import "OptionsViewController.h"
#import "NevoChessAppDelegate.h"
#import "QuartzUtils.h"
#import "GenericSettingViewController.h"
#import "AISelectionViewController.h"

@implementation OptionsViewController

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
    self.title = NSLocalizedString(@"Settings", @"");
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}



- (void)viewWillAppear:(BOOL)animated 
{
    [super viewWillAppear:animated];
    NSArray *cells = [(UITableView*)self.view visibleCells];
    if([cells count] > 0) {
        UITableViewCell *cell = [cells objectAtIndex:1];
        cell.detailTextLabel.text = [[NSUserDefaults standardUserDefaults] objectForKey:@"AI"];
    }
    [((NevoChessAppDelegate*)[[UIApplication sharedApplication] delegate]).navigationController setNavigationBarHidden:NO animated:NO];
}

/*
- (void)viewDidAppear:(BOOL)animated 
{
    [super viewDidAppear:animated];
    
}
*/ 

- (void)viewWillDisappear:(BOOL)animated 
{
	[super viewWillDisappear:animated];
    [((NevoChessAppDelegate*)[[UIApplication sharedApplication] delegate]).navigationController setNavigationBarHidden:YES animated:NO];
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


#pragma mark Table view methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView 
{
    return 1;
}


// Customize the number of rows in the table view.
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section 
{
    return 2;
}


// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath 
{
    UITableViewCell *cell = nil;
    // section 0
    if (indexPath.row == 0) {
        cell = [tableView dequeueReusableCellWithIdentifier:@"generic_setting"];
        if(!cell) {
            cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:@"generic_setting"] autorelease];
        }
        cell.textLabel.font = [UIFont systemFontOfSize:20.0f];
        cell.textLabel.text = NSLocalizedString(@"General", @"");
        cell.accessoryType = UITableViewCellAccessoryDetailDisclosureButton;
        return cell;
    }
    
    if (indexPath.row == 1) {
        cell = [tableView dequeueReusableCellWithIdentifier:@"ai_setting"];
        if(!cell) {
            cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:@"ai_setting"] autorelease];
        }
        cell.textLabel.font = [UIFont systemFontOfSize:20.0f];
        cell.textLabel.text = NSLocalizedString(@"AI_Setting_Key", @"");
        cell.accessoryType = UITableViewCellAccessoryDetailDisclosureButton;
        cell.detailTextLabel.text = [[NSUserDefaults standardUserDefaults] objectForKey:@"AI"];
        return cell;
    }
    return cell;
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath 
{
    // Navigation logic may go here. Create and push another view controller.
	// AnotherViewController *anotherViewController = [[AnotherViewController alloc] initWithNibName:@"AnotherView" bundle:nil];
	// [self.navigationController pushViewController:anotherViewController];
	// [anotherViewController release];
    if (indexPath.row == 0) {
        //generic settings
        SettingViewController *genericController = [[SettingViewController alloc] initWithNibName:@"GenericSettingViewController" bundle:nil];
        [((NevoChessAppDelegate*)[[UIApplication sharedApplication] delegate]).navigationController pushViewController:genericController animated:YES];
        [genericController release];  
    }
    
    if (indexPath.row == 1) {
        //AI selection
        AISelectionViewController *aiController = [[AISelectionViewController alloc] initWithNibName:@"AISelectionView" bundle:nil];
        [((NevoChessAppDelegate*)[[UIApplication sharedApplication] delegate]).navigationController pushViewController:aiController animated:YES];
        [aiController release]; 
        
    }
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

