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
#import "CChessGame.h"
#import "AudioHelper.h"

@class TimeInfo;

// --------------------------------------
@protocol BoardOwner <NSObject>
- (BOOL) isMyTurnNext;
- (BOOL) isGameReady;
- (void) onLocalMoveMade:(int)move gameResult:(int)nGameResult;
@end

// --------------------------------------
@interface BoardViewController : UIViewController
{
    CChessGame*           _game;           // Current Game
    CALayer*              _gameboard;      // Game's main layer

    AudioHelper*          _audioHelper;

    id <BoardOwner>       _boardOwner;

    IBOutlet UIButton*    _red_seat;
    IBOutlet UIButton*    _black_seat;
    IBOutlet UILabel*     _red_label;
    IBOutlet UILabel*     _black_label;
    IBOutlet UILabel*     _red_time;
    IBOutlet UILabel*     _red_move_time;
    IBOutlet UILabel*     _black_time;
    IBOutlet UILabel*     _black_move_time;

    IBOutlet UILabel*     _game_over_msg;

    IBOutlet UIButton*    _preview_prev;
    IBOutlet UIButton*    _preview_next;
    NSDate*               _previewLastTouched;
    NSDate*               _previewLastTouched_prev;
    NSDate*               _previewLastTouched_next;
    
    NSTimer*              _timer;
    
    TimeInfo*             _initialTime;
    TimeInfo*             _redTime;
    TimeInfo*             _blackTime;

    // Members to keep track of (H)igh(L)ight moves (e.g., move-hints).
    int                   _hl_moves[MAX_GEN_MOVES];
    int                   _hl_nMoves;
    int                   _hl_lastMove; // The last Move that was highlighted.    
    Piece*                _selectedPiece;

    NSMutableArray*       _moves;       // MOVE history
    int                   _nthMove;     // pivot for the Move Review
}

- (CALayer*) hitTestPoint:(CGPoint)locationInWindow
       LayerMatchCallback:(LayerMatchCallback)match offset:(CGPoint*)outOffset;

@property (readonly) CChessGame* game;
@property (nonatomic, retain) id <BoardOwner> boardOwner;
@property (nonatomic, retain) NSTimer* _timer;
@property (nonatomic, retain) NSDate* _previewLastTouched;
@property (nonatomic, retain) NSDate* _previewLastTouched_prev;
@property (nonatomic, retain) NSDate* _previewLastTouched_next;

- (IBAction) previewPrevious_DOWN:(id)sender;
- (IBAction) previewPrevious_UP:(id)sender;
- (IBAction) previewNext_DOWN:(id)sender;
- (IBAction) previewNext_UP:(id)sender;

- (void) setRedLabel:(NSString*)label;
- (void) setBlackLabel:(NSString*)label;
- (void) setInitialTime:(NSString*)times;
- (void) setRedTime:(NSString*)times;
- (void) setBlackTime:(NSString*)times;
- (void) rescheduleTimer;
- (void) destroyTimer;
- (void) onNewMove:(NSNumber *)moveInfo inSetupMode:(BOOL)bSetup;
- (void) onGameOver;
- (void) playSound:(NSString*)sound;
- (NSMutableArray*) getMoves;
- (void) resetBoard;
- (void) displayEmptyBoard;
- (void) reverseBoardView;
- (void) reverseRole;

@end
