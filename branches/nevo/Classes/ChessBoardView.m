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


#import "ChessBoardView.h"
#import "Game.h"
#import "QuartzUtils.h"
#import "Bit.h"
#import "BitHolder.h"
#import "Grid.h"
#import "Piece.h"
#import "XiangQi.h"
#import "CChessGame.h"
#import "NevoChessAppDelegate.h"


@implementation ChessBoardView

/** Class name of the current game. */
static NSString* sCurrentGameName = @"CChessGame";


- (void) startGameNamed: (NSString*)gameClassName
{
    ((NevoChessAppDelegate*)[[UIApplication sharedApplication] delegate]).navigationController.navigationBarHidden = YES;
    [super startGameNamed: gameClassName];
    //set search depth 
    int nDifficulty = [[NSUserDefaults standardUserDefaults] integerForKey:@"difficulty_setting"];
    [((CChessGame*)_game) setSearchDepth:nDifficulty];
    //self.title = [(id)[game class] displayName];
}


//- (CGRect) gameBoardFrame
//{
//    CGRect bounds = [super gameBoardFrame];
//    bounds.size.height -= 32;                   // Leave room for headline
//    return CGRectInset(bounds,4,4);
//}



- (void) awakeFromNib
{    
    [self startGameNamed: sCurrentGameName];
}

@end
