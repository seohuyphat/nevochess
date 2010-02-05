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

#import "Enums.h"
#import "Grid.h"
#import "Game.h"
#import "AIEngine.h"
#import "Referee.h"

#define INVALID_MOVE         (-1)
#define TOSQUARE(row, col)   (16 * ((row) + 3) + ((col) + 3))
#define COLUMN(sq)           ((sq) % 16 - 3)
#define ROW(sq)              ((sq) / 16 - 3)


// Possible game result
enum{
    kXiangQi_Unknown = -1,
    kXiangQi_InPlay,
    kXiangQi_YouWin,
    kXiangQi_ComputerWin,
    //we need this state because you might play with other online player
    kXiangqi_YouLose,
    kXiangQi_Draw,
    kXiangQi_OverMoves,
};

// Possible AI engines.
// TODO: We should use prefix "kNevoChess" to make our constants
// unique from others (to avoid naming conflicts).
// Also, once we are done with the AI framework, then there will be
// no need for these constants.
//
enum {
    kNevoChess_AI_xqwlight,
    kNevoChess_AI_haqikid,
    kNevoChess_AI_xqwlight_objc,
};


@class Piece;

@interface CChessGame : Game
{
    Grid*           _grid;
    NSMutableArray* _pieceBox;
    BOOL            _blackAtTopSide;

    NSString* _aiName;
    int _aiType;
    Referee  *_referee;
    AIEngine *_aiEngine;

    int game_result;
}

- (void)setupCChessPieces;
- (void)x_createPiece: (NSString*)imageName row: (int)row col: (int)col forPlayer: (unsigned)playerNo;
- (void)x_movePiece:(Piece*)piece toRow:(int)row toCol:(int)col;
- (Piece*)x_getPieceAtRow:(int)row col:(int)col;
- (GridCell*)x_getCellAtRow:(int)row col:(int)col;

- (int) getRobotMove:(int*)captured;
- (int) humanMove:(int)row1 fromCol:(int)col1
             toRow:(int)row2   toCol:(int)col2;

- (void)setSearchDepth:(int)depth;
- (int) generateMoveFrom:(int)sqSrc moves:(int*)mvs;
- (BOOL)isLegalMove:(int)mv;
- (int)checkGameStatus:(BOOL)isAI;
- (int) get_sdPlayer;
- (int) get_nMoveNum;
- (void)resetCChessPieces;
- (void)reset_game;
- (NSString*) getAIName;
- (void)reverseView;

@property (nonatomic, retain) NSString* _aiName;
@property (nonatomic, readonly) Grid* _grid;
@property (nonatomic, readonly) BOOL blackAtTopSide;
@property (nonatomic, readonly) int game_result;

@end
