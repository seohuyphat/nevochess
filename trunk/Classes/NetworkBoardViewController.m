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

#import "NetworkBoardViewController.h"
#import "Enums.h"
#import "NevoChessAppDelegate.h"
#import "Grid.h"
#import "Piece.h"
#import "ChessBoardView.h"


@interface NetworkBoardViewController (PrivateMethods)
- (NSMutableDictionary*) _allocNewEvent:(NSString*)event;
- (void) handleNetworkEvent_I_TABLE:(NSString*)event;
- (void) handleNetworkEvent_I_MOVES:(NSString*)event;
- (void) handleNetworkEvent_MOVE:(NSString*)event;
- (void) handleNetworkEvent_E_END:(NSString*)event;

- (NSString*) _generateGuestUserName;
- (int) _generateRandomNumber:(unsigned int)max_value;

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

@implementation NetworkBoardViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    NSLog(@"%s: ENTER.", __FUNCTION__);
    if (self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]) {
        _username = nil;
        _password = nil;

        _connection = [[NetworkConnection alloc] init];
        _connection.delegate = self;
        [_connection connect];
    }
    
    return self;
}

- (void)viewDidLoad
{
    NSLog(@"%s: ENTER.", __FUNCTION__);
    [super viewDidLoad];
} 

- (void)viewDidAppear:(BOOL)animated 
{
    NSLog(@"%s: ENTER.", __FUNCTION__);
    [super viewDidAppear:animated];
    if (_username == nil)
    {
        LoginViewController *loginController = [[LoginViewController alloc] initWithNibName:@"LoginView" bundle:nil];
        loginController.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
        loginController.delegate = self;
        [self presentModalViewController:loginController animated:YES];
    }
}

- (void)dealloc
{
    NSLog(@"%s: ENTER.", __FUNCTION__);
    [_connection release];
    [super dealloc];
}


- (IBAction)homePressed:(id)sender
{
    NSLog(@"%s: ENTER.", __FUNCTION__);
    [_connection send_LOGOUT];

    // !!!!!!!!!!!!!!!!!!!
    // NOTE: Let the handler for the 'NSStreamEventEndEncountered' event
    //       take care of closing the IO streams.
    // !!!!!!!!!!!!!!!!!!!
}

- (IBAction)resetPressed:(id)sender
{
    [_connection send_LIST];
}

- (IBAction)movePrevPressed:(id)sender
{
    if (_nthMove < 1) {  // No Move made yet?
        return;
    }
    
    _inReview = YES;  // Enter the Move-Review mode immediately!
    
    MoveAtom *pMove = [_moves objectAtIndex:--_nthMove];
    int move = [(NSNumber*)pMove.move intValue];
    int sqSrc = SRC(move);
    int sqDst = DST(move);
    [_audioHelper play_wav_sound:@"MOVE"]; // TODO: mono-type "move" sound
    
    // For Move-Review, just reverse the move order (sqDst->sqSrc)
    // Since it's only a review, no need to make actual move in
    // the underlying game logic.
    //
    [_game x_movePiece:(Piece*)pMove.srcPiece toRow:ROW(sqSrc) toCol:COLUMN(sqSrc)];
    if (pMove.capturedPiece) {
        [_game x_movePiece:(Piece*)pMove.capturedPiece toRow:ROW(sqDst) toCol:COLUMN(sqDst)];
    }
    
    int prevMove = INVALID_MOVE;
    if (_nthMove > 0) {  // No more Move?
        int prevIndex = _nthMove - 1;
        pMove = [_moves objectAtIndex:prevIndex];
        prevMove = [(NSNumber*)pMove.move intValue];
    }
    [self _showHighlightOfMove:prevMove];
}

- (IBAction)moveNextPressed:(id)sender
{
    BOOL bNext = NO; // One "Next" click was serviced.
    // This variable is introduced to enforce the rule:
    // "Only one Move is replayed PER click".
    //
    int nMoves = [_moves count];
    if (_nthMove >= 0 && _nthMove < nMoves) {
        MoveAtom *pMove = [_moves objectAtIndex:_nthMove++];
        int move = [(NSNumber*)pMove.move intValue];
        int sqDst = DST(move);
        int row2 = ROW(sqDst);
        int col2 = COLUMN(sqDst);
        [_audioHelper play_wav_sound:@"MOVE"];  // TODO: mono-type "move" sound
        Piece *capture = [_game x_getPieceAtRow:row2 col:col2];
        if (capture) {
            [capture removeFromSuperlayer];
        }
        [_game x_movePiece:(Piece*)pMove.srcPiece toRow:row2 toCol:col2];
        [self _showHighlightOfMove:move];
        bNext = YES;
    }
    
    if (_nthMove == nMoves)  // Are we reaching the latest Move end?
    {
        if ( _latestMove == INVALID_MOVE ) {
            _inReview = NO;
        }
        else if ( ! bNext ) {
            _inReview = NO;
            // Perform the latest Move if not yet done so.
            NSNumber *moveInfo = [NSNumber numberWithInteger:_latestMove];
            _latestMove = INVALID_MOVE;
            [self _handleNewMove:moveInfo];
        }
    }
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    if ( [[event allTouches] count] != 1 // Valid for single touch only
        ||  _inReview    // Do nothing if we are in the middle of Move-Review.
        || [_game get_sdPlayer] ) // Ignore any touch when it is robot's turn.
    { 
        return;
    }
    
    ChessBoardView *view = (ChessBoardView*) self.view;
    GridCell *holder = nil;
    
    UITouch *touch = [[touches allObjects] objectAtIndex:0];
    CGPoint p = [touch locationInView:self.view];
    Piece *piece = (Piece*)[view hitTestPoint:p LayerMatchCallback:layerIsBit offset:NULL];
    if(piece) {
        // Generate moves for the selected piece.
        holder = (GridCell*)piece.holder;
        if(!_selectedPiece || (_selectedPiece._owner == piece._owner)) {
            int sqSrc = TOSQUARE(holder._row, holder._column);
            [self _setHighlightCells:NO]; // Clear old highlight.
            
            _hl_nMoves = [_game generateMoveFrom:sqSrc moves:_hl_moves];
            [self _setHighlightCells:YES];
            _selectedPiece = piece;
            [_audioHelper play_wav_sound:@"CLICK"];
            return;
        }
        
    } else {
        holder = (GridCell*)[view hitTestPoint:p LayerMatchCallback:layerIsBitHolder offset:NULL];
    }
    
    // Make a Move from the last selected cell to the current selected cell.
    if(holder && holder._highlighted && _selectedPiece != nil && _hl_nMoves > 0) {
        [self _setHighlightCells:NO]; // Clear highlighted.
        
        int sqDst = TOSQUARE(holder._row, holder._column);
        GridCell *cell = (GridCell*)_selectedPiece.holder;
        int sqSrc = TOSQUARE(cell._row, cell._column);
        int move = MOVE(sqSrc, sqDst);
        if([_game isLegalMove:move])
        {
            [_game humanMove:cell._row fromCol:cell._column toRow:ROW(sqDst) toCol:COLUMN(sqDst)];
            
            NSNumber *moveInfo = [NSNumber numberWithInteger:move];
            [self _handleNewMove:moveInfo];
            
            // Send over the network.
            NSString* moveStr = [NSString stringWithFormat:@"%d%d%d%d", cell._column, cell._row, COLUMN(sqDst), ROW(sqDst)];
            [_connection send_MOVE:_tableId move:moveStr];
            
            // AI's turn.
            //if ( _game.game_result == kXiangQi_InPlay ) {
            //    [self performSelector:@selector(AIMove) onThread:robot withObject:nil waitUntilDone:NO];
            //}
        }
    } else {
        [self _setHighlightCells:NO];  // Clear highlighted.
    }
    
    _selectedPiece = nil;  // Reset selected state.
}

- (void) handleLoginRequest:(NSString *)button username:(NSString*)name password:(NSString*)passwd
{
    if (button != nil)
    {
        NSLog(@"%s: Username = [%@:%@]", __FUNCTION__, name, passwd);
        _username = ([name length] == 0 ? [self _generateGuestUserName] : name);
        _password = passwd;
        [_connection setLoginInfo:_username password:_password];
        [_connection send_LOGIN];
    }
    [self dismissModalViewControllerAnimated:YES];
}

- (void) handeTableJoin:(TableInfo *)table color:(NSString*)joinColor
{
    [self dismissModalViewControllerAnimated:YES];
    if ([self._tableId isEqualToString:table.tableId]) {
        NSLog(@"%s: Same table [%@]. Ignore request.", __FUNCTION__, table.tableId);
        return;
    } else if (self._tableId) {
        [_connection send_LEAVE:self._tableId]; // Leave the old table.
        self._tableId = nil; 
        [self resetBoard];
    }
    [_connection send_JOIN:table.tableId color:joinColor];
}

- (void) handleNetworkEvent:(ConnectionEventEnum)code event:(NSString*)event
{
    switch(code)
    {
        case NC_CONN_EVENT_OPEN:
        {
            NSLog(@"%s: Got NC_CONN_EVENT_OPEN.", __FUNCTION__);
            break;
        }
        case NC_CONN_EVENT_DATA:
        {
            NSLog(@"%s: A new event [%@].", __FUNCTION__, event);
            NSMutableDictionary* newEvent = [self _allocNewEvent:event];
            NSString* op = [newEvent objectForKey:@"op"];
            NSString* content = [newEvent objectForKey:@"content"];

            if ([op isEqualToString:@"LIST"]) {
                TableListViewController *listController = [[TableListViewController alloc] initWithList:content];
                listController.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
                listController.delegate = self;
                [self presentModalViewController:listController animated:YES];
            } else if ([op isEqualToString:@"I_TABLE"]) {
                [self handleNetworkEvent_I_TABLE:content];
            } else if ([op isEqualToString:@"I_MOVES"]) {
                [self handleNetworkEvent_I_MOVES:content];
            } else if ([op isEqualToString:@"MOVE"]) {
                [self handleNetworkEvent_MOVE:content];
            } else if ([op isEqualToString:@"E_END"]) {
                [self handleNetworkEvent_E_END:content];
            }

            [newEvent release];
            break;
        }
        case NC_CONN_EVENT_END:
        {
            NSLog(@"%s: Got NC_CONN_EVENT_END.", __FUNCTION__);
            [((NevoChessAppDelegate*)[[UIApplication sharedApplication] delegate]).navigationController popViewControllerAnimated:YES];
            break;
        }
    }
}

- (NSMutableDictionary*) _allocNewEvent:(NSString*)event
{
    NSMutableDictionary* entries = [[NSMutableDictionary alloc] init];
    
    NSArray *components = [event componentsSeparatedByString:@"&"];
    for (NSString *entry in components) {
        NSArray *pair = [entry componentsSeparatedByString:@"="];
        [entries setValue:[pair objectAtIndex:1] forKey:[pair objectAtIndex:0]];
    }
    
    return entries;
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

- (void) handleNetworkEvent_I_TABLE:(NSString*)event
{
    NSArray* components = [event componentsSeparatedByString:@";"];
    TableInfo* table = [TableInfo new];
    table.tableId = [components objectAtIndex:0];
    table.redId = [components objectAtIndex:6];
    table.redRating = [components objectAtIndex:7];
    table.blackId = [components objectAtIndex:8];
    table.blackRating = [components objectAtIndex:9];

    if (self._tableId && ![self._tableId isEqualToString:table.tableId]) {
        [self resetBoard];
    }
    self._tableId = table.tableId; 

    NSString* redInfo = ([table.redId length] == 0 ? @"*"
                         : [NSString stringWithFormat:@"%@ (%@)", table.redId, table.redRating]);
    NSString* blackInfo = ([table.blackId length] == 0 ? @"*"
                           : [NSString stringWithFormat:@"%@ (%@)", table.blackId, table.blackRating]);
    [self setRedLabel:redInfo];
    [self setBlackLabel:blackInfo];
}

- (void) handleNetworkEvent_I_MOVES:(NSString*)event
{
    NSArray* components = [event componentsSeparatedByString:@";"];
    NSString* tableId = [components objectAtIndex:0];
    NSString* movesStr = [components objectAtIndex:1];
    NSLog(@"%s: [#%@: %@].", __FUNCTION__, tableId, movesStr);
    NSArray* moves = [movesStr componentsSeparatedByString:@"/"];
    for (NSString *moveStr in moves) {
        
        int row1 = [moveStr characterAtIndex:1] - '0';
        int col1 = [moveStr characterAtIndex:0] - '0';
        int row2 = [moveStr characterAtIndex:3] - '0';
        int col2 = [moveStr characterAtIndex:2] - '0';
        NSLog(@"%s: MOVE [%d%d -> %d%d].", __FUNCTION__, row1, col1, row2, col2);
        
        int sqSrc = TOSQUARE(row1, col1);
        int sqDst = TOSQUARE(row2, col2);
        int move = MOVE(sqSrc, sqDst);
        
        [_game humanMove:ROW(sqSrc) fromCol:COLUMN(sqSrc)
                   toRow:ROW(sqDst) toCol:COLUMN(sqDst)];
        
        NSNumber *moveInfo = [NSNumber numberWithInteger:move];
        [self _handleNewMove:moveInfo];
    }
}

- (void) handleNetworkEvent_MOVE:(NSString*)event
{
    NSArray* components = [event componentsSeparatedByString:@";"];
    NSString* tableId = [components objectAtIndex:0];
    NSString* moveStr = [components objectAtIndex:2];

    if ( ! [self._tableId isEqualToString:tableId] ) {
        NSLog(@"%s: Move:[%@] from table:[%@] ignored.", __FUNCTION__, moveStr, tableId);
        return;
    }
    int row1 = [moveStr characterAtIndex:1] - '0';
    int col1 = [moveStr characterAtIndex:0] - '0';
    int row2 = [moveStr characterAtIndex:3] - '0';
    int col2 = [moveStr characterAtIndex:2] - '0';
    NSLog(@"%s: MOVE [%d%d -> %d%d].", __FUNCTION__, row1, col1, row2, col2);
    
    int sqSrc = TOSQUARE(row1, col1);
    int sqDst = TOSQUARE(row2, col2);
    int move = MOVE(sqSrc, sqDst);
    
    [_game humanMove:ROW(sqSrc) fromCol:COLUMN(sqSrc)
               toRow:ROW(sqDst) toCol:COLUMN(sqDst)];
    
    NSNumber *moveInfo = [NSNumber numberWithInteger:move];
    [self _handleNewMove:moveInfo];
}

- (void) handleNetworkEvent_E_END:(NSString*)event
{
    NSArray* components = [event componentsSeparatedByString:@";"];
    NSString* tableId = [components objectAtIndex:0];
    NSString* gameResult = [components objectAtIndex:1];
    
    NSLog(@"%s: Table:[%@] - Game Over: [%@].", __FUNCTION__, tableId, gameResult);
}

- (NSString*) _generateGuestUserName
{
    const const char* GUEST_PREFIX  = "Guest#";
    const unsigned int MAX_GUEST_ID = 10000;

    const int randNum = [self _generateRandomNumber:MAX_GUEST_ID];
    NSString* sGuestId = [NSString stringWithFormat:@"%sip%d", GUEST_PREFIX, randNum];
    return sGuestId;
}

- (int) _generateRandomNumber:(unsigned int)max_value
{        
    const unsigned int _RAND_MAX = (2<<31)-1;
    const int randNum =
        1 + (int) ((double)max_value * (arc4random() / (_RAND_MAX + 1.0)));
    
    return randNum;
}

@end
