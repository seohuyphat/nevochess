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
#import "NevoChessAppDelegate.h"
#import "Grid.h"
#import "Piece.h"
#import "AI_HaQiKiD.h"
#import "AI_XQWLight.h"
#import "XiangQi.h"  // XQWLight Objective-C based AI


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

- (void) _AIMove;
- (void) _handleEndGameInUI;
- (void) _displayResumeGameAlert;
- (void) _loadPendingGame:(NSString *)sPendingGame;
- (void) _undoLastMove;
- (int) _convertStringToAIType:(NSString *)aiSelection;

@end


///////////////////////////////////////////////////////////////////////////////
//
//    Implementation of Public methods
//
///////////////////////////////////////////////////////////////////////////////

@implementation AIBoardViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    if (self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]) {

        // Determine the type of AI.
        _aiName = [[NSUserDefaults standardUserDefaults] stringForKey:@"ai_type"];
        int aiType = [self _convertStringToAIType:_aiName];
        switch (aiType) {
            case NC_AI_XQWLight:
                _aiEngine = [[AI_XQWLight alloc] init];
                break;
            case NC_AI_HaQiKiD:
                _aiEngine = [[AI_HaQiKiD alloc] init];
                break;
            case NC_AI_XQWLight_ObjC:
                // NOTE: The Objective-c AI is still in experimental stage.
                _aiEngine = [[AI_XQWLightObjC alloc] init];
                break;
            default:
                _aiEngine = nil;
        }
        [_aiEngine initGame];
        int aiLevel = [[NSUserDefaults standardUserDefaults] integerForKey:@"ai_level"];
        int nDifficulty = 1;
        switch (aiLevel) {
            case 0: nDifficulty = 1; break;
            case 1: nDifficulty = 3; break;
            case 2: nDifficulty = 6; break;
            case 3: nDifficulty = 9; break;
        }
        [_aiEngine setDifficultyLevel:nDifficulty];

        // Robot
        _robotPort = [[NSMachPort port] retain]; //retain here otherwise it will be autoreleased
        [_robotPort setDelegate:self];
        [NSThread detachNewThreadSelector:@selector(robotThread:) toTarget:self withObject:nil];

        _myColor = NC_COLOR_RED;
        [_board setRedLabel:NSLocalizedString(@"You", @"")];
        [_board setBlackLabel:_aiName];
        
        // Restore pending game, if any.
        NSString *sPendingGame = [[NSUserDefaults standardUserDefaults] stringForKey:@"pending_game"];
        if ( sPendingGame != nil && [sPendingGame length]) {
            [self _displayResumeGameAlert];
        }
    }
    
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // Remove the Messages button.  
    NSMutableArray* newItems = [NSMutableArray arrayWithArray:nav_toolbar.items];
    [newItems removeLastObject];  // ... Messages button
    [newItems removeLastObject];  // ... Messages separator
    nav_toolbar.items = newItems;

    _actionButton = [(UIBarButtonItem*)[newItems objectAtIndex:ACTION_BUTTON_INDEX] retain];
    _aiThinkingActivity = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
    _aiThinkingActivity.hidden = YES;
    _aiThinkingButton = [[UIBarButtonItem alloc] initWithCustomView:_aiThinkingActivity];

    [activity stopAnimating];
}

- (void)dealloc
{
    [_aiEngine release];
    [_robotPort release];
    [_actionButton release];
    [_aiThinkingActivity release];
    [_aiThinkingButton release];
    [super dealloc];
}

- (void)robotThread:(void*)param
{
 	NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
	BOOL done = NO;
    
    robot = [NSThread currentThread];
    _robotLoop = CFRunLoopGetCurrent();
    
    // Set the priority to the highest so that Robot can utilize more time to think
    [NSThread setThreadPriority:1.0f];
    
    // connect myself to the controller
    [[NSRunLoop currentRunLoop] addPort:_robotPort forMode:NSDefaultRunLoopMode];
    
    do  // Let the run loop process things.
    {
        // Start the run loop but return after each source is handled.
        SInt32 result = CFRunLoopRunInMode(kCFRunLoopDefaultMode, 60, NO);
        // If a source explicitly stopped the run loop, go and exit the loop
        if (result == kCFRunLoopRunStopped)
            done = YES;
    } while (!done);
	
    [pool release];   
}

- (void)resetRobot:(id)restart
{
    [activity stopAnimating];
    if(restart) {
        [[NSRunLoop currentRunLoop] cancelPerformSelectorsWithTarget:self];
        // only after or before AI induce begins
        // NOTE: We "reset" the Board's data *here* inside the AI Thread to
        //       avoid clearing data while the AI is thinking of a Move.
        [self resetBoard];
    }else{
        // FIXME: in case of this function is invoked before "_AIMove", the app might crash thereafter due to the background AI 
        //       thinking is still on going. So trying to stop the runloop
        CFRunLoopStop(_robotLoop);
        [self goBackToHomeMenu];
    }
}

- (void) resetBoard
{
    [_aiEngine initGame];
    [_board resetBoard];
}

//
// Handle the "OK" button in the END-GAME and RESUME-GAME alert dialogs. 
//
- (void)alertView: (UIAlertView *)alertView clickedButtonAtIndex: (NSInteger)buttonIndex
{
    if ( alertView.tag == NC_ALERT_END_GAME ) {
        [self resetBoard];
    }
    else if (    alertView.tag == NC_ALERT_RESUME_GAME
              && buttonIndex != [alertView cancelButtonIndex] )
    {
        NSString *sPendingGame = [[NSUserDefaults standardUserDefaults] stringForKey:@"pending_game"];
        if ( sPendingGame != nil && [sPendingGame length]) {
            [self _loadPendingGame:sPendingGame];
        }
    }
    else if (    alertView.tag == NC_ALERT_RESET_GAME
             && buttonIndex != [alertView cancelButtonIndex] )
    {
        [activity setHidden:NO];
        [activity startAnimating];
        
        [self rescheduleTimer];
        
        [self performSelector:@selector(resetRobot:) onThread:robot withObject:self waitUntilDone:NO];
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
    [activity setHidden:NO];
    [activity startAnimating];

    [_board destroyTimer];

    [self performSelector:@selector(resetRobot:) onThread:robot withObject:nil waitUntilDone:NO];
    [self saveGame];
    // Not needed: [self _resetBoard];
}

- (IBAction)resetPressed:(id)sender
{
    if ([_game getMoveCount] == 0) return;  // Do nothing if game not yet started.

    UIAlertView *alert =
        [[UIAlertView alloc] initWithTitle:@"NevoChess"
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

    if (moveCount % 2) // Robot is thinking?
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

- (void)_AIMove
{
    int row1 = 0, col1 = 0, row2 = 0, col2 = 0;

    NSDate* startTime = [NSDate date];
    [_aiEngine generateMove:&row1 fromCol:&col1 toRow:&row2 toCol:&col2];
    NSTimeInterval timeInterval = - [startTime timeIntervalSinceNow]; // in seconds.
    NSLog(@"%s: AI took [%.02f] seconds.", __FUNCTION__, timeInterval);

    int sqSrc = TOSQUARE(row1, col1);
    int sqDst = TOSQUARE(row2, col2);
    int move = MOVE(sqSrc, sqDst);

    if (move == INVALID_MOVE) {
        NSLog(@"ERROR: %s: Invalid move [%d].", __FUNCTION__, move); 
        return;
    }

    [_game doMove:row1 fromCol:col1 toRow:row2 toCol:col2];

    NSNumber *moveInfo = [NSNumber numberWithInteger:move];
    [self performSelectorOnMainThread:@selector(handleNewMove:)
                           withObject:moveInfo waitUntilDone:NO];
}

- (void) handleNewMove:(NSNumber *)moveInfo
{
    NSMutableArray* newItems = [NSMutableArray arrayWithArray:nav_toolbar.items];
    [newItems replaceObjectAtIndex:ACTION_BUTTON_INDEX withObject:_actionButton];
    nav_toolbar.items = newItems;
    
    int nGameResult = [_board onNewMove:moveInfo inSetupMode:NO];
    if ( nGameResult != kXiangQi_Unknown ) {  // Game Result changed?
        [self _handleEndGameInUI];
    }
}

- (void) onLocalMoveMade:(int)move gameResult:(int)nGameResult
{
    // Inform the AI.
    int sqSrc = SRC(move);
    int sqDst = DST(move);
    [_aiEngine onHumanMove:ROW(sqSrc) fromCol:COLUMN(sqSrc) toRow:ROW(sqDst) toCol:COLUMN(sqDst)];

    if ( nGameResult != kXiangQi_Unknown ) {  // Game Result changed?
        [self _handleEndGameInUI];
    }
    else {
        _aiThinkingActivity.hidden = NO;
        [_aiThinkingActivity startAnimating];
        NSMutableArray* newItems = [NSMutableArray arrayWithArray:nav_toolbar.items];
        [newItems replaceObjectAtIndex:ACTION_BUTTON_INDEX withObject:_aiThinkingButton];
        nav_toolbar.items = newItems;

        // AI's turn.
        [self performSelector:@selector(_AIMove) onThread:robot withObject:nil waitUntilDone:NO];
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

    switch ( _game.gameResult ) {
        case kXiangQi_YouWin:
            sound = @"WIN";
            msg = NSLocalizedString(@"You win,congratulations!", @"");
            break;
        case kXiangQi_ComputerWin:
            sound = @"LOSS";
            msg = NSLocalizedString(@"Computer wins. Don't give up, please try again!", @"");
            break;
        case kXiangqi_YouLose:
            sound = @"LOSS";
            msg = NSLocalizedString(@"You lose. You may try again!", @"");
            break;
        case kXiangQi_Draw:
            sound = @"DRAW";
            msg = NSLocalizedString(@"Sorry,we are in draw!", @"");
            break;
        case kXiangQi_OverMoves:
            sound = @"ILLEGAL";
            msg = NSLocalizedString(@"Sorry,we made too many moves, please restart again!", @"");
            break;
        default:
            break;  // Do nothing
    }
    
    if ( !sound ) return;

    [_board playSound:sound];
    [_board onGameOver];

    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"NevoChess"
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
        [[UIAlertView alloc] initWithTitle:@"NevoChess"
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

    if ( _game.gameResult == kXiangQi_InPlay ) {
        NSMutableArray* moves = [_board getMoves];
        for (MoveAtom *pMove in moves) {
            NSNumber *move = pMove.move;
            if ([sMoves length]) [sMoves appendString:@","];
            [sMoves appendFormat:@"%d",[move integerValue]];
        }
    }

    [[NSUserDefaults standardUserDefaults] setObject:sMoves forKey:@"pending_game"];
    [sMoves release];
}

- (void) _loadPendingGame:(NSString *)sPendingGame
{
    NSArray *moves = [sPendingGame componentsSeparatedByString:@","];
    int move = 0;
    int sqSrc = 0;
    int sqDst = 0;
    BOOL bAIturn = NO;

    for (NSNumber *pMove in moves) {
        move  = [pMove integerValue];
        sqSrc = SRC(move);
        sqDst = DST(move);

        [_game doMove:ROW(sqSrc) fromCol:COLUMN(sqSrc)
                toRow:ROW(sqDst) toCol:COLUMN(sqDst)];
        [_aiEngine onHumanMove:ROW(sqSrc) fromCol:COLUMN(sqSrc)
                         toRow:ROW(sqDst) toCol:COLUMN(sqDst)];

        NSNumber *moveInfo = [NSNumber numberWithInteger:move];
        [self handleNewMove:moveInfo];
        
        bAIturn = !bAIturn;
    }

    // If it is AI's turn after the game is loaded, then inform the AI.
    if ( bAIturn && _game.gameResult == kXiangQi_InPlay ) {
        [self performSelector:@selector(_AIMove) onThread:robot withObject:nil waitUntilDone:NO];
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
    [activity setHidden:NO];
    [activity startAnimating];
    [self rescheduleTimer];
    [self resetBoard];
    [activity stopAnimating];

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
        [_aiEngine onHumanMove:ROW(sqSrc) fromCol:COLUMN(sqSrc)
                         toRow:ROW(sqDst) toCol:COLUMN(sqDst)];

        NSNumber* moveInfo = [NSNumber numberWithInteger:move];
        [self handleNewMove:moveInfo];
    }
}

- (int) _convertStringToAIType:(NSString *)aiSelection
{
    if ([aiSelection isEqualToString:@"XQWLight"]) {
        return NC_AI_XQWLight;
    } else if ([aiSelection isEqualToString:@"HaQiKiD"]) {
        return NC_AI_HaQiKiD;
    } else if ([aiSelection isEqualToString:@"XQWLightObjc"]) {
        return NC_AI_XQWLight_ObjC;
    }
    return NC_AI_XQWLight; // Default!
}

#pragma mark NSMachPort message handle 
// Handle messages from the controller thread.
- (void)handlePortMessage:(NSPortMessage *)portMessage
{
    //TODO: implement communication message between robot and controller
}
        
@end
