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

@interface ChessBoardViewController : UIViewController {
    
    IBOutlet UIToolbar   *nav_toolbar;
    IBOutlet UILabel     *red_label;
    IBOutlet UILabel     *black_label;
    IBOutlet UITextField *red_time;
    IBOutlet UITextField *black_time;
    
    IBOutlet UIActivityIndicatorView *activity;
    
    NSTimer *_timer;

    NSThread *robot;
    NSPort *_robotPort;       // the port is used to instruct the robot to do works
    CFRunLoopRef _robotLoop;  //the loop robot is on, used to control its lifecycle

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
}

@property (nonatomic, retain) IBOutlet UIToolbar *nav_toolbar;
@property (nonatomic, retain) IBOutlet UILabel *red_label;
@property (nonatomic, retain) IBOutlet UILabel *black_label;
@property (nonatomic, retain) IBOutlet UITextField *red_time;
@property (nonatomic, retain) IBOutlet UITextField *black_time;

@property (nonatomic, retain) NSTimer* _timer;

- (IBAction)homePressed:(id)sender;
- (IBAction)resetPressed:(id)sender;

- (IBAction)movePrevPressed:(id)sender;
- (IBAction)moveNextPressed:(id)sender;

- (void) saveGame;

- (void) _resetBoard;
- (id)   _initSoundSystem;

@end
