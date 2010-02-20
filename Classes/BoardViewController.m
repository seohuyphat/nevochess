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

#import "BoardViewController.h"
#import "NevoChessAppDelegate.h"

///////////////////////////////////////////////////////////////////////////////
//
//    BoardActionSheet
//
//////////////////////////////////////////////////////////////////////////////
@implementation BoardActionSheet

- (void) _clearAllIndices
{
    closeIndex  = -1;
    resignIndex = -1;
    drawIndex   = -1;
    resetIndex  = -1;
    logoutIndex = -1;
    cancelIndex = -1;
}

- (id)initWithTableState:(NSString *)state delegate:(id<UIActionSheetDelegate>)delegate
                   title:(NSString*)title
{
    [self _clearAllIndices];

    if ([state isEqualToString:@"play"]) {
        resignIndex = 0;
        drawIndex = 1;
        cancelIndex = 2;
        self = [super initWithTitle:title delegate:delegate
                  cancelButtonTitle:NSLocalizedString(@"Cancel", @"")
             destructiveButtonTitle:NSLocalizedString(@"Resign", @"")
                  otherButtonTitles:NSLocalizedString(@"Draw", @""), nil];
    }
    else if ([state isEqualToString:@"ended"]) {
        closeIndex = 0;
        resetIndex = 1;
        cancelIndex = 2;
        self = [super initWithTitle:title delegate:delegate
                  cancelButtonTitle:NSLocalizedString(@"Cancel", @"")
             destructiveButtonTitle:NSLocalizedString(@"Close Table", @"")
                  otherButtonTitles:NSLocalizedString(@"Reset Table", @""), nil];
    }
    else if ([state isEqualToString:@"view"] || [state isEqualToString:@"ready"]) {
        closeIndex = 0;
        cancelIndex = 1;
        self = [super initWithTitle:title delegate:delegate
                  cancelButtonTitle:NSLocalizedString(@"Cancel", @"")
             destructiveButtonTitle:NSLocalizedString(@"Close Table", @"")
                  otherButtonTitles:nil];
    }
    else if ([state isEqualToString:@"logout"]) {
        logoutIndex = 0;
        cancelIndex = 1;
        self = [super initWithTitle:title delegate:delegate
                  cancelButtonTitle:NSLocalizedString(@"Cancel", @"")
             destructiveButtonTitle:NSLocalizedString(@"Logout", @"")
                  otherButtonTitles:nil];
    }
    else {
        cancelIndex = 0;
        self = [super initWithTitle:title delegate:delegate
                  cancelButtonTitle:NSLocalizedString(@"Cancel", @"")
             destructiveButtonTitle:nil
                  otherButtonTitles:nil];
    }

    self.actionSheetStyle = UIActionSheetStyleAutomatic;
    return self;
}

- (NSInteger) valueOfClickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == closeIndex) { return ACTION_INDEX_CLOSE; }
    if (buttonIndex == resignIndex) { return ACTION_INDEX_RESIGN; }
    if (buttonIndex == drawIndex) { return ACTION_INDEX_DRAW; }
    if (buttonIndex == resetIndex) { return ACTION_INDEX_RESET; }
    if (buttonIndex == logoutIndex) { return ACTION_INDEX_LOGOUT; }
    return ACTION_INDEX_CANCEL;
}

@end


///////////////////////////////////////////////////////////////////////////////
//
//    Implementation of Public methods
//
///////////////////////////////////////////////////////////////////////////////

@implementation BoardViewController

@synthesize _board;
@synthesize _game;
@synthesize _tableId;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    if (self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]) {
        self._board = (BoardView*) self.view;
        _board.boardOwner = self;

        self._game = ((BoardView*)self.view).game;

        self._tableId = nil;
        _myColor = NC_COLOR_UNKNOWN;
    }
    
    return self;
}

- (void)viewDidLoad
{
    NSLog(@"%s: ENTER.", __FUNCTION__);
    [super viewDidLoad];
}

- (void)didReceiveMemoryWarning
{
	// Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
	// Release any cached data, images, etc that aren't in use.
}

- (void)dealloc
{
    [_board release];
    [_game release];
    [_tableId release];
    [super dealloc];
}

#pragma mark Button actions

- (IBAction)homePressed:(id)sender
{
    NSLog(@"%s: ENTER.", __FUNCTION__);
}

- (IBAction)resetPressed:(id)sender
{
    NSLog(@"%s: ENTER.", __FUNCTION__);
}

- (IBAction)actionPressed:(id)sender
{
    NSLog(@"%s: ENTER.", __FUNCTION__);
}

- (IBAction)messagesPressed:(id)sender
{
    NSLog(@"%s: ENTER.", __FUNCTION__);
}

- (void) onLocalMoveMade:(int)move
{
    NSLog(@"%s: ENTER. move = [%d -> %d]", __FUNCTION__, SRC(move), DST(move));
}

- (void) goBackToHomeMenu
{
    [((NevoChessAppDelegate*)[[UIApplication sharedApplication] delegate]).navigationController popViewControllerAnimated:YES];
}

- (void) setInitialTime:(NSString*)times
{
    [_board setInitialTime:times];
}

- (void) setRedTime:(NSString*)times
{
    [_board setRedTime:times];
}

- (void) setBlackTime:(NSString*)times
{
    [_board setBlackTime:times];
}

- (void) saveGame
{
    NSLog(@"%s: ENTER.", __FUNCTION__);
}

- (void) rescheduleTimer
{
    [_board rescheduleTimer];
}

- (BOOL) isMyTurnNext
{
    return ([_game getNextColor] == _myColor);
}

- (BOOL) isGameReady
{
    return YES;
}

- (void) reverseBoardView
{
    [_board reverseBoardView];
}

@end
