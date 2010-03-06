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
#import "QuartzUtils.h"
#import "Grid.h"
#import "Piece.h"
#import "Types.h"

enum HistoryIndex // NOTE: Do not change the constants 'values below.
{
    HISTORY_INDEX_END   = -2,
    HISTORY_INDEX_BEGIN = -1
};

// The threshold (in seconds) to "go-BEGIN" or "go-END".
#define REVIEW_BEGIN_END_THRESHOLD 0.7

///////////////////////////////////////////////////////////////////////////////
//
//    BoardViewController
//
///////////////////////////////////////////////////////////////////////////////

//
// Private methods (BoardViewController)
//
@interface BoardViewController (PrivateMethods)
- (CGRect) _gameBoardFrame;
- (id) _initSoundSystem:(NSString*)soundPath;
- (void) _setHighlightCells:(BOOL)bHighlight;
- (void) _animateLatestPiece:(Piece*)piece;
- (void) _clearAllHighlight;
- (void) _setReviewMode:(BOOL)on;
- (void) _ticked:(NSTimer*)timer;
- (void) _updateTimer;
- (NSString*) _allocStringFrom:(int)seconds;
@end

@implementation BoardViewController

@synthesize game=_game;
@synthesize boardOwner=_boardOwner;
@synthesize _timer, _reviewLastTouched;
@synthesize _reviewLastTouched_prev, _reviewLastTouched_next;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    NSLog(@"%s: ENTER.", __FUNCTION__);
    if (self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil])
    {
        _gameboard = [[CALayer alloc] init];
        _gameboard.frame = [self _gameBoardFrame];
        [self.view.layer insertSublayer:_gameboard atIndex:0]; // ... in the back.

        int boardType = [[NSUserDefaults standardUserDefaults] integerForKey:@"board_type"];
        _game = [[CChessGame alloc] initWithBoard:_gameboard boardType:boardType];

        _audioHelper = ( [[NSUserDefaults standardUserDefaults] boolForKey:@"sound_on"]
                        ? [self _initSoundSystem:NC_SOUND_PATH]
                        : nil );    
        _boardOwner = nil;

        _initialTime = [TimeInfo allocTimeFromString:@"1500/240/30"];
        _redTime = [[TimeInfo alloc] initWithTime:_initialTime];
        _blackTime = [[TimeInfo alloc] initWithTime:_initialTime];
        _red_time.font = [UIFont fontWithName:@"DBLCDTempBlack" size:13.0];
        _red_move_time.font = [UIFont fontWithName:@"DBLCDTempBlack" size:13.0];
        _red_time.text = [self _allocStringFrom:_redTime.gameTime];
        _red_move_time.text = [self _allocStringFrom:_redTime.moveTime];
        
        _black_time.font = [UIFont fontWithName:@"DBLCDTempBlack" size:13.0];
        _black_move_time.font = [UIFont fontWithName:@"DBLCDTempBlack" size:13.0];
        _black_time.text = [self _allocStringFrom:_blackTime.gameTime];
        _black_move_time.text = [self _allocStringFrom:_blackTime.moveTime];

        _red_label.text = @"";
        _black_label.text = @"";
        _game_over_msg.hidden = YES;
        _gameOver = NO;

        _moves = [[NSMutableArray alloc] initWithCapacity:NC_MAX_MOVES_PER_GAME];
        _nthMove = HISTORY_INDEX_END;
        _hl_nMoves = 0;

        _animatedPiece = nil;
        _pickedUpPiece = nil;

        self._reviewLastTouched = [[NSDate date] addTimeInterval:-60]; // 1-minute earlier.
        self._reviewLastTouched_prev = nil;
        self._reviewLastTouched_next = nil;
        self._timer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(_ticked:) userInfo:nil repeats:YES];
    }

    return self;
}

- (void)dealloc
{
    //NSLog(@"%s: ENTER.", __FUNCTION__);
    [_boardOwner release];
    [_timer release];
    [_moves release];
    [_reviewLastTouched release];
    [_reviewLastTouched_prev release];
    [_reviewLastTouched_next release];
    [_audioHelper release];
    [_game release];
    [_gameboard removeFromSuperlayer];
    [_gameboard release];
    [super dealloc];
}

- (CGRect) _gameBoardFrame
{
    CGRect bounds = self.view.layer.bounds;
/*
    bounds.origin.x += 2;
    bounds.origin.y += 2;
    bounds.size.width -= 4;
    bounds.size.height -= 24;
    self.layer.bounds = bounds;
*/
    return bounds;
}

- (id) _initSoundSystem:(NSString*)soundPath
{
    AudioHelper* audioHelper = [[AudioHelper alloc] initWithPath:soundPath];

    NSArray *soundList = [NSArray arrayWithObjects:@"CAPTURE", @"CAPTURE2", @"CLICK",
                          @"DRAW", @"LOSS", @"CHECK", @"CHECK2",
                          @"MOVE", @"MOVE2", @"WIN", @"ILLEGAL", @"PROMOTE",
                          @"Review", nil];
    for (NSString* sound in soundList) {
        [audioHelper loadSound:sound];
    }
    return audioHelper;
}


#pragma mark -
#pragma mark HIT-TESTING:


// Locates the layer at a given point in window coords.
//    If the leaf layer doesn't pass the layer-match callback, the nearest ancestor that does is returned.
//    If outOffset is provided, the point's position relative to the layer is stored into it.
- (CALayer*) hitTestPoint:(CGPoint)locationInWindow
       LayerMatchCallback:(LayerMatchCallback)match offset:(CGPoint*)outOffset
{
    CGPoint where = locationInWindow;
    where = [_gameboard convertPoint: where fromLayer:self.view.layer];
    CALayer *layer = [_gameboard hitTest:where];
    while ( layer ) {
        if ( match(layer) ) {
            CGPoint bitPos = [self.view.layer convertPoint:layer.position
                                                 fromLayer:layer.superlayer];
            if ( outOffset ) {
                *outOffset = CGPointMake( bitPos.x-where.x, bitPos.y-where.y);
            }
            return layer;
        } else {
            layer = layer.superlayer;
        }
    }
    return nil;
}

- (void) setRedLabel:(NSString*)label  { _red_label.text = label; }
- (void) setBlackLabel:(NSString*)label { _black_label.text = label; }

- (void) setInitialTime:(NSString*)times
{
    [_initialTime release];
    _initialTime = [TimeInfo allocTimeFromString:times];
}

- (void) setRedTime:(NSString*)times
{
    [_redTime release];
    _redTime = [TimeInfo allocTimeFromString:times];
    _red_time.text = [self _allocStringFrom:_redTime.gameTime];
    _red_move_time.text = [self _allocStringFrom:_redTime.moveTime];
}

- (void) setBlackTime:(NSString*)times
{
    [_blackTime release];
    _blackTime = [TimeInfo allocTimeFromString:times];
    _black_time.text = [self _allocStringFrom:_blackTime.gameTime];
    _black_move_time.text = [self _allocStringFrom:_blackTime.moveTime];
}

- (BOOL) _isInReview
{
    return (_nthMove != HISTORY_INDEX_END);
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

- (void) _setHighlightCells:(BOOL)bHighlight
{
    for (int i = 0; i < _hl_nMoves; ++i) {
        [_game highlightCell:DST(_hl_moves[i]) highlight:bHighlight];
    }

    if ( ! bHighlight ) {
        _hl_nMoves = 0;
    }
}

- (void) _animateLatestPiece:(Piece*)piece
{
    if (_animatedPiece) {
        _animatedPiece.animated = NO;
        _animatedPiece = nil;
    }

    if (piece) {
        _animatedPiece = piece;
        _animatedPiece.animated = YES;
    }
}

- (void) _clearAllHighlight
{
    [self _setHighlightCells:NO];
    [self _animateLatestPiece:nil];
    _pickedUpPiece.pickedUp = NO;
    _pickedUpPiece = nil;
}

- (NSString*) _allocStringFrom:(int)seconds
{
    return [[NSString alloc] initWithFormat:@"%d:%02d", (seconds / 60), (seconds % 60)];
}

- (void) onNewMoveFrom:(Position)from toPosition:(Position)to
           inSetupMode:(BOOL)bSetup
{
    int sqSrc = TOSQUARE(from.row, from.col);
    int sqDst = TOSQUARE(to.row, to.col);
    int move = MOVE(sqSrc, sqDst);

    ColorEnum moveColor = (_game.nextColor == NC_COLOR_RED ? NC_COLOR_BLACK : NC_COLOR_RED);

    if (!bSetup) {
        [self resetMoveTime:moveColor];
    }

    MoveAtom* pMove = [[[MoveAtom alloc] initWithMove:move] autorelease];
    [_moves addObject:pMove];

    // Delay update the UI if in Review mode.
    if ([self _isInReview]) {
        // NOTE: We do not update pMove.srcPiece (leaving it equal to nil)
        //       to signal that it is NOT yet processed.
        return;
    }

    Piece* piece = [_game getPieceAtRow:from.row col:from.col];
    Piece* capture = [_game getPieceAtRow:to.row col:to.col];

    [_game movePiece:piece toPosition:to animated:(bSetup ? NO : YES)];
    if (!bSetup) {
        _animatedPiece.animated = NO;
        _animatedPiece = piece;

        NSString* sound = ( capture ? (moveColor == NC_COLOR_RED ? @"CAPTURE" : @"CAPTURE2")
                                    : (moveColor == NC_COLOR_RED ? @"MOVE" : @"MOVE2") );
        [_audioHelper playSound:sound];
    }

    if (capture) {
        [capture destroyWithAnimation:(bSetup ? NO : YES)];
    }

    // Add this new Move to the Move-History.
    pMove.srcPiece = piece;
    pMove.capturedPiece = capture;
}

- (void) onGameOver
{
    _game_over_msg.text = NSLocalizedString(@"Game Over", @"");
    _game_over_msg.alpha = 1.0;
    _game_over_msg.hidden = NO;
    _gameOver = YES;
}

- (void) _setReviewMode:(BOOL)on
{
    if (_game.gameResult != NC_GAME_STATUS_IN_PROGRESS) {
        return;  // Do nothing if Game Over.
    }

    if (on && _game_over_msg.hidden) {
        _game_over_msg.text = NSLocalizedString(@"Review Mode", @"");
        _game_over_msg.alpha = 0.5;
        _game_over_msg.hidden = NO;
    } else if (!on) {
        _game_over_msg.hidden = YES;
    }
}

- (void) _updateTimer
{
    if (_game.nextColor == NC_COLOR_BLACK) {
        _black_time.text = [self _allocStringFrom:_blackTime.gameTime];
        _black_move_time.text = [self _allocStringFrom:_blackTime.moveTime];
        [_blackTime decrement];
    } else {
        _red_time.text = [self _allocStringFrom:_redTime.gameTime];
        _red_move_time.text = [self _allocStringFrom:_redTime.moveTime];
        [_redTime decrement];
    }
}

- (void) _ticked:(NSTimer*)timer
{
    NSTimeInterval timeInterval = - [_reviewLastTouched timeIntervalSinceNow]; // in seconds.
    if (![self _isInReview] && timeInterval > 5) { // hide if older than 5 seconds?
        _review_prev.hidden = YES;
        _review_next.hidden = YES;
    }
    
    // NOTE: On networked games, at least one Move made by EACH player before
    //       the timer is started. However, it is more user-friendly for
    //       this App (with AI only) to start the timer right after one Move
    //       is made (by RED).
    //
    if (!_gameOver && [_moves count] > 0) {
        [self _updateTimer];
    }
}

- (void) rescheduleTimer
{
    if (_timer) [_timer invalidate];
    self._timer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(_ticked:) userInfo:nil repeats:YES];
}

- (void) destroyTimer
{
    if (_timer) [_timer invalidate];
    self._timer = nil;
}

- (void) playSound:(NSString*)sound
{
    [_audioHelper playSound:sound];
}

- (NSMutableArray*) getMoves
{
    return _moves;
}

#pragma mark -
#pragma mark UI-Event Handlers:

- (BOOL) _doPreviewPREV
{
    if (    [_moves count] == 0              // No Moves made yet?
        || _nthMove == HISTORY_INDEX_BEGIN ) // ... or already at BEGIN mark?
    {
        return NO;
    }

    if (_nthMove == HISTORY_INDEX_END ) { // at the END mark?
        _nthMove = [_moves count] - 1; // Get the latest move.
    }
    
    MoveAtom* pMove = [_moves objectAtIndex:_nthMove];
    int move = pMove.move;
    int sqSrc = SRC(move);
    int sqDst = DST(move);
    [_audioHelper playSound:@"Review"];
    
    // For Move-Review, just reverse the move order (sqDst->sqSrc)
    // Since it's only a review, no need to make actual move in
    // the underlying game logic.

    [self _animateLatestPiece:nil];
    [_game movePiece:pMove.srcPiece toRow:ROW(sqSrc) toCol:COLUMN(sqSrc)];

    if (pMove.capturedPiece) {
        [_game movePiece:pMove.capturedPiece toRow:ROW(sqDst) toCol:COLUMN(sqDst)];
    }
    
    // Highlight the Piece (if any) of the "next-PREV" Move.
    --_nthMove;
    if (_nthMove >= 0) {
        pMove = [_moves objectAtIndex:_nthMove];
        Piece* prevPiece = [_game getPieceAtCell:DST(pMove.move)];
        [self _animateLatestPiece:prevPiece];
    }
    return YES;
}

- (BOOL) _doPreviewBEGIN
{
    while ([self _doPreviewPREV]) { /* keep going */}
    return YES;
}

- (IBAction) reviewPrevious_DOWN:(id)sender
{
    self._reviewLastTouched_prev = [NSDate date];
}

- (IBAction) reviewPrevious_UP:(id)sender
{
    self._reviewLastTouched = [NSDate date];
    if (![self _isInReview]) {
        //NSLog(@"%s: Clear old highlight.", __FUNCTION__);
        [self _clearAllHighlight];
    }

    NSTimeInterval timeInterval = - [_reviewLastTouched_prev timeIntervalSinceNow]; // in seconds.
    if (timeInterval > REVIEW_BEGIN_END_THRESHOLD) {
        [self _doPreviewBEGIN];
    } else {
        [self _doPreviewPREV];
    }

    [self _setReviewMode:[self _isInReview]];
}

- (BOOL) _doPreviewNEXT
{
    if (    [_moves count] == 0             // No Moves made yet?
         || _nthMove == HISTORY_INDEX_END ) // ... or at the END mark?
    {
        return NO;
    }

    ++_nthMove;
    NSAssert1(_nthMove >= 0 && _nthMove < [_moves count], @"Invalid index [%d]", _nthMove);
    
    const MoveAtom* pMove = [_moves objectAtIndex:_nthMove];
    
    if (_nthMove == [_moves count] - 1) {
        _nthMove = HISTORY_INDEX_END;
    }
    
    int move = pMove.move;
    int sqDst = DST(move);
    [_audioHelper playSound:@"Review"];
    Piece *capture = [_game getPieceAtCell:DST(move)];
    if (capture) {
        [capture destroyWithAnimation:NO];
    }
    if (!pMove.srcPiece) { // not yet processed?
        NSLog(@"%s: Process pending move [%@]...", __FUNCTION__, pMove);
        pMove.srcPiece = [_game getPieceAtCell:SRC(move)];
        NSAssert(pMove.srcPiece, @"The SRC piece should be found.");
        pMove.capturedPiece = capture;
    }
    [_game movePiece:pMove.srcPiece toRow:ROW(sqDst) toCol:COLUMN(sqDst)];
    [self _animateLatestPiece:pMove.srcPiece];
    return YES;
}

- (BOOL) _doPreviewEND
{
    while ([self _doPreviewNEXT]) { /* keep going */}
    return YES;
}

- (IBAction) reviewNext_DOWN:(id)sender
{
    self._reviewLastTouched_next = [NSDate date];
}

- (IBAction) reviewNext_UP:(id)sender
{
    self._reviewLastTouched = [NSDate date];

    NSTimeInterval timeInterval = - [_reviewLastTouched_next timeIntervalSinceNow]; // in seconds.
    if (timeInterval > REVIEW_BEGIN_END_THRESHOLD) {
        [self _doPreviewEND];
    } else {
        [self _doPreviewNEXT];
    }

    [self _setReviewMode:[self _isInReview]];
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    if ( [[event allTouches] count] != 1 ) { // Valid for single touch only
        return;
    }
    
    UITouch* touch = [[touches allObjects] objectAtIndex:0];
    CGPoint p = [touch locationInView:self.view];
    //NSLog(@"%s: p = [%f, %f].", __FUNCTION__, p.x, p.y);    

    Piece* piece = (Piece*)[self hitTestPoint:p LayerMatchCallback:layerIsPiece offset:NULL];

     if (!piece && p.y > 382) // ... near the y-coordinate of Review buttons.
     {
         _review_prev.hidden = NO;
         _review_next.hidden = NO;
         self._reviewLastTouched = [NSDate date]; // now.
     }
    
    if (    [self _isInReview]   // Do nothing if in the middle of Move-Review.
        ||  _game.gameResult != NC_GAME_STATUS_IN_PROGRESS
        || ![_boardOwner isMyTurnNext] // Ignore when it is not my turn.
        || ![_boardOwner isGameReady] )
    { 
        return;
    }
    
    GridCell* holder = nil;
    
    if (piece) {
        holder = piece.holder;
        if (   (!_pickedUpPiece && piece.color == _game.nextColor) 
            || (_pickedUpPiece && piece.color == _pickedUpPiece.color) )
        {
            Position from = [_game getActualPositionAtCell:holder];
            [self _setHighlightCells:NO];
            _hl_nMoves = [_game generateMoveFrom:from moves:_hl_moves];
            [self _setHighlightCells:YES];
            _pickedUpPiece.pickedUp = NO;
            _pickedUpPiece = piece;
            _pickedUpPiece.pickedUp = YES;
            [_audioHelper playSound:@"CLICK"];
            return;
        }
    } else {
        holder = (GridCell*)[self hitTestPoint:p LayerMatchCallback:layerIsGridCell offset:NULL];
    }
    
    // Make a Move from the last selected cell to the current selected cell.
    _pickedUpPiece.pickedUp = NO;
    if (holder && holder.highlighted && _pickedUpPiece)
    {
        GridCell* fromCell = _pickedUpPiece.holder;
        Position from = [_game getActualPositionAtCell:fromCell];
        Position to = [_game getActualPositionAtCell:holder];
        if ([_game isMoveLegalFrom:from toPosition:to])
        {
            [_game doMoveFrom:from toPosition:to];
            [self onNewMoveFrom:from toPosition:to inSetupMode:NO];
            [_boardOwner onLocalMoveMadeFrom:from toPosition:to];
        }
        else {
            [_audioHelper playSound:@"ILLEGAL"];
        }

    }

    [self _setHighlightCells:NO];
    _pickedUpPiece = nil;
}

- (void) resetBoard
{
    [self _clearAllHighlight];

    [_redTime release];
    _redTime = [[TimeInfo alloc] initWithTime:_initialTime];
    [_blackTime release];
    _blackTime = [[TimeInfo alloc] initWithTime:_initialTime];
    _red_time.text = [self _allocStringFrom:_redTime.gameTime];
    _red_move_time.text = [self _allocStringFrom:_redTime.moveTime];
    _black_time.text = [self _allocStringFrom:_blackTime.gameTime];
    _black_move_time.text = [self _allocStringFrom:_blackTime.moveTime];

    _game_over_msg.hidden = YES;
    _gameOver = NO;

    [_game resetGame];
    [_moves removeAllObjects];
    _nthMove = HISTORY_INDEX_END;
}

- (void) reverseBoardView
{
    [_game reverseView];
    CGRect redRect = _red_label.frame;
    _red_label.frame = _black_label.frame;
    _black_label.frame = redRect;
    redRect = _red_time.frame;
    _red_time.frame = _black_time.frame;
    _black_time.frame = redRect;
    redRect = _red_move_time.frame;
    _red_move_time.frame = _black_move_time.frame;
    _black_move_time.frame = redRect;
}

- (void) reverseRole
{
    [self reverseBoardView];
    NSString* redText = _red_label.text;
    _red_label.text = _black_label.text;
    _black_label.text = redText;
}

@end
