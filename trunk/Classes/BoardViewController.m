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

- (id)initWithTableState:(NSString *)state delegate:(id<UIActionSheetDelegate>)delegate
                   title:(NSString*)title
{
    if ([state isEqualToString:@"play"]) {
        closeIndex = -1;
        resignIndex = 0;
        drawIndex = 1;
        logoutIndex = -1;
        cancelIndex = 2;
        self = [super initWithTitle:title delegate:delegate
                  cancelButtonTitle:@"Cancel"
             destructiveButtonTitle:@"Resign"
                  otherButtonTitles:@"Draw", nil];
    }
    else if ([state isEqualToString:@"view"] || [state isEqualToString:@"ready"]) {
        closeIndex = 0;
        resignIndex = -1;
        drawIndex = -1;
        logoutIndex = -1;
        cancelIndex = 1;
        self = [super initWithTitle:title delegate:delegate
                  cancelButtonTitle:@"Cancel"
             destructiveButtonTitle:@"Close Table"
                  otherButtonTitles:nil];
    }
    else if ([state isEqualToString:@"logout"]) {
        closeIndex = -1;
        resignIndex = -1;
        drawIndex = -1;
        logoutIndex = 0;
        cancelIndex = 1;
        self = [super initWithTitle:title delegate:delegate
                  cancelButtonTitle:@"Cancel"
             destructiveButtonTitle:@"Logout"
                  otherButtonTitles:nil];
    }
    else {
        closeIndex = -1;
        resignIndex = -1;
        drawIndex = -1;
        logoutIndex = -1;
        cancelIndex = 0;
        self = [super initWithTitle:title delegate:delegate
                  cancelButtonTitle:@"Cancel"
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
    if (buttonIndex == logoutIndex) { return ACTION_INDEX_LOGOUT; }
    return ACTION_INDEX_CANCEL;
}

@end

///////////////////////////////////////////////////////////////////////////////
//
//    Private methods (BoardViewController)
//
///////////////////////////////////////////////////////////////////////////////

@interface BoardViewController (PrivateMethods)

@end


///////////////////////////////////////////////////////////////////////////////
//
//    Implementation of Public methods
//
///////////////////////////////////////////////////////////////////////////////

@implementation BoardViewController

@synthesize nav_toolbar;
@synthesize red_seat;
@synthesize black_seat;
@synthesize _board;
@synthesize _game;
@synthesize _tableId;
@synthesize game_over_msg;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    if (self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]) {
        self._board = (BoardView*) self.view;
        _board.boardOwner = self;
        [_board setRedLabel:@""];
        [_board setBlackLabel:@""];

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

    [activity stopAnimating];
    [game_over_msg setHidden:YES];
}

- (void)didReceiveMemoryWarning
{
	// Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
	// Release any cached data, images, etc that aren't in use.
}

- (void)dealloc
{
    [nav_toolbar release];
    [activity release];
    [game_over_msg release];
    [red_seat release];
    [black_seat release];
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

- (void) setRedLabel:(NSString*)label
{
    [_board setRedLabel:label];
}

- (void) setBlackLabel:(NSString*)label
{
    [_board setBlackLabel:label];
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

///////////////////////////////////////////////////////////////////////////////
//
//    Implementation of Private methods
//
///////////////////////////////////////////////////////////////////////////////

#pragma mark -
#pragma mark Private methods

- (void) handleNewMove:(NSNumber *)moveInfo
{
    int nGameResult = [_board onNewMove:moveInfo];
    if ( nGameResult != kXiangQi_Unknown ) {  // Game Result changed?
        [self handleEndGameInUI];
    }
}

- (void) handleEndGameInUI
{
    NSLog(@"%s: ENTER.", __FUNCTION__);
}

- (void) saveGame
{
    NSLog(@"%s: ENTER.", __FUNCTION__);
}

- (void) rescheduleTimer
{
    [_board rescheduleTimer];
}

- (void) resetBoard
{
    [_board resetBoard];
}

- (void) displayEmptyBoard
{
    [_board displayEmptyBoard];
    [game_over_msg setHidden:YES];
}

- (BOOL) isMyTurnNext
{
    NSLog(@"%s: ENTER.", __FUNCTION__);
    const ColorEnum nextColor = ([_game get_sdPlayer] ? NC_COLOR_BLACK : NC_COLOR_RED); 
    return (nextColor == _myColor);
}

- (BOOL) isGameReady
{
    NSLog(@"%s: ENTER.", __FUNCTION__);
    return YES;
}

- (void) reverseBoardView
{
    [_board reverseBoardView];
}

@end
