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

- (void) _connectToNetwork;
- (void) _showLoginView:(NSString*)errorStr;
- (void) _dismissLoginView;
- (void) _dismissListTableView;

- (NSMutableDictionary*) _allocNewEvent:(NSString*)event;
- (void) _handleNetworkEvent_LOGIN:(NSString*)event;
- (void) _handleNetworkEvent_LIST:(NSString*)event;
- (void) _handleNetworkEvent_I_TABLE:(NSString*)event;
- (void) _handleNetworkEvent_I_MOVES:(NSString*)event;
- (void) _handleNetworkEvent_MOVE:(NSString*)event;
- (void) _handleNetworkEvent_E_END:(NSString*)event;
- (void) _handleNetworkEvent_RESET:(NSString*)event;
- (void) _handleNetworkEvent_E_JOIN:(NSString*)event;
- (void) _handleNetworkEvent_LEAVE:(NSString*)event;

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
@synthesize _password;
@synthesize _redId;
@synthesize _blackId;
@synthesize _connection;
@synthesize _loginController;
@synthesize _tableListController;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    NSLog(@"%s: ENTER.", __FUNCTION__);
    if (self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]) {
        self._username = nil;
        self._password = nil;
        self._redId = nil;
        self._blackId = nil;
        _isGameOver = NO;
        _loginCanceled = NO;
        _loginAuthenticated = NO;
        _logoutPending = NO;
        self._loginController = nil;
        self._tableListController = nil;

        self._connection = nil;
        [self _connectToNetwork];
    }
    
    return self;
}

- (void)viewDidLoad
{
    NSLog(@"%s: ENTER.", __FUNCTION__);
    [super viewDidLoad];
} 

- (void)viewWillAppear:(BOOL)animated
{
    NSLog(@"%s: ENTER.", __FUNCTION__);
    [super viewWillAppear:animated];
    if (_loginController != nil) {
        NSLog(@"%s: Hide the navigation-bar.", __FUNCTION__);
        self.navigationController.navigationBarHidden = YES;
        return;
    }
}

- (void)viewDidAppear:(BOOL)animated 
{
    NSLog(@"%s: ENTER.", __FUNCTION__);
    [super viewDidAppear:animated];
    if (_username != nil) {
        return;
    }
    else if (_loginController != nil) {
        return;
    }
    else if (!_loginCanceled)
    {
        NSLog(@"%s: Show the Login view...", __FUNCTION__);
        [self _showLoginView:@""];
    }
}

- (void)dealloc
{
    self._username = nil;
    self._password = nil;
    self._connection = nil;
    self._redId = nil;
    self._blackId = nil;
    self._loginController = nil;
    self._tableListController = nil;
    [super dealloc];
}


- (IBAction)homePressed:(id)sender
{
    NSLog(@"%s: ENTER.", __FUNCTION__);
    if (_connection == nil) {
        [self goBackToHomeMenu];
    }
    else if (_loginAuthenticated) {
        _logoutPending = YES;
        [_connection send_LOGOUT];
    } else {
        NSLog(@"%s: Disconnect the network connection...", __FUNCTION__);
        [_connection disconnect];
        self._connection = nil;
        [self goBackToHomeMenu];
    }


    // !!!!!!!!!!!!!!!!!!!
    // NOTE: Let the handler for the 'NSStreamEventEndEncountered' event
    //       take care of closing the IO streams.
    // !!!!!!!!!!!!!!!!!!!
}

- (IBAction)resetPressed:(id)sender
{
    [_connection send_LIST];
}

- (void) onLocalMoveMade:(int)move
{
    int sqSrc = SRC(move);
    int sqDst = DST(move);
    int row1 = ROW(sqSrc);
    int col1 = COLUMN(sqSrc);
    int row2 = ROW(sqDst);
    int col2 = COLUMN(sqDst);

    // Send over the network.
    NSString* moveStr = [NSString stringWithFormat:@"%d%d%d%d", col1, row1, col2, row2];
    [_connection send_MOVE:_tableId move:moveStr];
}

- (BOOL) isGameReady
{
    NSLog(@"%s: ENTER.", __FUNCTION__);
    return (   !_isGameOver
            && _redId != nil && _blackId != nil );
}

#pragma mark -
#pragma mark Delegate callback functions

- (void) handleLoginRequest:(NSString *)button username:(NSString*)name password:(NSString*)passwd
{
    NSLog(@"%s: ENTER.", __FUNCTION__);
    
    if (button == nil) // "Cancel" button clicked?
    {
        NSLog(@"%s: Login got canceled.", __FUNCTION__);
        _loginCanceled = YES;
        self._loginController = nil;
    }
    else {
        NSLog(@"%s: Username = [%@:%@]", __FUNCTION__, name, passwd);
        if ([name length] == 0) {
            name = [self _generateGuestUserName];
            NSLog(@"%s: Generated a Guest username: [%@].", __FUNCTION__, name);
        }
        self._username = name;
        self._password = passwd;
        [self _connectToNetwork]; // Connect if needed.
        [_connection setLoginInfo:_username password:_password];
        [_connection send_LOGIN];
    }
}

- (void) handeBackFromList
{
    [self _dismissListTableView];
}

- (void) handeNewFromList
{
    [self _dismissListTableView];

    if (self._tableId) {
        [_connection send_LEAVE:self._tableId]; // Leave the old table.
        self._tableId = nil; 
        [self resetBoard];
    }
    [_connection send_NEW:@"900/180/20"];
}

- (void) handeRefreshFromList
{
    NSLog(@"%s: ENTER.", __FUNCTION__);
    // DO NOT dismiss the existing List-of-Tables view!

    [_connection send_LIST];
}

- (void) handeTableJoin:(TableInfo *)table color:(NSString*)joinColor
{
    [self _dismissListTableView];

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

- (void) _connectToNetwork
{
    NSLog(@"%s: ENTER.", __FUNCTION__);
    if (self._connection == nil) {
        NSLog(@"%s: Connecting to network...", __FUNCTION__);
        self._connection = [[NetworkConnection alloc] init];
        _connection.delegate = self;
        [_connection connect];
    }
}

- (void) _showLoginView:(NSString*)errorStr
{
    NSLog(@"%s: ENTER.", __FUNCTION__);
    if (self._loginController == nil) {
        NSLog(@"%s: Creating new Login view...", __FUNCTION__);
        self._loginController = [[LoginViewController alloc] initWithNibName:@"LoginView" bundle:nil];
        _loginController.delegate = self;
    }
    [_loginController setErrorString:errorStr];
    [self.navigationController pushViewController:_loginController animated:YES];
    self.navigationController.navigationBarHidden = NO;
}

- (void) _dismissLoginView
{
    [self.navigationController popViewControllerAnimated:YES];
    self._loginController = nil;
}

- (void) _dismissListTableView
{
    [self dismissModalViewControllerAnimated:YES];
    self._tableListController = nil;
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
            int code = [[newEvent objectForKey:@"code"] integerValue];
            NSString* content = [newEvent objectForKey:@"content"];

            if (code != 0) {  // Error
                if ([op isEqualToString:@"LOGIN"]) {
                    NSLog(@"%s: Login failed. Error: [%@].", __FUNCTION__, content);
                    [self _showLoginView:content];
                } else {
                    NSLog(@"%s: Received an ERROR event: [%@].", __FUNCTION__, content);
                }
            }
            else {
                if ([op isEqualToString:@"LOGIN"]) {
                    [self _handleNetworkEvent_LOGIN:content];
                } else if ([op isEqualToString:@"LIST"]) {
                    [self _handleNetworkEvent_LIST:content];
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
                } else if ([op isEqualToString:@"E_JOIN"]) {
                    [self _handleNetworkEvent_E_JOIN:content];
                } else if ([op isEqualToString:@"LEAVE"]) {
                    [self _handleNetworkEvent_LEAVE:content];
                }
            }

            [newEvent release];
            break;
        }
        case NC_CONN_EVENT_END:
        {
            NSLog(@"%s: Got NC_CONN_EVENT_END.", __FUNCTION__);
            self._connection = nil;
            if (_logoutPending) {
                [self goBackToHomeMenu];
            }
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

- (void) _handleNetworkEvent_LOGIN:(NSString*)event
{
    NSLog(@"%s: ENTER.", __FUNCTION__);
    _loginAuthenticated = YES;
    if (_loginController != nil) {
        NSLog(@"%s: Destroy Login view...", __FUNCTION__);
        self._loginController = nil;
    }
}

- (void) _handleNetworkEvent_LIST:(NSString*)event
{
    NSLog(@"%s: ENTER.", __FUNCTION__);
    if (_tableListController == nil) {
        self._tableListController = [[TableListViewController alloc] initWithList:event];
        _tableListController.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
        _tableListController.delegate = self;
        [self presentModalViewController:_tableListController animated:YES];
    } else {
        [_tableListController reinitWithList:event];
    }

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
    self._redId = ([table.redId length] == 0 ? nil : table.redId);
    self._blackId = ([table.blackId length] == 0 ? nil : table.blackId);
    _isGameOver = NO;
    [table release];
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

    if ( [self._tableId isEqualToString:tableId] ) {
        _isGameOver = YES;
    }
    [self handleEndGameInUI];
}

- (void) _handleNetworkEvent_RESET:(NSString*)event
{
    NSArray* components = [event componentsSeparatedByString:@";"];
    NSString* tableId = [components objectAtIndex:0];
    
    NSLog(@"%s: Table:[%@] - Game Reset.", __FUNCTION__, tableId);
    [self resetBoard];
    _isGameOver = NO;
}

- (void) _handleNetworkEvent_E_JOIN:(NSString*)event
{
    NSArray* components = [event componentsSeparatedByString:@";"];
    NSString* tableId = [components objectAtIndex:0];
    NSString* pid = [components objectAtIndex:1];
    NSString* rating = [components objectAtIndex:2];
    NSString* color = [components objectAtIndex:3];

    NSString* playerInfo = ([pid length] == 0 ? @"*"
                            : [NSString stringWithFormat:@"%@ (%@)", pid, rating]);

    if ( ! [self._tableId isEqualToString:tableId] ) {
        NSLog(@"%s: E_JOIN:[%@ as %@] from table:[%@] ignored.", __FUNCTION__, playerInfo, color, tableId);
        return;
    }
    if ([color isEqualToString:@"Red"]) {
        self._redId = pid;
        [self setRedLabel:playerInfo];
    } else if ([color isEqualToString:@"Black"]) {
        self._blackId = pid;
        [self setBlackLabel:playerInfo];
    } else if ([color isEqualToString:@"None"]) {
        NSLog(@"%s: Player: [%@] joined as an observer.", __FUNCTION__, playerInfo);
        if ([pid isEqualToString:self._redId]) {
            self._redId = nil;
            [self setRedLabel:@"*"];
        } else if ([pid isEqualToString:self._blackId]) {
            self._blackId = nil;
            [self setBlackLabel:@"*"];
        }
    }
}

- (void) _handleNetworkEvent_LEAVE:(NSString*)event
{
    NSArray* components = [event componentsSeparatedByString:@";"];
    NSString* tableId = [components objectAtIndex:0];
    NSString* pid = [components objectAtIndex:1];

    if ( ! [self._tableId isEqualToString:tableId] ) {
        NSLog(@"%s: E_LEAVE:[%@] from table:[%@] ignored.", __FUNCTION__, pid, tableId);
        return;
    }
    if ([pid isEqualToString:self._redId]) {
        self._redId = nil;
        [self setRedLabel:@"*"];
    } else if ([pid isEqualToString:self._blackId]) {
        self._blackId = nil;
        [self setBlackLabel:@"*"];
    }
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