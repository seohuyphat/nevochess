/***************************************************************************
 *  XiangQi Wizard Light Engine - A Very Simple Chinese Chess Engine       *
 *  Designed by Morning Yellow, Version: 0.6, Last Modified: Mar. 2008     *
 *  Copyright (C) 2004-2008 www.elephantbase.net                           *
 *                                                                         *
 *  The engine is rewritten in Objective-C to be extensible in iPhone      *
 *  platform.                                                              *
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

#import "XiangQi.h"
#import "Sort.h"
#import "Book.h"

#include <sys/time.h>
#include <string.h>
#include <stdlib.h>
#include <stdio.h>

// ENABLE MTDF Search
//#define USE_MTDF
//#define ENABLE_DEBUG

// board range
int RANK_TOP = 3;
int RANK_BOTTOM = 12;
int FILE_LEFT = 3;
int FILE_RIGHT = 11;

// piece id
#define PIECE_KING  0
#define PIECE_ADVISOR  1
#define PIECE_BISHOP  2
#define PIECE_KNIGHT  3
#define PIECE_ROOK  4
#define PIECE_CANNON  5
#define PIECE_PAWN  6


// 判断棋子是否在棋盘中的数组
static const char ccInBoard[256] = {
0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0, 0,
0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0, 0,
0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0, 0,
0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0, 0,
0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0, 0,
0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0, 0,
0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0, 0,
0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0, 0,
0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0, 0,
0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0, 0,
0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
};

// 判断棋子是否在九宫的数组
static const char ccInFort[256] = {
0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
0, 0, 0, 0, 0, 0, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0,
0, 0, 0, 0, 0, 0, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0,
0, 0, 0, 0, 0, 0, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0,
0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
0, 0, 0, 0, 0, 0, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0,
0, 0, 0, 0, 0, 0, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0,
0, 0, 0, 0, 0, 0, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0,
0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
};

// 判断步长是否符合特定走法的数组，1=帅(将)，2=仕(士)，3=相(象)
static const char ccLegalSpan[512] = {
0, 0, 0, 0, 0, 0, 0, 0, 0,
0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
0, 0, 0, 0, 0, 3, 0, 0, 0, 3, 0, 0, 0, 0, 0, 0,
0, 0, 0, 0, 0, 0, 2, 1, 2, 0, 0, 0, 0, 0, 0, 0,
0, 0, 0, 0, 0, 0, 1, 0, 1, 0, 0, 0, 0, 0, 0, 0,
0, 0, 0, 0, 0, 0, 2, 1, 2, 0, 0, 0, 0, 0, 0, 0,
0, 0, 0, 0, 0, 3, 0, 0, 0, 3, 0, 0, 0, 0, 0, 0,
0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
0, 0, 0, 0, 0, 0, 0
};

// 根据步长判断马是否蹩腿的数组
static const char ccKnightPin[512] = {
0,  0,  0,  0,  0,  0,  0,  0,  0,
0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,
0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,
0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,
0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,
0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,
0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,
0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,
0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,
0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,
0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,
0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,
0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,
0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,
0,  0,  0,  0,  0,  0,-16,  0,-16,  0,  0,  0,  0,  0,  0,  0,
0,  0,  0,  0,  0, -1,  0,  0,  0,  1,  0,  0,  0,  0,  0,  0,
0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,
0,  0,  0,  0,  0, -1,  0,  0,  0,  1,  0,  0,  0,  0,  0,  0,
0,  0,  0,  0,  0,  0, 16,  0, 16,  0,  0,  0,  0,  0,  0,  0,
0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,
0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,
0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,
0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,
0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,
0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,
0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,
0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,
0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,
0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,
0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,
0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,
0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,
0,  0,  0,  0,  0,  0,  0
};

// 帅(将)的步长
static const char ccKingDelta[4] = {-16, -1, 1, 16};
// 仕(士)的步长
static const char ccAdvisorDelta[4] = {-17, -15, 15, 17};
// 马的步长，以帅(将)的步长作为马腿
static const char ccKnightDelta[4][2] = {{-33, -31}, {-18, 14}, {-14, 18}, {31, 33}};
// 马被将军的步长，以仕(士)的步长作为马腿
static const char ccKnightCheckDelta[4][2] = {{-33, -18}, {-31, -14}, {14, 31}, {18, 33}};

// 棋盘初始设置
static const unsigned char cucpcStartup[256] = {
0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,
0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,
0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,
0,  0,  0, 20, 19, 18, 17, 16, 17, 18, 19, 20,  0,  0,  0,  0,
0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,
0,  0,  0,  0, 21,  0,  0,  0,  0,  0, 21,  0,  0,  0,  0,  0,
0,  0,  0, 22,  0, 22,  0, 22,  0, 22,  0, 22,  0,  0,  0,  0,
0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,
0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,
0,  0,  0, 14,  0, 14,  0, 14,  0, 14,  0, 14,  0,  0,  0,  0,
0,  0,  0,  0, 13,  0,  0,  0,  0,  0, 13,  0,  0,  0,  0,  0,
0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,
0,  0,  0, 12, 11, 10,  9,  8,  9, 10, 11, 12,  0,  0,  0,  0,
0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,
0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,
0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0
};

// 子力位置价值表
static const unsigned char cucvlPiecePos[7][256] = {
{ // 帅(将)
0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,
0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,
0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,
0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,
0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,
0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,
0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,
0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,
0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,
0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,
0,  0,  0,  0,  0,  0,  1,  1,  1,  0,  0,  0,  0,  0,  0,  0,
0,  0,  0,  0,  0,  0,  2,  2,  2,  0,  0,  0,  0,  0,  0,  0,
0,  0,  0,  0,  0,  0, 11, 15, 11,  0,  0,  0,  0,  0,  0,  0,
0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,
0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,
0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0
}, { // 仕(士)
0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,
0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,
0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,
0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,
0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,
0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,
0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,
0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,
0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,
0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,
0,  0,  0,  0,  0,  0, 20,  0, 20,  0,  0,  0,  0,  0,  0,  0,
0,  0,  0,  0,  0,  0,  0, 23,  0,  0,  0,  0,  0,  0,  0,  0,
0,  0,  0,  0,  0,  0, 20,  0, 20,  0,  0,  0,  0,  0,  0,  0,
0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,
0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,
0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0
}, { // 相(象)
0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,
0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,
0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,
0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,
0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,
0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,
0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,
0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,
0,  0,  0,  0,  0, 20,  0,  0,  0, 20,  0,  0,  0,  0,  0,  0,
0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,
0,  0,  0, 18,  0,  0,  0, 23,  0,  0,  0, 18,  0,  0,  0,  0,
0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,
0,  0,  0,  0,  0, 20,  0,  0,  0, 20,  0,  0,  0,  0,  0,  0,
0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,
0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,
0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0
}, { // 马
0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,
0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,
0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,
0,  0,  0, 90, 90, 90, 96, 90, 96, 90, 90, 90,  0,  0,  0,  0,
0,  0,  0, 90, 96,103, 97, 94, 97,103, 96, 90,  0,  0,  0,  0,
0,  0,  0, 92, 98, 99,103, 99,103, 99, 98, 92,  0,  0,  0,  0,
0,  0,  0, 93,108,100,107,100,107,100,108, 93,  0,  0,  0,  0,
0,  0,  0, 90,100, 99,103,104,103, 99,100, 90,  0,  0,  0,  0,
0,  0,  0, 90, 98,101,102,103,102,101, 98, 90,  0,  0,  0,  0,
0,  0,  0, 92, 94, 98, 95, 98, 95, 98, 94, 92,  0,  0,  0,  0,
0,  0,  0, 93, 92, 94, 95, 92, 95, 94, 92, 93,  0,  0,  0,  0,
0,  0,  0, 85, 90, 92, 93, 78, 93, 92, 90, 85,  0,  0,  0,  0,
0,  0,  0, 88, 85, 90, 88, 90, 88, 90, 85, 88,  0,  0,  0,  0,
0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,
0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,
0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0
}, { // 车
0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,
0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,
0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,
0,  0,  0,206,208,207,213,214,213,207,208,206,  0,  0,  0,  0,
0,  0,  0,206,212,209,216,233,216,209,212,206,  0,  0,  0,  0,
0,  0,  0,206,208,207,214,216,214,207,208,206,  0,  0,  0,  0,
0,  0,  0,206,213,213,216,216,216,213,213,206,  0,  0,  0,  0,
0,  0,  0,208,211,211,214,215,214,211,211,208,  0,  0,  0,  0,
0,  0,  0,208,212,212,214,215,214,212,212,208,  0,  0,  0,  0,
0,  0,  0,204,209,204,212,214,212,204,209,204,  0,  0,  0,  0,
0,  0,  0,198,208,204,212,212,212,204,208,198,  0,  0,  0,  0,
0,  0,  0,200,208,206,212,200,212,206,208,200,  0,  0,  0,  0,
0,  0,  0,194,206,204,212,200,212,204,206,194,  0,  0,  0,  0,
0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,
0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,
0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0
}, { // 炮
0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,
0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,
0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,
0,  0,  0,100,100, 96, 91, 90, 91, 96,100,100,  0,  0,  0,  0,
0,  0,  0, 98, 98, 96, 92, 89, 92, 96, 98, 98,  0,  0,  0,  0,
0,  0,  0, 97, 97, 96, 91, 92, 91, 96, 97, 97,  0,  0,  0,  0,
0,  0,  0, 96, 99, 99, 98,100, 98, 99, 99, 96,  0,  0,  0,  0,
0,  0,  0, 96, 96, 96, 96,100, 96, 96, 96, 96,  0,  0,  0,  0,
0,  0,  0, 95, 96, 99, 96,100, 96, 99, 96, 95,  0,  0,  0,  0,
0,  0,  0, 96, 96, 96, 96, 96, 96, 96, 96, 96,  0,  0,  0,  0,
0,  0,  0, 97, 96,100, 99,101, 99,100, 96, 97,  0,  0,  0,  0,
0,  0,  0, 96, 97, 98, 98, 98, 98, 98, 97, 96,  0,  0,  0,  0,
0,  0,  0, 96, 96, 97, 99, 99, 99, 97, 96, 96,  0,  0,  0,  0,
0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,
0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,
0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0
}, { // 兵(卒)
0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,
0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,
0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,
0,  0,  0,  9,  9,  9, 11, 13, 11,  9,  9,  9,  0,  0,  0,  0,
0,  0,  0, 19, 24, 34, 42, 44, 42, 34, 24, 19,  0,  0,  0,  0,
0,  0,  0, 19, 24, 32, 37, 37, 37, 32, 24, 19,  0,  0,  0,  0,
0,  0,  0, 19, 23, 27, 29, 30, 29, 27, 23, 19,  0,  0,  0,  0,
0,  0,  0, 14, 18, 20, 27, 29, 27, 20, 18, 14,  0,  0,  0,  0,
0,  0,  0,  7,  0, 13,  0, 16,  0, 13,  0,  7,  0,  0,  0,  0,
0,  0,  0,  7,  0,  7,  0, 15,  0,  7,  0,  7,  0,  0,  0,  0,
0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,
0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,
0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,
0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,
0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,
0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0
}
};

// 判断棋子是否在棋盘中
BOOL IN_BOARD(int sq) {
    return ccInBoard[sq] != 0;
}

// 判断棋子是否在九宫中
BOOL IN_FORT(int sq) {
    return ccInFort[sq] != 0;
}

// 获得格子的横坐标
int RANK_Y(int sq) {
    return sq >> 4;
}

// 获得格子的纵坐标
int FILE_X(int sq) {
    return sq & 15;
}

// 根据纵坐标和横坐标获得格子
int COORD_XY(int x, int y) {
    return x + (y << 4);
}

// 翻转格子
int SQUARE_FLIP(int sq) {
    return 254 - sq;
}

// 纵坐标水平镜像
int FILE_FLIP(int x) {
    return 14 - x;
}

// 横坐标垂直镜像
int RANK_FLIP(int y) {
    return 15 - y;
}

// 格子水平镜像
int MIRROR_SQUARE(int sq) {
    return COORD_XY(FILE_FLIP(FILE_X(sq)), RANK_Y(sq));
}

// 格子水平镜像
int SQUARE_FORWARD(int sq, int sd) {
    return sq - 16 + (sd << 5);
}

// 走法是否符合帅(将)的步长
BOOL KING_SPAN(int sqSrc, int sqDst) {
    return ccLegalSpan[sqDst - sqSrc + 256] == 1;
}

// 走法是否符合仕(士)的步长
BOOL ADVISOR_SPAN(int sqSrc, int sqDst) {
    return ccLegalSpan[sqDst - sqSrc + 256] == 2;
}

// 走法是否符合相(象)的步长
BOOL BISHOP_SPAN(int sqSrc, int sqDst) {
    return ccLegalSpan[sqDst - sqSrc + 256] == 3;
}

// 相(象)眼的位置
int BISHOP_PIN(int sqSrc, int sqDst) {
    return (sqSrc + sqDst) >> 1;
}

// 马腿的位置
int KNIGHT_PIN(int sqSrc, int sqDst) {
    return sqSrc + ccKnightPin[sqDst - sqSrc + 256];
}

// 是否未过河
BOOL HOME_HALF(int sq, int sd) {
    return (sq & 0x80) != (sd << 7);
}

// 是否已过河
BOOL AWAY_HALF(int sq, int sd) {
    return (sq & 0x80) == (sd << 7);
}

// 是否在河的同一边
BOOL SAME_HALF(int sqSrc, int sqDst) {
    return ((sqSrc ^ sqDst) & 0x80) == 0;
}

// 是否在同一行
BOOL SAME_RANK(int sqSrc, int sqDst) {
    return ((sqSrc ^ sqDst) & 0xf0) == 0;
}

// 是否在同一列
BOOL SAME_FILE(int sqSrc, int sqDst) {
    return ((sqSrc ^ sqDst) & 0x0f) == 0;
}

// 获得红黑标记(红子是8，黑子是16)
int SIDE_TAG(int sd) {
    return 8 + (sd << 3);
}

// 获得对方红黑标记
int OPP_SIDE_TAG(int sd) {
    return 16 - (sd << 3);
}


// 走法水平镜像
int MIRROR_MOVE(int mv) {
    return MOVE(MIRROR_SQUARE(SRC(mv)), MIRROR_SQUARE(DST(mv)));
}

static XiangQi *xiangqi;
static int nHistoryTable[65536];

// "qsort"按历史表排序的比较函数
static int CompareHistory(const void *lpmv1, const void *lpmv2) {
    return nHistoryTable[*(int *) lpmv2] - nHistoryTable[*(int *) lpmv1];
}



// 历史走法信息(占4字节)
typedef struct _MoveStruct {
    unsigned short wmv;
    unsigned char ucpcCaptured, ucbCheck;
    unsigned int dwKey;
}MoveStruct; // mvs

static void set_move_history(MoveStruct *mv_history, int mv, int pcCaptured, BOOL bCheck, unsigned int dwKey_) {
    mv_history->wmv = mv;
    mv_history->ucpcCaptured = pcCaptured;
    mv_history->ucbCheck = bCheck;
    mv_history->dwKey = dwKey_;
}

static MoveStruct mvsList[MAX_MOVES];  // 历史走法信息列表



// 置换表项结构
typedef struct _HashItem {
    unsigned char ucDepth, ucFlag;
    short svl;
    unsigned short wmv, wReserved;
    unsigned int dwLock0, dwLock1;
}HashItem;

static int mvKillers[LIMIT_DEPTH][2]; // 杀手走法表
static HashItem HashTable[HASH_SIZE]; // 置换表

// MVV/LVA每种子力的价值
static unsigned char cucMvvLva[24] = {
0, 0, 0, 0, 0, 0, 0, 0,
5, 1, 1, 3, 4, 3, 2, 0,
5, 1, 1, 3, 4, 3, 2, 0
};

// 求MVV/LVA值
static int MvvLva(int mv)
{
    return (cucMvvLva[xiangqi.ucpc_squares[DST(mv)]] << 3) - cucMvvLva[xiangqi.ucpc_squares[SRC(mv)]];
}

// "qsort"按MVV/LVA值排序的比较函数
static int CompareMvvLva(const void *lpmv1, const void *lpmv2) {
    return MvvLva(*(int*)lpmv2) - MvvLva(*(int*)lpmv1);
}

static int CompareBook(const void *lpbk1, const void *lpbk2) {
    unsigned int dw1, dw2;
    dw1 = ((BookItem *) lpbk1)->dwLock;
    dw2 = ((BookItem *) lpbk2)->dwLock;
    return dw1 > dw2 ? 1 : dw1 < dw2 ? -1 : 0;
}


#define GEN_CAPTURE  TRUE
#define NO_NULL  TRUE

@implementation XiangQi

@synthesize mvResult;
@synthesize ucpc_squares;
@synthesize nMoveNum;
@synthesize sd_player;
@synthesize n_distance;
@synthesize search_depth;
@synthesize search_time;
@synthesize zobr;

- (void)dealloc
{
    free(ucpc_squares);
    [zobr release];
    [player_zobr release];
    for (int i = 0; i < 14; i ++) {
        for (int j = 0; j < 256; j ++) {
            [table[i][j] release];
        }
    }
    [book release];
    [super dealloc];
}

- (id)init
{
    self = [super init];
    [self startup];
    return self;
    
}

// 初始化Zobrist表
- (void)init_zobrist
{
    int i, j;
    RC4Generator *rc4 = [[RC4Generator alloc] init];
    player_zobr = [[ZobristHashGenerator alloc] init];
    zobr = [[ZobristHashGenerator alloc] init];
    [rc4 initZero];
    [player_zobr initRC4:rc4];
    for (i = 0; i < 14; i ++) {
        for (j = 0; j < 256; j ++) {
            table[i][j] = [[ZobristHashGenerator alloc] init];
            [table[i][j] initRC4:rc4];
        }
    }
    [rc4 release];
}

- (void)clear_board
{
    sd_player = vl_white = vl_black = n_distance = 0;
    memset(ucpc_squares, 0, 256);
    [zobr initZero];    
}

- (void)reset
{
    int sq, pc;
    [self clear_board];
    for(sq = 0; sq < 256; sq ++) {
        pc = cucpcStartup[sq];
        if(pc !=0) {
            [self add_piece:pc square:sq];
        }
    }
    [self set_irrev];
}

- (void)set_irrev
{           
    // 清空(初始化)历史走法信息
    set_move_history(&mvsList[0], 0, 0, [self checked], zobr.dwKey);
    nMoveNum = 1;
}

- (void)startup
{
    int sq, pc;
    //default search depth 
    search_depth = DEFAULT_SEARCH_DEPTH;
    search_time = DEFAULT_SEARCH_TIME;
    ucpc_squares = malloc(256 * sizeof(unsigned char));
    memset(ucpc_squares, 0, 256 * sizeof(unsigned char));
    memset(mvsList, 0x0, sizeof(MoveStruct) * MAX_MOVES);
    //load book
    book = [[Book alloc] initWithBook:@"BOOK.DAT"];
    [self init_zobrist];
    [self clear_board];
    for(sq = 0; sq < 256; sq ++) {
        pc = cucpcStartup[sq];
        if(pc !=0) {
            [self add_piece:pc square:sq];
        }
    }
    [self set_irrev];
}

- (void)change_side
{
    sd_player = 1 - sd_player;
    [zobr Xor:player_zobr];
}

- (void)add_piece:(int)pc square:(int)sq
{
    ucpc_squares[sq] = pc;
    if(pc < 16) {
        vl_white += cucvlPiecePos[pc - 8][sq];
        [zobr Xor:table[pc - 8][sq]];
    } else {
        vl_black += cucvlPiecePos[pc - 16][SQUARE_FLIP(sq)];
        [zobr Xor:table[pc - 9][sq]];
    }
}

- (void)del_piece:(int)pc square:(int)sq
{
    ucpc_squares[sq] = 0;
    if(pc < 16) {
        vl_white -= cucvlPiecePos[pc - 8][sq];
        [zobr Xor:table[pc - 8][sq]];
    } else {
        vl_black -= cucvlPiecePos[pc - 16][SQUARE_FLIP(sq)];
        [zobr Xor:table[pc - 9][sq]];
    }
}

- (int)evaluate {
    return ((sd_player == 0) ? vl_white - vl_black : vl_black - vl_white) + ADVANCED_VALUE;
}

- (int)move_piece:(int)mv
{
    int sqSrc, sqDst, pc, pcCaptured;
    sqSrc = SRC(mv);
    sqDst = DST(mv);
    pcCaptured = ucpc_squares[sqDst];
    if(pcCaptured != 0) {
        [self del_piece:pcCaptured square:sqDst];
    }
    
    pc = ucpc_squares[sqSrc];
    [self del_piece:pc square:sqSrc];
    [self add_piece:pc square:sqDst];
    return pcCaptured;
}

- (void)undo_move_piece:(int)mv captured:(int)pcCaptured
{
    int sqSrc, sqDst, pc;
    sqSrc = SRC(mv);
    sqDst = DST(mv);
    pc = ucpc_squares[sqDst];
    [self del_piece:pc square:sqDst];
    [self add_piece:pc square:sqSrc];
    if (pcCaptured != 0) {
        [self add_piece:pcCaptured square:sqDst];
    }    
}

- (BOOL)make_move:(int)mv captured:(int*)pcCaptured
{
    unsigned int dwKey;
    
    dwKey = zobr.dwKey;
    *pcCaptured = [self move_piece:mv];
    if ([self checked]) {
        [self undo_move_piece:mv captured:*pcCaptured];
        return FALSE;
    }
    [self change_side];
    set_move_history(&mvsList[nMoveNum], mv, *pcCaptured, [self checked], dwKey);
    nMoveNum ++;
    n_distance ++;
    return TRUE;  
}

- (BOOL)make_move:(int)mv
{
    int pcCaptured;
    unsigned int dwKey;
    
    dwKey = zobr.dwKey;
    pcCaptured = [self move_piece:mv];
    if ([self checked]) {
        [self undo_move_piece:mv captured:pcCaptured];
        return FALSE;
    }
    [self change_side];
    set_move_history(&mvsList[nMoveNum], mv, pcCaptured, [self checked], dwKey);
    nMoveNum ++;
    n_distance ++;
    return TRUE;   
}

- (void)null_move
{                       
    // 走一步空步
    unsigned int dwKey;
    dwKey = zobr.dwKey;
    [self change_side];
    set_move_history(&mvsList[nMoveNum], 0, 0, FALSE, dwKey);
    nMoveNum ++;
    n_distance ++;
}

- (void)undo_null_move
{                   
    // 撤消走一步空步
    n_distance --;
    nMoveNum --;
    [self change_side];
}


- (void)undo_make_move
{
    nMoveNum --;
    [self undo_make_move:mvsList[nMoveNum].wmv captured:mvsList[nMoveNum].ucpcCaptured];
}

- (void)undo_make_move:(int)mv captured:(int)pcCaptured
{
    n_distance --;
    [self change_side];
    [self undo_move_piece:mv captured:pcCaptured];
}

- (int)generate_moves:(int*)mvs
{
    return [self generate_moves:mvs isCaptured:FALSE];
}

- (int)generate_moves:(int*)mvs square:(int)sqSrc
{
    int i, j, nGenMoves, nDelta, sqDst;
    int pcSelfSide, pcOppSide, pcSrc, pcDst;
    // 生成所有走法，需要经过以下几个步骤：
    
    nGenMoves = 0;
    pcSelfSide = SIDE_TAG(sd_player);
    pcOppSide = OPP_SIDE_TAG(sd_player);
    if (sqSrc > 0 && sqSrc < 256) {
        
        // 1. 找到一个本方棋子，再做以下判断：
        pcSrc = ucpc_squares[sqSrc];
        if ((pcSrc & pcSelfSide) == 0) {
            goto ret;
        }
        
        // 2. 根据棋子确定走法
        switch (pcSrc - pcSelfSide) {
            case PIECE_KING:
                for (i = 0; i < 4; i ++) {
                    sqDst = sqSrc + ccKingDelta[i];
                    if (!IN_FORT(sqDst)) {
                        continue;
                    }
                    pcDst = ucpc_squares[sqDst];
                    if ((pcDst & pcSelfSide) == 0) {
                        mvs[nGenMoves] = MOVE(sqSrc, sqDst);
                        nGenMoves ++;
                    }
                }
                break;
            case PIECE_ADVISOR:
                for (i = 0; i < 4; i ++) {
                    sqDst = sqSrc + ccAdvisorDelta[i];
                    if (!IN_FORT(sqDst)) {
                        continue;
                    }
                    pcDst = ucpc_squares[sqDst];
                    if ((pcDst & pcSelfSide) == 0) {
                        mvs[nGenMoves] = MOVE(sqSrc, sqDst);
                        nGenMoves ++;
                    }
                }
                break;
            case PIECE_BISHOP:
                for (i = 0; i < 4; i ++) {
                    sqDst = sqSrc + ccAdvisorDelta[i];
                    if (!(IN_BOARD(sqDst) && HOME_HALF(sqDst, sd_player) && ucpc_squares[sqDst] == 0)) {
                        continue;
                    }
                    sqDst += ccAdvisorDelta[i];
                    pcDst = ucpc_squares[sqDst];
                    if ((pcDst & pcSelfSide) == 0) {
                        mvs[nGenMoves] = MOVE(sqSrc, sqDst);
                        nGenMoves ++;
                    }
                }
                break;
            case PIECE_KNIGHT:
                for (i = 0; i < 4; i ++) {
                    sqDst = sqSrc + ccKingDelta[i];
                    if (ucpc_squares[sqDst] != 0) {
                        continue;
                    }
                    for (j = 0; j < 2; j ++) {
                        sqDst = sqSrc + ccKnightDelta[i][j];
                        if (!IN_BOARD(sqDst)) {
                            continue;
                        }
                        pcDst = ucpc_squares[sqDst];
                        if ((pcDst & pcSelfSide) == 0) {
                            mvs[nGenMoves] = MOVE(sqSrc, sqDst);
                            nGenMoves ++;
                        }
                    }
                }
                break;
            case PIECE_ROOK:
                for (i = 0; i < 4; i ++) {
                    nDelta = ccKingDelta[i];
                    sqDst = sqSrc + nDelta;
                    while (IN_BOARD(sqDst)) {
                        pcDst = ucpc_squares[sqDst];
                        if (pcDst == 0) {
                            mvs[nGenMoves] = MOVE(sqSrc, sqDst);
                            nGenMoves ++;
                        } else {
                            if ((pcDst & pcOppSide) != 0) {
                                mvs[nGenMoves] = MOVE(sqSrc, sqDst);
                                nGenMoves ++;
                            }
                            break;
                        }
                        sqDst += nDelta;
                    }
                }
                break;
            case PIECE_CANNON:
                for (i = 0; i < 4; i ++) {
                    nDelta = ccKingDelta[i];
                    sqDst = sqSrc + nDelta;
                    while (IN_BOARD(sqDst)) {
                        pcDst = ucpc_squares[sqDst];
                        if (pcDst == 0) {
                            mvs[nGenMoves] = MOVE(sqSrc, sqDst);
                            nGenMoves ++;
                        } else {
                            break;
                        }
                        sqDst += nDelta;
                    }
                    sqDst += nDelta;
                    while (IN_BOARD(sqDst)) {
                        pcDst = ucpc_squares[sqDst];
                        if (pcDst != 0) {
                            if ((pcDst & pcOppSide) != 0) {
                                mvs[nGenMoves] = MOVE(sqSrc, sqDst);
                                nGenMoves ++;
                            }
                            break;
                        }
                        sqDst += nDelta;
                    }
                }
                break;
            case PIECE_PAWN:
                sqDst = SQUARE_FORWARD(sqSrc, sd_player);
                if (IN_BOARD(sqDst)) {
                    pcDst = ucpc_squares[sqDst];
                    if ((pcDst & pcSelfSide) == 0) {
                        mvs[nGenMoves] = MOVE(sqSrc, sqDst);
                        nGenMoves ++;
                    }
                }
                if (AWAY_HALF(sqSrc, sd_player)) {
                    for (nDelta = -1; nDelta <= 1; nDelta += 2) {
                        sqDst = sqSrc + nDelta;
                        if (IN_BOARD(sqDst)) {
                            pcDst = ucpc_squares[sqDst];
                            if ((pcDst & pcSelfSide) == 0) {
                                mvs[nGenMoves] = MOVE(sqSrc, sqDst);
                                nGenMoves ++;
                            }
                        }
                    }
                }
                break;
        }
    }
    
ret:
    return nGenMoves;    
}

- (int)generate_moves:(int*)mvs isCaptured:(BOOL)bCapture
{
    int i, j, nGenMoves, nDelta, sqSrc, sqDst;
    int pcSelfSide, pcOppSide, pcSrc, pcDst;
    // 生成3所有走法，需要经过以下几个步骤：
    
    nGenMoves = 0;
    pcSelfSide = SIDE_TAG(sd_player);
    pcOppSide = OPP_SIDE_TAG(sd_player);
    for (sqSrc = 0; sqSrc < 256; sqSrc ++) {
        
        // 1. 找到一个本方棋子，再做以下判断：
        pcSrc = ucpc_squares[sqSrc];
        if ((pcSrc & pcSelfSide) == 0) {
            continue;
        }
        
        // 2. 根据棋子确定走法
        switch (pcSrc - pcSelfSide) {
            case PIECE_KING:
                for (i = 0; i < 4; i ++) {
                    sqDst = sqSrc + ccKingDelta[i];
                    if (!IN_FORT(sqDst)) {
                        continue;
                    }
                    pcDst = ucpc_squares[sqDst];
                    if (bCapture ? (pcDst & pcOppSide) != 0 : (pcDst & pcSelfSide) == 0) {
                        mvs[nGenMoves] = MOVE(sqSrc, sqDst);
                        nGenMoves ++;
                    }
                }
                break;
            case PIECE_ADVISOR:
                for (i = 0; i < 4; i ++) {
                    sqDst = sqSrc + ccAdvisorDelta[i];
                    if (!IN_FORT(sqDst)) {
                        continue;
                    }
                    pcDst = ucpc_squares[sqDst];
                    if (bCapture ? (pcDst & pcOppSide) != 0 : (pcDst & pcSelfSide) == 0) {
                        mvs[nGenMoves] = MOVE(sqSrc, sqDst);
                        nGenMoves ++;
                    }
                }
                break;
            case PIECE_BISHOP:
                for (i = 0; i < 4; i ++) {
                    sqDst = sqSrc + ccAdvisorDelta[i];
                    if (!(IN_BOARD(sqDst) && HOME_HALF(sqDst, sd_player) && ucpc_squares[sqDst] == 0)) {
                        continue;
                    }
                    sqDst += ccAdvisorDelta[i];
                    pcDst = ucpc_squares[sqDst];
                    if (bCapture ? (pcDst & pcOppSide) != 0 : (pcDst & pcSelfSide) == 0) {
                        mvs[nGenMoves] = MOVE(sqSrc, sqDst);
                        nGenMoves ++;
                    }
                }
                break;
            case PIECE_KNIGHT:
                for (i = 0; i < 4; i ++) {
                    sqDst = sqSrc + ccKingDelta[i];
                    if (ucpc_squares[sqDst] != 0) {
                        continue;
                    }
                    for (j = 0; j < 2; j ++) {
                        sqDst = sqSrc + ccKnightDelta[i][j];
                        if (!IN_BOARD(sqDst)) {
                            continue;
                        }
                        pcDst = ucpc_squares[sqDst];
                        if (bCapture ? (pcDst & pcOppSide) != 0 : (pcDst & pcSelfSide) == 0) {
                            mvs[nGenMoves] = MOVE(sqSrc, sqDst);
                            nGenMoves ++;
                        }
                    }
                }
                break;
            case PIECE_ROOK:
                for (i = 0; i < 4; i ++) {
                    nDelta = ccKingDelta[i];
                    sqDst = sqSrc + nDelta;
                    while (IN_BOARD(sqDst)) {
                        pcDst = ucpc_squares[sqDst];
                        if (pcDst == 0) {
                            if (!bCapture) {
                                mvs[nGenMoves] = MOVE(sqSrc, sqDst);
                                nGenMoves ++;
                            }
                        } else {
                            if ((pcDst & pcOppSide) != 0) {
                                mvs[nGenMoves] = MOVE(sqSrc, sqDst);
                                nGenMoves ++;
                            }
                            break;
                        }
                        sqDst += nDelta;
                    }
                }
                break;
            case PIECE_CANNON:
                for (i = 0; i < 4; i ++) {
                    nDelta = ccKingDelta[i];
                    sqDst = sqSrc + nDelta;
                    while (IN_BOARD(sqDst)) {
                        pcDst = ucpc_squares[sqDst];
                        if (pcDst == 0) {
                            if (!bCapture) {
                                mvs[nGenMoves] = MOVE(sqSrc, sqDst);
                                nGenMoves ++;
                            }
                        } else {
                            break;
                        }
                        sqDst += nDelta;
                    }
                    sqDst += nDelta;
                    while (IN_BOARD(sqDst)) {
                        pcDst = ucpc_squares[sqDst];
                        if (pcDst != 0) {
                            if ((pcDst & pcOppSide) != 0) {
                                mvs[nGenMoves] = MOVE(sqSrc, sqDst);
                                nGenMoves ++;
                            }
                            break;
                        }
                        sqDst += nDelta;
                    }
                }
                break;
            case PIECE_PAWN:
                sqDst = SQUARE_FORWARD(sqSrc, sd_player);
                if (IN_BOARD(sqDst)) {
                    pcDst = ucpc_squares[sqDst];
                    if (bCapture ? (pcDst & pcOppSide) != 0 : (pcDst & pcSelfSide) == 0) {
                        mvs[nGenMoves] = MOVE(sqSrc, sqDst);
                        nGenMoves ++;
                    }
                }
                if (AWAY_HALF(sqSrc, sd_player)) {
                    for (nDelta = -1; nDelta <= 1; nDelta += 2) {
                        sqDst = sqSrc + nDelta;
                        if (IN_BOARD(sqDst)) {
                            pcDst = ucpc_squares[sqDst];
                            if (bCapture ? (pcDst & pcOppSide) != 0 : (pcDst & pcSelfSide) == 0) {
                                mvs[nGenMoves] = MOVE(sqSrc, sqDst);
                                nGenMoves ++;
                            }
                        }
                    }
                }
                break;
        }
    }
    return nGenMoves;   
}

- (BOOL)legal_move:(int)mv
{
    int sqSrc, sqDst, sqPin;
    int pcSelfSide, pcSrc, pcDst, nDelta;
    // 判断走法是否合法，需要经过以下的判断过程：
    
    // 1. 判断起始格是否有自己的棋子
    sqSrc = SRC(mv);
    pcSrc = ucpc_squares[sqSrc];
    pcSelfSide = SIDE_TAG(sd_player);
    if ((pcSrc & pcSelfSide) == 0) {
        return FALSE;
    }
    
    // 2. 判断目标格是否有自己的棋子
    sqDst = DST(mv);
    pcDst = ucpc_squares[sqDst];
    if ((pcDst & pcSelfSide) != 0) {
        return FALSE;
    }
    
    // 3. 根据棋子的类型检查走法是否合理
    switch (pcSrc - pcSelfSide) {
        case PIECE_KING:
            return IN_FORT(sqDst) && KING_SPAN(sqSrc, sqDst);
        case PIECE_ADVISOR:
            return IN_FORT(sqDst) && ADVISOR_SPAN(sqSrc, sqDst);
        case PIECE_BISHOP:
            return SAME_HALF(sqSrc, sqDst) && BISHOP_SPAN(sqSrc, sqDst) &&
            ucpc_squares[BISHOP_PIN(sqSrc, sqDst)] == 0;
        case PIECE_KNIGHT:
            sqPin = KNIGHT_PIN(sqSrc, sqDst);
            return sqPin != sqSrc && ucpc_squares[sqPin] == 0;
        case PIECE_ROOK:
        case PIECE_CANNON:
            if (SAME_RANK(sqSrc, sqDst)) {
                nDelta = (sqDst < sqSrc ? -1 : 1);
            } else if (SAME_FILE(sqSrc, sqDst)) {
                nDelta = (sqDst < sqSrc ? -16 : 16);
            } else {
                return FALSE;
            }
            sqPin = sqSrc + nDelta;
            while (sqPin != sqDst && ucpc_squares[sqPin] == 0) {
                sqPin += nDelta;
            }
            if (sqPin == sqDst) {
                return pcDst == 0 || pcSrc - pcSelfSide == PIECE_ROOK;
            } else if (pcDst != 0 && pcSrc - pcSelfSide == PIECE_CANNON) {
                sqPin += nDelta;
                while (sqPin != sqDst && ucpc_squares[sqPin] == 0) {
                    sqPin += nDelta;
                }
                return sqPin == sqDst;
            } else {
                return FALSE;
            }
        case PIECE_PAWN:
            if (AWAY_HALF(sqDst, sd_player) && (sqDst == sqSrc - 1 || sqDst == sqSrc + 1)) {
                return TRUE;
            }
            return sqDst == SQUARE_FORWARD(sqSrc, sd_player);
        default:
            return FALSE;
    }
}
- (BOOL)checked
{
    int i, j, sqSrc, sqDst;
    int pcSelfSide, pcOppSide, pcDst, nDelta;
    pcSelfSide = SIDE_TAG(sd_player);
    pcOppSide = OPP_SIDE_TAG(sd_player);
    // 找到棋盘上的帅(将)，再做以下判断：
    
    for (sqSrc = 0; sqSrc < 256; sqSrc ++) {
        if (ucpc_squares[sqSrc] != pcSelfSide + PIECE_KING) {
            continue;
        }
        
        // 1. 判断是否被对方的兵(卒)将军
        if (ucpc_squares[SQUARE_FORWARD(sqSrc, sd_player)] == pcOppSide + PIECE_PAWN) {
            return TRUE;
        }
        for (nDelta = -1; nDelta <= 1; nDelta += 2) {
            if (ucpc_squares[sqSrc + nDelta] == pcOppSide + PIECE_PAWN) {
                return TRUE;
            }
        }
        
        // 2. 判断是否被对方的马将军(以仕(士)的步长当作马腿)
        for (i = 0; i < 4; i ++) {
            if (ucpc_squares[sqSrc + ccAdvisorDelta[i]] != 0) {
                continue;
            }
            for (j = 0; j < 2; j ++) {
                pcDst = ucpc_squares[sqSrc + ccKnightCheckDelta[i][j]];
                if (pcDst == pcOppSide + PIECE_KNIGHT) {
                    return TRUE;
                }
            }
        }
        
        // 3. 判断是否被对方的车或炮将军(包括将帅对脸)
        for (i = 0; i < 4; i ++) {
            nDelta = ccKingDelta[i];
            sqDst = sqSrc + nDelta;
            while (IN_BOARD(sqDst)) {
                pcDst = ucpc_squares[sqDst];
                if (pcDst != 0) {
                    if (pcDst == pcOppSide + PIECE_ROOK || pcDst == pcOppSide + PIECE_KING) {
                        return TRUE;
                    }
                    break;
                }
                sqDst += nDelta;
            }
            sqDst += nDelta;
            while (IN_BOARD(sqDst)) {
                int pcDst = ucpc_squares[sqDst];
                if (pcDst != 0) {
                    if (pcDst == pcOppSide + PIECE_CANNON) {
                        return TRUE;
                    }
                    break;
                }
                sqDst += nDelta;
            }
        }
        return FALSE;
    }
    return FALSE;
}

- (BOOL)is_mate
{
    int i, nGenMoveNum, pcCaptured;
    int mvs[MAX_GEN_MOVES];
    memset(mvs, 0x0, MAX_GEN_MOVES * sizeof(int));
    nGenMoveNum = [self generate_moves:mvs];
    for (i = 0; i < nGenMoveNum; i ++) {
        pcCaptured = [self move_piece:mvs[i]];
        if (![self checked]) {
            [self undo_move_piece:mvs[i] captured:pcCaptured];
            return FALSE;
        } else {
            [self undo_move_piece:mvs[i] captured:pcCaptured];
        }
    }
    return TRUE;
}

- (BOOL)in_check
{
    return mvsList[nMoveNum - 1].ucbCheck;
}

- (BOOL)captured
{
    return mvsList[nMoveNum - 1].ucpcCaptured != 0;
}


// iterative-deepening search
- (void)SearchMain 
{
    int i, t, nGenMoves;
    int vl;
    int mvs[MAX_GEN_MOVES];
    memset(mvs, 0x0, MAX_GEN_MOVES * sizeof(int));
    // initialize
    memset(nHistoryTable, 0, 65536 * sizeof(int)); // clear history table
    memset(mvKillers, 0, LIMIT_DEPTH * 2 * sizeof(int)); // clear killer move table
    memset(HashTable, 0, HASH_SIZE * sizeof(HashItem));  // clear TT
    t = clock();       // initialize timer
    n_distance = 0; // initialize steps
    
    // search opening book
    mvResult = [self searchBook];
#ifdef ENABLE_DEBUG_OBJC
    {
        NSLog(@"[XQWlightObjc]SearchBook Result : %d", mvResult);
    }
#endif
    if (mvResult != 0) {
#ifdef ENABLE_DEBUG
        printf("[%s] get one move in open book\n", __func__);
#endif
        [self make_move:mvResult];
        if ([self rep_status:3] == 0) {
            [self undo_make_move];
            return;
        }
        [self undo_make_move];
    }
    
    // check if we have only one move to go
    vl = 0;
    nGenMoves = [self generate_moves:mvs];
#ifdef ENABLE_DEBUG_OBJC
    {
        NSLog(@"[XQWlightObjc] generate %d moves\n", nGenMoves);
    }
#endif
    for (i = 0; i < nGenMoves; i ++) {
        if ([self make_move:mvs[i]]) {
            [self undo_make_move];
            mvResult = mvs[i];
            vl ++;
        }
    }
    if (vl == 1) {
        return;
    }
    
    // iterative-deepen search
    for (i = 1; i <= search_depth; i ++) {
#ifdef ENABLE_DEBUG
        printf("[%s]search %d (%d) depth\n", __func__, i, search_depth);
#endif
        vl = [self search_root:i];
#ifdef ENABLE_DEBUG_OBJC
        {
            NSLog(@"[XQWlightObjc] SearchRoot ret : %d", vl);
        }
#endif
        // search to capture then quit search
        if (vl > WIN_VALUE || vl < -WIN_VALUE) {
            break;
        }
        // timeout
        if (clock() - t > search_time * CLOCKS_PER_SEC) {
            break;
        }
    }
}

- (int)search_full_for_depth:(int)nDepth alpha:(int)vlAlpha beta:(int)vlBeta nonull:(BOOL)bNoNull
{
    int nHashFlag, nNewDepth;
    int mv, mvBest;
    int vl, vlBest;
    int mHash = 0;
    Sort *sort;
    // 一个Alpha-Beta完全搜索分为以下几个阶段
    
    // 1. 到达水平线，则调用静态搜索(注意：由于空步裁剪，深度可能小于零)
    if (nDepth <= 0) {
        return [self search_quiescent_for_alpha:vlAlpha beta:vlBeta];
    }
    
    // 1-1. 检查重复局面(注意：不要在根节点检查，否则就没有走法了)
    vl = [self rep_status:1];
    if (vl != 0) {
        return [self rep_value:vl];
    }
    
    // 1-2. 到达极限深度就返回局面评价
    if (n_distance == search_depth) {
        return [self evaluate];
    }
    
    // 1-3. 尝试置换表裁剪，并得到置换表走法
    vl = [self ProbeHashWithAlpha:vlAlpha beta:vlBeta depth:nDepth move:&mHash];
    if (vl > -MATE_VALUE) {
        return vl;
    }
    
    // 1-4. 尝试空步裁剪(根节点的Beta值是"MATE_VALUE"，所以不可能发生空步裁剪)
    if (!bNoNull && ![self in_check] && [self null_okay]) {
        [self null_move];
        vl = -[self search_full_for_depth:nDepth - NULL_DEPTH - 1 alpha:-vlBeta beta:1 - vlBeta nonull:NO_NULL];
        [self undo_null_move];
        if (vl >= vlBeta) {
            return vl;
        }
    }
    
    // 2. 初始化最佳值和最佳走法
    nHashFlag = HASH_ALPHA;
    vlBest = -MATE_VALUE; // 这样可以知道，是否一个走法都没走过(杀棋)
    mvBest = 0;           // 这样可以知道，是否搜索到了Beta走法或PV走法，以便保存到历史表
    
    // 3. 初始化走法排序结构
    sort = [[Sort alloc] init];
    [sort initWithHash:mHash];
    // 4. 逐一走这些走法，并进行递归
    while ((mv = [sort next_move]) != 0) {
        if ([self make_move:mv]) {
            // 将军延伸
            nNewDepth = [self in_check] ? nDepth : nDepth - 1;
            // PVS
            if (vlBest == -MATE_VALUE) {
                vl = -[self search_full_for_depth:nNewDepth alpha:-vlBeta beta:-vlAlpha nonull:FALSE];
            } else {
                vl = -[self search_full_for_depth:nNewDepth alpha:-vlAlpha - 1 beta:-vlAlpha nonull:FALSE];
                if (vl > vlAlpha && vl < vlBeta) {
                    vl = -[self search_full_for_depth:nNewDepth alpha:-vlBeta beta:-vlAlpha nonull:FALSE];
                }
            }
            [self undo_make_move];
            
            // 5. 进行Alpha-Beta大小判断和截断
            if (vl > vlBest) {    // 找到最佳值(但不能确定是Alpha、PV还是Beta走法)
                vlBest = vl;        // "vlBest"就是目前要返回的最佳值，可能超出Alpha-Beta边界
                if (vl >= vlBeta) { // 找到一个Beta走法
                    nHashFlag = HASH_BETA;
                    mvBest = mv;      // Beta走法要保存到历史表
                    break;            // Beta截断
                }
                if (vl > vlAlpha) { // 找到一个PV走法
                    nHashFlag = HASH_PV;
                    mvBest = mv;      // PV走法要保存到历史表
                    vlAlpha = vl;     // 缩小Alpha-Beta边界
                }
            }
        }
    }
    
    // 5. 所有走法都搜索完了，把最佳走法(不能是Alpha走法)保存到历史表，返回最佳值
    if (vlBest == -MATE_VALUE) {
        [sort release];
        // 如果是杀棋，就根据杀棋步数给出评价
        return n_distance - MATE_VALUE;
    }
    // 记录到置换表
    [self RecordHash:nHashFlag value:vlBest depth:nDepth move:mvBest];
    if (mvBest != 0) {
        // 如果不是Alpha走法，就将最佳走法保存到历史表
        [self set_best_move:mvBest depth:nDepth]; 
    }
    [sort release];
    return vlBest;
}

// 超出边界(Fail-Soft)的Alpha-Beta搜索过程
- (int)search_full_for_depth:(int)nDepth alpha:(int)vlAlpha beta:(int)vlBeta 
{
    int i, nGenMoves, pcCaptured;
    int vl, vlBest;
    int mvBest;
    int mvs[MAX_GEN_MOVES];
    memset(mvs, 0x0, MAX_GEN_MOVES * sizeof(int));
    // 一个Alpha-Beta完全搜索分为以下几个阶段
    
    // 1. 到达水平线，则返回局面评价值
    if (nDepth == 0) {
        return [self evaluate];
    }
    
    // 2. 初始化最佳值和最佳走法
    vlBest = -MATE_VALUE; // 这样可以知道，是否一个走法都没走过(杀棋)
    mvBest = 0;           // 这样可以知道，是否搜索到了Beta走法或PV走法，以便保存到历史表
    
    // 3. 生成全部走法，并根据历史表排序
    nGenMoves = [self generate_moves:mvs];
    qsort(mvs, nGenMoves, sizeof(int), CompareHistory);
    
    // 4. 逐一走这些走法，并进行递归
    for (i = 0; i < nGenMoves; i ++) {
        if ([self make_move:mvs[i] captured:&pcCaptured]) {
            vl = -[self search_full_for_depth:nDepth - 1 alpha:-vlBeta beta:-vlAlpha];
            [self undo_make_move:mvs[i] captured:pcCaptured];
            
            // 5. 进行Alpha-Beta大小判断和截断
            if (vl > vlBest) {    // 找到最佳值(但不能确定是Alpha、PV还是Beta走法)
                vlBest = vl;        // "vlBest"就是目前要返回的最佳值，可能超出Alpha-Beta边界
                if (vl >= vlBeta) { // 找到一个Beta走法
                    mvBest = mvs[i];  // Beta走法要保存到历史表
                    break;            // Beta截断
                }
                if (vl > vlAlpha) { // 找到一个PV走法
                    mvBest = mvs[i];  // PV走法要保存到历史表
                    vlAlpha = vl;     // 缩小Alpha-Beta边界
                }
            }
        }
    }
    
    // 5. 所有走法都搜索完了，把最佳走法(不能是Alpha走法)保存到历史表，返回最佳值
    if (vlBest == -MATE_VALUE) {
        // 如果是杀棋，就根据杀棋步数给出评价
        return n_distance - MATE_VALUE;
    }
    if (mvBest != 0) {
        // 如果不是Alpha走法，就将最佳走法保存到历史表
        nHistoryTable[mvBest] += nDepth * nDepth;
        if (n_distance == 0) {
            // 搜索根节点时，总是有一个最佳走法(因为全窗口搜索不会超出边界)，将这个走法保存下来
            mvResult = mvBest;
        }
    }
    return vlBest;
}

- (int)search_quiescent_for_alpha:(int)vlAlpha beta:(int)vlBeta
{
    int i, nGenMoves;
    int vl, vlBest;
    int mvs[MAX_GEN_MOVES];
    memset(mvs, 0x0, MAX_GEN_MOVES * sizeof(int));
    // 一个静态搜索分为以下几个阶段
    
    // 1. 检查重复局面
    vl = [self rep_status:1];
    if (vl != 0) {
        return [self rep_value:vl];
    }
    
    // 2. 到达极限深度就返回局面评价
    if (n_distance == search_depth) {
        return [self evaluate];
    }
    
    // 3. 初始化最佳值
    vlBest = -MATE_VALUE; // 这样可以知道，是否一个走法都没走过(杀棋)
    
    if ([self in_check]) {
        // 4. 如果被将军，则生成全部走法
        nGenMoves = [self generate_moves:mvs];
        qsort(mvs, nGenMoves, sizeof(int), CompareHistory);
    } else {
        
        // 5. 如果不被将军，先做局面评价
        vl = [self evaluate];
        if (vl > vlBest) {
            vlBest = vl;
            if (vl >= vlBeta) {
                return vl;
            }
            if (vl > vlAlpha) {
                vlAlpha = vl;
            }
        }
        
        // 6. 如果局面评价没有截断，再生成吃子走法
        nGenMoves = [self generate_moves:mvs isCaptured:GEN_CAPTURE];
        qsort(mvs, nGenMoves, sizeof(int), CompareMvvLva);
    }
    
    // 7. 逐一走这些走法，并进行递归
    for (i = 0; i < nGenMoves; i ++) {
        if ([self make_move:mvs[i]]) {
            vl = -[self search_quiescent_for_alpha:-vlBeta beta:-vlAlpha];
            [self undo_make_move];
            
            // 8. 进行Alpha-Beta大小判断和截断
            if (vl > vlBest) {    // 找到最佳值(但不能确定是Alpha、PV还是Beta走法)
                vlBest = vl;        // "vlBest"就是目前要返回的最佳值，可能超出Alpha-Beta边界
                if (vl >= vlBeta) { // 找到一个Beta走法
                    return vl;        // Beta截断
                }
                if (vl > vlAlpha) { // 找到一个PV走法
                    vlAlpha = vl;     // 缩小Alpha-Beta边界
                }
            }
        }
    }
    
    // 9. 所有走法都搜索完了，返回最佳值
    return vlBest == -MATE_VALUE ? n_distance - MATE_VALUE : vlBest;
}


- (int)search_root:(int)nDepth
{
    int nNewDepth;
    int mv;
    int vl, vlBest;
    Sort *sort = [[Sort alloc] init];
    vlBest = -MATE_VALUE;
    [sort initWithHash:mvResult];
    while ((mv = [sort next_move]) != 0) {
        if ([self make_move:mv]) {
            nNewDepth = [self in_check] ? nDepth : nDepth - 1;
            if (vlBest == -MATE_VALUE) {
                //full window search for the first ply
#ifdef USE_MTDF
                vl = [self search_root_mtdf:nNewDepth];
#else
                vl = -[self search_full_for_depth:nNewDepth alpha:-MATE_VALUE beta:MATE_VALUE nonull:NO_NULL];
#ifdef ENABLE_DEBUG_OBJC
                NSLog(@"[XQWLightOBJC] vl (full window search) %d depth %d", vl, nNewDepth);
#endif
#endif /*USE_MTDF*/
            } else {
                vl = -[self search_full_for_depth:nNewDepth alpha:-vlBest - 1 beta:-vlBest nonull:FALSE];
#ifdef ENABLE_DEBUG_OBJC
                NSLog(@"[XQWLightOBJC] vl 1 %d", vl);
#endif
                if (vl > vlBest) {
                    vl = -[self search_full_for_depth:nNewDepth alpha:-MATE_VALUE beta:-vlBest nonull:NO_NULL];
#ifdef ENABLE_DEBUG_OBJC
                    NSLog(@"[XQWLightOBJC] vl 2 %d", vl);
#endif
                }
            }
            [self undo_make_move];
            if (vl > vlBest) {
#ifdef ENABLE_DEBUG_OBJC
                NSLog(@"vl > vlBest (%d)", vlBest);
#endif
                vlBest = vl;
                mvResult = mv;
                if (vlBest > -WIN_VALUE && vlBest < WIN_VALUE) {
                    //vlBest += (arc4random() & RANDOM_MASK) - (arc4random() & RANDOM_MASK);
                    vlBest += (rand() & RANDOM_MASK) - (rand() & RANDOM_MASK);
#ifdef ENABLE_DEBUG
                    printf("[%s]random value %d\n", __func__, vlBest);
#endif
                }
            }
        }
    }
    [self RecordHash:HASH_PV value:vlBest depth:nDepth move:mvResult]; 
    [self set_best_move:mvResult depth:nDepth];
    [sort release];
    return vlBest;   
}

// 提取置换表项
- (int)ProbeHashWithAlpha:(int)vlAlpha beta:(int)vlBeta depth:(int)nDepth move:(int*)mv  {
    BOOL bMate; // 杀棋标志：如果是杀棋，那么不需要满足深度条件
    HashItem hsh;
    
    hsh = HashTable[zobr.dwKey & (HASH_SIZE - 1)];
    if (hsh.dwLock0 != zobr.dwLock0 || hsh.dwLock1 != zobr.dwLock1) {
        *mv = 0;
        return -MATE_VALUE;
    }
    *mv = hsh.wmv;
    bMate = FALSE;
    if (hsh.svl > WIN_VALUE) {
        if (hsh.svl < BAN_VALUE) {
            return -MATE_VALUE; // 可能导致搜索的不稳定性，立刻退出，但最佳着法可能拿到
        }
        hsh.svl -= n_distance;
        bMate = TRUE;
    } else if (hsh.svl < -WIN_VALUE) {
        if (hsh.svl > -BAN_VALUE) {
            return -MATE_VALUE; // 同上
        }
        hsh.svl += n_distance;
        bMate = TRUE;
    }
    if (hsh.ucDepth >= nDepth || bMate) {
        if (hsh.ucFlag == HASH_BETA) {
            return (hsh.svl >= vlBeta ? hsh.svl : -MATE_VALUE);
        } else if (hsh.ucFlag == HASH_ALPHA) {
            return (hsh.svl <= vlAlpha ? hsh.svl : -MATE_VALUE);
        }
        return hsh.svl;
    }
    return -MATE_VALUE;
}

// 保存置换表项
- (void)RecordHash:(int)nFlag value:(int)vl depth:(int)nDepth move:(int)mv 
{
    HashItem hsh;
    hsh = HashTable[zobr.dwKey & (HASH_SIZE - 1)];
    if (hsh.ucDepth > nDepth) {
        return;
    }
    hsh.ucFlag = nFlag;
    hsh.ucDepth = nDepth;
    if (vl > WIN_VALUE) {
        if (mv == 0 && vl <= BAN_VALUE) {
            return; // 可能导致搜索的不稳定性，并且没有最佳着法，立刻退出
        }
        hsh.svl = vl + n_distance;
    } else if (vl < -WIN_VALUE) {
        if (mv == 0 && vl >= -BAN_VALUE) {
            return; // 同上
        }
        hsh.svl = vl - n_distance;
    } else {
        hsh.svl = vl;
    }
    hsh.wmv = mv;
    hsh.dwLock0 = zobr.dwLock0;
    hsh.dwLock1 = zobr.dwLock1;
    HashTable[zobr.dwKey & (HASH_SIZE - 1)] = hsh;
}

// 对最佳走法的处理
- (void)set_best_move:(int)mv depth:(int)nDepth 
{
    int *lpmvKillers;
    nHistoryTable[mv] += (nDepth * nDepth);
    lpmvKillers = mvKillers[n_distance];
    if (lpmvKillers[0] != mv) {
        lpmvKillers[1] = lpmvKillers[0];
        lpmvKillers[0] = mv;
    }
}

- (int)killerMoveAtDepth:(int)depth atIndex:(int)index
{
    return mvKillers[depth][index];
}

- (int)compare_history_move1:(int*)mv1 move2:(int*)mv2 
{
    return CompareHistory((void*)mv1, (void*)mv2);
}

// 检测重复局面
- (int)rep_status:(int)nRecur
{
    BOOL bSelfSide, bPerpCheck, bOppPerpCheck;
    MoveStruct *lpmvs;
    
    bSelfSide = FALSE;
    bPerpCheck = bOppPerpCheck = TRUE;
    lpmvs = mvsList + nMoveNum - 1;
    while (lpmvs->wmv != 0 && lpmvs->ucpcCaptured == 0) {
        if (bSelfSide) {
            bPerpCheck = bPerpCheck && lpmvs->ucbCheck;
            if (lpmvs->dwKey == zobr.dwKey) {
                nRecur --;
                if (nRecur == 0) {
                    return 1 + (bPerpCheck ? 2 : 0) + (bOppPerpCheck ? 4 : 0);
                }
            }
        } else {
            bOppPerpCheck = bOppPerpCheck && lpmvs->ucbCheck;
        }
        bSelfSide = !bSelfSide;
        lpmvs --;
    }
    return 0;
}

- (int)rep_value:(int)nRepStatus
{
    int vlReturn;
    vlReturn = ((nRepStatus & 2) == 0 ? 0 : n_distance - BAN_VALUE) + ((nRepStatus & 4) == 0 ? 0 : BAN_VALUE - n_distance);
    return vlReturn == 0 ? [self draw_value] : vlReturn;   
}

- (int)draw_value
{
    return (n_distance & 1) == 0 ? -DRAW_VALUE : DRAW_VALUE;
}

- (BOOL)null_okay
{   //check if Null Cut is allowed
    return (sd_player == 0 ? vl_white : vl_black) > NULL_MARGIN;
}

- (void)mirror:(XiangQi*)posMirror
{
    int sq, pc;
    [posMirror clear_board];
    for (sq = 0; sq < 256; sq ++) {
        pc = ucpc_squares[sq];
        if (pc != 0) {
            [posMirror add_piece:pc square:MIRROR_SQUARE(sq)];
        }
    }
    if (sd_player == 1) {
        [posMirror change_side];
    }
    [posMirror set_irrev];    
}

+ (XiangQi*)getXiangQi
{
    if(!xiangqi)
        xiangqi = [[XiangQi alloc] init];
    return xiangqi;
}

#pragma mark  MTD tree search (experimental)
//
// Current XQLight AI is quite slow when setting timeout to a bigger value , whereas it's weak when using a small value.
// Beside this, because we r not using opening book at this moment, it seems the first ply for AI is quite predictable 
// although XQLight has already randomized the evalatuated value (see search_root). This leads me to think how to make the
// openning more unpredictable. My idea here is use MTD tree search which is faster than NegaScout(same with PVS) to search
// the first ply.
// The algorithm can be found at http://people.csail.mit.edu/plaat/mtdf.html
//
- (int)mtdf_search:(int)depth guess:(int)guess
{
    int g, beta;
    int upperbound = MATE_VALUE; 
    int lowerbound = -MATE_VALUE; 
    g = guess;
    do {
        if(g == lowerbound) { 
            beta = g + 1; 
        } else {
            beta = g;
        }
        g = [self search_full_for_depth:depth alpha:beta - 1 beta:beta nonull:NO_NULL];
        if(g < beta) {
            upperbound = g;
        } else {
            lowerbound = g;
        }
    } while (lowerbound < upperbound);
    return g; 
}

- (int)search_root_mtdf:(int)depth
{

    int first_guess = 0;
    /* Typically, one would call MTD(f) in an iterative deepening framework. 
     * A natural choice for a first guess is to use the value of the previous 
     * iteration, like this:
     *     for d = 1 to MAX_SEARCH_DEPTH do
     *         firstguess := MTDF(root, firstguess, d);
     * 
     */
    for(int d = 1; d < depth; d++) {
        first_guess = [self mtdf_search:d guess:first_guess];
    }
    return first_guess;
}

#pragma mark  seach book
- (int)searchBook
{
    int i, vl, nBookMoves;
    int mv;
    int mvs[MAX_GEN_MOVES], vls[MAX_GEN_MOVES];
    BOOL bMirror;
    BookItem bkToSearch, *lpbk;
    bzero(mvs, MAX_GEN_MOVES * sizeof(int));
    bzero(vls, MAX_GEN_MOVES * sizeof(int));
    // 搜索开局库的过程有以下几个步骤
    
    // 1. 如果没有开局库，则立即返回
    if (book.nBookSize == 0) {
        return 0;
    }

    XiangQi *posMirror = [[XiangQi alloc] init];
    // 2. 搜索当前局面
    bMirror = FALSE;
    bkToSearch.dwLock = zobr.dwLock1;
    lpbk = (BookItem *) bsearch(&bkToSearch, book.BookTable, book.nBookSize, sizeof(BookItem), CompareBook);
    // 3. 如果没有找到，那么搜索当前局面的镜像局面
    if (lpbk == NULL) {
        bMirror = TRUE;
        [self mirror:posMirror];
        bkToSearch.dwLock = posMirror.zobr.dwLock1;
        lpbk = (BookItem *) bsearch(&bkToSearch, book.BookTable, book.nBookSize, sizeof(BookItem), CompareBook);
    }
    // 4. 如果镜像局面也没找到，则立即返回
    [posMirror release];
    if (lpbk == NULL) {
        return 0;
    }
    // 5. 如果找到，则向前查第一个开局库项
    while (lpbk >= book.BookTable && lpbk->dwLock == bkToSearch.dwLock) {
        lpbk --;
    }
    lpbk ++;
    // 6. 把走法和分值写入到"mvs"和"vls"数组中
    vl = nBookMoves = 0;
    while (lpbk < book.BookTable + book.nBookSize && lpbk->dwLock == bkToSearch.dwLock) {
        mv = (bMirror ? MIRROR_MOVE(lpbk->wmv) : lpbk->wmv);
        if ([self legal_move:mv]) {
            mvs[nBookMoves] = mv;
            vls[nBookMoves] = lpbk->wvl;
            vl += vls[nBookMoves];
            nBookMoves ++;
#ifdef ENABLE_DEBUG
            printf("[%s]search %d book move\n", __func__, nBookMoves);
#endif
            if (nBookMoves == MAX_GEN_MOVES) {
                break; // 防止"BOOK.DAT"中含有异常数据
            }
        }
        lpbk ++;
    }
    if (vl == 0) {
        return 0; // 防止"BOOK.DAT"中含有异常数据
    }
    // 7. 根据权重随机选择一个走法
    vl = arc4random() % vl;
#ifdef ENABLE_DEBUG
    printf("[%s]random value %d\n", __func__, vl);
#endif
    for (i = 0; i < nBookMoves; i ++) {
        vl -= vls[i];
        if (vl < 0) {
            break;
        }
    }
#ifdef ENABLE_DEBUG
    printf("[%s]select %dth move\n", __func__, i);
#endif
    return mvs[i];
}

@end

///////////////////////////////////////////////////////////////////////////////
//
// TODO: Temporarily place the XQWLight Objective-C based AI here.
//
///////////////////////////////////////////////////////////////////////////////

#pragma mark -
#pragma mark XQWLight Objective-C based AI

#define TOSQUARE(row, col)   (16 * ((row) + 3) + ((col) + 3))
#define COLUMN(sq)           ((sq) % 16 - 3)
#define ROW(sq)              ((sq) / 16 - 3)

@implementation AI_XQWLightObjC

- (void)dealloc
{
    [_objcEngine release];
    [super dealloc];
}

- (id) init
{
    if (self = [super init]) {
        srand((unsigned)time(NULL));
        _objcEngine = [XiangQi getXiangQi];
    }
    return self;
}

- (int) setDifficultyLevel: (int)nAILevel
{
    _objcEngine.search_depth = nAILevel;
    return AI_RC_OK;
}

- (int) initGame
{
    [_objcEngine reset];
    return AI_RC_OK;
}

- (int) generateMove:(int*)pRow1 fromCol:(int*)pCol1
               toRow:(int*)pRow2 toCol:(int*)pCol2
{
    int move = -1;  // No valid move found.
    [_objcEngine SearchMain];
    move = _objcEngine.mvResult;
    int captured = 0;
    if ( ! [_objcEngine make_move:move captured:&captured] ) {
        return AI_RC_ERR;  // No valid move found.
    }
    
    int sqSrc = SRC(move);
    int sqDst = DST(move);
    *pRow1 = ROW(sqSrc);
    *pCol1 = COLUMN(sqSrc);
    *pRow2 = ROW(sqDst);
    *pCol2 = COLUMN(sqDst);
    
    return AI_RC_OK;
}

- (int) onHumanMove:(int)row1 fromCol:(int)col1
              toRow:(int)row2 toCol:(int)col2
{
    int sqSrc = TOSQUARE(row1, col1);
    int sqDst = TOSQUARE(row2, col2);
    int move = MOVE(sqSrc, sqDst);
    int captured = 0;
    
    if ( ! [_objcEngine make_move:move captured:&captured] ) {
        return AI_RC_ERR;
    }
    return AI_RC_OK;
}

- (NSString *) getInfo
{
    return @"The XQWLight Objective-C based AI written by Nevo";
}
@end


