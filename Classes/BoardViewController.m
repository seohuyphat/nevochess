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
#import "Enums.h"
#import "NevoChessAppDelegate.h"
#import "Grid.h"
#import "Piece.h"
#import "BoardView.h"

BOOL layerIsBit( CALayer* layer )        {return [layer isKindOfClass: [Bit class]];}
BOOL layerIsBitHolder( CALayer* layer )  {return [layer conformsToProtocol: @protocol(BitHolder)];}

///////////////////////////////////////////////////////////////////////////////
//
//    MoveAtom
//
///////////////////////////////////////////////////////////////////////////////

@implementation MoveAtom

@synthesize move;
@synthesize srcPiece;
@synthesize capturedPiece;

- (id)init
{
    self = [super init];
    if (self ) {
        move = nil;
        srcPiece = nil;
        capturedPiece = nil;
    }
    return self;
}

- (void)dealloc
{
    [move release];
    [srcPiece release];
    [capturedPiece release];
    [super dealloc];
}

@end

///////////////////////////////////////////////////////////////////////////////
//
//    BoardActionSheet
//
//////////////////////////////////////////////////////////////////////////////
@implementation BoardActionSheet

- (id)initWithTableState:(NSString *)state delegate:(id<UIActionSheetDelegate>)delegate
{
    if ([state isEqualToString:@"play"]) {
        closeIndex = -1;
        resignIndex = 0;
        drawIndex = 1;
        cancelIndex = 2;
        self = [super initWithTitle:nil delegate:delegate
                  cancelButtonTitle:@"Cancel"
             destructiveButtonTitle:@"Resign"
                  otherButtonTitles:@"Draw", nil];
    }
    else if ([state isEqualToString:@"view"] || [state isEqualToString:@"ready"]) {
        closeIndex = 0;
        resignIndex = -1;
        drawIndex = -1;
        cancelIndex = 1;
        self = [super initWithTitle:nil delegate:delegate
                  cancelButtonTitle:@"Cancel"
             destructiveButtonTitle:@"Close Table"
                  otherButtonTitles:nil];
    }
    else {
        closeIndex = -1;
        resignIndex = -1;
        drawIndex = -1;
        cancelIndex = 0;
        self = [super initWithTitle:nil delegate:delegate
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
    return ACTION_INDEX_CANCEL;
}

@end

///////////////////////////////////////////////////////////////////////////////
//
//    Private methods (BoardViewController)
//
///////////////////////////////////////////////////////////////////////////////

@interface BoardViewController (PrivateMethods)

- (id)   _initSoundSystem;
- (void) _ticked:(NSTimer*)timer;
- (void) _updateTimer:(int)color;

@end


///////////////////////////////////////////////////////////////////////////////
//
//    Implementation of Public methods
//
///////////////////////////////////////////////////////////////////////////////

@implementation BoardViewController

@synthesize nav_toolbar;
@synthesize red_label;
@synthesize black_label;
@synthesize red_time, red_move_time;
@synthesize black_time, black_move_time;
@synthesize red_seat;
@synthesize black_seat;
@synthesize _timer;
@synthesize _tableId;
@synthesize _initialTime, _redTime, _blackTime;

// -------- TEMP functions (to be reviewed and moved later ------------
- (NSString*) _allocStringFrom:(int)seconds
{
    return [[NSString alloc] initWithFormat:@"%d:%02d", (seconds / 60), (seconds % 60)];
}

/**
 * Reset the MOVE time to the initial value.
 * If the GAME time is already zero, then reset the FREE time as well.
 */
- (void) resetMoveTime:(int)color
{
    if ( color == NC_COLOR_RED ) {
        _redTime.moveTime = _initialTime.moveTime;
        if (_redTime.gameTime == 0) {
            _redTime.moveTime = _initialTime.freeTime;
        }
    }
    else {
        _blackTime.moveTime = _initialTime.moveTime;
        if (_blackTime.gameTime == 0) {
            _blackTime.moveTime = _initialTime.freeTime;
        }
    }
}
// --------------------

//
// The designated initializer.
// Override if you create the controller programmatically and want to perform
// customization that is not appropriate for viewDidLoad.
//
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    if (self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]) {
        _timer = nil;
        _audioHelper = [self _initSoundSystem];

        memset(_hl_moves, 0x0, sizeof(_hl_moves));
        _hl_nMoves = 0;
        _hl_lastMove = INVALID_MOVE;
        _selectedPiece = nil;

        _game = ((BoardView*)self.view).game;
        [_game retain];
        _moves = [[NSMutableArray alloc] initWithCapacity: POC_MAX_MOVES_PER_GAME];
        _nthMove = -1;
        _inReview = NO;
        _latestMove = INVALID_MOVE;

        self._tableId = nil;
        _myColor = NC_COLOR_UNKNOWN;
    }
    
    return self;
}

- (void)_ticked:(NSTimer*)timer
{
    // NOTE: On networked games, at least one Move made by EACH player before
    //       the timer is started. However, it is more user-friendly for
    //       this App (with AI only) to start the timer right after one Move
    //       is made (by RED).
    //
    if ( _game.game_result == kXiangQi_InPlay && [_moves count] > 0 ) {
        [self _updateTimer:[_game get_sdPlayer]];
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
    [activity setHidden:YES];
    [activity stopAnimating];
    [self.view bringSubviewToFront:activity];
    [self.view bringSubviewToFront:nav_toolbar];
    [self.view bringSubviewToFront:red_label];
    [self.view bringSubviewToFront:black_label];
    [self.view bringSubviewToFront:red_time];
    [self.view bringSubviewToFront:red_move_time];
    [self.view bringSubviewToFront:black_time];
    [self.view bringSubviewToFront:black_move_time];
    [self.view bringSubviewToFront:red_seat];
    [self.view bringSubviewToFront:black_seat];
    // TODO: _initialTime = [[NSUserDefaults standardUserDefaults] integerForKey:@"time_setting"];
    self._initialTime = [TimeInfo allocTimeFromString:@"900/180/20"];
    self._redTime = [[TimeInfo alloc] initWithTime:_initialTime];
    self._blackTime = [[TimeInfo alloc] initWithTime:_initialTime];
    [red_time setFont:[UIFont fontWithName:@"DBLCDTempBlack" size:13.0]];
    [red_move_time setFont:[UIFont fontWithName:@"DBLCDTempBlack" size:13.0]];
    red_time.text = [self _allocStringFrom:_redTime.gameTime];
    red_move_time.text = [self _allocStringFrom:_redTime.moveTime];

    [black_time setFont:[UIFont fontWithName:@"DBLCDTempBlack" size:13.0]];
    [black_move_time setFont:[UIFont fontWithName:@"DBLCDTempBlack" size:13.0]];
    black_time.text = [self _allocStringFrom:_blackTime.gameTime];
    black_move_time.text = [self _allocStringFrom:_blackTime.moveTime];

    red_label.text = @"";
    black_label.text = @"";

    self._timer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(_ticked:) userInfo:nil repeats:YES];
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
    [red_label release];
    [black_label release];
    [red_time release];
    [red_move_time release];
    [black_time release];
    [black_move_time release];
    [activity release];
    [red_seat release];
    [black_seat release];
    [_timer release];
    [_audioHelper release];
    [_game release];
    [_moves release];
    [_tableId release];
    [_initialTime release];
    [_redTime release];
    [_blackTime release];

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
    [self showHighlightOfMove:prevMove];
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
        [self showHighlightOfMove:move];
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
            [self handleNewMove:moveInfo];
        }
    }
}

- (IBAction)actionPressed:(id)sender
{
    NSLog(@"%s: ENTER.", __FUNCTION__);
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    if ( [[event allTouches] count] != 1 // Valid for single touch only
        ||  _inReview    // Do nothing if we are in the middle of Move-Review.
        || ![self isMyTurnNext] // Ignore when it is not my turn.
        || ![self isGameReady] )
    { 
        return;
    }

    BoardView *view = (BoardView*) self.view;
    GridCell *holder = nil;
    
    UITouch *touch = [[touches allObjects] objectAtIndex:0];
    CGPoint p = [touch locationInView:self.view];
    Piece *piece = (Piece*)[view hitTestPoint:p LayerMatchCallback:layerIsBit offset:NULL];
    if(piece) {
        // Generate moves for the selected piece.
        holder = (GridCell*)piece.holder;
        if(!_selectedPiece || (_selectedPiece._owner == piece._owner)) {
            //*******************
            int row = holder._row;
            int col = holder._column;
            if (!_game.blackAtTopSide) {
                row = 9 - row;
                col = 8 - col;
            }
            //*******************
            int sqSrc = TOSQUARE(row, col);
            [self setHighlightCells:NO]; // Clear old highlight.
            
            _hl_nMoves = [_game generateMoveFrom:sqSrc moves:_hl_moves];
            [self setHighlightCells:YES];
            _selectedPiece = piece;
            [_audioHelper play_wav_sound:@"CLICK"];
            return;
        }
    } else {
        holder = (GridCell*)[view hitTestPoint:p LayerMatchCallback:layerIsBitHolder offset:NULL];
    }
    
    // Make a Move from the last selected cell to the current selected cell.
    if(holder && holder._highlighted && _selectedPiece != nil && _hl_nMoves > 0) {
        [self setHighlightCells:NO]; // Clear highlighted.

        GridCell *cell = (GridCell*)_selectedPiece.holder;
        //*******************
        int row1 = cell._row;
        int col1 = cell._column;
        int row2 = holder._row;
        int col2 = holder._column;
        if (!_game.blackAtTopSide) {
            row1 = 9 - row1;
            col1 = 8 - col1;
            row2 = 9 - row2;
            col2 = 8 - col2;
        }
        //*******************
        int sqSrc = TOSQUARE(row1, col1);
        int sqDst = TOSQUARE(row2, col2);
        int move = MOVE(sqSrc, sqDst);
        if([_game isLegalMove:move])
        {
            [_game humanMove:row1 fromCol:col1 toRow:row2 toCol:col2];
            
            NSNumber *moveInfo = [NSNumber numberWithInteger:move];
            [self handleNewMove:moveInfo];

            [self onLocalMoveMade:move];
        }
    } else {
        [self setHighlightCells:NO];  // Clear highlighted.
    }

    _selectedPiece = nil;  // Reset selected state.
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
    red_label.text = label;
}

- (void) setBlackLabel:(NSString*)label
{
    black_label.text = label;
}

- (void) setInitialTime:(NSString*)times
{
    self._initialTime = [TimeInfo allocTimeFromString:times];
}

- (void) setRedTime:(NSString*)times
{
    self._redTime = [TimeInfo allocTimeFromString:times];
    red_time.text = [self _allocStringFrom:_redTime.gameTime];
    red_move_time.text = [self _allocStringFrom:_redTime.moveTime];
}

- (void) setBlackTime:(NSString*)times
{
    self._blackTime = [TimeInfo allocTimeFromString:times];
    black_time.text = [self _allocStringFrom:_blackTime.gameTime];
    black_move_time.text = [self _allocStringFrom:_blackTime.moveTime];
}

///////////////////////////////////////////////////////////////////////////////
//
//    Implementation of Private methods
//
///////////////////////////////////////////////////////////////////////////////

#pragma mark -
#pragma mark Private methods

- (id) _initSoundSystem
{
    AudioHelper* audioHelper = [[AudioHelper alloc] init];
    
    if ( audioHelper != nil ) {
        NSArray *soundList = [NSArray arrayWithObjects:@"CAPTURE", @"CAPTURE2", @"CLICK",
                              @"DRAW", @"LOSS", @"CHECK", @"CHECK2",
                              @"MOVE", @"MOVE2", @"WIN", @"ILLEGAL",
                              nil];
        for (NSString *sound in soundList) {
            [audioHelper load_wav_sound:sound];
        }
    }
    return audioHelper;
}

- (void) _updateTimer:(int)color
{
    if ( color == 1 ) {
        black_time.text = [self _allocStringFrom:_blackTime.gameTime--];
        black_move_time.text = [self _allocStringFrom:_blackTime.moveTime--];
    } else {
        red_time.text = [self _allocStringFrom:_redTime.gameTime--];
        red_move_time.text = [self _allocStringFrom:_redTime.moveTime--];
    }
}

- (void) setHighlightCells:(BOOL)bHighlight
{
    // Set (or Clear) highlighted cells.
    for(int i = 0; i < _hl_nMoves; ++i) {
        int sqDst = DST(_hl_moves[i]);
        int row = ROW(sqDst);
        int col = COLUMN(sqDst);
        if ( ! bHighlight ) {
            _hl_moves[i] = 0;
        }
        [_game x_getCellAtRow:row col:col]._highlighted = bHighlight;
    }

    if ( ! bHighlight ) {
        _hl_nMoves = 0;
    }
}

- (void) showHighlightOfMove:(int)move
{
    if (_hl_lastMove != INVALID_MOVE) {
        _hl_nMoves = 1;
        _hl_moves[0] = _hl_lastMove;
        [self setHighlightCells:NO];
        _hl_lastMove = INVALID_MOVE;
    }
    
    if (move != INVALID_MOVE) {
        int sqDst = DST(move);
        [_game x_getCellAtRow:ROW(sqDst) col:COLUMN(sqDst)]._highlighted = YES;
        _hl_lastMove = move;
    }
}

- (void) handleNewMove:(NSNumber *)moveInfo
{
    int  move     = [moveInfo integerValue];
    BOOL isAI     = ([_game get_sdPlayer] == 0);  // AI just made this Move.

    [self resetMoveTime:(isAI ? NC_COLOR_BLACK : NC_COLOR_RED)];
    
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
    [self showHighlightOfMove:move];

    // Check End-Game status.
    int nGameResult = [_game checkGameStatus:isAI];
    if ( nGameResult != kXiangQi_Unknown ) {  // Game Result changed?
        [self handleEndGameInUI];
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
    if (self._timer) [self._timer invalidate];
    self._timer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(_ticked:) userInfo:nil repeats:YES];
}

- (void) resetBoard
{
    [self setHighlightCells:NO];
    _selectedPiece = nil;
    [self showHighlightOfMove:INVALID_MOVE];  // Clear the last highlight.
    self._redTime = [[TimeInfo alloc] initWithTime:_initialTime];
    self._blackTime = [[TimeInfo alloc] initWithTime:_initialTime];
    memset(_hl_moves, 0x0, sizeof(_hl_moves));
    red_time.text = [self _allocStringFrom:_redTime.gameTime];
    red_move_time.text = [self _allocStringFrom:_redTime.moveTime];
    black_time.text = [self _allocStringFrom:_blackTime.gameTime];
    black_move_time.text = [self _allocStringFrom:_blackTime.moveTime];

    [_game reset_game];
    [_moves removeAllObjects];
    _nthMove = -1;
    _inReview = NO;
    _latestMove = INVALID_MOVE;
}

- (void) displayEmptyBoard
{
    [self resetBoard];
    [self setRedLabel:@""];
    [self setBlackLabel:@""];
    if (!_game.blackAtTopSide )
    {
        [self reverseBoardView];
    }
}

- (BOOL) isMyTurnNext
{
    const ColorEnum nextColor = ([_game get_sdPlayer] ? NC_COLOR_BLACK : NC_COLOR_RED); 
    return (nextColor == _myColor);
}

- (BOOL) isGameReady
{
    return YES;
}

- (void) reverseBoardView
{
    [_game reverseView];
    CGRect redRect = red_label.frame;
    red_label.frame = black_label.frame;
    black_label.frame = redRect;
    redRect = red_time.frame;
    red_time.frame = black_time.frame;
    black_time.frame = redRect;
    redRect = red_move_time.frame;
    red_move_time.frame = black_move_time.frame;
    black_move_time.frame = redRect;
}

@end