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

#import "BoardViewController.h"
#import "Enums.h"
#import "NevoChessAppDelegate.h"
#import "Grid.h"
#import "Piece.h"
#import "ChessBoardView.h"

BOOL layerIsBit( CALayer* layer )        {return [layer isKindOfClass: [Bit class]];}
BOOL layerIsBitHolder( CALayer* layer )  {return [layer conformsToProtocol: @protocol(BitHolder)];}

///////////////////////////////////////////////////////////////////////////////
//
//    MoveAtom
//
///////////////////////////////////////////////////////////////////////////////

@implementation MoveAtom

@synthesize move;
@synthesize srcPiece;
@synthesize capturedPiece;

- (id)init
{
    self = [super init];
    if (self ) {
        move = nil;
        srcPiece = nil;
        capturedPiece = nil;
    }
    return self;
}

- (void)dealloc
{
    [move release];
    [srcPiece release];
    [capturedPiece release];
    [super dealloc];
}

@end


///////////////////////////////////////////////////////////////////////////////
//
//    Private methods (BoardViewController)
//
///////////////////////////////////////////////////////////////////////////////

@interface BoardViewController (PrivateMethods)

- (id)   _initSoundSystem;
- (void) _ticked:(NSTimer*)timer;
- (void) _updateTimer:(int)color;
- (void) _setHighlightCells:(BOOL)bHighlight;
- (void) _showHighlightOfMove:(int)move;
- (void) _handleNewMove:(NSNumber *)pMove;
- (void) _handleEndGameInUI;

@end


///////////////////////////////////////////////////////////////////////////////
//
//    Implementation of Public methods
//
///////////////////////////////////////////////////////////////////////////////

@implementation BoardViewController

@synthesize nav_toolbar;
@synthesize red_label;
@synthesize black_label;
@synthesize red_time;
@synthesize black_time;
@synthesize red_seat;
@synthesize black_seat;
@synthesize _timer;
@synthesize _tableId;

//
// The designated initializer.
// Override if you create the controller programmatically and want to perform
// customization that is not appropriate for viewDidLoad.
//
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    if (self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]) {
        _timer = nil;
        _audioHelper = [self _initSoundSystem];

        memset(_hl_moves, 0x0, sizeof(_hl_moves));
        _hl_nMoves = 0;
        _hl_lastMove = INVALID_MOVE;
        _selectedPiece = nil;

        _game = (CChessGame*)((ChessBoardView*)self.view).game;
        [_game retain];
        _moves = [[NSMutableArray alloc] initWithCapacity: POC_MAX_MOVES_PER_GAME];
        _nthMove = -1;
        _inReview = NO;
        _latestMove = INVALID_MOVE;

        _tableId = nil;
    }
    
    return self;
}

- (void)_ticked:(NSTimer*)timer
{
    // NOTE: On networked games, at least one Move made by EACH player before
    //       the timer is started. However, it is more user-friendly for
    //       this App (with AI only) to start the timer right after one Move
    //       is made (by RED).
    //
    if ( _game.game_result == kXiangQi_InPlay && [_moves count] > 0 ) {
        [self _updateTimer:[_game get_sdPlayer]];
    }
}

//
// Implement viewDidLoad to do additional setup after loading the view,
// typically from a nib.
//
- (void)viewDidLoad
{
    NSLog(@"%s: ENTER.", __FUNCTION__);
    [super viewDidLoad];
    [activity setHidden:YES];
    [activity stopAnimating];
    [self.view bringSubviewToFront:activity];
    [self.view bringSubviewToFront:nav_toolbar];
    [self.view bringSubviewToFront:red_label];
    [self.view bringSubviewToFront:black_label];
    [self.view bringSubviewToFront:red_time];
    [self.view bringSubviewToFront:black_time];
    [self.view bringSubviewToFront:red_seat];
    [self.view bringSubviewToFront:black_seat];
    _initialTime = [[NSUserDefaults standardUserDefaults] integerForKey:@"time_setting"];
    _redTime = _blackTime = _initialTime * 60;
    [red_time setFont:[UIFont fontWithName:@"DBLCDTempBlack" size:13.0]];
    red_time.text = [NSString stringWithFormat:@"%d:%02d", (_redTime / 60), (_redTime % 60)];

    [black_time setFont:[UIFont fontWithName:@"DBLCDTempBlack" size:13.0]];
    black_time.text = [NSString stringWithFormat:@"%d:%02d", (_blackTime / 60), (_blackTime % 60)];

    self._timer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(_ticked:) userInfo:nil repeats:YES];
}

- (void)didReceiveMemoryWarning
{
	// Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
	
	// Release any cached data, images, etc that aren't in use.
}

- (void)dealloc
{
    [nav_toolbar release];
    [red_label release];
    [black_label release];
    [red_time release];
    [black_time release];
    [activity release];
    [red_seat release];
    [black_seat release];
    [_timer release];
    [_audioHelper release];
    [_game release];
    [_moves release];

    [super dealloc];
}

#pragma mark Button actions

- (IBAction)homePressed:(id)sender
{
    NSLog(@"%s: ENTER.", __FUNCTION__);
}

- (IBAction)resetPressed:(id)sender
{
    NSLog(@"%s: ENTER.", __FUNCTION__);
}

- (IBAction)movePrevPressed:(id)sender
{
    NSLog(@"%s: ENTER.", __FUNCTION__);
}

- (IBAction)moveNextPressed:(id)sender
{
    NSLog(@"%s: ENTER.", __FUNCTION__);
}

- (void) setRedLabel:(NSString*)label
{
    red_label.text = label;
}

- (void) setBlackLabel:(NSString*)label
{
    black_label.text = label;
}


///////////////////////////////////////////////////////////////////////////////
//
//    Implementation of Private methods
//
///////////////////////////////////////////////////////////////////////////////

#pragma mark -
#pragma mark Private methods

- (id) _initSoundSystem
{
    AudioHelper* audioHelper = [[AudioHelper alloc] init];
    
    if ( audioHelper != nil ) {
        NSArray *soundList = [NSArray arrayWithObjects:@"CAPTURE", @"CAPTURE2", @"CLICK",
                              @"DRAW", @"LOSS", @"CHECK", @"CHECK2",
                              @"MOVE", @"MOVE2", @"WIN", @"ILLEGAL",
                              nil];
        for (NSString *sound in soundList) {
            [audioHelper load_wav_sound:sound];
        }
    }
    return audioHelper;
}

- (void) _updateTimer:(int)color
{
    if ( color == 1 ) {
        --_blackTime;
        int min = _blackTime / 60;
        int sec = _blackTime % 60;
        black_time.text = [NSString stringWithFormat:@"%d:%02d", min, sec];
    } else {
        --_redTime;
        int min = _redTime / 60;
        int sec = _redTime % 60;
        red_time.text = [NSString stringWithFormat:@"%d:%02d", min, sec];
    }
}

- (void) _setHighlightCells:(BOOL)bHighlight
{
    // Set (or Clear) highlighted cells.
    for(int i = 0; i < _hl_nMoves; ++i) {
        int sqDst = DST(_hl_moves[i]);
        int row = ROW(sqDst);
        int col = COLUMN(sqDst);
        if ( ! bHighlight ) {
            _hl_moves[i] = 0;
        }
        ((XiangQiSquare*)[_game._grid cellAtRow:row column:col])._highlighted = bHighlight;
    }

    if ( ! bHighlight ) {
        _hl_nMoves = 0;
    }
}

- (void) _showHighlightOfMove:(int)move
{
    if (_hl_lastMove != INVALID_MOVE) {
        _hl_nMoves = 1;
        _hl_moves[0] = _hl_lastMove;
        [self _setHighlightCells:NO];
        _hl_lastMove = INVALID_MOVE;
    }
    
    if (move != INVALID_MOVE) {
        int sqDst = DST(move);
        ((XiangQiSquare*)[_game._grid cellAtRow:ROW(sqDst) column:COLUMN(sqDst)])._highlighted = YES;
        _hl_lastMove = move;
    }
}

- (void) _handleNewMove:(NSNumber *)moveInfo
{
    int  move     = [moveInfo integerValue];
    BOOL isAI     = ([_game get_sdPlayer] == 0);  // AI just made this Move.

    // Delay update the UI if in Preview mode.
    if ( _inReview ) {
        NSAssert1(_latestMove == INVALID_MOVE,
                  @"The latest Move should not be set [%d]", _latestMove);
        _latestMove = move;  // NOTE: Save the Move to be processed later.
        return;
    }
    
    int sqSrc = SRC(move);
    int sqDst = DST(move);
    int row1 = ROW(sqSrc);
    int col1 = COLUMN(sqSrc);
    int row2 = ROW(sqDst);
    int col2 = COLUMN(sqDst);

    NSString *sound = @"MOVE";

    Piece *capture = [_game x_getPieceAtRow:row2 col:col2];
    Piece *piece = [_game x_getPieceAtRow:row1 col:col1];

    if (capture != nil) {
        [capture removeFromSuperlayer];
        sound = (isAI ? @"CAPTURE2" : @"CAPTURE");
    }
    
    [_audioHelper play_wav_sound:sound];
    
    [_game x_movePiece:piece toRow:row2 toCol:col2];
    [self _showHighlightOfMove:move];

    // Check End-Game status.
    int nGameResult = [_game checkGameStatus:isAI];
    if ( nGameResult != kXiangQi_Unknown ) {  // Game Result changed?
        [self _handleEndGameInUI];
    }
    
    // Add this new Move to the Move-History.
    MoveAtom *pMove = [[MoveAtom alloc] init];
    pMove.srcPiece = piece;
    pMove.capturedPiece = capture;
    pMove.move = [NSNumber numberWithInteger:move];
    [_moves addObject:pMove];
    [pMove release];
    _nthMove = [_moves count];
}

- (void) _handleEndGameInUI
{
    NSString *sound = nil;
    NSString *msg   = nil;

    switch ( _game.game_result ) {
        case kXiangQi_YouWin:
            sound = @"WIN";
            msg = NSLocalizedString(@"You win,congratulations!", @"");
            break;
        case kXiangQi_ComputerWin:
            sound = @"LOSS";
            msg = NSLocalizedString(@"Computer wins. Don't give up, please try again!", @"");
            break;
        case kXiangqi_YouLose:
            sound = @"LOSS";
            msg = NSLocalizedString(@"You lose. You may try again!", @"");
            break;
        case kXiangQi_Draw:
            sound = @"DRAW";
            msg = NSLocalizedString(@"Sorry,we are in draw!", @"");
            break;
        case kXiangQi_OverMoves:
            sound = @"ILLEGAL";
            msg = NSLocalizedString(@"Sorry,we made too many moves, please restart again!", @"");
            break;
        default:
            break;  // Do nothing
    }
    
    if ( !sound ) return;

    [_audioHelper play_wav_sound:sound];

    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"NevoChess"
                                                    message:msg
                                                   delegate:self 
                                          cancelButtonTitle:nil
                                          otherButtonTitles:@"OK", nil];
    alert.tag = POC_ALERT_END_GAME;
    [alert show];
    [alert release];
}

- (void) saveGame
{
    NSLog(@"%s: ENTER.", __FUNCTION__);
}

- (void) rescheduleTimer
{
    if (self._timer) [self._timer invalidate];
    self._timer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(_ticked:) userInfo:nil repeats:YES];
}

- (void) resetBoard
{
    [self _setHighlightCells:NO];
    _selectedPiece = nil;
    [self _showHighlightOfMove:INVALID_MOVE];  // Clear the last highlight.
    _redTime = _blackTime = _initialTime * 60;
    memset(_hl_moves, 0x0, sizeof(_hl_moves));
    red_time.text = [NSString stringWithFormat:@"%d:%02d", (_redTime / 60), (_redTime % 60)];
    black_time.text = [NSString stringWithFormat:@"%d:%02d", (_blackTime / 60), (_blackTime % 60)];
    
    [_game reset_game];
    [_moves removeAllObjects];
    _nthMove = -1;
    _inReview = NO;
    _latestMove = INVALID_MOVE;
}

@end
