/*
 
 File: BoardView.h
 
 Abstract: 
 
 Version: 1.0
 
 Disclaimer: IMPORTANT:  This Apple software is supplied to you by 
 Apple Inc. ("Apple") in consideration of your agreement to the
 following terms, and your use, installation, modification or
 redistribution of this Apple software constitutes acceptance of these
 terms.  If you do not agree with these terms, please do not use,
 install, modify or redistribute this Apple software.
 
 In consideration of your agreement to abide by the following terms, and
 subject to these terms, Apple grants you a personal, non-exclusive
 license, under Apple's copyrights in this original Apple software (the
 "Apple Software"), to use, reproduce, modify and redistribute the Apple
 Software, with or without modifications, in source and/or binary forms;
 provided that if you redistribute the Apple Software in its entirety and
 without modifications, you must retain this notice and the following
 text and disclaimers in all such redistributions of the Apple Software. 
 Neither the name, trademarks, service marks or logos of Apple Inc. 
 may be used to endorse or promote products derived from the Apple
 Software without specific prior written permission from Apple.  Except
 as expressly stated in this notice, no other rights or licenses, express
 or implied, are granted by Apple herein, including but not limited to
 any patent rights that may be infringed by your derivative works or by
 other works in which the Apple Software may be incorporated.
 
 The Apple Software is provided by Apple on an "AS IS" basis.  APPLE
 MAKES NO WARRANTIES, EXPRESS OR IMPLIED, INCLUDING WITHOUT LIMITATION
 THE IMPLIED WARRANTIES OF NON-INFRINGEMENT, MERCHANTABILITY AND FITNESS
 FOR A PARTICULAR PURPOSE, REGARDING THE APPLE SOFTWARE OR ITS USE AND
 OPERATION ALONE OR IN COMBINATION WITH YOUR PRODUCTS.
 
 IN NO EVENT SHALL APPLE BE LIABLE FOR ANY SPECIAL, INDIRECT, INCIDENTAL
 OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 INTERRUPTION) ARISING IN ANY WAY OUT OF THE USE, REPRODUCTION,
 MODIFICATION AND/OR DISTRIBUTION OF THE APPLE SOFTWARE, HOWEVER CAUSED
 AND WHETHER UNDER THEORY OF CONTRACT, TORT (INCLUDING NEGLIGENCE),
 STRICT LIABILITY OR OTHERWISE, EVEN IF APPLE HAS BEEN ADVISED OF THE
 POSSIBILITY OF SUCH DAMAGE.
 
 Copyright © 2007 Apple Inc. All Rights Reserved.
 
 */

/***************************************************************************
 *                                                                         *
 * Customized by the PlayXiangqi team to work as a Xiangqi Board.          *
 *                                                                         *
 ***************************************************************************/

#import <UIKit/UIKit.h>
#import <CoreGraphics/CoreGraphics.h>
#import <QuartzCore/QuartzCore.h>
#import "CChessGame.h"
#import "AudioHelper.h"

@class Bit, Card, Grid;
@protocol BitHolder;
@class TimeInfo;


// Hit-testing callbacks (to identify which layers caller is interested in):
typedef BOOL (*LayerMatchCallback)(CALayer*);

// --------------------------------------
@protocol BoardOwner <NSObject>
- (BOOL) isMyTurnNext;
- (BOOL) isGameReady;
- (void) onLocalMoveMade:(int)move;
@end

/** UIView that hosts a game. */
@interface BoardView : UIView
{
    CChessGame*           _game;           // Current Game
    CALayer*              _gameboard;      // Game's main layer

    AudioHelper*          _audioHelper;

    id <BoardOwner>       _boardOwner;
    
    IBOutlet UILabel*     _red_label;
    IBOutlet UILabel*     _black_label;
    IBOutlet UILabel*     _red_time;
    IBOutlet UILabel*     _red_move_time;
    IBOutlet UILabel*     _black_time;
    IBOutlet UILabel*     _black_move_time;

    IBOutlet UIButton*    _preview_prev;
    IBOutlet UIButton*    _preview_next;
    NSDate*               _previewLastTouched;

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

- (CALayer*) hitTestPoint: (CGPoint)locationInWindow
       LayerMatchCallback: (LayerMatchCallback)match
                   offset: (CGPoint*)outOffset;

@property (readonly) CChessGame* game;
@property (nonatomic, retain) id <BoardOwner> boardOwner;
@property (nonatomic, retain) NSTimer* _timer;
@property (nonatomic, retain) TimeInfo* _initialTime;
@property (nonatomic, retain) TimeInfo* _redTime;
@property (nonatomic, retain) TimeInfo* _blackTime;
@property (nonatomic, retain) NSDate* _previewLastTouched;

- (IBAction)movePrevPressed:(id)sender;
- (IBAction)moveNextPressed:(id)sender;

- (void) setRedLabel:(NSString*)label;
- (void) setBlackLabel:(NSString*)label;
- (void) setInitialTime:(NSString*)times;
- (void) setRedTime:(NSString*)times;
- (void) setBlackTime:(NSString*)times;
- (void) rescheduleTimer;
- (void) destroyTimer;
- (int) onNewMove:(NSNumber *)moveInfo;
- (void) playSound:(NSString*)sound;
- (NSMutableArray*) getMoves;
- (void) resetBoard;
- (void) displayEmptyBoard;
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

- (id)initWithMove:(int)mv;

@end

////////////////////////////////////////////////////////////////////
//
// TimeInfo
//
////////////////////////////////////////////////////////////////////
@interface TimeInfo : NSObject
{
    int  gameTime;  // Game-time (in seconds).
    int  moveTime;  // Move-time (in seconds).
    int  freeTime;  // Free-time (in seconds).
}

@property (nonatomic) int gameTime;
@property (nonatomic) int moveTime;
@property (nonatomic) int freeTime;

- (id)initWithTime:(TimeInfo*)other;
+ (id)allocTimeFromString:(NSString *)timeContent;

@end
