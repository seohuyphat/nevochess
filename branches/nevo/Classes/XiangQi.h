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
#import "ZobristHashGenerator.h"
// other constants
// 最大的生成走法数
#define MAX_GEN_MOVES  128
#define MAX_MOVES 256
// 最大的搜索深度
#define LIMIT_DEPTH  64
// 最高分值，即将死的分值
#define MATE_VALUE  10000 
// 长将判负的分值，低于该值将不写入置换
#define BAN_VALUE (MATE_VALUE - 100)
// 搜索出胜负的分值界限，超出此值就说明已经搜索出杀棋了
#define WIN_VALUE  (MATE_VALUE - 200)
// 和棋时返回的分数(取负值)
#define DRAW_VALUE  20
// 随机性分值
#define RANDOM_MASK  7
// 空步裁剪的子力边界
#define NULL_MARGIN  400 
// 空步裁剪的裁剪深度
#define NULL_DEPTH   2

// 置换表大小
#define HASH_SIZE  (1 << 20)
// ALPHA节点的置换表项
#define HASH_ALPHA  1  
// BETA节点的置换表项
#define HASH_BETA  2
// PV节点的置换表项
#define HASH_PV  3    
// 先行权分值
#define ADVANCED_VALUE  3  

// 获得走法的起点
#define SRC(mv) ((mv) & 255)

// 获得走法的终点
#define DST(mv) ((mv) >> 8)

// 根据起点和终点获得走法
#define MOVE(sqSrc, sqDst) ((sqSrc) + (sqDst) * 256)


// 走法排序阶段
#define PHASE_HASH       0
#define PHASE_KILLER_1   1
#define PHASE_KILLER_2   2
#define PHASE_GEN_MOVES  3
#define PHASE_REST       4

//default search time for iterative-deepening search
#define DEFAULT_SEARCH_TIME 5
//default search depth for iterative-deepening search
#define DEFAULT_SEARCH_DEPTH 5

@class Book;

@interface XiangQi : NSObject {
    int sd_player; //0 - red 1 - black
    unsigned char *ucpc_squares;
    
    int vl_white, vl_black;
    int n_distance; //the plys from root
    int nMoveNum; 
    
    int mvResult;
    
    int search_depth;
    
    int search_time; //secs time for iterative-deepening search
    
    //zobrist table
    ZobristHashGenerator *zobr;
    ZobristHashGenerator *player_zobr;
    ZobristHashGenerator *table[14][256];
    
    //opening book
    Book *book;
    
}

- (void)startup;
- (void)change_side;

- (void)add_piece:(int)pc square:(int)sq;
- (void)del_piece:(int)pc square:(int)sq;

- (int)evaluate;

- (int)move_piece:(int)mv;
- (void)undo_move_piece:(int)mv captured:(int)pcCaptured;
- (BOOL)make_move:(int)mv captured:(int*)pcCaptured;
- (void)undo_make_move:(int)mv captured:(int)pcCaptured;

- (int)generate_moves:(int*)mvs;
- (int)generate_moves:(int*)mvs square:(int)sq;
- (int)generate_moves:(int*)mvs isCaptured:(BOOL)bCapture;

- (BOOL)legal_move:(int)mv;
- (BOOL)checked;
- (BOOL)is_mate;

- (int)search_full_for_depth:(int)nDepth alpha:(int)vlAlpha beta:(int)vlBeta;
- (void)SearchMain;

// quiescent search
- (int)search_quiescent_for_alpha:(int)alpha beta:(int)beta;

// mtdf root search
- (int)search_root_mtdf:(int)depth;
- (int)searchBook;

- (BOOL)null_okay;
- (int)draw_value;
- (int)rep_value:(int)nRepStatus;
- (int)rep_status:(int)nRecur;
- (void)set_best_move:(int)mv depth:(int)nDepth;
- (void)RecordHash:(int)nFlag value:(int)vl depth:(int)nDepth move:(int)mv;
- (int)ProbeHashWithAlpha:(int)vlAlpha beta:(int)vlBeta depth:(int)nDepth move:(int*)mv;
- (int)search_root:(int)nDepth;
- (int)search_quiescent_for_alpha:(int)vlAlpha beta:(int)vlBeta;
- (int)search_full_for_depth:(int)nDepth alpha:(int)vlAlpha beta:(int)vlBeta nonull:(BOOL)bNoNull;
- (void)set_irrev;

- (int)killerMoveAtDepth:(int)depth atIndex:(int)index;

- (int)compare_history_move1:(int*)mv1 move2:(int*)mv2;

- (void)clear_board;
- (void)reset;

//mirror the current positions
- (void)mirror:(XiangQi*)posMirror;

+ (XiangQi*)getXiangQi;

@property (nonatomic, assign) int mvResult;
@property (nonatomic, assign) unsigned char *ucpc_squares;
@property (nonatomic, assign) int nMoveNum; 
@property (nonatomic, readonly) int sd_player;
@property (nonatomic, readonly) int n_distance;
@property (nonatomic, assign) int search_depth;
@property (nonatomic, assign) int search_time;
@property (nonatomic, readonly) ZobristHashGenerator *zobr;
@end

//////////////////////////////////////////////////////////////////////////////
// TODO: Temporarily place the XQWLight Objective-C based AI here.
// !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

#pragma mark -
#pragma mark XQWLight Objective-C based AI

#import "AIEngine.h"

@interface AI_XQWLightObjC : AIEngine
{
    XiangQi *_objcEngine; // The XQWlight Objective-C based AI engine.
}

- (id) init;
- (int) setDifficultyLevel: (int)nAILevel;
- (int) initGame;
- (int) generateMove:(int*)pRow1 fromCol:(int*)pCol1
               toRow:(int*) pRow2 toCol:(int*) pCol2;
- (int) onHumanMove:(int)row1 fromCol:(int)col1
              toRow:(int)row2 toCol:(int)col2;
- (NSString *) getInfo;

@end
///////////////////////////////////////////////////////////////////////////////

