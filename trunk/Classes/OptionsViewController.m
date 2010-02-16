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
#import "QuartzUtils.h"
#import "GenericSettingViewController.h"
#import "AISelectionViewController.h"

@implementation OptionsViewController

- (void)viewDidLoad 
{
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor colorWithCGColor:GetCGPatternNamed(@"board_320x480.png")];
    self.title = NSLocalizedString(@"Settings", @"");
}

- (void)viewWillAppear:(BOOL)animated 
{
    [super viewWillAppear:animated];
    NSArray *cells = [(UITableView*)self.view visibleCells];
    if([cells count] > 0) {
        UITableViewCell *cell = [cells objectAtIndex:1];
        cell.detailTextLabel.text = [[NSUserDefaults standardUserDefaults] objectForKey:@"AI"];
    }
    [self.navigationController setNavigationBarHidden:NO animated:YES];
}

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
    UITableViewCell* cell = nil;

    if (indexPath.row == 0) {
        cell = [tableView dequeueReusableCellWithIdentifier:@"generic_setting"];
        if(!cell) {
            cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"generic_setting"] autorelease];
            cell.textLabel.font = [UIFont systemFontOfSize:20.0f];
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        }
        cell.textLabel.text = NSLocalizedString(@"General", @"");
    }
    else if (indexPath.row == 1) {
        cell = [tableView dequeueReusableCellWithIdentifier:@"ai_setting"];
        if(!cell) {
            cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:@"ai_setting"] autorelease];
            cell.textLabel.font = [UIFont systemFontOfSize:20.0f];
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        }
        cell.textLabel.text = NSLocalizedString(@"AI_Setting_Key", @"");
        cell.detailTextLabel.text = [[NSUserDefaults standardUserDefaults] objectForKey:@"AI"];
    }

    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath 
{
    UITableViewController* subController = nil;

    if (indexPath.row == 0) {
        subController = [[SettingViewController alloc] initWithNibName:@"GenericSettingViewController" bundle:nil];
    }
    else if (indexPath.row == 1) {
        
        subController = [[AISelectionViewController alloc] initWithNibName:@"AISelectionView" bundle:nil];
    }

    [self.navigationController pushViewController:subController animated:YES];
    [subController release];
}

- (void)dealloc 
{
    [super dealloc];
}


@end

