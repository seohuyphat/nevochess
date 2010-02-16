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

#import "AISelectionViewController.h"
#import "QuartzUtils.h"
#import "NevoChessAppDelegate.h"
//#define ENABLE_XQWLIGHT_OBJC

static char* ai_selections[] = {
    "XQWLight",
    "HaQiKiD",
#ifdef ENABLE_XQWLIGHT_OBJC
    "XQWLightObjc"
#endif
};

@implementation AISelectionViewController

- (void)viewDidLoad 
{
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor colorWithCGColor:GetCGPatternNamed(@"board_320x480.png")];
    self.title = NSLocalizedString(@"AI", @"");
}

- (void)viewWillAppear:(BOOL)animated 
{
    [super viewWillAppear:animated];
    [((NevoChessAppDelegate*)[[UIApplication sharedApplication] delegate]).navigationController setNavigationBarHidden:NO animated:YES];
}

- (void)viewWillDisappear:(BOOL)animated 
{
	[super viewWillDisappear:animated];
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

- (void) _clearCheckMarkState
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
    NSString *currentAI = [[NSUserDefaults standardUserDefaults] objectForKey:@"AI"];
    NSString *CellIdentifier = [NSString stringWithUTF8String:ai_selections[indexPath.row]];
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:CellIdentifier] autorelease];
        cell.textLabel.font = [UIFont fontWithName:@"Marker Felt" size:20.0f];
    }

	cell.textLabel.text = CellIdentifier;

    cell.accessoryType = ([CellIdentifier isEqualToString:currentAI]
                          ? UITableViewCellAccessoryCheckmark
                          : UITableViewCellAccessoryNone);    

    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath 
{
    [self _clearCheckMarkState];
    UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    cell.accessoryType = UITableViewCellAccessoryCheckmark;
    [[NSUserDefaults standardUserDefaults] setObject:[NSString stringWithUTF8String:ai_selections[indexPath.row]] forKey:@"AI"];
}

- (void) dealloc 
{
    [super dealloc];
}


@end

