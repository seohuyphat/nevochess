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
#import "AboutViewController.h"
#import "AudioHelper.h"

enum ViewTagEnum
{
    VIEW_TAG_BOARD_STYLE  = 1,  // The tags must be non-zero.
    VIEW_TAG_PIECE_STYLE,
    VIEW_TAG_AI_TYPE,
    VIEW_TAG_AI_LEVEL
};

enum CellSubViewTagEnum
{
    VIEW_TAG_NAME = 1,
    VIEW_TAG_ICON,
    VIEW_TAG_VALUE 
};

@interface OptionsViewController (/* private interfaces */)
- (UITableViewCell *)tableViewCellWithReuseIdentifier:(NSString *)identifier;
@end

@implementation OptionsViewController

- (void)viewDidLoad 
{
    [super viewDidLoad];
    self.title = NSLocalizedString(@"Settings", @"");

    _soundSwitch.on = [[NSUserDefaults standardUserDefaults] boolForKey:@"sound_on"];

    // --- Piece Type.
    _pieceChoices = [[NSArray alloc] initWithObjects:
                                        NSLocalizedString(@"Default", @""),
                                        NSLocalizedString(@"Western", @""),
                                        @"Wikipedia",
                                        @"HOXChess",
                                        @"iXiangQi",
                                        nil];
    _pieceType = [[NSUserDefaults standardUserDefaults] integerForKey:@"piece_type"];
    if (_pieceType >= [_pieceChoices count]) { _pieceType = 0; }

    // --- Board Type.
    _boardChoices = [[NSArray alloc] initWithObjects:
                                        NSLocalizedString(@"Default", @""),
                                        NSLocalizedString(@"Western", @""),
                                        NSLocalizedString(@"Simple", @""),
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

    // --- Network
    _username = [[NSUserDefaults standardUserDefaults] stringForKey:@"network_username"];
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
    return 4;
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
        case 3: return 1;
    }
    return 0;
}

- (UIImage*) _getImageNamed:(NSString*)name
{
    NSString* imageName = [[NSBundle mainBundle] pathForResource:name
                                                          ofType:@"png"
                                                     inDirectory:nil];
    UIImage* theImage = [UIImage imageWithContentsOfFile:imageName];
    return theImage;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath 
{
    UITableViewCell* cell = nil;
    UILabel*         theLabel = nil;
    UILabel*         theValue = nil;
    UIImageView      *icon = nil;
    UIFont*          defaultFont = [UIFont boldSystemFontOfSize:17.0];
    
    cell = [tableView dequeueReusableCellWithIdentifier:@"OptionCell"];
    if (!cell) {
        cell = [self tableViewCellWithReuseIdentifier:@"OptionCell"];
    }
    
    switch (indexPath.section)
    {
        case 0: // ----- General
        {
            switch (indexPath.row)
            {
                case 0:
                {
                    theLabel = (UILabel *)[cell viewWithTag:VIEW_TAG_NAME];
                    theLabel.font = defaultFont;
                    theLabel.text  = NSLocalizedString(@"Sound", @"");
                    icon = (UIImageView*)[cell viewWithTag:VIEW_TAG_ICON];
                    icon.image = [self _getImageNamed:@"volume_on"];
                    _soundSwitch.frame = CGRectMake(192, 6, 94, 27);
                    [cell.contentView addSubview:_soundSwitch];
                    cell.accessoryType = UITableViewCellAccessoryNone;
                    break;
                }
                case 1:   // - Board
                {
                    theLabel = (UILabel *)[cell viewWithTag:VIEW_TAG_NAME];
                    theLabel.font = defaultFont;
                    theLabel.text  = NSLocalizedString(@"Board", @"");
                    theValue = (UILabel *)[cell viewWithTag:VIEW_TAG_VALUE];
                    theValue.text = [_boardChoices objectAtIndex:_boardType];
                    icon = (UIImageView*)[cell viewWithTag:VIEW_TAG_ICON];
                    icon.image = [self _getImageNamed:@"board_22px"];
                    break;
                }
                case 2:  // - Piece
                {
                    theLabel = (UILabel *)[cell viewWithTag:VIEW_TAG_NAME];
                    theLabel.font = defaultFont;
                    theLabel.text  = NSLocalizedString(@"Piece", @"");
                    theValue = (UILabel *)[cell viewWithTag:VIEW_TAG_VALUE];
                    theValue.text = [_pieceChoices objectAtIndex:_pieceType];
                    icon = (UIImageView*)[cell viewWithTag:VIEW_TAG_ICON];
                    icon.image = [self _getImageNamed:@"piece_22px"];
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
                    theLabel = (UILabel *)[cell viewWithTag:VIEW_TAG_NAME];
                    theLabel.font = defaultFont;
                    theLabel.text  = NSLocalizedString(@"AI Type", @"");
                    theValue = (UILabel *)[cell viewWithTag:VIEW_TAG_VALUE];
                    theValue.text = [_aiTypeChoices objectAtIndex:_aiType];
                    icon = (UIImageView*)[cell viewWithTag:VIEW_TAG_ICON];
                    icon.image = [self _getImageNamed:@"AI-avatar"];
                    break;
                }
                case 1:
                {
                    theLabel = (UILabel *)[cell viewWithTag:VIEW_TAG_NAME];
                    theLabel.font = defaultFont;
                    theLabel.text  = NSLocalizedString(@"AI Level", @"");
                    theValue = (UILabel *)[cell viewWithTag:VIEW_TAG_VALUE];
                    theValue.text = [_aiLevelChoices objectAtIndex:_aiLevel];
                    icon = (UIImageView*)[cell viewWithTag:VIEW_TAG_ICON];
                    icon.image = [self _getImageNamed:@"AI-level"];
                    break;
                }

            }
            break;
        }
        case 2: // ----- Network
        {            
            theLabel = (UILabel *)[cell viewWithTag:VIEW_TAG_NAME];
            theLabel.font = defaultFont;
            theLabel.text  = NSLocalizedString(@"Network", @"");
            theValue = (UILabel *)[cell viewWithTag:VIEW_TAG_VALUE];
            theValue.text = _username;
            icon = (UIImageView*)[cell viewWithTag:VIEW_TAG_ICON];
            icon.image = [self _getImageNamed:@"applications-internet"];
            break;
        }
        case 3: // ----- About
        {
            theLabel = (UILabel *)[cell viewWithTag:VIEW_TAG_NAME];
            theLabel.font = defaultFont;
            theLabel.text  = NSLocalizedString(@"About", @"");
            icon = (UIImageView*)[cell viewWithTag:VIEW_TAG_ICON];
            icon.image = [self _getImageNamed:@"help"];
            break;
        }
    }

    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath 
{
    UITableViewController* subController = nil;
    UITableViewCell        *cell = nil;
    switch (indexPath.section)
    {
        case 0: // ----- General
        {
            switch (indexPath.row)
            {
                case 1:  // - Board
                {
                    NSArray* boards = [NSArray arrayWithObjects:@"board_60px", @"Western_60px",
                                        @"PlayXiangqi_60px", @"SKELETON_60px", @"WOOD_60px", nil];
                    NSMutableArray* imageNames = [[NSMutableArray alloc] initWithCapacity:[boards count]];
                    for (NSString* name in boards)
                    {
                        NSString* path = [[NSBundle mainBundle] pathForResource:name
                                                                         ofType:@"png"
                                                                    inDirectory:nil];
                        [imageNames addObject:path];
                    }
                    NSArray* subTitles = [NSArray arrayWithObjects:
                                          @"", @"http://www.playxiangqi.com",
                                          @"http://www.playxiangqi.com",
                                          @"http://www.xqbase.com", @"http://www.xqbase.com",
                                          nil];
                    SingleSelectionController* controller =
                        [[SingleSelectionController alloc] initWithChoices:_boardChoices
                                                                imageNames:imageNames
                                                                 subTitles:subTitles
                                                                  delegate:self];
                    [imageNames release];
                    controller.rowHeight = 78;
                    subController = controller;
                    cell = [(UITableView*)self.view cellForRowAtIndexPath:indexPath];
                    controller.title = ((UILabel*)[cell viewWithTag:VIEW_TAG_NAME]).text;
                    controller.selectionIndex = _boardType;
                    controller.tag = VIEW_TAG_BOARD_STYLE;
                    break;
                }
                case 2:  // - Piece
                {
                    NSArray* piecePaths = [NSArray arrayWithObjects:@"pieces/xqwizard",
                                           @"pieces/alfaerie",
                                           @"pieces/wikipedia", @"pieces/HOXChess",
                                           @"pieces/iXiangQi", nil];
                    NSMutableArray* imageNames = [[NSMutableArray alloc] initWithCapacity:[piecePaths count]];
                    for (NSString* subPath in piecePaths)
                    {
                        NSString* path = [[NSBundle mainBundle] pathForResource:@"rking"
                                                                         ofType:@"png"
                                                                    inDirectory:subPath];
                        [imageNames addObject:path];
                    }
                    NSArray* subTitles = [NSArray arrayWithObjects:
                                          @"",
                                          @"Alfaerie graphics \nhttp://www.chessvariants.com",
                                          @"http://wikipedia.org/wiki/Xiangqi",
                                          @"http://wikipedia.org/wiki/Xiangqi",
                                          @"'nanshanweng' \nhttp://sites.google.com/site/328113",
                                          nil];
                    SingleSelectionController* controller =
                    [[SingleSelectionController alloc] initWithChoices:_pieceChoices
                                                            imageNames:imageNames
                                                             subTitles:subTitles
                                                              delegate:self];
                    [imageNames release];
                    controller.rowHeight = 75;
                    subController = controller;
                    cell = [(UITableView*)self.view cellForRowAtIndexPath:indexPath];
                    controller.title = ((UILabel*)[cell viewWithTag:VIEW_TAG_NAME]).text;
                    controller.selectionIndex = _pieceType;
                    controller.tag = VIEW_TAG_PIECE_STYLE;
                    break;
                }
            }
            break;
        }
        case 1: // ----- AI
        {
            switch (indexPath.row)
            {
                case 0:  // - AI-Type
                {
                    NSArray* subTitles = [NSArray arrayWithObjects:
                                          @" Morning Yellow \n http://www.xqbase.com",
                                          @" H.G. Muller \n http://home.hccnet.nl/h.g.muller",
                                          nil];
                    SingleSelectionController* controller =
                        [[SingleSelectionController alloc] initWithChoices:_aiTypeChoices
                                                                 subTitles:subTitles
                                                                  delegate:self];
                    controller.rowHeight = 80;
                    subController = controller;
                    cell = [(UITableView*)self.view cellForRowAtIndexPath:indexPath];
                    controller.title = ((UILabel*)[cell viewWithTag:VIEW_TAG_NAME]).text;
                    controller.selectionIndex = _aiType;
                    controller.tag = VIEW_TAG_AI_TYPE;
                    break;
                }
                case 1:  // - AI-Level
                {
                    SingleSelectionController* controller =
                        [[SingleSelectionController alloc] initWithChoices:_aiLevelChoices
                                                                  delegate:self];
                    subController = controller;
                    cell = [(UITableView*)self.view cellForRowAtIndexPath:indexPath];
                    controller.title = ((UILabel*)[cell viewWithTag:VIEW_TAG_NAME]).text;
                    controller.selectionIndex = _aiLevel;
                    controller.tag = VIEW_TAG_AI_LEVEL;
                    break;
                }
            }
            break;
        }
        case 2: // ----- Network
        {
            subController = [[NetworkSettingController alloc] initWithNibName:@"NetworkSettingView" bundle:nil];
            ((NetworkSettingController*)subController).delegate = self;
            break;
        }
        case 3: // ----- About
        {
            subController = [[AboutViewController alloc] initWithNibName:@"AboutViewController" bundle:nil];
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
#pragma mark Private methods
- (UITableViewCell *)tableViewCellWithReuseIdentifier:(NSString *)identifier 
{
	UITableViewCell *cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:identifier] autorelease];
    
	UILabel *label;
	CGRect rect;
	
	rect = CGRectMake(41, 10, 104, 21);
	label = [[UILabel alloc] initWithFrame:rect];
	label.tag = VIEW_TAG_NAME;
	label.font = [UIFont boldSystemFontOfSize:17];
	label.adjustsFontSizeToFitWidth = YES;
	[cell.contentView addSubview:label];
	label.highlightedTextColor = [UIColor blackColor];
	[label release];
    
    rect = CGRectMake(167, 11, 106, 21);
	label = [[UILabel alloc] initWithFrame:rect];
	label.tag = VIEW_TAG_VALUE;
	label.font = [UIFont boldSystemFontOfSize:17];
	label.adjustsFontSizeToFitWidth = YES;
	[cell.contentView addSubview:label];
	label.highlightedTextColor = [UIColor blackColor];
	[label release];
    
	rect = CGRectMake(9, 10, 22, 22);
	UIImageView *imageView = [[UIImageView alloc] initWithFrame:rect];
	imageView.tag = VIEW_TAG_ICON;
	[cell.contentView addSubview:imageView];
	[imageView release];
	
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
	
	return cell;
}

#pragma mark SingleSelectionDelegate methods

- (void) didSelect:(SingleSelectionController*)controller rowAtIndex:(NSUInteger)index
{
    UITableViewCell *cell = nil;
    switch (controller.tag)
    {
        case VIEW_TAG_BOARD_STYLE:
        {
            if (_boardType != index)
            {
                _boardType = index;
                cell = [(UITableView*)self.view cellForRowAtIndexPath:[NSIndexPath indexPathForRow:1 inSection:0]];
                UILabel* theValue = (UILabel *)[cell viewWithTag:VIEW_TAG_VALUE];
                theValue.text = [_boardChoices objectAtIndex:_boardType];
                [[NSUserDefaults standardUserDefaults] setInteger:_boardType forKey:@"board_type"];
            }
            break;
        }
        case VIEW_TAG_PIECE_STYLE:
        {
            if (_pieceType != index)
            {
                _pieceType = index;
                cell = [(UITableView*)self.view cellForRowAtIndexPath:[NSIndexPath indexPathForRow:2 inSection:0]];
                UILabel* theValue = (UILabel *)[cell viewWithTag:VIEW_TAG_VALUE];
                theValue.text = [_pieceChoices objectAtIndex:_pieceType];
                [[NSUserDefaults standardUserDefaults] setInteger:_pieceType forKey:@"piece_type"];
            }
            break;
        }
        case VIEW_TAG_AI_TYPE:
        {
            if (_aiType != index)
            {
                _aiType = index;
                cell = [(UITableView*)self.view cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:1]];
                UILabel* theValue = (UILabel *)[cell viewWithTag:VIEW_TAG_VALUE];
                theValue.text = [_aiTypeChoices objectAtIndex:_aiType];
                [[NSUserDefaults standardUserDefaults] setObject:[_aiTypeChoices objectAtIndex:_aiType] forKey:@"ai_type"];
            }
            break;
        }
        case VIEW_TAG_AI_LEVEL:
        {
            if (_aiLevel != index)
            {
                _aiLevel = index;
                cell = [(UITableView*)self.view cellForRowAtIndexPath:[NSIndexPath indexPathForRow:1 inSection:1]];
                UILabel* theValue = (UILabel *)[cell viewWithTag:VIEW_TAG_VALUE];
                theValue.text = [_aiLevelChoices objectAtIndex:_aiLevel];
                [[NSUserDefaults standardUserDefaults] setInteger:_aiLevel forKey:@"ai_level"];
            }
            break;
        }
    }
}

#pragma mark -
#pragma mark SingleSelectionDelegate methods

- (void) didChangeUsername:(NetworkSettingController*)controller username:(NSString*)username
{
    UITableViewCell *cell = [(UITableView*)self.view cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:2]];
    UILabel* theValue = (UILabel *)[cell viewWithTag:VIEW_TAG_VALUE];
    theValue.text = username;
}

#pragma mark Event handlers

- (IBAction) autoConnectValueChanged:(id)sender
{    
    [[NSUserDefaults standardUserDefaults] setBool:_soundSwitch.on forKey:@"sound_on"];
    [AudioHelper sharedInstance].enabled = _soundSwitch.on;
}

@end

