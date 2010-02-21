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
#import "NetworkSettingController.h"
#import "SingleSelectionController.h"

enum ViewTagEnum
{
    VIEW_TAG_PIECE_STYLE  = 1,  // Must be non-zero.
    VIEW_TAG_BOARD_STYLE  = 2,
    VIEW_TAG_AI_LEVEL     = 3,
    VIEW_TAG_AI_TYPE      = 4
};

@implementation OptionsViewController

- (void)viewDidLoad 
{
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor colorWithCGColor:GetCGPatternNamed(@"board_320x480.png")];
    self.title = NSLocalizedString(@"Settings", @"");

    _soundSwitch.on = [[NSUserDefaults standardUserDefaults] boolForKey:@"sound_on"];

    // --- Piece Type.
    _pieceChoices = [[NSArray alloc] initWithObjects:
                                        NSLocalizedString(@"Chinese", @""),
                                        NSLocalizedString(@"Western", @""),
                                        @"iXiangQi",
                                        nil];
    _pieceType = [[NSUserDefaults standardUserDefaults] integerForKey:@"piece_type"];
    if (_pieceType >= [_pieceChoices count]) { _pieceType = 0; }

    // --- Board Type.
    _boardChoices = [[NSArray alloc] initWithObjects:
                                        NSLocalizedString(@"Default", @""),
                                        NSLocalizedString(@"Skeleton", @""),
                                        NSLocalizedString(@"Wood", @""),
                                        nil];
    _boardType = [[NSUserDefaults standardUserDefaults] integerForKey:@"board_type"];
    if (_boardType >= [_boardChoices count]) { _boardType = 0; }

    // --- AI Level
    _aiLevelChoices = [[NSArray alloc] initWithObjects:
                                        NSLocalizedString(@"Easy", @""),
                                        NSLocalizedString(@"Normal", @""),
                                        NSLocalizedString(@"Hard", @""),
                                        NSLocalizedString(@"Master", @""),
                                        nil];
    _aiLevel = [[NSUserDefaults standardUserDefaults] integerForKey:@"ai_level"];
    if (_aiLevel >= [_aiLevelChoices count]) { _aiLevel = 0; }

    // --- AI Type
    _aiTypeChoices = [[NSArray alloc] initWithObjects:
                                        @"XQWLight",
                                        @"HaQiKiD",
#ifdef ENABLE_XQWLIGHT_OBJC
                                        @"XQWLightObjc",
#endif
                                        nil];
    NSString* aiStr = [[NSUserDefaults standardUserDefaults] objectForKey:@"ai_type"];
    _aiType = [_aiTypeChoices indexOfObject:aiStr];
    if (_aiType == NSNotFound) { _aiType = 0; }
}

- (void)viewWillAppear:(BOOL)animated 
{
    [super viewWillAppear:animated];
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
    return 3;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    return nil;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section 
{
    switch (section) {
        case 0: return 3;
        case 1: return 2;
        case 2: return 1;
    }
    return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath 
{
    UITableViewCell* cell = nil;
    UILabel*         theLabel = nil;
    UIFont*          defaultFont = [UIFont systemFontOfSize:18.0];
    
    switch (indexPath.section)
    {
        case 0: // ----- General
        {
            switch (indexPath.row)
            {
                case 0:
                {
                    cell = _soundCell;
                    theLabel = (UILabel *)[cell viewWithTag:1];
                    theLabel.font = defaultFont;
                    theLabel.text  = NSLocalizedString(@"Sound", @"");
                    break;
                }
                case 1:  // - Piece
                {
                    cell = [tableView dequeueReusableCellWithIdentifier:@"piece_cell"];
                    if(!cell) {
                        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:@"piece_cell"] autorelease];
                        cell.textLabel.font = defaultFont;
                        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
                    }
                    _pieceCell = cell;
                    cell.textLabel.text = NSLocalizedString(@"Piece Style", @"");
                    cell.detailTextLabel.text = [_pieceChoices objectAtIndex:_pieceType];
                    break;
                }
                case 2:   // - Board
                {
                    cell = [tableView dequeueReusableCellWithIdentifier:@"board_cell"];
                    if(!cell) {
                        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:@"board_cell"] autorelease];
                        cell.textLabel.font = defaultFont;
                        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
                    }
                    _boardCell = cell;
                    cell.textLabel.text = NSLocalizedString(@"Board Style", @"");
                    cell.detailTextLabel.text = [_boardChoices objectAtIndex:_boardType];
                    break;
                }
            }
            break;
        }
        case 1:  // ----- AI
        {
            switch (indexPath.row)
            {
                case 0:
                {
                    cell = [tableView dequeueReusableCellWithIdentifier:@"ai_level_cell"];
                    if(!cell) {
                        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:@"ai_level_cell"] autorelease];
                        cell.textLabel.font = defaultFont;
                        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
                    }
                    cell.textLabel.text = NSLocalizedString(@"AI Level", @"");
                    cell.detailTextLabel.text = [_aiLevelChoices objectAtIndex:_aiLevel];
                    _aiLevelCell = cell;
                    break;
                }
                case 1:
                    cell = [tableView dequeueReusableCellWithIdentifier:@"ai_type_cell"];
                    if(!cell) {
                        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:@"ai_type_cell"] autorelease];
                        cell.textLabel.font = defaultFont;
                        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
                    }
                    cell.textLabel.text = NSLocalizedString(@"AI Type", @"");
                    cell.detailTextLabel.text = [_aiTypeChoices objectAtIndex:_aiType];
                    _aiTypeCell = cell;
                    break;
            }
            break;
        }
        case 2: // ----- Network
        {
            cell = [tableView dequeueReusableCellWithIdentifier:@"network_setting_cell"];
            if(!cell) {
                cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"network_setting_cell"] autorelease];
                cell.textLabel.font = defaultFont;
                cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            }
            cell.textLabel.text = NSLocalizedString(@"Network", @"");
            break;
        }
    }

    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath 
{
    UITableViewController* subController = nil;

    switch (indexPath.section)
    {
        case 0:
        {
            switch (indexPath.row)
            {
                case 1:  // - Piece
                {
                    SingleSelectionController* controller = [[SingleSelectionController alloc] initWithChoices:_pieceChoices delegate:self];
                    subController = controller;
                    controller.title = _pieceCell.textLabel.text;
                    controller.selectionIndex = _pieceType;
                    controller.tag = VIEW_TAG_PIECE_STYLE;
                    break;
                }
                case 2:  // - Board
                {
                    SingleSelectionController* controller = [[SingleSelectionController alloc] initWithChoices:_boardChoices delegate:self];
                    subController = controller;
                    controller.title = _boardCell.textLabel.text;
                    controller.selectionIndex = _boardType;
                    controller.tag = VIEW_TAG_BOARD_STYLE;
                    break;
                }
            }
            break;
        }
        case 1:
        {
            switch (indexPath.row)
            {
                case 0:
                {
                    SingleSelectionController* controller = [[SingleSelectionController alloc] initWithChoices:_aiLevelChoices delegate:self];
                    subController = controller;
                    controller.title = _aiLevelCell.textLabel.text;
                    controller.selectionIndex = _aiLevel;
                    controller.tag = VIEW_TAG_AI_LEVEL;
                    break;
                }
                case 1:
                {
                    SingleSelectionController* controller = [[SingleSelectionController alloc] initWithChoices:_aiTypeChoices delegate:self];
                    subController = controller;
                    controller.title = _aiTypeCell.textLabel.text;
                    controller.selectionIndex = _aiType;
                    controller.tag = VIEW_TAG_AI_TYPE;
                    break;
                }
            }
            break;
        }
        case 2:
        {
            subController = [[NetworkSettingController alloc] initWithNibName:@"NetworkSettingView" bundle:nil];
            break;
        }
    }

    if (subController) {
        [self.navigationController pushViewController:subController animated:YES];
        [subController release];
    }
}

- (void)dealloc 
{
    [_pieceChoices release];
    [_boardChoices release];
    [_aiLevelChoices release];
    [_aiTypeChoices release];
    [super dealloc];
}

#pragma mark -
#pragma mark SingleSelectionDelegate methods

- (void) didSelect:(SingleSelectionController*)controller rowAtIndex:(NSUInteger)index
{
    switch (controller.tag)
    {
        case VIEW_TAG_PIECE_STYLE:
        {
            if (_pieceType != index)
            {
                _pieceType = index;
                _pieceCell.detailTextLabel.text = [_pieceChoices objectAtIndex:_pieceType];
                [[NSUserDefaults standardUserDefaults] setInteger:_pieceType forKey:@"piece_type"];
            }
            break;
        }
        case VIEW_TAG_BOARD_STYLE:
        {
            if (_boardType != index)
            {
                _boardType = index;
                _boardCell.detailTextLabel.text = [_boardChoices objectAtIndex:_boardType];
                [[NSUserDefaults standardUserDefaults] setInteger:_boardType forKey:@"board_type"];
            }
            break;
        }
        case VIEW_TAG_AI_LEVEL:
        {
            if (_aiLevel != index)
            {
                _aiLevel = index;
                _aiLevelCell.detailTextLabel.text = [_aiLevelChoices objectAtIndex:_aiLevel];
                [[NSUserDefaults standardUserDefaults] setInteger:_aiLevel forKey:@"ai_level"];
            }
            break;
        }
        case VIEW_TAG_AI_TYPE:
        {
            if (_aiType != index)
            {
                _aiType = index;
                _aiTypeCell.detailTextLabel.text = [_aiTypeChoices objectAtIndex:_aiType];
                [[NSUserDefaults standardUserDefaults] setObject:[_aiTypeChoices objectAtIndex:_aiType] forKey:@"ai_type"];
            }
            break;
        }
    }
}

#pragma mark Event handlers

- (IBAction) autoConnectValueChanged:(id)sender
{    
    [[NSUserDefaults standardUserDefaults] setBool:_soundSwitch.on forKey:@"sound_on"];
}

@end

