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


#import "CChessGame.h"
#import "Piece.h"
#import "QuartzUtils.h"
#import "XiangQi.h"  // XQWLight Objective-C based AI

///////////////////////////////////////////////////////////////////////////////
//
//    Private methods
//
///////////////////////////////////////////////////////////////////////////////

#pragma mark -
#pragma mark The private interface of CChessGame

@interface CChessGame (PrivateMethods)

- (void) _setupPieces;
- (void) _resetPieces;
- (void) _createPiece:(NSString*)imageName row:(int)row col:(int)col forPlayer:(unsigned)playerNo;
- (void) _setPiece:(Piece*)piece toRow:(int)row toCol:(int)col;

@end


///////////////////////////////////////////////////////////////////////////////
//
//    Implementation of Public methods
//
///////////////////////////////////////////////////////////////////////////////

#pragma mark -
#pragma mark The implementation of the interface of CChessGame

@implementation CChessGame

@synthesize _grid;
@synthesize gameResult=_gameResult;
@synthesize blackAtTopSide=_blackAtTopSide;

- (void) _createPiece:(NSString*)imageName row:(int)row col:(int)col forPlayer:(unsigned)playerNo
{
    GridCell *s = [_grid cellAtRow:row column:col]; 
    CGRect frame = s.frame;
    CGPoint position;
    position.x = CGRectGetMidX(frame);
    position.y = CGRectGetMidY(frame); 
    CGFloat pieceSize = _grid.spacing.width;  // make sure it's even
    // western or Chinese?
    BOOL toggleWestern = [[NSUserDefaults standardUserDefaults] boolForKey:@"toggle_western"];
    imageName = [[NSBundle mainBundle] pathForResource:imageName ofType:nil
                                           inDirectory:(toggleWestern ? @"pieces/alfaerie_31x31" : @"pieces/xqwizard_31x31")];

    Piece *piece = [[Piece alloc] initWithImageNamed: imageName scale: pieceSize];
    piece._owner = [self._players objectAtIndex: playerNo];
    piece.holder = [_grid cellAtRow:row column:col];
    [_board addSublayer:piece];
    position = [s.superlayer convertPoint:position toLayer:_board];
    piece.position = position;
    [_pieceBox addObject:piece];
    [piece release];
}

- (void) movePiece:(Piece*)piece toRow:(int)row toCol:(int)col
{
    if (!_blackAtTopSide) {
        row = 9 - row;
        col = 8 - col;
    }
    [self _setPiece:piece toRow:row toCol:col];
}

- (void) _setPiece:(Piece*)piece toRow:(int)row toCol:(int)col
{
    GridCell *s = [_grid cellAtRow: row column: col]; 
    CGRect frame = s.frame;
    CGPoint position;
    position.x = floor(CGRectGetMidX(frame))+0.5;
    position.y = floor(CGRectGetMidY(frame))+0.5;
    position = [s.superlayer convertPoint:position toLayer:_board];
    piece.position = position;
    piece.holder = s;
    if(piece.superlayer == nil) {
        // restore the captured piece during reset
        [_board addSublayer:piece];
    }
}

- (Piece*) getPieceAtRow:(int)row col:(int)col
{
    if (!_blackAtTopSide) {
        row = 9 - row;
        col = 8 - col;
    }
    GridCell *s = [_grid cellAtRow: row column: col]; 
    CGRect frame = s.frame;
    CGPoint position;
    position.x = floor(CGRectGetMidX(frame))+0.5;
    position.y = floor(CGRectGetMidY(frame))+0.5;
    position = [s.superlayer convertPoint:position toLayer:_board];
    CALayer *piece = [_board hitTest:position];
    if(piece && [piece isKindOfClass:[Piece class]]) {
        return (Piece*)piece;
    }
    
    return nil;
}

- (GridCell*) getCellAtRow:(int)row col:(int)col
{
    if (!_blackAtTopSide) {
        row = 9 - row;
        col = 8 - col;
    }
    GridCell *s = [_grid cellAtRow:row column:col];
    return s;
}

- (void)dealloc
{
    [_grid removeAllCells];
    [_grid release];
    [_pieceBox release];
    [_referee release];
    [super dealloc];
}

- (id) initWithBoard: (CALayer*)board
{
    if (self = [super initWithBoard: board]) {
        [self setNumberOfPlayers: 2];
        
        CGSize size = board.bounds.size;
        board.backgroundColor = GetCGPatternNamed(@"board_320x480.png");
        _grid = [[Grid alloc] initWithRows: 10 columns: 9
                                     frame: CGRectMake(board.bounds.origin.x + 2, board.bounds.origin.y + 35,
                                                       size.width-4,size.height-4)];
        //_grid.backgroundColor = GetCGPatternNamed(@"board.png");
        //_grid.borderColor = kTranslucentLightGrayColor;
        //_grid.borderWidth = 2;
        _grid.lineColor = kRedColor;
        [_grid addAllCells];
        [board addSublayer: _grid];
        
        _pieceBox = [[NSMutableArray alloc] initWithCapacity:32];
        [self _setupPieces];
        
        [_grid cellAtRow: 3 column: 0].dotted = YES;
        [_grid cellAtRow: 6 column: 0].dotted = YES;
        [_grid cellAtRow: 2 column: 1].dotted = YES;
        [_grid cellAtRow: 7 column: 1].dotted = YES;
        [_grid cellAtRow: 3 column: 2].dotted = YES;
        [_grid cellAtRow: 6 column: 2].dotted = YES;
        [_grid cellAtRow: 3 column: 4].dotted = YES;
        [_grid cellAtRow: 6 column: 4].dotted = YES;
        [_grid cellAtRow: 3 column: 6].dotted = YES;
        [_grid cellAtRow: 6 column: 6].dotted = YES;
        [_grid cellAtRow: 2 column: 7].dotted = YES;
        [_grid cellAtRow: 7 column: 7].dotted = YES;
        [_grid cellAtRow: 3 column: 8].dotted = YES;
        [_grid cellAtRow: 6 column: 8].dotted = YES;
        
        [_grid cellAtRow: 1 column: 4].cross = YES;
        [_grid cellAtRow: 8 column: 4].cross = YES;

        _blackAtTopSide = YES;
        _gameResult = kXiangQi_InPlay;
        
        // Create a Referee to manage the Game.
        _referee = [[Referee alloc] init];
        [_referee initGame];
    }
    return self;
}

- (int) humanMove:(int)row1 fromCol:(int)col1 toRow:(int)row2 toCol:(int)col2
{
    int sqSrc = TOSQUARE(row1, col1);
    int sqDst = TOSQUARE(row2, col2);
    int move = MOVE(sqSrc, sqDst);
    int captured = 0;

    [_referee makeMove:move captured:&captured];    
    return captured;
}

- (int) generateMoveFrom:(int)sqSrc moves:(int*)mvs
{
    return [_referee generateMoveFrom:sqSrc moves:mvs];
}

- (BOOL) isLegalMove:(int)mv
{
    return [_referee isLegalMove:mv];
}

- (int) checkGameStatus:(BOOL)isAI
{
    int nGameResult = kXiangQi_Unknown;
    
    if ( [_referee isMate] ) {
        nGameResult = (isAI ? kXiangQi_ComputerWin : kXiangQi_YouWin);
    }
    else {
        // Check repeat status
        int nRepVal = 0;
        if( [_referee repStatus:3 repValue:&nRepVal] > 0) {
            if (isAI) {
                nGameResult = nRepVal < -WIN_VALUE ? kXiangQi_ComputerWin 
                    : (nRepVal > WIN_VALUE ? kXiangQi_YouWin : kXiangQi_Draw);
            } else {
                nGameResult = nRepVal > WIN_VALUE ? kXiangQi_ComputerWin 
                    : (nRepVal < -WIN_VALUE ? kXiangQi_YouWin : kXiangQi_Draw);
            }
        } else if ([_referee get_nMoveNum] > POC_MAX_MOVES_PER_GAME) {
            nGameResult = kXiangQi_OverMoves; // Too many moves
        }
    }

    if ( nGameResult != kXiangQi_Unknown ) {  // Game Result changed?
        _gameResult = nGameResult;
    }

    return nGameResult;
}

- (ColorEnum) getNextColor { return [_referee get_sdPlayer] ? NC_COLOR_BLACK : NC_COLOR_RED; }
- (int) getMoveCount { return [_referee get_nMoveNum]; }

- (void) resetGame
{
    BOOL saved_blackAtTopSide = _blackAtTopSide;
    _blackAtTopSide = YES;
    [self _resetPieces];
    if (!saved_blackAtTopSide) {
        [self reverseView];
    }
    _blackAtTopSide = saved_blackAtTopSide;
    
    [_referee initGame];
    _gameResult = kXiangQi_InPlay;
}

- (void) reverseView
{
    for (Piece* piece in _pieceBox) {
        if(piece.superlayer != nil) { // not captured?
            GridCell *holder = (GridCell*)piece.holder;
            
            unsigned row = 9 - holder._row;
            unsigned column = 8 - holder._column;
            //NSLog(@"%s: Convert [%d%d -> %d%d].", __FUNCTION__, holder._row, holder._column, row, column);
            
            [self _setPiece:piece toRow:row toCol:column];
        }
    }
    _blackAtTopSide = !_blackAtTopSide;
}

- (void) _resetPieces
{
    // reset the pieces in pieceBox by the order they are created
    // chariot
    [self movePiece:[_pieceBox objectAtIndex:0] toRow:0 toCol:0];
    [self movePiece:[_pieceBox objectAtIndex:1] toRow:0 toCol:8];
    [self movePiece:[_pieceBox objectAtIndex:2] toRow:9 toCol:0];
    [self movePiece:[_pieceBox objectAtIndex:3] toRow:9 toCol:8];
    
    // horse
    [self movePiece:[_pieceBox objectAtIndex:4] toRow:0 toCol:1];
    [self movePiece:[_pieceBox objectAtIndex:5] toRow:0 toCol:7];
    [self movePiece:[_pieceBox objectAtIndex:6] toRow:9 toCol:1];
    [self movePiece:[_pieceBox objectAtIndex:7] toRow:9 toCol:7];
    
    // elephant
    [self movePiece:[_pieceBox objectAtIndex:8] toRow:0 toCol:2];
    [self movePiece:[_pieceBox objectAtIndex:9] toRow:0 toCol:6];
    [self movePiece:[_pieceBox objectAtIndex:10] toRow:9 toCol:2];
    [self movePiece:[_pieceBox objectAtIndex:11] toRow:9 toCol:6];
    
    // advisor
    [self movePiece:[_pieceBox objectAtIndex:12] toRow:0 toCol:3];
    [self movePiece:[_pieceBox objectAtIndex:13] toRow:0 toCol:5];
    [self movePiece:[_pieceBox objectAtIndex:14] toRow:9 toCol:3];
    [self movePiece:[_pieceBox objectAtIndex:15] toRow:9 toCol:5];
    
    // king
    [self movePiece:[_pieceBox objectAtIndex:16] toRow:0 toCol:4];
    [self movePiece:[_pieceBox objectAtIndex:17] toRow:9 toCol:4];
    
    // cannon
    [self movePiece:[_pieceBox objectAtIndex:18] toRow:2 toCol:1];
    [self movePiece:[_pieceBox objectAtIndex:19] toRow:2 toCol:7];
    [self movePiece:[_pieceBox objectAtIndex:20] toRow:7 toCol:1];
    [self movePiece:[_pieceBox objectAtIndex:21] toRow:7 toCol:7];
    
    // pawn
    [self movePiece:[_pieceBox objectAtIndex:22] toRow:3 toCol:0];
    [self movePiece:[_pieceBox objectAtIndex:23] toRow:3 toCol:2];
    [self movePiece:[_pieceBox objectAtIndex:24] toRow:3 toCol:4];
    [self movePiece:[_pieceBox objectAtIndex:25] toRow:3 toCol:6];
    [self movePiece:[_pieceBox objectAtIndex:26] toRow:3 toCol:8];
    [self movePiece:[_pieceBox objectAtIndex:27] toRow:6 toCol:0];
    [self movePiece:[_pieceBox objectAtIndex:28] toRow:6 toCol:2];
    [self movePiece:[_pieceBox objectAtIndex:29] toRow:6 toCol:4];
    [self movePiece:[_pieceBox objectAtIndex:30] toRow:6 toCol:6];
    [self movePiece:[_pieceBox objectAtIndex:31] toRow:6 toCol:8];
}

- (void) _setupPieces
{
    // chariot      
    [self _createPiece:@"bchariot.png" row:0 col:0 forPlayer:0];
    [self _createPiece:@"bchariot.png" row:0 col:8 forPlayer:0];         
    [self _createPiece:@"rchariot.png" row:9 col:0 forPlayer:1];     
    [self _createPiece:@"rchariot.png" row:9 col:8 forPlayer:1];  

    // horse    
    [self _createPiece:@"bhorse.png" row:0 col:1 forPlayer:0];        
    [self _createPiece:@"bhorse.png" row:0 col:7 forPlayer:0];         
    [self _createPiece:@"rhorse.png" row:9 col:1 forPlayer:1];      
    [self _createPiece:@"rhorse.png" row:9 col:7 forPlayer:1];
    
    // elephant      
    [self _createPiece:@"belephant.png" row:0 col:2 forPlayer:0];        
    [self _createPiece:@"belephant.png" row:0 col:6 forPlayer:0];        
    [self _createPiece:@"relephant.png" row:9 col:2 forPlayer:1];     
    [self _createPiece:@"relephant.png" row:9 col:6 forPlayer:1]; 
    
    // advisor      
    [self _createPiece:@"badvisor.png" row:0 col:3 forPlayer:0];         
    [self _createPiece:@"badvisor.png" row:0 col:5 forPlayer:0];         
    [self _createPiece:@"radvisor.png" row:9 col:3 forPlayer:1];        
    [self _createPiece:@"radvisor.png" row:9 col:5 forPlayer:1];
    
    // king       
    [self _createPiece:@"bking.png" row:0 col:4 forPlayer:0];       
    [self _createPiece:@"rking.png" row:9 col:4 forPlayer:1];
    
    // cannon     
    [self _createPiece:@"bcannon.png" row:2 col:1 forPlayer:0];       
    [self _createPiece:@"bcannon.png" row:2 col:7 forPlayer:0];          
    [self _createPiece:@"rcannon.png" row:7 col:1 forPlayer:1];        
    [self _createPiece:@"rcannon.png" row:7 col:7 forPlayer:1];

    // pawn       
    [self _createPiece:@"bpawn.png" row:3 col:0 forPlayer:0];         
    [self _createPiece:@"bpawn.png" row:3 col:2 forPlayer:0];         
    [self _createPiece:@"bpawn.png" row:3 col:4 forPlayer:0];        
    [self _createPiece:@"bpawn.png" row:3 col:6 forPlayer:0];      
    [self _createPiece:@"bpawn.png" row:3 col:8 forPlayer:0];     
    [self _createPiece:@"rpawn.png" row:6 col:0 forPlayer:1];      
    [self _createPiece:@"rpawn.png" row:6 col:2 forPlayer:1];         
    [self _createPiece:@"rpawn.png" row:6 col:4 forPlayer:1];       
    [self _createPiece:@"rpawn.png" row:6 col:6 forPlayer:1];      
    [self _createPiece:@"rpawn.png" row:6 col:8 forPlayer:1];
}

@end
