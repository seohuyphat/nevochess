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

#import <Foundation/Foundation.h>
#import "XiangQi.h"

@interface Sort : NSObject {
    int mvHash, mvKiller1, mvKiller2; // 置换表走法和两个杀手走法
    int nPhase, nIndex, nSortGenMoves;    // 当前阶段，当前采用第几个走法，总共有几个走法
    int sort_mvs[MAX_GEN_MOVES];           // 所有的走法
}

@property (nonatomic, readonly) int mvHash, mvKiller1, mvKiller2;
@property (nonatomic, readonly) int nPhase, nIndex, nSortGenMoves;

- (void)initWithHash:(int)_mvHash;
- (int)next_move;
@end
