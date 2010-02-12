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


#import <UIKit/UIKit.h>
#import "BoardView.h"
#import "CChessGame.h"
#import "TableListViewController.h"  // TODO: To get TimeInfo, TableInfo, ...


// TODO: Temporary place here! ---------------------------------------

enum ActionIndexEnum
{
    ACTION_INDEX_CLOSE,
    ACTION_INDEX_RESIGN,
    ACTION_INDEX_DRAW,
    ACTION_INDEX_LOGOUT,
    ACTION_INDEX_CANCEL
};

@interface BoardActionSheet : UIActionSheet
{
    int closeIndex;  // Close the current table.
    int resignIndex;
    int drawIndex;
    int logoutIndex;
    int cancelIndex;
}
- (id)initWithTableState:(NSString *)state delegate:(id<UIActionSheetDelegate>)delegate
                   title:(NSString*)title;
- (NSInteger) valueOfClickedButtonAtIndex:(NSInteger)buttonIndex;
@end

// -------------------------------------------------------
@interface BoardViewController : UIViewController <BoardOwner>
{
    
    IBOutlet UIToolbar*   nav_toolbar;
    IBOutlet UIButton*    red_seat;
    IBOutlet UIButton*    black_seat;
    IBOutlet UIActivityIndicatorView *activity;

    BoardView*            _board;
    CChessGame*           _game;

    NSString*             _tableId;
    ColorEnum             _myColor;  // The color (role) of the LOCAL player.
}

@property (nonatomic, retain) BoardView* _board;
@property (nonatomic, retain) CChessGame* _game;
@property (nonatomic, retain) NSString* _tableId;

- (IBAction)homePressed:(id)sender;
- (IBAction)resetPressed:(id)sender;
- (IBAction)actionPressed:(id)sender;
- (IBAction)messagesPressed:(id)sender;

- (void) onLocalMoveMade:(int)move;

- (void) goBackToHomeMenu;
- (void) setRedLabel:(NSString*)label;
- (void) setBlackLabel:(NSString*)label;
- (void) setInitialTime:(NSString*)times;
- (void) setRedTime:(NSString*)times;
- (void) setBlackTime:(NSString*)times;

- (void) saveGame;
- (void) rescheduleTimer;
- (void) resetBoard;
- (void) displayEmptyBoard;
- (BOOL) isMyTurnNext;
- (BOOL) isGameReady;
- (void) handleNewMove:(NSNumber *)pMove;
- (void) handleEndGameInUI;
- (void) reverseBoardView;

@end
