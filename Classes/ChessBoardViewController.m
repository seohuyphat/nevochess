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

#import "ChessBoardViewController.h"
#import "Enums.h"
#import "NevoChessAppDelegate.h"
#import "Grid.h"
#import "Piece.h"
#import "ChessBoardView.h"

///////////////////////////////////////////////////////////////////////////////
//
//    Private methods
//
///////////////////////////////////////////////////////////////////////////////

@interface ChessBoardViewController (PrivateMethods)

- (void) _setHighlightCells:(BOOL)bHighlight;
- (void) _showHighlightOfMove:(int)move;
- (void) _handleNewMove:(NSNumber *)pMove;
- (void) _handleEndGameInUI;
- (void) _displayResumeGameAlert;
- (void) _loadPendingGame:(NSString *)sPendingGame;

@end


///////////////////////////////////////////////////////////////////////////////
//
//    Implementation of Public methods
//
///////////////////////////////////////////////////////////////////////////////

@implementation ChessBoardViewController

//
// The designated initializer.
// Override if you create the controller programmatically and want to perform
// customization that is not appropriate for viewDidLoad.
//
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    if (self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]) {

        [self setBlackLabel:[_game getAIName]]; 
        
        // Restore pending game, if any.
        NSString *sPendingGame = [[NSUserDefaults standardUserDefaults] stringForKey:@"pending_game"];
        if ( sPendingGame != nil && [sPendingGame length]) {
            [self _displayResumeGameAlert];
        }
    }
    
    return self;
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
        // FIXME: in case of this function is invoked before "AIMove", the app might crash thereafter due to the background AI 
        //       thinking is still on going. So trying to stop the runloop
        CFRunLoopStop(_robotLoop);
        [((NevoChessAppDelegate*)[[UIApplication sharedApplication] delegate]).navigationController popViewControllerAnimated:YES];
    }
}


//
// Implement viewDidLoad to do additional setup after loading the view,
// typically from a nib.
//
- (void)viewDidLoad
{
    NSLog(@"%s: ENTER.", __FUNCTION__);
    [super viewDidLoad];

    // Robot
    _robotPort = [[NSMachPort port] retain]; //retain here otherwise it will be autoreleased
    [_robotPort setDelegate:self];
    [NSThread detachNewThreadSelector:@selector(robotThread:) toTarget:self withObject:nil];
}

//
// Handle the "OK" button in the END-GAME and RESUME-GAME alert dialogs. 
//
- (void)alertView: (UIAlertView *)alertView clickedButtonAtIndex: (NSInteger)buttonIndex
{
    if ( alertView.tag == POC_ALERT_END_GAME ) {
        [self resetBoard];
    }
    else if (    alertView.tag == POC_ALERT_RESUME_GAME
              && buttonIndex != [alertView cancelButtonIndex] )
    {
        NSString *sPendingGame = [[NSUserDefaults standardUserDefaults] stringForKey:@"pending_game"];
        if ( sPendingGame != nil && [sPendingGame length]) {
            [self _loadPendingGame:sPendingGame];
        }
    }
    else if (    alertView.tag == POC_ALERT_RESET_GAME
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

- (void)viewDidUnload
{
	// Release any retained subviews of the main view.
	// e.g. self.myOutlet = nil;
}

- (void)dealloc
{
    [_robotPort release];
    [super dealloc];
}

#pragma mark Button actions

- (IBAction)homePressed:(id)sender
{
    [activity setHidden:NO];
    [activity startAnimating];

    if (self._timer) [self._timer invalidate];
    self._timer = nil;

    [self performSelector:@selector(resetRobot:) onThread:robot withObject:nil waitUntilDone:NO];
    [self saveGame];
    // Not needed: [self _resetBoard];
}

- (IBAction)resetPressed:(id)sender
{
    if ( [_moves count] == 0 ) return;  // Do nothing if game not yet started.

    UIAlertView *alert =
        [[UIAlertView alloc] initWithTitle:@"NevoChess"
                                   message:NSLocalizedString(@"New game?", @"")
                                  delegate:self 
                         cancelButtonTitle:NSLocalizedString(@"No", @"")
                         otherButtonTitles:NSLocalizedString(@"Yes", @""), nil];
    alert.tag = POC_ALERT_RESET_GAME;
    [alert show];
    [alert release];
}

- (IBAction)movePrevPressed:(id)sender
{
    if (_nthMove < 1) {  // No Move made yet?
        return;
    }

    _inReview = YES;  // Enter the Move-Review mode immediately!

    MoveAtom *pMove = [_moves objectAtIndex:--_nthMove];
    int move = [(NSNumber*)pMove.move intValue];
    int sqSrc = SRC(move);
    int sqDst = DST(move);
    [_audioHelper play_wav_sound:@"MOVE"]; // TODO: mono-type "move" sound

    // For Move-Review, just reverse the move order (sqDst->sqSrc)
    // Since it's only a review, no need to make actual move in
    // the underlying game logic.
    //
    [_game x_movePiece:(Piece*)pMove.srcPiece toRow:ROW(sqSrc) toCol:COLUMN(sqSrc)];
    if (pMove.capturedPiece) {
        [_game x_movePiece:(Piece*)pMove.capturedPiece toRow:ROW(sqDst) toCol:COLUMN(sqDst)];
    }

    int prevMove = INVALID_MOVE;
    if (_nthMove > 0) {  // No more Move?
        int prevIndex = _nthMove - 1;
        pMove = [_moves objectAtIndex:prevIndex];
        prevMove = [(NSNumber*)pMove.move intValue];
    }
    [self _showHighlightOfMove:prevMove];
}

- (IBAction)moveNextPressed:(id)sender
{
    BOOL bNext = NO; // One "Next" click was serviced.
                     // This variable is introduced to enforce the rule:
                     // "Only one Move is replayed PER click".
                     //
    int nMoves = [_moves count];
    if (_nthMove >= 0 && _nthMove < nMoves) {
        MoveAtom *pMove = [_moves objectAtIndex:_nthMove++];
        int move = [(NSNumber*)pMove.move intValue];
        int sqDst = DST(move);
        int row2 = ROW(sqDst);
        int col2 = COLUMN(sqDst);
        [_audioHelper play_wav_sound:@"MOVE"];  // TODO: mono-type "move" sound
        Piece *capture = [_game x_getPieceAtRow:row2 col:col2];
        if (capture) {
            [capture removeFromSuperlayer];
        }
        [_game x_movePiece:(Piece*)pMove.srcPiece toRow:row2 toCol:col2];
        [self _showHighlightOfMove:move];
        bNext = YES;
    }

    if (_nthMove == nMoves)  // Are we reaching the latest Move end?
    {
        if ( _latestMove == INVALID_MOVE ) {
            _inReview = NO;
        }
        else if ( ! bNext ) {
            _inReview = NO;
            // Perform the latest Move if not yet done so.
            NSNumber *moveInfo = [NSNumber numberWithInteger:_latestMove];
            _latestMove = INVALID_MOVE;
            [self _handleNewMove:moveInfo];
        }
    }
}

#pragma mark AI move 
- (void)AIMove
{
    int captured = 0;
    int move = [_game getRobotMove:&captured];
    if (move == INVALID_MOVE) {
        NSLog(@"ERROR: %s: Invalid move [%d].", __FUNCTION__, move); 
        return;
    }

    NSNumber *moveInfo = [NSNumber numberWithInteger:move];
    [self performSelectorOnMainThread:@selector(_handleNewMove:)
                           withObject:moveInfo waitUntilDone:NO];
}

#pragma mark Touch event handling
- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    if ( [[event allTouches] count] != 1 // Valid for single touch only
      ||  _inReview    // Do nothing if we are in the middle of Move-Review.
      || [_game get_sdPlayer] ) // Ignore any touch when it is robot's turn.
    { 
        return;
    }

    ChessBoardView *view = (ChessBoardView*) self.view;
    GridCell *holder = nil;
    
    UITouch *touch = [[touches allObjects] objectAtIndex:0];
    CGPoint p = [touch locationInView:self.view];
    Piece *piece = (Piece*)[view hitTestPoint:p LayerMatchCallback:layerIsBit offset:NULL];
    if(piece) {
        // Generate moves for the selected piece.
        holder = (GridCell*)piece.holder;
        if(!_selectedPiece || (_selectedPiece._owner == piece._owner)) {
            int sqSrc = TOSQUARE(holder._row, holder._column);
            [self _setHighlightCells:NO]; // Clear old highlight.

            _hl_nMoves = [_game generateMoveFrom:sqSrc moves:_hl_moves];
            [self _setHighlightCells:YES];
            _selectedPiece = piece;
            [_audioHelper play_wav_sound:@"CLICK"];
            return;
        }
        
    } else {
        holder = (GridCell*)[view hitTestPoint:p LayerMatchCallback:layerIsBitHolder offset:NULL];
    }

    // Make a Move from the last selected cell to the current selected cell.
    if(holder && holder._highlighted && _selectedPiece != nil && _hl_nMoves > 0) {
        [self _setHighlightCells:NO]; // Clear highlighted.

        int sqDst = TOSQUARE(holder._row, holder._column);
        GridCell *cell = (GridCell*)_selectedPiece.holder;
        int sqSrc = TOSQUARE(cell._row, cell._column);
        int move = MOVE(sqSrc, sqDst);
        if([_game isLegalMove:move])
        {
            [_game humanMove:cell._row fromCol:cell._column toRow:ROW(sqDst) toCol:COLUMN(sqDst)];

            NSNumber *moveInfo = [NSNumber numberWithInteger:move];
            [self _handleNewMove:moveInfo];

            // AI's turn.
            if ( _game.game_result == kXiangQi_InPlay ) {
                [self performSelector:@selector(AIMove) onThread:robot withObject:nil waitUntilDone:NO];
            }
        }
    } else {
        [self _setHighlightCells:NO];  // Clear highlighted.
    }

    _selectedPiece = nil;  // Reset selected state.
}

///////////////////////////////////////////////////////////////////////////////
//
//    Implementation of Private methods
//
///////////////////////////////////////////////////////////////////////////////

#pragma mark -
#pragma mark Private methods

- (void) _setHighlightCells:(BOOL)bHighlight
{
    // Set (or Clear) highlighted cells.
    for(int i = 0; i < _hl_nMoves; ++i) {
        int sqDst = DST(_hl_moves[i]);
        int row = ROW(sqDst);
        int col = COLUMN(sqDst);
        if ( ! bHighlight ) {
            _hl_moves[i] = 0;
        }
        ((XiangQiSquare*)[_game._grid cellAtRow:row column:col])._highlighted = bHighlight;
    }

    if ( ! bHighlight ) {
        _hl_nMoves = 0;
    }
}

- (void) _showHighlightOfMove:(int)move
{
    if (_hl_lastMove != INVALID_MOVE) {
        _hl_nMoves = 1;
        _hl_moves[0] = _hl_lastMove;
        [self _setHighlightCells:NO];
        _hl_lastMove = INVALID_MOVE;
    }
    
    if (move != INVALID_MOVE) {
        int sqDst = DST(move);
        ((XiangQiSquare*)[_game._grid cellAtRow:ROW(sqDst) column:COLUMN(sqDst)])._highlighted = YES;
        _hl_lastMove = move;
    }
}

- (void) _handleNewMove:(NSNumber *)moveInfo
{
    int  move     = [moveInfo integerValue];
    BOOL isAI     = ([_game get_sdPlayer] == 0);  // AI just made this Move.

    // Delay update the UI if in Preview mode.
    if ( _inReview ) {
        NSAssert1(_latestMove == INVALID_MOVE,
                  @"The latest Move should not be set [%d]", _latestMove);
        _latestMove = move;  // NOTE: Save the Move to be processed later.
        return;
    }
    
    int sqSrc = SRC(move);
    int sqDst = DST(move);
    int row1 = ROW(sqSrc);
    int col1 = COLUMN(sqSrc);
    int row2 = ROW(sqDst);
    int col2 = COLUMN(sqDst);

    NSString *sound = @"MOVE";

    Piece *capture = [_game x_getPieceAtRow:row2 col:col2];
    Piece *piece = [_game x_getPieceAtRow:row1 col:col1];

    if (capture != nil) {
        [capture removeFromSuperlayer];
        sound = (isAI ? @"CAPTURE2" : @"CAPTURE");
    }
    
    [_audioHelper play_wav_sound:sound];
    
    [_game x_movePiece:piece toRow:row2 toCol:col2];
    [self _showHighlightOfMove:move];

    // Check End-Game status.
    int nGameResult = [_game checkGameStatus:isAI];
    if ( nGameResult != kXiangQi_Unknown ) {  // Game Result changed?
        [self _handleEndGameInUI];
    }
    
    // Add this new Move to the Move-History.
    MoveAtom *pMove = [[MoveAtom alloc] init];
    pMove.srcPiece = piece;
    pMove.capturedPiece = capture;
    pMove.move = [NSNumber numberWithInteger:move];
    [_moves addObject:pMove];
    [pMove release];
    _nthMove = [_moves count];
}

- (void) _handleEndGameInUI
{
    NSString *sound = nil;
    NSString *msg   = nil;

    switch ( _game.game_result ) {
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

    [_audioHelper play_wav_sound:sound];

    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"NevoChess"
                                                    message:msg
                                                   delegate:self 
                                          cancelButtonTitle:nil
                                          otherButtonTitles:@"OK", nil];
    alert.tag = POC_ALERT_END_GAME;
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
    alert.tag = POC_ALERT_RESUME_GAME;
    [alert show];
    [alert release];
}

- (void) saveGame
{
    NSMutableString *sMoves = [NSMutableString new];

    if ( _game.game_result == kXiangQi_InPlay ) {
        for (MoveAtom *pMove in _moves) {
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

        [_game humanMove:ROW(sqSrc) fromCol:COLUMN(sqSrc)
                   toRow:ROW(sqDst) toCol:COLUMN(sqDst)];

        NSNumber *moveInfo = [NSNumber numberWithInteger:move];
        [self _handleNewMove:moveInfo];
        
        bAIturn = !bAIturn;
    }

    // If it is AI's turn after the game is loaded, then inform the AI.
    if ( bAIturn && _game.game_result == kXiangQi_InPlay ) {
        [self performSelector:@selector(AIMove) onThread:robot withObject:nil waitUntilDone:NO];
    }
}

#pragma mark NSMachPort message handle 
// Handle messages from the controller thread.
- (void)handlePortMessage:(NSPortMessage *)portMessage
{
    //TODO: implement communication message between robot and controller
}
        
@end
