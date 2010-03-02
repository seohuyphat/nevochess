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

#import "AIBoardViewController.h"
#import "Enums.h"
#import "Types.h"

#define ACTION_BUTTON_INDEX 4

enum AlertViewEnum
{
    NC_ALERT_END_GAME,
    NC_ALERT_RESUME_GAME,
    NC_ALERT_RESET_GAME
};

enum ActionSheetEnum
{
    NC_ACTION_SHEET_CANCEL = 1, // Must be non-zero.
    NC_ACTION_SHEET_UNDO   = 2
};

///////////////////////////////////////////////////////////////////////////////
//
//    Private methods
//
///////////////////////////////////////////////////////////////////////////////

@interface AIBoardViewController (PrivateMethods)

- (void) _handleEndGameInUI;
- (void) _displayResumeGameAlert;
- (void) _loadPendingGame:(NSString *)sPendingGame;
- (void) _undoLastMove;
- (void) _countDownToAIMove:(NSTimer*)timer;

@end


///////////////////////////////////////////////////////////////////////////////
//
//    Implementation of Public methods
//
///////////////////////////////////////////////////////////////////////////////

@implementation AIBoardViewController

@synthesize _board;
@synthesize _game;
@synthesize _tableId;
@synthesize _idleTimer;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    if (self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil])
    {
        // Empty.
    }

    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    _board = [[BoardViewController alloc] initWithNibName:@"BoardView" bundle:nil];
    _board.boardOwner = self;
    [self.view addSubview:_board.view];
    [self.view bringSubviewToFront:_toolbar];

    self._game = _board.game;    
    self._tableId = nil;

    self._idleTimer = nil;
    _aiRobot = [[AIRobot alloc] initWith:self];

    _myColor = NC_COLOR_RED;
    [_board setRedLabel:NSLocalizedString(@"You", @"")];
    [_board setBlackLabel:[NSString stringWithFormat:@"%@ [%d]", _aiRobot.aiName, _aiRobot.aiLevel + 1]];

    // Restore pending game, if any.
    NSString* sPendingGame = [[NSUserDefaults standardUserDefaults] stringForKey:@"pending_game"];
    if ( sPendingGame && [sPendingGame length]) {
        [self _displayResumeGameAlert];
    }

    _aiThinkingActivity = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
    _aiThinkingActivity.hidden = YES;
    _aiThinkingButton = [[UIBarButtonItem alloc] initWithCustomView:_aiThinkingActivity];

    [_activity stopAnimating];
}

- (void)dealloc
{
    NSLog(@"%s: ENTER.", __FUNCTION__);
    [_aiRobot release];
    [_aiThinkingActivity release];
    [_aiThinkingButton release];
    [_reverseRoleButton release];
    if (_idleTimer) {
        [_idleTimer invalidate];
        self._idleTimer = nil;
    }
    self._board = nil;
    [super dealloc];
}

- (void)viewDidDisappear:(BOOL)animated
{
    NSLog(@"%s: ENTER.", __FUNCTION__);
    [self saveGame];
    [_board.view removeFromSuperview];
    self._board = nil;
}

- (void) onAIRobotStopped
{
    NSLog(@"%s: ENTER.", __FUNCTION__);
    [_aiRobot release];
    _aiRobot = nil;
    [self goBackToHomeMenu];
}

- (void) goBackToHomeMenu
{
    [self.navigationController popViewControllerAnimated:YES];
}

//
// Handle the "OK" button in the END-GAME and RESUME-GAME alert dialogs. 
//
- (void)alertView: (UIAlertView *)alertView clickedButtonAtIndex: (NSInteger)buttonIndex
{
    if ( alertView.tag == NC_ALERT_END_GAME ) {
        [_aiRobot runResetRobot];
    }
    else if (    alertView.tag == NC_ALERT_RESUME_GAME
              && buttonIndex != [alertView cancelButtonIndex] )
    {
        NSString *sPendingGame = [[NSUserDefaults standardUserDefaults] stringForKey:@"pending_game"];
        if ( sPendingGame && [sPendingGame length]) {
            NSString* colorStr = [[NSUserDefaults standardUserDefaults] stringForKey:@"my_color"];
            _myColor = ( !colorStr || [colorStr isEqualToString:@"Red"]
                        ? NC_COLOR_RED : NC_COLOR_BLACK );
            [self _loadPendingGame:sPendingGame];
        }
    }
    else if (    alertView.tag == NC_ALERT_RESET_GAME
             && buttonIndex != [alertView cancelButtonIndex] )
    {
        [_activity setHidden:NO];
        [_activity startAnimating];
        [_board rescheduleTimer];
        [_aiRobot runResetRobot];
    }
}

- (void)didReceiveMemoryWarning
{
	// Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
	
	// Release any cached data, images, etc that aren't in use.
}

#pragma mark Button actions

- (IBAction)homePressed:(id)sender
{
    [_activity setHidden:NO];
    [_activity startAnimating];
    [_board destroyTimer];
    [_aiRobot runStopRobot];
}

- (IBAction)resetPressed:(id)sender
{
    if ([_game getMoveCount] == 0) return;  // Do nothing if game not yet started.

    UIAlertView *alert =
        [[UIAlertView alloc] initWithTitle:nil
                                   message:NSLocalizedString(@"New game?", @"")
                                  delegate:self 
                         cancelButtonTitle:NSLocalizedString(@"No", @"")
                         otherButtonTitles:NSLocalizedString(@"Yes", @""), nil];
    alert.tag = NC_ALERT_RESET_GAME;
    [alert show];
    [alert release];
}

- (IBAction)actionPressed:(id)sender
{
    NSUInteger moveCount = [[_board getMoves] count];
    if (moveCount == 0) {
        return;  // Do nothing.
    }

    UIActionSheet* actionSheet = nil;

    if (_myColor != [_game getNextColor]) // Robot is thinking?
    {
        actionSheet = [[UIActionSheet alloc] initWithTitle:nil
                                                  delegate:self
                                         cancelButtonTitle:NSLocalizedString(@"AI thinking...", @"")
                                    destructiveButtonTitle:nil
                                         otherButtonTitles:nil];
        actionSheet.tag = NC_ACTION_SHEET_CANCEL;
    }
    else
    {
        actionSheet = [[UIActionSheet alloc] initWithTitle:nil
                                                  delegate:self
                                         cancelButtonTitle:NSLocalizedString(@"Cancel", @"")
                                    destructiveButtonTitle:NSLocalizedString(@"Undo Move", @"")
                                         otherButtonTitles:nil];
        actionSheet.tag = NC_ACTION_SHEET_UNDO;
        
    }

    actionSheet.actionSheetStyle = UIActionSheetStyleAutomatic;
    [actionSheet showInView:self.view];
    [actionSheet release];
}

- (IBAction)reverseRolePressed:(id)sender
{
    if ([_game getMoveCount] > 0) {
        NSLog(@"%s: Game already started. Do nothing.", __FUNCTION__);
        return;
    }

    _myColor = (_myColor == NC_COLOR_RED ? NC_COLOR_BLACK : NC_COLOR_RED);
    [_board reverseRole];

    if (_myColor == NC_COLOR_BLACK) {
        NSLog(@"%s: Schedule AI to run the 1st move in 5 seconds.", __FUNCTION__);
        self._idleTimer = [NSTimer scheduledTimerWithTimeInterval:5.0 target:self selector:@selector(_countDownToAIMove:) userInfo:nil repeats:NO];
    } else {
        _reverseRoleButton.enabled = YES;
        if (_idleTimer) {
            NSLog(@"%s: Cancel the pending AI-timer...", __FUNCTION__);
            [_idleTimer invalidate];
            self._idleTimer = nil;
        }
    }
}

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (actionSheet.tag == NC_ACTION_SHEET_CANCEL) {
        return;
    }

    switch (buttonIndex)
    {
        case 0:  // Undo Move
            [self _undoLastMove];
            break;
    }
}

- (void) onMoveGeneratedByAI:(NSNumber *)moveInfo
{
    int  move = [moveInfo integerValue];
    int sqSrc = SRC(move);
    int sqDst = DST(move);
    [_game doMove:ROW(sqSrc) fromCol:COLUMN(sqSrc) toRow:ROW(sqDst) toCol:COLUMN(sqDst)];
                      
    [self handleNewMove:moveInfo];
}

- (void) handleNewMove:(NSNumber *)moveInfo
{
    NSMutableArray* newItems = [NSMutableArray arrayWithArray:_toolbar.items];
    [newItems replaceObjectAtIndex:ACTION_BUTTON_INDEX withObject:_actionButton];
    _toolbar.items = newItems;

    if ([_game getMoveCount] == 1) {
        _reverseRoleButton.enabled = NO;
    }

    [_board onNewMove:moveInfo inSetupMode:NO];
    if ( _game.gameResult != NC_GAME_STATUS_IN_PROGRESS ) { // Game Over?
        [self _handleEndGameInUI];
    }
}

- (void) onLocalMoveMade:(int)move gameResult:(int)nGameResult
{
    if ([_game getMoveCount] == 1) {
        _reverseRoleButton.enabled = NO;
    }

    // Inform the AI.
    int sqSrc = SRC(move);
    int sqDst = DST(move);
    [_aiRobot onMove_sync:ROW(sqSrc) fromCol:COLUMN(sqSrc) toRow:ROW(sqDst) toCol:COLUMN(sqDst)];

    if ( nGameResult != NC_GAME_STATUS_IN_PROGRESS ) {
        [self _handleEndGameInUI];
    }
    else {
        _aiThinkingActivity.hidden = NO;
        [_aiThinkingActivity startAnimating];
        NSMutableArray* newItems = [NSMutableArray arrayWithArray:_toolbar.items];
        [newItems replaceObjectAtIndex:ACTION_BUTTON_INDEX withObject:_aiThinkingButton];
        _toolbar.items = newItems;

        // AI's turn.
        [_aiRobot runGenerateMove];
    }
}

///////////////////////////////////////////////////////////////////////////////
//
//    Implementation of Private methods
//
///////////////////////////////////////////////////////////////////////////////

#pragma mark -
#pragma mark Private methods

- (void) _handleEndGameInUI
{
    NSString *sound = nil;
    NSString *msg   = nil;

    GameStatusEnum result = _game.gameResult;

    if (   (result == NC_GAME_STATUS_RED_WIN && _myColor == NC_COLOR_RED)
        || (result == NC_GAME_STATUS_BLACK_WIN && _myColor == NC_COLOR_BLACK) )
    {
        sound = @"WIN";
        msg = NSLocalizedString(@"You win,congratulations!", @"");
    }
    else if (  (result == NC_GAME_STATUS_RED_WIN && _myColor == NC_COLOR_BLACK)
           || (result == NC_GAME_STATUS_BLACK_WIN && _myColor == NC_COLOR_RED) )
    {
        sound = @"LOSS";
        msg = NSLocalizedString(@"Computer wins. Don't give up, please try again!", @"");
    }
    else if (result == NC_GAME_STATUS_DRAWN)
    {
        sound = @"DRAW";
        msg = NSLocalizedString(@"Sorry,we are in draw!", @"");
    }
    else if (result == NC_GAME_STATUS_TOO_MANY_MOVES)
    {
        sound = @"ILLEGAL";
        msg = NSLocalizedString(@"Sorry,we made too many moves, please restart again!", @"");
    }
    
    if ( !sound ) return;

    [_board playSound:sound];
    [_board onGameOver];

    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:nil
                                                    message:msg
                                                   delegate:self 
                                          cancelButtonTitle:nil
                                          otherButtonTitles:@"OK", nil];
    alert.tag = NC_ALERT_END_GAME;
    [alert show];
    [alert release];
}

- (void) _displayResumeGameAlert
{
    UIAlertView *alert =
        [[UIAlertView alloc] initWithTitle:nil
                                   message:NSLocalizedString(@"Resume game?", @"")
                                  delegate:self 
                         cancelButtonTitle:NSLocalizedString(@"No", @"")
                         otherButtonTitles:NSLocalizedString(@"Yes", @""), nil];
    alert.tag = NC_ALERT_RESUME_GAME;
    [alert show];
    [alert release];
}

- (void) saveGame
{
    NSMutableString *sMoves = [NSMutableString new];

    if ( _game.gameResult == NC_GAME_STATUS_IN_PROGRESS ) {
        NSMutableArray* moves = [_board getMoves];
        for (MoveAtom *pMove in moves) {
            NSNumber *move = pMove.move;
            if ([sMoves length]) [sMoves appendString:@","];
            [sMoves appendFormat:@"%d",[move integerValue]];
        }
    }

    [[NSUserDefaults standardUserDefaults] setObject:sMoves forKey:@"pending_game"];
    [sMoves release];

    [[NSUserDefaults standardUserDefaults]
            setObject:(_myColor == NC_COLOR_RED ? @"Red" : @"Black")
            forKey:@"my_color"];
}

- (void) _loadPendingGame:(NSString *)sPendingGame
{
    if (_myColor == NC_COLOR_BLACK) {
        [_board reverseRole];
    }

    NSArray *moves = [sPendingGame componentsSeparatedByString:@","];
    int move = 0;
    int sqSrc = 0;
    int sqDst = 0;

    for (NSNumber *pMove in moves) {
        move  = [pMove integerValue];
        sqSrc = SRC(move);
        sqDst = DST(move);

        [_game doMove:ROW(sqSrc) fromCol:COLUMN(sqSrc)
                toRow:ROW(sqDst) toCol:COLUMN(sqDst)];
        [_aiRobot onMove_sync:ROW(sqSrc) fromCol:COLUMN(sqSrc)
                        toRow:ROW(sqDst) toCol:COLUMN(sqDst)];

        NSNumber *moveInfo = [NSNumber numberWithInteger:move];
        [self handleNewMove:moveInfo];
    }

    // If it is AI's turn after the game is loaded, then inform the AI.
    if (   _myColor != [_game getNextColor]  // AI's turn?
        && _game.gameResult == NC_GAME_STATUS_IN_PROGRESS )
    {
        [_aiRobot runGenerateMove];
    }
}

- (void) _undoLastMove
{
    NSArray* moves = [[[NSArray alloc] initWithArray:[_board getMoves]] autorelease]; // Make a copy
    NSUInteger moveCount = [moves count];
    if (moveCount == 0) return;

    // Determine the index of my last Move.
    int myLastMoveIndex = (_myColor == NC_COLOR_RED
                           ? ( (moveCount % 2) ? moveCount-1 : moveCount-2 )
                           : ( (moveCount % 2) ? moveCount-2 : moveCount-1 ));

    // NOTE: We know that at this time AI is not thinking.
    //       Therefore, we directly reset the Game to avoid race conditions.
    //
    [_activity setHidden:NO];
    [_activity startAnimating];
    [_board rescheduleTimer];

    [_aiRobot resetRobot_sync];
    [_board resetBoard];
    
    [_activity stopAnimating];

    // Re-load the moves before my last Move.
    MoveAtom* pMove = nil;
    int move = 0;
    int sqSrc = 0;
    int sqDst = 0;

    for (int i = 0; i < myLastMoveIndex; ++i)
    {
        pMove = [moves objectAtIndex:i]; 
        move = [pMove.move integerValue];
        sqSrc = SRC(move);
        sqDst = DST(move);

        [_game doMove:ROW(sqSrc) fromCol:COLUMN(sqSrc)
                toRow:ROW(sqDst) toCol:COLUMN(sqDst)];
        [_aiRobot onMove_sync:ROW(sqSrc) fromCol:COLUMN(sqSrc)
                        toRow:ROW(sqDst) toCol:COLUMN(sqDst)];

        NSNumber* moveInfo = [NSNumber numberWithInteger:move];
        [self handleNewMove:moveInfo];
    }

    // Handle the special case if the game is reset to the beginning.
    if ([_game getMoveCount] == 0)
    {
        NSLog(@"%s: Game reset to the beginning.", __FUNCTION__);
        _reverseRoleButton.enabled = YES;

        if (_myColor == NC_COLOR_BLACK) {
            NSLog(@"%s: Schedule AI to run the 1st move in 5 seconds.", __FUNCTION__);
            self._idleTimer = [NSTimer scheduledTimerWithTimeInterval:5.0 target:self selector:@selector(_countDownToAIMove:) userInfo:nil repeats:NO];
        }
    }
    // If it is AI's turn after the game is loaded, then inform the AI.
    else if (   _myColor != [_game getNextColor]
             && _game.gameResult == NC_GAME_STATUS_IN_PROGRESS )
    {
        [_aiRobot runGenerateMove];
    }
}

- (void) _countDownToAIMove:(NSTimer*)timer
{
    NSLog(@"%s: ENTER.", __FUNCTION__);
    _reverseRoleButton.enabled = NO;
    [_aiRobot runGenerateMove];
}

- (void) onResetDoneByAI
{
    NSLog(@"%s: ENTER.", __FUNCTION__);
    [_board resetBoard];
    [_activity stopAnimating];
    
    _reverseRoleButton.enabled = YES;
    if (_myColor == NC_COLOR_BLACK) {
        NSLog(@"%s: Schedule AI to run the 1st move in 5 seconds.", __FUNCTION__);
        self._idleTimer = [NSTimer scheduledTimerWithTimeInterval:5.0 target:self selector:@selector(_countDownToAIMove:) userInfo:nil repeats:NO];
    }
}

- (BOOL) isMyTurnNext
{
    return ([_game getNextColor] == _myColor);
}

- (BOOL) isGameReady
{
    return YES;
}

@end
