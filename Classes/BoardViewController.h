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

BOOL layerIsBit( CALayer* layer );
BOOL layerIsBitHolder( CALayer* layer );

enum AlertViewEnum
{
    POC_ALERT_END_GAME,
    POC_ALERT_RESUME_GAME,
    POC_ALERT_RESET_GAME
};

@interface BoardViewController : UIViewController
{
    
    IBOutlet UIToolbar   *nav_toolbar;
    IBOutlet UILabel     *red_label;
    IBOutlet UILabel     *black_label;
    IBOutlet UITextField *red_time;
    IBOutlet UITextField *black_time;
    IBOutlet UIButton    *red_seat;
    IBOutlet UIButton    *black_seat;
    IBOutlet UIActivityIndicatorView *activity;

    NSTimer *_timer;

    AudioHelper *_audioHelper;

    // Members to keep track of (H)igh(L)ight moves (e.g., move-hints).
    int    _hl_moves[MAX_GEN_MOVES];
    int    _hl_nMoves;
    int    _hl_lastMove;      // The last Move that was highlighted.

    Piece *_selectedPiece;

    CChessGame *_game;

    int _initialTime;  // The initial time (in seconds)
    int _redTime;      // RED   time (in seconds)
    int _blackTime;    // BLACK time (in seconds)
    
    NSMutableArray *_moves;       // MOVE history
    int             _nthMove;     // pivot for the Move Review
    BOOL            _inReview;
    int             _latestMove;  // Latest Move waiting to be UI-updated.

    // ---------
    NSString*       _tableId;
    ColorEnum       _myColor;     // The color (role) of the LOCAL player.
}

@property (nonatomic, retain) IBOutlet UIToolbar *nav_toolbar;
@property (nonatomic, retain) IBOutlet UILabel *red_label;
@property (nonatomic, retain) IBOutlet UILabel *black_label;
@property (nonatomic, retain) IBOutlet UITextField *red_time;
@property (nonatomic, retain) IBOutlet UITextField *black_time;
@property (nonatomic, retain) IBOutlet UIButton *red_seat;
@property (nonatomic, retain) IBOutlet UIButton *black_seat;

@property (nonatomic, retain) NSTimer* _timer;
@property (nonatomic, retain) NSString* _tableId;

- (IBAction)homePressed:(id)sender;
- (IBAction)resetPressed:(id)sender;
- (IBAction)movePrevPressed:(id)sender;
- (IBAction)moveNextPressed:(id)sender;

- (void) onLocalMoveMade:(int)move;

- (void) goBackToHomeMenu;
- (void) setRedLabel:(NSString*)label;
- (void) setBlackLabel:(NSString*)label;

- (void) saveGame;
- (void) rescheduleTimer;
- (void) resetBoard;
- (void) setMyColor:(ColorEnum)color;
- (BOOL) isMyTurnNext;
- (BOOL) isGameReady;
- (void) setHighlightCells:(BOOL)bHighlight;
- (void) showHighlightOfMove:(int)move;
- (void) handleNewMove:(NSNumber *)pMove;
- (void) handleEndGameInUI;
- (void) reverseBoardView;

@end


////////////////////////////////////////////////////////////////////
//
// Move review holder unit
//
////////////////////////////////////////////////////////////////////

@interface MoveAtom : NSObject {
    id move;
    id srcPiece;
    id capturedPiece;
}

@property(nonatomic,retain) id move;
@property(nonatomic,retain) id srcPiece;
@property(nonatomic,retain) id capturedPiece;

@end
