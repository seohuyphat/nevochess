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
- (void) _handleNetworkEvent_I_TABLE:(NSString*)event;
- (void) _handleNetworkEvent_I_MOVES:(NSString*)event;
- (void) _handleNetworkEvent_MOVE:(NSString*)event;
- (void) _handleNetworkEvent_E_END:(NSString*)event;
- (void) _handleNetworkEvent_RESET:(NSString*)event;

- (NSString*) _generateGuestUserName;
- (int) _generateRandomNumber:(unsigned int)max_value;

@end


///////////////////////////////////////////////////////////////////////////////
//
//    Implementation of Public methods
//
///////////////////////////////////////////////////////////////////////////////

@implementation NetworkBoardViewController

@synthesize _username;

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

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    if ( [[event allTouches] count] != 1 // Valid for single touch only
        ||  _inReview    // Do nothing if we are in the middle of Move-Review.
        || ![self isMyTurnNext] ) // Ignore when it is not my turn.
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
            //*******************
            int row = holder._row;
            int col = holder._column;
            if (!_game.blackAtTopSide) {
                row = 9 - row;
                col = 8 - col;
            }
            //*******************
            int sqSrc = TOSQUARE(row, col);
            [self setHighlightCells:NO]; // Clear old highlight.
            
            _hl_nMoves = [_game generateMoveFrom:sqSrc moves:_hl_moves];
            [self setHighlightCells:YES];
            _selectedPiece = piece;
            [_audioHelper play_wav_sound:@"CLICK"];
            return;
        }
        
    } else {
        holder = (GridCell*)[view hitTestPoint:p LayerMatchCallback:layerIsBitHolder offset:NULL];
    }
    
    // Make a Move from the last selected cell to the current selected cell.
    if(holder && holder._highlighted && _selectedPiece != nil && _hl_nMoves > 0) {
        [self setHighlightCells:NO]; // Clear highlighted.
        
        GridCell *cell = (GridCell*)_selectedPiece.holder;
        //*******************
        int row1 = cell._row;
        int col1 = cell._column;
        int row2 = holder._row;
        int col2 = holder._column;
        if (!_game.blackAtTopSide) {
            row1 = 9 - row1;
            col1 = 8 - col1;
            row2 = 9 - row2;
            col2 = 8 - col2;
        }
        //*******************
        int sqSrc = TOSQUARE(row1, col1);
        int sqDst = TOSQUARE(row2, col2);
        int move = MOVE(sqSrc, sqDst);
        if([_game isLegalMove:move])
        {
            [_game humanMove:row1 fromCol:col1 toRow:row2 toCol:col2];
            
            NSNumber *moveInfo = [NSNumber numberWithInteger:move];
            [self handleNewMove:moveInfo];
            
            // Send over the network.
            NSString* moveStr = [NSString stringWithFormat:@"%d%d%d%d", col1, row1, col2, row2];
            [_connection send_MOVE:_tableId move:moveStr];
            
            // AI's turn.
            //if ( _game.game_result == kXiangQi_InPlay ) {
            //    [self performSelector:@selector(AIMove) onThread:robot withObject:nil waitUntilDone:NO];
            //}
        }
    } else {
        [self setHighlightCells:NO];  // Clear highlighted.
    }
    
    _selectedPiece = nil;  // Reset selected state.
}

#pragma mark -
#pragma mark Delegate callback functions

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

#pragma mark -
#pragma mark Network-event handers

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
                [self _handleNetworkEvent_I_TABLE:content];
            } else if ([op isEqualToString:@"I_MOVES"]) {
                [self _handleNetworkEvent_I_MOVES:content];
            } else if ([op isEqualToString:@"MOVE"]) {
                [self _handleNetworkEvent_MOVE:content];
            } else if ([op isEqualToString:@"E_END"]) {
                [self _handleNetworkEvent_E_END:content];
            } else if ([op isEqualToString:@"RESET"]) {
                [self _handleNetworkEvent_RESET:content];
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

- (void) _handleNetworkEvent_I_TABLE:(NSString*)event
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

    ColorEnum myColor = NC_COLOR_NONE; // Default: an observer.
    if      ([_username isEqualToString:table.redId])   { myColor = NC_COLOR_RED;   }
    else if ([_username isEqualToString:table.blackId]) { myColor = NC_COLOR_BLACK; }
    [self setMyColor:myColor];

    // Reverse the View if necessary.
    if (   (myColor == NC_COLOR_BLACK && _game.blackAtTopSide)
        || (!_game.blackAtTopSide) )
    {
        [self reverseBoardView];
    }
    
    NSString* redInfo = ([table.redId length] == 0 ? @"*"
                         : [NSString stringWithFormat:@"%@ (%@)", table.redId, table.redRating]);
    NSString* blackInfo = ([table.blackId length] == 0 ? @"*"
                           : [NSString stringWithFormat:@"%@ (%@)", table.blackId, table.blackRating]);
    [self setRedLabel:redInfo];
    [self setBlackLabel:blackInfo];
}

- (void) _handleNetworkEvent_I_MOVES:(NSString*)event
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
        [self handleNewMove:moveInfo];
    }
}

- (void) _handleNetworkEvent_MOVE:(NSString*)event
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
    [self handleNewMove:moveInfo];
}

- (void) _handleNetworkEvent_E_END:(NSString*)event
{
    NSArray* components = [event componentsSeparatedByString:@";"];
    NSString* tableId = [components objectAtIndex:0];
    NSString* gameResult = [components objectAtIndex:1];
    
    NSLog(@"%s: Table:[%@] - Game Over: [%@].", __FUNCTION__, tableId, gameResult);
    [self handleEndGameInUI];
}

- (void) _handleNetworkEvent_RESET:(NSString*)event
{
    NSArray* components = [event componentsSeparatedByString:@";"];
    NSString* tableId = [components objectAtIndex:0];
    
    NSLog(@"%s: Table:[%@] - Game Reset.", __FUNCTION__, tableId);
    [self resetBoard];
}

#pragma mark -
#pragma mark Other helper functions

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
