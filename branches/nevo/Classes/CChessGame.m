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
#import "Enums.h"
#import "Grid.h"
#import "Piece.h"
#import "QuartzUtils.h"
#import "AI_HaQiKiD.h"
#import "AI_XQWLight.h"
#import "XiangQi.h"  // XQWLight Objective-C based AI

///////////////////////////////////////////////////////////////////////////////
//
//    Private methods
//
///////////////////////////////////////////////////////////////////////////////

#pragma mark -
#pragma mark The private interface of CChessGame

@interface CChessGame ()

- (int) _convertStringToAIType:(NSString *)aiSelection;

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
@synthesize game_result;

- (void)x_createPiece: (NSString*)imageName row: (int)row col: (int)col forPlayer: (unsigned)playerNo
{
    XiangQiSquare *s = ((XiangQiSquare*)[_grid cellAtRow: row column: col]); 
    CGRect frame = s.frame;
    CGPoint position;
    position.x = CGRectGetMidX(frame);
    position.y = CGRectGetMidY(frame); 
    CGFloat pieceSize = _grid.spacing.width;  // make sure it's even
    // western or Chinese?
    BOOL toggleWestern = [[NSUserDefaults standardUserDefaults] boolForKey:@"toggle_western"];
    if(toggleWestern) {
        imageName = [[NSBundle mainBundle] pathForResource:imageName ofType:nil inDirectory:@"pieces/alfaerie_31x31"];
    } else {
        imageName = [[NSBundle mainBundle] pathForResource:imageName ofType:nil inDirectory:@"pieces/xqwizard_31x31"];
    }
    
    Piece *piece = [[Piece alloc] initWithImageNamed: imageName scale: pieceSize];
    piece._owner = [self._players objectAtIndex: playerNo];
    piece.holder = [_grid cellAtRow:row column:col];
    [_board addSublayer:piece];
    position = [s.superlayer convertPoint:position toLayer:_board];
    piece.position = position;
    [_pieceBox addObject:piece];
    [piece release];
}

- (void)x_movePiece:(Piece*)piece toRow:(int)row toCol:(int)col
{
    XiangQiSquare *s = ((XiangQiSquare*)[_grid cellAtRow: row column: col]); 
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

- (Piece*)x_getPieceAtRow:(int)row col:(int)col
{
    XiangQiSquare *s = ((XiangQiSquare*)[_grid cellAtRow: row column: col]); 
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

- (void)dealloc
{
    [_grid removeAllCells];
    [_grid release];
    [_pieceBox release];
    [_referee release];
    [_aiEngine release];
    [super dealloc];
}

- (id) initWithBoard: (CALayer*)board
{
    self = [super initWithBoard: board];
    if (self != nil) {
        [self setNumberOfPlayers: 2];
        
        CGSize size = board.bounds.size;
        board.backgroundColor = GetCGPatternNamed(@"board_320x480.png");
        XiangQiGrid *grid = [[XiangQiGrid alloc] initWithRows: 10 columns: 9 
                                                  frame: CGRectMake(board.bounds.origin.x + 2, board.bounds.origin.y + 25,
                                                                    size.width-4,size.height-4)];
        _grid = (RectGrid*)grid;
        //grid.backgroundColor = GetCGPatternNamed(@"board.png");
        //grid.borderColor = kTranslucentLightGrayColor;
        //grid.borderWidth = 2;
        grid.lineColor = kRedColor;
        grid.cellClass = [XiangQiSquare class];
        [grid addAllCells];
        grid.usesDiagonals = grid.allowsMoves = grid.allowsCaptures = NO;
        [board addSublayer: grid];
        
        _pieceBox = [[NSMutableArray alloc] initWithCapacity:32];
        [self setupCChessPieces];
        
        ((XiangQiSquare*)[grid cellAtRow: 3 column: 0])._dotted = YES;
        ((XiangQiSquare*)[grid cellAtRow: 6 column: 0])._dotted = YES;
        ((XiangQiSquare*)[grid cellAtRow: 2 column: 1])._dotted = YES;
        ((XiangQiSquare*)[grid cellAtRow: 7 column: 1])._dotted = YES;
        ((XiangQiSquare*)[grid cellAtRow: 3 column: 2])._dotted = YES;
        ((XiangQiSquare*)[grid cellAtRow: 6 column: 2])._dotted = YES;
        ((XiangQiSquare*)[grid cellAtRow: 3 column: 4])._dotted = YES;
        ((XiangQiSquare*)[grid cellAtRow: 6 column: 4])._dotted = YES;
        ((XiangQiSquare*)[grid cellAtRow: 3 column: 6])._dotted = YES;
        ((XiangQiSquare*)[grid cellAtRow: 6 column: 6])._dotted = YES;
        ((XiangQiSquare*)[grid cellAtRow: 2 column: 7])._dotted = YES;
        ((XiangQiSquare*)[grid cellAtRow: 7 column: 7])._dotted = YES;
        ((XiangQiSquare*)[grid cellAtRow: 3 column: 8])._dotted = YES;
        ((XiangQiSquare*)[grid cellAtRow: 6 column: 8])._dotted = YES;
        
        ((XiangQiSquare*)[grid cellAtRow: 1 column: 4]).cross = YES;
        ((XiangQiSquare*)[grid cellAtRow: 8 column: 4]).cross = YES;
        
        game_result = kXiangQi_InPlay;
        
        // Create a Referee to manage the Game.
        _referee = [[Referee alloc] init];
        [_referee initGame];
        
        // Determine the type of AI.
        NSString *aiSelection = [[NSUserDefaults standardUserDefaults] stringForKey:@"AI"];
        _aiType = [self _convertStringToAIType:aiSelection];

        switch (_aiType) {
            case kNevoChess_AI_xqwlight:
                _aiEngine = [[AI_XQWLight alloc] init];
                break;
            case kNevoChess_AI_haqikid:
                _aiEngine = [[AI_HaQiKiD alloc] init];
                break;
            case kNevoChess_AI_xqwlight_objc:
                // NOTE: The Objective-c AI is still in experimental stage.
                _aiEngine = [[AI_XQWLightObjC alloc] init];
                break;
            default:
                break;
        }

        [_aiEngine initGame];
    }
    return self;
}


- (int)getRobotMove:(int*)captured
{
    int row1 = 0, col1 = 0, row2 = 0, col2 = 0;
    [_aiEngine generateMove:&row1 fromCol:&col1 toRow:&row2 toCol:&col2];
    
    int sqSrc = TOSQUARE(row1, col1);
    int sqDst = TOSQUARE(row2, col2);
    int move = MOVE(sqSrc, sqDst);

    [_referee makeMove:move captured:captured];
    return move;
}

- (int)humanMove:(int)row1 fromCol:(int)col1
            toRow:(int)row2 toCol:(int)col2
{
    int sqSrc = TOSQUARE(row1, col1);
    int sqDst = TOSQUARE(row2, col2);
    int move = MOVE(sqSrc, sqDst);
    int captured = 0;

    [_aiEngine onHumanMove:row1 fromCol:col1 toRow:row2 toCol:col2];
    [_referee makeMove:move captured:&captured];
    
    return captured;
}

- (void)setSearchDepth:(int)depth
{
    [_aiEngine setDifficultyLevel:depth];
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
        game_result = nGameResult;
    }

    return nGameResult;
}

- (int) get_sdPlayer
{
    return [_referee get_sdPlayer];
}

- (void)reset_game
{
    [self resetCChessPieces];
    [_referee initGame];
    [_aiEngine initGame];
    game_result = kXiangQi_InPlay;
}

- (void)resetCChessPieces
{
    // reset the pieces in pieceBox by the order they are created
    // chariot
    [self x_movePiece:[_pieceBox objectAtIndex:0] toRow:0 toCol:0];
    [self x_movePiece:[_pieceBox objectAtIndex:1] toRow:0 toCol:8];
    [self x_movePiece:[_pieceBox objectAtIndex:2] toRow:9 toCol:0];
    [self x_movePiece:[_pieceBox objectAtIndex:3] toRow:9 toCol:8];
    
    // horse
    [self x_movePiece:[_pieceBox objectAtIndex:4] toRow:0 toCol:1];
    [self x_movePiece:[_pieceBox objectAtIndex:5] toRow:0 toCol:7];
    [self x_movePiece:[_pieceBox objectAtIndex:6] toRow:9 toCol:1];
    [self x_movePiece:[_pieceBox objectAtIndex:7] toRow:9 toCol:7];
    
    // elephant
    [self x_movePiece:[_pieceBox objectAtIndex:8] toRow:0 toCol:2];
    [self x_movePiece:[_pieceBox objectAtIndex:9] toRow:0 toCol:6];
    [self x_movePiece:[_pieceBox objectAtIndex:10] toRow:9 toCol:2];
    [self x_movePiece:[_pieceBox objectAtIndex:11] toRow:9 toCol:6];
    
    // advisor
    [self x_movePiece:[_pieceBox objectAtIndex:12] toRow:0 toCol:3];
    [self x_movePiece:[_pieceBox objectAtIndex:13] toRow:0 toCol:5];
    [self x_movePiece:[_pieceBox objectAtIndex:14] toRow:9 toCol:3];
    [self x_movePiece:[_pieceBox objectAtIndex:15] toRow:9 toCol:5];
    
    // king
    [self x_movePiece:[_pieceBox objectAtIndex:16] toRow:0 toCol:4];
    [self x_movePiece:[_pieceBox objectAtIndex:17] toRow:9 toCol:4];
    
    // cannon
    [self x_movePiece:[_pieceBox objectAtIndex:18] toRow:2 toCol:1];
    [self x_movePiece:[_pieceBox objectAtIndex:19] toRow:2 toCol:7];
    [self x_movePiece:[_pieceBox objectAtIndex:20] toRow:7 toCol:1];
    [self x_movePiece:[_pieceBox objectAtIndex:21] toRow:7 toCol:7];
    
    // pawn
    [self x_movePiece:[_pieceBox objectAtIndex:22] toRow:3 toCol:0];
    [self x_movePiece:[_pieceBox objectAtIndex:23] toRow:3 toCol:2];
    [self x_movePiece:[_pieceBox objectAtIndex:24] toRow:3 toCol:4];
    [self x_movePiece:[_pieceBox objectAtIndex:25] toRow:3 toCol:6];
    [self x_movePiece:[_pieceBox objectAtIndex:26] toRow:3 toCol:8];
    [self x_movePiece:[_pieceBox objectAtIndex:27] toRow:6 toCol:0];
    [self x_movePiece:[_pieceBox objectAtIndex:28] toRow:6 toCol:2];
    [self x_movePiece:[_pieceBox objectAtIndex:29] toRow:6 toCol:4];
    [self x_movePiece:[_pieceBox objectAtIndex:30] toRow:6 toCol:6];
    [self x_movePiece:[_pieceBox objectAtIndex:31] toRow:6 toCol:8];    

}

- (void)setupCChessPieces
{
    // chariot      
    [self x_createPiece:@"bchariot.png" row:0 col:0 forPlayer:0];
    [self x_createPiece:@"bchariot.png" row:0 col:8 forPlayer:0];         
    [self x_createPiece:@"rchariot.png" row:9 col:0 forPlayer:1];     
    [self x_createPiece:@"rchariot.png" row:9 col:8 forPlayer:1];  

    // horse    
    [self x_createPiece:@"bhorse.png" row:0 col:1 forPlayer:0];        
    [self x_createPiece:@"bhorse.png" row:0 col:7 forPlayer:0];         
    [self x_createPiece:@"rhorse.png" row:9 col:1 forPlayer:1];      
    [self x_createPiece:@"rhorse.png" row:9 col:7 forPlayer:1];
    
    // elephant      
    [self x_createPiece:@"belephant.png" row:0 col:2 forPlayer:0];        
    [self x_createPiece:@"belephant.png" row:0 col:6 forPlayer:0];        
    [self x_createPiece:@"relephant.png" row:9 col:2 forPlayer:1];     
    [self x_createPiece:@"relephant.png" row:9 col:6 forPlayer:1]; 
    
    // advisor      
    [self x_createPiece:@"badvisor.png" row:0 col:3 forPlayer:0];         
    [self x_createPiece:@"badvisor.png" row:0 col:5 forPlayer:0];         
    [self x_createPiece:@"radvisor.png" row:9 col:3 forPlayer:1];        
    [self x_createPiece:@"radvisor.png" row:9 col:5 forPlayer:1];
    
    // king       
    [self x_createPiece:@"bking.png" row:0 col:4 forPlayer:0];       
    [self x_createPiece:@"rking.png" row:9 col:4 forPlayer:1];
    
    // cannon     
    [self x_createPiece:@"bcannon.png" row:2 col:1 forPlayer:0];       
    [self x_createPiece:@"bcannon.png" row:2 col:7 forPlayer:0];          
    [self x_createPiece:@"rcannon.png" row:7 col:1 forPlayer:1];        
    [self x_createPiece:@"rcannon.png" row:7 col:7 forPlayer:1];

    // pawn       
    [self x_createPiece:@"bpawn.png" row:3 col:0 forPlayer:0];         
    [self x_createPiece:@"bpawn.png" row:3 col:2 forPlayer:0];         
    [self x_createPiece:@"bpawn.png" row:3 col:4 forPlayer:0];        
    [self x_createPiece:@"bpawn.png" row:3 col:6 forPlayer:0];      
    [self x_createPiece:@"bpawn.png" row:3 col:8 forPlayer:0];     
    [self x_createPiece:@"rpawn.png" row:6 col:0 forPlayer:1];      
    [self x_createPiece:@"rpawn.png" row:6 col:2 forPlayer:1];         
    [self x_createPiece:@"rpawn.png" row:6 col:4 forPlayer:1];       
    [self x_createPiece:@"rpawn.png" row:6 col:6 forPlayer:1];      
    [self x_createPiece:@"rpawn.png" row:6 col:8 forPlayer:1];
}

///////////////////////////////////////////////////////////////////////////////
//
//    Implementation of Private methods
//
///////////////////////////////////////////////////////////////////////////////

#pragma mark -
#pragma mark Private methods

- (int) _convertStringToAIType:(NSString *)aiSelection;
{
    if ([aiSelection isEqualToString:@"XQWLight"]) {
        return kNevoChess_AI_xqwlight;
    } else if ([aiSelection isEqualToString:@"HaQiKiD"]) {
        return kNevoChess_AI_haqikid;
    } else if ([aiSelection isEqualToString:@"XQWLightObjc"]) {
        return kNevoChess_AI_xqwlight_objc;
    }
    return kNevoChess_AI_xqwlight; // Default!
}

@end
