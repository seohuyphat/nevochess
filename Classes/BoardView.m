/*
 
 File: BoardView.m
 
 Abstract: 
 
 Version: 1.0
 
 Disclaimer: IMPORTANT:  This Apple software is supplied to you by 
 Apple Inc. ("Apple") in consideration of your agreement to the
 following terms, and your use, installation, modification or
 redistribution of this Apple software constitutes acceptance of these
 terms.  If you do not agree with these terms, please do not use,
 install, modify or redistribute this Apple software.
 
 In consideration of your agreement to abide by the following terms, and
 subject to these terms, Apple grants you a personal, non-exclusive
 license, under Apple's copyrights in this original Apple software (the
 "Apple Software"), to use, reproduce, modify and redistribute the Apple
 Software, with or without modifications, in source and/or binary forms;
 provided that if you redistribute the Apple Software in its entirety and
 without modifications, you must retain this notice and the following
 text and disclaimers in all such redistributions of the Apple Software. 
 Neither the name, trademarks, service marks or logos of Apple Inc. 
 may be used to endorse or promote products derived from the Apple
 Software without specific prior written permission from Apple.  Except
 as expressly stated in this notice, no other rights or licenses, express
 or implied, are granted by Apple herein, including but not limited to
 any patent rights that may be infringed by your derivative works or by
 other works in which the Apple Software may be incorporated.
 
 The Apple Software is provided by Apple on an "AS IS" basis.  APPLE
 MAKES NO WARRANTIES, EXPRESS OR IMPLIED, INCLUDING WITHOUT LIMITATION
 THE IMPLIED WARRANTIES OF NON-INFRINGEMENT, MERCHANTABILITY AND FITNESS
 FOR A PARTICULAR PURPOSE, REGARDING THE APPLE SOFTWARE OR ITS USE AND
 OPERATION ALONE OR IN COMBINATION WITH YOUR PRODUCTS.
 
 IN NO EVENT SHALL APPLE BE LIABLE FOR ANY SPECIAL, INDIRECT, INCIDENTAL
 OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 INTERRUPTION) ARISING IN ANY WAY OUT OF THE USE, REPRODUCTION,
 MODIFICATION AND/OR DISTRIBUTION OF THE APPLE SOFTWARE, HOWEVER CAUSED
 AND WHETHER UNDER THEORY OF CONTRACT, TORT (INCLUDING NEGLIGENCE),
 STRICT LIABILITY OR OTHERWISE, EVEN IF APPLE HAS BEEN ADVISED OF THE
 POSSIBILITY OF SUCH DAMAGE.
 
 Copyright © 2007 Apple Inc. All Rights Reserved.
 
 */

/***************************************************************************
 *                                                                         *
 * Customized by the PlayXiangqi team to work as a Xiangqi Board.          *
 *                                                                         *
 ***************************************************************************/

#import "BoardView.h"
#import "Bit.h"
#import "BitHolder.h"
#import "QuartzUtils.h"
#import "NevoChessAppDelegate.h"
#import "Grid.h"
#import "Piece.h"

enum HistoryIndex // NOTE: Do not change the constants 'values below.
{
    HISTORY_INDEX_END   = -2,
    HISTORY_INDEX_BEGIN = -1
};

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

- (id)initWithMove:(int)mv
{
    if (self = [super init]) {
        self.move = [NSNumber numberWithInteger:mv];
        self.srcPiece = nil;
        self.capturedPiece = nil;
    }
    return self;
}

- (NSString*) description
{
    int m = [(NSNumber*)self.move intValue];
    int sqSrc = SRC(m);
    int sqDst = DST(m);
    return [NSString stringWithFormat: @"%u%u -> %u%u)", ROW(sqSrc), COLUMN(sqSrc), ROW(sqDst), COLUMN(sqDst)];
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
//    TimeInfo
//
///////////////////////////////////////////////////////////////////////////////
@implementation TimeInfo

@synthesize gameTime, moveTime, freeTime;

- (id)initWithTime:(TimeInfo*)other
{
    if (self = [self init]) {
        gameTime = other.gameTime;
        moveTime = other.moveTime;
        freeTime = other.freeTime;
    }
    return self;
}

- (void) decrement
{
    if (gameTime > 0) { --gameTime; }
    if (moveTime > 0) { --moveTime; }
}

+ (id)allocTimeFromString:(NSString *)timeContent
{
    TimeInfo* newTime = [TimeInfo new];
    NSArray* components = [timeContent componentsSeparatedByString:@"/"];
    
    newTime.gameTime = [[components objectAtIndex:0] intValue];
    newTime.moveTime = [[components objectAtIndex:1] intValue];
    newTime.freeTime = [[components objectAtIndex:2] intValue];
    
    return newTime;
}

@end

///////////////////////////////////////////////////////////////////////////////
//
//    BoardView
//
///////////////////////////////////////////////////////////////////////////////

//
// Private methods (BoardView)
//
@interface BoardView (PrivateMethods)
- (CGRect) _gameBoardFrame;
- (id) _initSoundSystem;
- (void) _setHighlightCells:(BOOL)bHighlight;
- (void) _showHighlightOfMove:(int)move;
- (void) _ticked:(NSTimer*)timer;
- (void) _updateTimer;
- (NSString*) _allocStringFrom:(int)seconds;
@end

@implementation BoardView

@synthesize game=_game;
@synthesize boardOwner=_boardOwner;
@synthesize _timer, _previewLastTouched;
@synthesize _initialTime, _redTime, _blackTime;


- (void) awakeFromNib
{
    NSLog(@"%s: ENTER.", __FUNCTION__);
    ((NevoChessAppDelegate*)[[UIApplication sharedApplication] delegate]).navigationController.navigationBarHidden = YES;

    _gameboard = [[CALayer alloc] init];
    _gameboard.frame = [self _gameBoardFrame];
    self.layer.backgroundColor = GetCGPatternNamed(@"board_320x480.png");
    [self.layer insertSublayer:_gameboard atIndex:0]; // ... in the back.

    _game = [[CChessGame alloc] initWithBoard:_gameboard];

    _audioHelper = [self _initSoundSystem];
    _boardOwner = nil;

    // TODO: _initialTime = [[NSUserDefaults standardUserDefaults] integerForKey:@"time_setting"];
    self._initialTime = [TimeInfo allocTimeFromString:@"900/180/20"];
    self._redTime = [[TimeInfo alloc] initWithTime:_initialTime];
    self._blackTime = [[TimeInfo alloc] initWithTime:_initialTime];
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

    _moves = [[NSMutableArray alloc] initWithCapacity:POC_MAX_MOVES_PER_GAME];
    _nthMove = HISTORY_INDEX_END;

    _hl_nMoves = 0;
    _hl_lastMove = INVALID_MOVE;
    _selectedPiece = nil;

    self._previewLastTouched = [[NSDate date] addTimeInterval:-60]; // 1-minute earlier.
    self._timer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(_ticked:) userInfo:nil repeats:YES];
}

- (void)dealloc
{
    [_gameboard removeFromSuperlayer];
    [_gameboard release];
    [_game release];
    [_boardOwner release];
    [_timer release];
    [_moves release];
    [_previewLastTouched release];
    [super dealloc];
}

- (CGRect) _gameBoardFrame
{
    CGRect bounds = self.layer.bounds;
/*
    bounds.origin.x += 2;
    bounds.origin.y += 2;
    bounds.size.width -= 4;
    bounds.size.height -= 24;
    self.layer.bounds = bounds;
*/
    return bounds;
}

- (id) _initSoundSystem
{
    AudioHelper* audioHelper = [[AudioHelper alloc] init];

    NSArray *soundList = [NSArray arrayWithObjects:@"CAPTURE", @"CAPTURE2", @"CLICK",
                          @"DRAW", @"LOSS", @"CHECK", @"CHECK2",
                          @"MOVE", @"MOVE2", @"WIN", @"ILLEGAL",
                          nil];
    for (NSString* sound in soundList) {
        [audioHelper load_wav_sound:sound];
    }
    return audioHelper;
}


#pragma mark -
#pragma mark HIT-TESTING:


// Locates the layer at a given point in window coords.
//    If the leaf layer doesn't pass the layer-match callback, the nearest ancestor that does is returned.
//    If outOffset is provided, the point's position relative to the layer is stored into it.
- (CALayer*) hitTestPoint: (CGPoint)locationInWindow
       LayerMatchCallback: (LayerMatchCallback)match offset: (CGPoint*)outOffset
{
    CGPoint where = locationInWindow;
    where = [_gameboard convertPoint: where fromLayer: self.layer];
    CALayer *layer = [_gameboard hitTest: where];
    while( layer ) {
        if( match(layer) ) {
            CGPoint bitPos = [self.layer convertPoint: layer.position 
                              fromLayer: layer.superlayer];
            if( outOffset )
                *outOffset = CGPointMake( bitPos.x-where.x, bitPos.y-where.y);
            return layer;
        } else
            layer = layer.superlayer;
    }
    return nil;
}

- (void) setRedLabel:(NSString*)label  { _red_label.text = label; }
- (void) setBlackLabel:(NSString*)label { _black_label.text = label; }

- (void) setInitialTime:(NSString*)times
{
    self._initialTime = [TimeInfo allocTimeFromString:times];
}

- (void) setRedTime:(NSString*)times
{
    self._redTime = [TimeInfo allocTimeFromString:times];
    _red_time.text = [self _allocStringFrom:_redTime.gameTime];
    _red_move_time.text = [self _allocStringFrom:_redTime.moveTime];
}

- (void) setBlackTime:(NSString*)times
{
    self._blackTime = [TimeInfo allocTimeFromString:times];
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
        [_game highlightCell:DST(_hl_lastMove) highlight:NO];
        _hl_lastMove = INVALID_MOVE;
    }

    if (move != INVALID_MOVE) {
        [_game highlightCell:DST(move) highlight:YES];
        _hl_lastMove = move;
    }
}

- (NSString*) _allocStringFrom:(int)seconds
{
    return [[NSString alloc] initWithFormat:@"%d:%02d", (seconds / 60), (seconds % 60)];
}

- (int) onNewMove:(NSNumber *)moveInfo inSetupMode:(BOOL)bSetup
{
    int  move = [moveInfo integerValue];
    ColorEnum moveColor = ([_game getNextColor] == NC_COLOR_RED ? NC_COLOR_BLACK : NC_COLOR_RED);

    if (!bSetup) {
        [self resetMoveTime:moveColor];
    }

    MoveAtom* pMove = [[[MoveAtom alloc] initWithMove:move] autorelease];
    NSLog(@"%s: Add new move [%@].", __FUNCTION__, pMove);
    [_moves addObject:pMove];

    // Delay update the UI if in Preview mode.
    if ([self _isInReview]) {
        // NOTE: We do not update pMove.srcPiece (leaving it equal to nil)
        //       to signal that it is NOT yet processed.
        return kXiangQi_Unknown;
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
        [capture removeFromSuperlayer];
        sound = (moveColor == NC_COLOR_RED ? @"CAPTURE" : @"CAPTURE2" );
    }

    [_audioHelper play_wav_sound:sound];

    [_game movePiece:piece toRow:row2 toCol:col2];
    [self _showHighlightOfMove:move];

    // Add this new Move to the Move-History.
    pMove.srcPiece = piece;
    pMove.capturedPiece = capture;

    int nGameResult = [_game checkGameStatus];
    return nGameResult;
}

- (void) onGameOver
{
    _game_over_msg.hidden = NO;
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
    if (self._timer) [self._timer invalidate];
    self._timer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(_ticked:) userInfo:nil repeats:YES];
}

- (void) destroyTimer
{
    if (self._timer) [self._timer invalidate];
    self._timer = nil;
}

- (void) playSound:(NSString*)sound
{
    [_audioHelper play_wav_sound:sound];
}

- (NSMutableArray*) getMoves
{
    return _moves;
}

- (IBAction)movePrevPressed:(id)sender
{
    self._previewLastTouched = [NSDate date];
    
    if ([_moves count] == 0) {
        NSLog(@"%s: No Moves made yet.", __FUNCTION__);
        return;
    }
    else if (_nthMove == HISTORY_INDEX_END ) { // at the END mark?
        _nthMove = [_moves count] - 1; // Get the latest move.
    }
    else if (_nthMove == HISTORY_INDEX_BEGIN) {
        NSLog(@"%s: The index is already at BEGIN. Do nothing.", __FUNCTION__);
        return;
    }
    
    MoveAtom* pMove = [_moves objectAtIndex:_nthMove];
    int move = [(NSNumber*)pMove.move intValue];
    int sqSrc = SRC(move);
    int sqDst = DST(move);
    [_audioHelper play_wav_sound:@"MOVE"]; // TODO: mono-type "move" sound
    
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
}

- (IBAction)moveNextPressed:(id)sender
{
    self._previewLastTouched = [NSDate date];
    
    if ([_moves count] == 0) {
        NSLog(@"%s: No Moves made yet.", __FUNCTION__);
        return;
    }
    else if (_nthMove == HISTORY_INDEX_END ) { // at the END mark?
        NSLog(@"%s: No PREV done. Do nothing.", __FUNCTION__);
        return;
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
    [_audioHelper play_wav_sound:@"MOVE"];  // TODO: mono-type "move" sound
    Piece *capture = [_game getPieceAtRow:row2 col:col2];
    if (capture) {
        [capture removeFromSuperlayer];
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
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    if ( [[event allTouches] count] != 1 ) { // Valid for single touch only
        return;
    }
    
    UITouch *touch = [[touches allObjects] objectAtIndex:0];
    CGPoint p = [touch locationInView:self];
    NSLog(@"%s: p = [%f, %f].", __FUNCTION__, p.x, p.y);
    
    BoardView *view = self;//(BoardView*) self.view;
    Piece *piece = (Piece*)[view hitTestPoint:p LayerMatchCallback:layerIsBit offset:NULL];

     if (!piece && p.y > 382) {
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
        holder = (GridCell*)piece.holder;
        if (!_selectedPiece || (_selectedPiece._owner == piece._owner)) {
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
            _selectedPiece = piece;
            [self playSound:@"CLICK"];
            return;
        }
    } else {
        holder = (GridCell*)[view hitTestPoint:p LayerMatchCallback:layerIsBitHolder offset:NULL];
    }
    
    // Make a Move from the last selected cell to the current selected cell.
    if (holder && holder._highlighted && _selectedPiece) {
        [self _setHighlightCells:NO];
        
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
        if ([_game isLegalMove:move])
        {
            [_game doMove:row1 fromCol:col1 toRow:row2 toCol:col2];
            
            NSNumber *moveInfo = [NSNumber numberWithInteger:move];
            [self onNewMove:moveInfo inSetupMode:NO];
            
            [_boardOwner onLocalMoveMade:move];
        }
    } else {
        [self _setHighlightCells:NO];
    }

    _selectedPiece = nil;  // Reset selected state.
}

- (void) resetBoard
{
    [self _setHighlightCells:NO];
    [self _showHighlightOfMove:INVALID_MOVE];  // Clear the last highlight.
    _selectedPiece = nil;

    self._redTime = [[TimeInfo alloc] initWithTime:_initialTime];
    self._blackTime = [[TimeInfo alloc] initWithTime:_initialTime];
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
    [self resetBoard];
    [self setRedLabel:@""];
    [self setBlackLabel:@""];
    if (!_game.blackAtTopSide )
    {
        [self reverseBoardView];
    }
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

@end
