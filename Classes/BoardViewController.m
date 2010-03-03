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
- (void) _showHighlightOfMove:(int)move;
- (void) _clearAllHighlight;
- (void) _setReviewMode:(BOOL)on;
- (void) _ticked:(NSTimer*)timer;
- (void) _updateTimer;
- (NSString*) _allocStringFrom:(int)seconds;
@end

@implementation BoardViewController

@synthesize game=_game;
@synthesize boardOwner=_boardOwner;
@synthesize _timer, _previewLastTouched;
@synthesize _previewLastTouched_prev, _previewLastTouched_next;

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

        _moves = [[NSMutableArray alloc] initWithCapacity:NC_MAX_MOVES_PER_GAME];
        _nthMove = HISTORY_INDEX_END;

        _hl_nMoves = 0;
        _hl_lastMove = INVALID_MOVE;
        _selectedPiece = nil;

        self._previewLastTouched = [[NSDate date] addTimeInterval:-60]; // 1-minute earlier.
        self._previewLastTouched_prev = nil;
        self._previewLastTouched_next = nil;
        self._timer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(_ticked:) userInfo:nil repeats:YES];
    }

    return self;
}

- (void)dealloc
{
    NSLog(@"%s: ENTER.", __FUNCTION__);
    [_gameboard removeFromSuperlayer];
    [_gameboard release];
    [_game release];
    [_boardOwner release];
    [_timer release];
    [_moves release];
    [_previewLastTouched release];
    [_previewLastTouched_prev release];
    [_previewLastTouched_next release];
    [_audioHelper release];
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
                          @"MOVE", @"MOVE2", @"WIN", @"ILLEGAL",
                          nil];
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

- (void) _showHighlightOfMove:(int)move
{
    if (_hl_lastMove != INVALID_MOVE) {
        GridCell* lastCell = [_game getCellAt:DST(_hl_lastMove)];
        [lastCell removeAnimationForKey:@"animateBounds"];
        lastCell._animated = NO;
        _hl_lastMove = INVALID_MOVE;
    }

    if (move != INVALID_MOVE) {
        _hl_lastMove = move;
        GridCell* currentCell = [_game getCellAt:DST(move)];
        CGFloat ds = 5.0;
        CGRect oriBounds = currentCell.bounds;
        CGRect ubounds = oriBounds;
        ubounds.size.width += ds*2;
        ubounds.size.height += ds*2;

        // 'bounds' animation
        CABasicAnimation* boundsAnimation = [CABasicAnimation animationWithKeyPath:@"bounds"];
        boundsAnimation.duration=1.0;
        boundsAnimation.repeatCount=1000;
        boundsAnimation.autoreverses=YES;
        boundsAnimation.fromValue=[NSValue valueWithCGRect:oriBounds];
        boundsAnimation.toValue=[NSValue valueWithCGRect:ubounds];

        [currentCell addAnimation:boundsAnimation forKey:@"animateBounds"];
        currentCell._animated = YES;
        currentCell.bounds = oriBounds;  // Restore!!!
    }
}

- (void) _clearAllHighlight
{
    [self _setHighlightCells:NO];
    [self _showHighlightOfMove:INVALID_MOVE];  // Clear the last highlight.
    _selectedPiece.highlighted = NO;
    _selectedPiece = nil;
}

- (NSString*) _allocStringFrom:(int)seconds
{
    return [[NSString alloc] initWithFormat:@"%d:%02d", (seconds / 60), (seconds % 60)];
}

- (void) onNewMove:(int)move inSetupMode:(BOOL)bSetup
{
    ColorEnum moveColor = ([_game getNextColor] == NC_COLOR_RED ? NC_COLOR_BLACK : NC_COLOR_RED);

    if (!bSetup) {
        [self resetMoveTime:moveColor];
    }

    MoveAtom* pMove = [[[MoveAtom alloc] initWithMove:move] autorelease];
    [_moves addObject:pMove];

    // Delay update the UI if in Preview mode.
    if ([self _isInReview]) {
        // NOTE: We do not update pMove.srcPiece (leaving it equal to nil)
        //       to signal that it is NOT yet processed.
        return;
    }

    int sqSrc = SRC(move);
    int sqDst = DST(move);
    int row1 = ROW(sqSrc);
    int col1 = COLUMN(sqSrc);
    int row2 = ROW(sqDst);
    int col2 = COLUMN(sqDst);

    NSString* sound = @"MOVE";

    Piece* capture = [_game getPieceAtRow:row2 col:col2];
    Piece* piece = [_game getPieceAtRow:row1 col:col1];

    if (capture) {
        [capture destroyWithAnimation:(bSetup ? NO : YES)];
        sound = (moveColor == NC_COLOR_RED ? @"CAPTURE" : @"CAPTURE2" );
    }

    [_audioHelper playSound:sound];

    [_game movePiece:piece toRow:row2 toCol:col2];
    [self _showHighlightOfMove:move];

    // Add this new Move to the Move-History.
    pMove.srcPiece = piece;
    pMove.capturedPiece = capture;
}

- (void) onGameOver
{
    _game_over_msg.text = NSLocalizedString(@"Game Over", @"");
    _game_over_msg.alpha = 1.0;
    _game_over_msg.hidden = NO;
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
    if ([_game getNextColor] == NC_COLOR_BLACK) {
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
    NSTimeInterval timeInterval = - [_previewLastTouched timeIntervalSinceNow]; // in seconds.
    if (![self _isInReview] && timeInterval > 5) { // hide if older than 5 seconds?
        _preview_prev.hidden = YES;
        _preview_next.hidden = YES;
    }
    
    // NOTE: On networked games, at least one Move made by EACH player before
    //       the timer is started. However, it is more user-friendly for
    //       this App (with AI only) to start the timer right after one Move
    //       is made (by RED).
    //
    if (_game_over_msg.hidden == YES && [_moves count] > 0) {
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

- (BOOL) _doPreviewPREV
{    
    if ([_moves count] == 0) {
        NSLog(@"%s: No Moves made yet.", __FUNCTION__);
        return NO;
    }
    else if (_nthMove == HISTORY_INDEX_END ) { // at the END mark?
        _nthMove = [_moves count] - 1; // Get the latest move.
    }
    else if (_nthMove == HISTORY_INDEX_BEGIN) {
        NSLog(@"%s: The index is already at BEGIN. Do nothing.", __FUNCTION__);
        return NO;
    }
    
    MoveAtom* pMove = [_moves objectAtIndex:_nthMove];
    int move = [(NSNumber*)pMove.move intValue];
    int sqSrc = SRC(move);
    int sqDst = DST(move);
    [_audioHelper playSound:@"MOVE"]; // TODO: mono-type "move" sound
    
    // For Move-Review, just reverse the move order (sqDst->sqSrc)
    // Since it's only a review, no need to make actual move in
    // the underlying game logic.
    //
    [_game movePiece:(Piece*)pMove.srcPiece toRow:ROW(sqSrc) toCol:COLUMN(sqSrc)];
    if (pMove.capturedPiece) {
        [_game movePiece:(Piece*)pMove.capturedPiece toRow:ROW(sqDst) toCol:COLUMN(sqDst)];
    }
    
    // Highlight the Piece (if any) of the "next-PREV" Move.
    --_nthMove;
    int prevMove = INVALID_MOVE;
    if (_nthMove >= 0) {
        pMove = [_moves objectAtIndex:_nthMove];
        prevMove = [(NSNumber*)pMove.move intValue];
    }
    [self _showHighlightOfMove:prevMove];
    return YES;
}

- (BOOL) _doPreviewBEGIN
{
    while ([self _doPreviewPREV]) { /* keep going */}
    return YES;
}

- (IBAction) previewPrevious_DOWN:(id)sender
{
    self._previewLastTouched_prev = [NSDate date];
}

- (IBAction) previewPrevious_UP:(id)sender
{
    self._previewLastTouched = [NSDate date];
    if (![self _isInReview]) {
        NSLog(@"%s: Clear old highlight.", __FUNCTION__);
        [self _clearAllHighlight];
    }

    NSTimeInterval timeInterval = - [_previewLastTouched_prev timeIntervalSinceNow]; // in seconds.
    if (timeInterval > 0.9) { // do "go-BEGIN" if older than 1 seconds?
        [self _doPreviewBEGIN];
    } else {
        [self _doPreviewPREV];
    }

    [self _setReviewMode:[self _isInReview]];
}

- (BOOL) _doPreviewNEXT
{
    if ([_moves count] == 0) {
        NSLog(@"%s: No Moves made yet.", __FUNCTION__);
        return NO;
    }
    else if (_nthMove == HISTORY_INDEX_END ) { // at the END mark?
        NSLog(@"%s: No PREV done. Do nothing.", __FUNCTION__);
        return NO;
    }
    
    ++_nthMove;
    NSAssert1(_nthMove >= 0 && _nthMove < [_moves count], @"Invalid index [%d]", _nthMove);
    
    const MoveAtom* pMove = [_moves objectAtIndex:_nthMove];
    
    if (_nthMove == [_moves count] - 1) {
        _nthMove = HISTORY_INDEX_END;
    }
    
    int move = [(NSNumber*)pMove.move intValue];
    int sqDst = DST(move);
    int row2 = ROW(sqDst);
    int col2 = COLUMN(sqDst);
    [_audioHelper playSound:@"MOVE"];  // TODO: mono-type "move" sound
    Piece *capture = [_game getPieceAtRow:row2 col:col2];
    if (capture) {
        [capture destroyWithAnimation:NO];
    }
    if (!pMove.srcPiece) { // not yet processed?
        NSLog(@"%s: Process pending move [%@]...", __FUNCTION__, pMove);
        int sqSrc = SRC(move);
        pMove.srcPiece = [_game getPieceAtRow:ROW(sqSrc) col:COLUMN(sqSrc)];
        NSAssert(pMove.srcPiece, @"The SRC piece should be found.");
        pMove.capturedPiece = capture;
    }
    [_game movePiece:(Piece*)pMove.srcPiece toRow:row2 toCol:col2];
    [self _showHighlightOfMove:move];
    return YES;
}

- (BOOL) _doPreviewEND
{
    while ([self _doPreviewNEXT]) { /* keep going */}
    return YES;
}

- (IBAction) previewNext_DOWN:(id)sender
{
    self._previewLastTouched_next = [NSDate date];
}

- (IBAction) previewNext_UP:(id)sender
{
    self._previewLastTouched = [NSDate date];

    NSTimeInterval timeInterval = - [_previewLastTouched_next timeIntervalSinceNow]; // in seconds.
    if (timeInterval > 0.9) { // do "go-END" if older than 1 seconds?
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
    
    UITouch *touch = [[touches allObjects] objectAtIndex:0];
    CGPoint p = [touch locationInView:self.view];
    //NSLog(@"%s: p = [%f, %f].", __FUNCTION__, p.x, p.y);    

    Piece *piece = (Piece*)[self hitTestPoint:p LayerMatchCallback:layerIsBit offset:NULL];

     if (!piece && p.y > 382)
     {
         _preview_prev.hidden = NO;
         _preview_next.hidden = NO;
         self._previewLastTouched = [NSDate date]; // now.
     }
    
    if (    [self _isInReview]   // Do nothing if in the middle of Move-Review.
        || ![_boardOwner isMyTurnNext] // Ignore when it is not my turn.
        || ![_boardOwner isGameReady] )
    { 
        return;
    }
    
    GridCell *holder = nil;
    
    if (piece) {
        // Generate moves for the selected piece.
        holder = piece.holder;
        if (!_selectedPiece || (_selectedPiece.color == piece.color)) {
            //*******************
            int row = holder._row;
            int col = holder._column;
            if (!_game.blackAtTopSide) {
                row = 9 - row;
                col = 8 - col;
            }
            //*******************
            [self _setHighlightCells:NO];
            int sqSrc = TOSQUARE(row, col);
            _hl_nMoves = [_game generateMoveFrom:sqSrc moves:_hl_moves];
            [self _setHighlightCells:YES];
            _selectedPiece.highlighted = NO;
            _selectedPiece = piece;
            _selectedPiece.highlighted = YES;
            [self playSound:@"CLICK"];
            return;
        }
    } else {
        holder = (GridCell*)[self hitTestPoint:p LayerMatchCallback:layerIsGridCell offset:NULL];
    }
    
    // Make a Move from the last selected cell to the current selected cell.
    _selectedPiece.highlighted = NO;
    if (holder && holder._highlighted && _selectedPiece)
    {
        GridCell *cell = _selectedPiece.holder;
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
        if ([_game isLegalMove:move])
        {
            [_game doMove:row1 fromCol:col1 toRow:row2 toCol:col2];
            [self onNewMove:move inSetupMode:NO];
            [_boardOwner onLocalMoveMade:move gameResult:_game.gameResult];
        }
    }

    [self _setHighlightCells:NO];
    _selectedPiece = nil;  // Reset selected state.
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

    [_game resetGame];
    [_moves removeAllObjects];
    _nthMove = HISTORY_INDEX_END;
}

- (void) displayEmptyBoard
{
    _game_over_msg.hidden = YES;
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
