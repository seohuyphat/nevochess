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

#import "Sort.h"
#import "XiangQi.h"

static int CompareHistoryMove(const void *mv1, const void *mv2)
{
    XiangQi *engine = [XiangQi getXiangQi];
    return [engine compare_history_move1:(int*)mv1 move2:(int*)mv2];
}

@implementation Sort

@synthesize  mvHash, mvKiller1, mvKiller2;
@synthesize nPhase, nIndex, nSortGenMoves;

// 初始化，设定置换表走法和两个杀手走法
- (void)initWithHash:(int)_mvHash
{
    XiangQi *engine = [XiangQi getXiangQi];
    mvHash = _mvHash;
    mvKiller1 = [engine killerMoveAtDepth:engine.n_distance atIndex:0]; //mvKillers[n_distance][0];
    mvKiller2 = [engine killerMoveAtDepth:engine.n_distance atIndex:1]; //mvKillers[n_distance][1];
    nPhase = PHASE_HASH;
    memset(sort_mvs, 0x0, MAX_GEN_MOVES * sizeof(int));   
}

// 得到下一个走法
- (int)next_move
{
    int mv;
    XiangQi *engine = [XiangQi getXiangQi];
    switch (nPhase) {
            // "nPhase"表示着法启发的若干阶段，依次为：
            
            // 0. 置换表着法启发，完成后立即进入下一阶段；
        case PHASE_HASH:
            nPhase = PHASE_KILLER_1;
            if (mvHash != 0) {
                return mvHash;
            }
            // 技巧：这里没有"break"，表示"switch"的上一个"case"执行完后紧接着做下一个"case"，下同
            
            // 1. 杀手着法启发(第一个杀手着法)，完成后立即进入下一阶段；
        case PHASE_KILLER_1:
            nPhase = PHASE_KILLER_2;
            if (mvKiller1 != mvHash && mvKiller1 != 0 && [engine legal_move:mvKiller1]) {
                return mvKiller1;
            }
            
            // 2. 杀手着法启发(第二个杀手着法)，完成后立即进入下一阶段；
        case PHASE_KILLER_2:
            nPhase = PHASE_GEN_MOVES;
            if (mvKiller2 != mvHash && mvKiller2 != 0 && [engine legal_move:mvKiller2]) {
                return mvKiller2;
            }
            
            // 3. 生成所有着法，完成后立即进入下一阶段；
        case PHASE_GEN_MOVES:
            nPhase = PHASE_REST;
            nSortGenMoves = [engine generate_moves:sort_mvs];
            qsort(sort_mvs, nSortGenMoves, sizeof(int), CompareHistoryMove);
            nIndex = 0;
            
            // 4. 对剩余着法做历史表启发；
        case PHASE_REST:
            while (nIndex < nSortGenMoves) {
                mv = sort_mvs[nIndex];
                nIndex ++;
                if (mv != mvHash && mv != mvKiller1 && mv != mvKiller2) {
                    return mv;
                }
            }
            
            // 5. 没有着法了，返回零。
        default:
            return 0;
    }
    
}


@end
