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
#import "Types.h"
#import "Grid.h"
#import "Referee.h"

@interface CChessGame : NSObject
{
    CALayer*        _board;
    Grid*           _grid;
    NSMutableArray* _pieceBox;
    NSString*       _pieceFolder;
    BOOL            _blackAtTopSide;

    Referee*        _referee;
    GameStatusEnum  _gameResult;
}

- (id) initWithBoard:(CALayer*)board boardType:(int)boardType;
- (void) showBoard:(BOOL)visible;
- (void) movePiece:(Piece*)piece toRow:(int)row toCol:(int)col;
- (Piece*) getPieceAtRow:(int)row col:(int)col;
- (Piece*) getPieceAtCell:(int)square;
- (GridCell*) getCellAtRow:(int)row col:(int)col;
- (GridCell*) getCellAt:(int)square;
- (void) highlightCell:(int)cell highlight:(BOOL)bHighlight;

- (int) doMoveFrom:(Position)from toPosition:(Position)to;
- (int) generateMoveFrom:(Position)from moves:(int*)mvs;
- (BOOL) isMoveLegalFrom:(Position)from toPosition:(Position)to;
- (int) getMoveCount;
- (void) resetGame;
- (void) reverseView;
- (Position) getActualPositionAt:(int)row column:(int)col;

@property (nonatomic, readonly) BOOL blackAtTopSide;
@property (nonatomic, readonly) GameStatusEnum gameResult;
@property (readonly, getter=getNextColor) ColorEnum nextColor;

@end
