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
#import "ChessBoardView.h"
#import "TableListViewController.h"  // TODO: To get TimeInfo, TableInfo, ...

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
@synthesize red_time;
@synthesize black_time;
@synthesize red_seat;
@synthesize black_seat;
@synthesize _timer;
@synthesize _tableId;

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

        _game = (CChessGame*)((ChessBoardView*)self.view).game;
        [_game retain];
        _moves = [[NSMutableArray alloc] initWithCapacity: POC_MAX_MOVES_PER_GAME];
        _nthMove = -1;
        _inReview = NO;
        _latestMove = INVALID_MOVE;

        _tableId = nil;
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
    [self.view bringSubviewToFront:black_time];
    [self.view bringSubviewToFront:red_seat];
    [self.view bringSubviewToFront:black_seat];
    _initialTime = [[NSUserDefaults standardUserDefaults] integerForKey:@"time_setting"];
    _redTime = _blackTime = _initialTime * 60;
    [red_time setFont:[UIFont fontWithName:@"DBLCDTempBlack" size:13.0]];
    red_time.text = [NSString stringWithFormat:@"%d:%02d", (_redTime / 60), (_redTime % 60)];

    [black_time setFont:[UIFont fontWithName:@"DBLCDTempBlack" size:13.0]];
    black_time.text = [NSString stringWithFormat:@"%d:%02d", (_blackTime / 60), (_blackTime % 60)];

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
    [black_time release];
    [activity release];
    [red_seat release];
    [black_seat release];
    [_timer release];
    [_audioHelper release];
    [_game release];
    [_moves release];

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

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    if ( [[event allTouches] count] != 1 // Valid for single touch only
        ||  _inReview    // Do nothing if we are in the middle of Move-Review.
        || ![self isMyTurnNext] // Ignore when it is not my turn.
        || ![self isGameReady] )
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

- (void) setRedTime:(NSString*)times
{
    TimeInfo* timeInfo = [TimeInfo allocTimeFromString:times];
    _redTime = timeInfo.gameTime;
    [timeInfo release];
    red_time.text = [NSString stringWithFormat:@"%d:%02d", (_redTime / 60), (_redTime % 60)];
}

- (void) setBlackTime:(NSString*)times
{
    TimeInfo* timeInfo = [TimeInfo allocTimeFromString:times];
    _blackTime = timeInfo.gameTime;
    [timeInfo release];
    black_time.text = [NSString stringWithFormat:@"%d:%02d", (_blackTime / 60), (_blackTime % 60)];
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
        --_blackTime;
        int min = _blackTime / 60;
        int sec = _blackTime % 60;
        black_time.text = [NSString stringWithFormat:@"%d:%02d", min, sec];
    } else {
        --_redTime;
        int min = _redTime / 60;
        int sec = _redTime % 60;
        red_time.text = [NSString stringWithFormat:@"%d:%02d", min, sec];
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
    NSString *sound = nil;
    NSString *msg   = nil;
    
    sound = @"WIN";
    msg = NSLocalizedString(@"Game Over", @"");
    
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
    _redTime = _blackTime = _initialTime * 60;
    memset(_hl_moves, 0x0, sizeof(_hl_moves));
    red_time.text = [NSString stringWithFormat:@"%d:%02d", (_redTime / 60), (_redTime % 60)];
    black_time.text = [NSString stringWithFormat:@"%d:%02d", (_blackTime / 60), (_blackTime % 60)];
    
    [_game reset_game];
    [_moves removeAllObjects];
    _nthMove = -1;
    _inReview = NO;
    _latestMove = INVALID_MOVE;
}

- (void) setMyColor:(ColorEnum)color
{
    _myColor = color;
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
}

@end
