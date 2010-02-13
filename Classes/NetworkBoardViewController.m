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

@interface NetworkBoardViewController (PrivateMethods)

- (void) _handleCommandLogout;
- (void) _connectToNetwork;
- (void) _showLoginView:(NSString*)errorStr;
- (void) _showListTableView:(NSString*)event;
- (void) _dismissLoginView;
- (void) _dismissListTableView;
- (void) _resetAndClearTable;
- (void) _onNewMessage:(NSString*)msg from:(NSString*)pid;

- (NSMutableDictionary*) _allocNewEvent:(NSString*)event;
- (void) _handleNetworkEvent_LOGIN:(int)code withContent:(NSString*)event;
- (void) _handleNetworkEvent_LIST:(NSString*)event;
- (void) _handleNetworkEvent_I_TABLE:(NSString*)event;
- (void) _handleNetworkEvent_I_MOVES:(NSString*)event;
- (void) _handleNetworkEvent_MOVE:(NSString*)event;
- (void) _handleNetworkEvent_E_END:(NSString*)event;
- (void) _handleNetworkEvent_RESET:(NSString*)event;
- (void) _handleNetworkEvent_E_JOIN:(NSString*)event;
- (void) _handleNetworkEvent_LEAVE:(NSString*)event;
- (void) _handleNetworkEvent_UPDATE:(NSString*)event;
- (void) _handleNetworkEvent_MSG:(NSString*)event;
- (void) _handleNetworkEvent_DRAW:(NSString*)event;
- (void) _handleNetworkEvent_INVITE:(NSString*)event toTable:(NSString*)tableId;

- (NSString*) _generateGuestUserName;
- (int) _generateRandomNumber:(unsigned int)max_value;

@end

///////////////////////////////////////////////////////////////////////////////
//
//    Implementation of Public methods
//
///////////////////////////////////////////////////////////////////////////////

@implementation NetworkBoardViewController

@synthesize _username, _password, _rating;
@synthesize _redId;
@synthesize _blackId;
@synthesize _connection;
@synthesize _loginController;
@synthesize _tableListController;
@synthesize _messageListController;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    NSLog(@"%s: ENTER.", __FUNCTION__);
    if (self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]) {
        self._username = nil;
        self._password = nil;
        self._rating = nil;
        self._redId = nil;
        self._blackId = nil;
        _isGameOver = NO;
        _loginCanceled = NO;
        _loginAuthenticated = NO;
        _logoutPending = NO;
        self._loginController = nil;
        self._tableListController = nil;

        self._messageListController = [[MessageListViewController alloc] initWithNibName:@"MessageListView" bundle:nil];
        _messageListController.delegate = self;

        self._connection = nil;
        [self _connectToNetwork];
    }
    
    return self;
}

- (void)viewDidLoad
{
    NSLog(@"%s: ENTER.", __FUNCTION__);
    [super viewDidLoad];

    // Replace the image of "addButton" with Search image.
    NSArray* items = nav_toolbar.items;
    UIBarButtonItem* addButton = (UIBarButtonItem*) [items objectAtIndex:2];
    NSMutableArray* newItems = [NSMutableArray arrayWithArray:items];
    UIBarButtonItem* newButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSearch 
                                                                               target:addButton.target action:addButton.action];
    newButton.style = UIBarButtonItemStylePlain;
    [newItems replaceObjectAtIndex:2 withObject:newButton];
    [newButton release];
    nav_toolbar.items = newItems;

    _messagesButton = (UIBarButtonItem*) [items objectAtIndex:([items count]-1)];
    _messagesButton.enabled = NO;
} 

- (void)viewWillAppear:(BOOL)animated
{
    NSLog(@"%s: ENTER.", __FUNCTION__);
    [super viewWillAppear:animated];

    NSLog(@"%s: Hide the navigation-bar.", __FUNCTION__);
    self.navigationController.navigationBarHidden = YES;

    _messagesButton.title = @"0";
}

- (void)viewDidAppear:(BOOL)animated 
{
    NSLog(@"%s: ENTER.", __FUNCTION__);
    [super viewDidAppear:animated];

    if (!_loginAuthenticated && !_loginCanceled)
    {
        NSLog(@"%s: Show the Login view...", __FUNCTION__);
        [self _showLoginView:@""];
    }
}

- (void) didReceiveMemoryWarning
{
	// Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
	
	// Release any cached data, images, etc that aren't in use.
    self._tableListController = nil;
    self._messageListController = nil;
}

- (void)dealloc
{
    [_username release];
    [_password release];
    [_rating release];
    self._connection = nil;
    [_redId release];
    [_blackId release];
    self._loginController = nil;
    self._tableListController = nil;
    self._messageListController = nil;
    [super dealloc];
}


- (IBAction)homePressed:(id)sender
{
    NSString* title = nil;
    if (_username) {
        title = [NSString stringWithFormat:@"%@ (%@)", _username, _rating];
    }
    NSString* state = @"logout";
    BoardActionSheet* actionSheet = [[BoardActionSheet alloc] initWithTableState:state delegate:self title:title];
    [actionSheet showInView:self.view];
    [actionSheet release];
}

- (void) _handleCommandLogout
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

// 'Reset' is now a LIST command.
- (IBAction)resetPressed:(id)sender
{
    if (!_loginAuthenticated) {
        [self _showLoginView:@""];
        return;
    }
    [self _showListTableView:nil];
    [_connection send_LIST];
}

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    NSLog(@"%s: ENTER. buttonIndex = [%d].", __FUNCTION__, buttonIndex);

    BoardActionSheet* boardActionSheet = (BoardActionSheet*)actionSheet;
    NSInteger buttonValue = [boardActionSheet valueOfClickedButtonAtIndex:buttonIndex];

    if (buttonValue == ACTION_INDEX_LOGOUT) {
        [self _handleCommandLogout];
        return;
    }
    if (!_tableId) {
        NSLog(@"%s: No current table. Do nothing.", __FUNCTION__);
        return;
    }

    switch (buttonValue)
    {
        case ACTION_INDEX_CLOSE:
            NSLog(@"%s: Leave table [%@].", __FUNCTION__, _tableId);
            [_connection send_LEAVE:_tableId];
            self._tableId = nil; 
            [self displayEmptyBoard];
            break;
        case ACTION_INDEX_RESIGN:
            [_connection send_RESIGN:_tableId];
            break;
        case ACTION_INDEX_DRAW:
            [_connection send_DRAW:_tableId];
            break;
        case ACTION_INDEX_RESET:
            [_connection send_RESET:_tableId];
            break;
        default:
            break; // Do nothing.
    };
}

- (IBAction)actionPressed:(id)sender
{
    NSString* state = @"";
    NSString* title = nil;

    if (_tableId)
    {
        title = [NSString stringWithFormat:@"Table #%@", _tableId];
        if (_myColor == NC_COLOR_RED || _myColor == NC_COLOR_BLACK)
        {
            if (_isGameOver) {
                state = @"ended";
            } else {
                state = ([_game getMoveCount] == 0 ? @"ready" : @"play");
            }
        } else {
            state = @"view";
        }
    }

    BoardActionSheet* actionSheet = [[BoardActionSheet alloc] initWithTableState:state delegate:self title:title];
    [actionSheet showInView:self.view];
    [actionSheet release];
}

- (IBAction)messagesPressed:(id)sender
{
    [self.navigationController pushViewController:_messageListController animated:YES];
    self.navigationController.navigationBarHidden = NO;
    [_messageListController setTableId:_tableId];
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
    return ( !_isGameOver && _redId && _blackId );
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
        [self _dismissLoginView];
        return;
    }

    NSLog(@"%s: Username = [%@:%@]", __FUNCTION__, name, passwd);
    if ([button isEqualToString:@"guest"])
    {
        name = [self _generateGuestUserName];
        NSLog(@"%s: Generated a Guest username: [%@].", __FUNCTION__, name);
    }
    self._username = name;
    self._password = passwd;
    [self _connectToNetwork]; // Connect if needed.
    [_connection setLoginInfo:_username password:_password];
    [_connection send_LOGIN];
}

- (void) handeNewFromList
{
    [self _dismissListTableView];

    if (_tableId) {
        [_connection send_LEAVE:_tableId]; // Leave the old table.
        self._tableId = nil; 
        [self _resetAndClearTable];
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

    if ([_tableId isEqualToString:table.tableId]) {
        NSLog(@"%s: Same table [%@]. Ignore request.", __FUNCTION__, table.tableId);
        return;
    } else if (_tableId) {
        [_connection send_LEAVE:_tableId]; // Leave the old table.
        self._tableId = nil; 
        [self _resetAndClearTable];
    }
    [_connection send_JOIN:table.tableId color:joinColor];
}

- (void) handeNewMessageFromList:(NSString*)msg
{
    if (!_username || !_tableId) {
        NSLog(@"%s: No current table. Do nothing.", __FUNCTION__);
        return;
    }
    [self _onNewMessage:msg from:_username];
    [_connection send_MSG:_tableId msg:msg];
}

- (void) _connectToNetwork
{
    NSLog(@"%s: ENTER.", __FUNCTION__);
    if (self._connection == nil) {
        NSLog(@"%s: Connecting to network...", __FUNCTION__);
        [activity setHidden:NO];
        [activity startAnimating];
        self._connection = [[NetworkConnection alloc] init];
        _connection.delegate = self;
        [_connection connect];
    }
}

- (void) _showLoginView:(NSString*)errorStr
{
    NSLog(@"%s: ENTER.", __FUNCTION__);
    if (!_loginController) {
        NSLog(@"%s: Creating new Login view...", __FUNCTION__);
        self._loginController = [[LoginViewController alloc] initWithNibName:@"LoginView" bundle:nil];
        _loginController.delegate = self;
    }
    [_loginController setErrorString:errorStr];

    UIViewController* topController = [self.navigationController topViewController];
    if (topController != _loginController) {
        [self.navigationController pushViewController:_loginController animated:YES];
        self.navigationController.navigationBarHidden = NO;
    }

    // Load the existing Login info, if available, the 1st time.
    if (!_username) {
        NSString* username = [[NSUserDefaults standardUserDefaults] stringForKey:@"network_username"];
        if (username && [username length]) {
            NSString* password = [[NSUserDefaults standardUserDefaults] stringForKey:@"network_password"];
            NSLog(@"%s: Load existing LOGIN [%@, %@].", __FUNCTION__, username, password);
            [_loginController setInitialLogin:username password:password];
        }
    }
}

- (void) _showListTableView:(NSString*)event
{
    NSLog(@"%s: ENTER.", __FUNCTION__);
    if (!_tableListController) {
        self._tableListController = [[TableListViewController alloc] initWithDelegate:self];
    }
    if (event) {
        [_tableListController reinitWithList:event];
    }

    UIViewController* topController = [self.navigationController topViewController];
    if (topController != _tableListController) {
        self.navigationController.navigationBarHidden = NO;
        [self.navigationController pushViewController:_tableListController animated:YES];
    }

    _tableListController.viewOnly =
        ( _tableId
         && ([_username isEqualToString:_redId] || [_username isEqualToString:_blackId]));
}

- (void) _dismissLoginView
{
    [self.navigationController popToViewController:self animated:YES];
    [activity stopAnimating];
}

- (void) _dismissListTableView
{
    [self.navigationController popToViewController:self animated:YES];
}

- (void) _resetAndClearTable
{
    [self resetBoard];
    _isGameOver = NO;
}

- (void) _onNewMessage:(NSString*)msg from:(NSString*)pid
{
    [_messageListController newMessage:msg from:pid];
    _messagesButton.title = [NSString stringWithFormat:@"%d", _messageListController.nNew];
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
            NSString* tableId = [newEvent objectForKey:@"tid"];

            if ([op isEqualToString:@"LOGIN"]) {
                [self _handleNetworkEvent_LOGIN:code withContent:content];
            }
            else if (code != 0) {  // Error
                NSLog(@"%s: Received an ERROR event: [%@].", __FUNCTION__, content);
            }
            else {
                if ([op isEqualToString:@"LIST"]) {
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
                } else if ([op isEqualToString:@"UPDATE"]) {
                    [self _handleNetworkEvent_UPDATE:content];
                } else if ([op isEqualToString:@"MSG"]) {
                    [self _handleNetworkEvent_MSG:content];
                } else if ([op isEqualToString:@"DRAW"]) {
                    [self _handleNetworkEvent_DRAW:content];
                } else if ([op isEqualToString:@"INVITE"]) {
                    [self _handleNetworkEvent_INVITE:content toTable:tableId];
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
            } else {
                [self _showLoginView:nil];
            }
            break;
        }
        case NC_CONN_EVENT_ERROR:
        {
            NSLog(@"%s: Got NC_CONN_EVENT_ERROR.", __FUNCTION__);
            [_connection disconnect];
            self._connection = nil;
            [self _showLoginView:@"Connection error"];
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

- (void) _handleNetworkEvent_LOGIN:(int)code withContent:(NSString*)event
{
    if (code != 0) {  // Error
        NSLog(@"%s: Login failed. Error: [%@].", __FUNCTION__, event);
        [self _showLoginView:event];
        return;
    }
    NSArray* components = [event componentsSeparatedByString:@";"];
    NSString* pid = [components objectAtIndex:0];
    NSString* rating = [components objectAtIndex:1];
    NSLog(@"%s: [%@ %@] LOGIN.", __FUNCTION__, pid, rating);

    if (![_username isEqualToString:pid]) { // not mine?
        return; // Other users' login. Ignore for now.
    }

    self._rating = rating;  // Save my Rating.
    _loginAuthenticated = YES;
    [self _dismissLoginView];

    _messagesButton.enabled = YES;

    // Save the Login info after a successful login.
    if (![_username hasPrefix:NC_GUEST_PREFIX]) { // A normal account?
        [[NSUserDefaults standardUserDefaults] setObject:_username forKey:@"network_username"];
        [[NSUserDefaults standardUserDefaults] setObject:_password forKey:@"network_password"];
    }
}

- (void) _handleNetworkEvent_LIST:(NSString*)event
{
    NSLog(@"%s: ENTER.", __FUNCTION__);
    [self _showListTableView:event];
}

- (void) _handleNetworkEvent_I_TABLE:(NSString*)event
{
    TableInfo* table = [TableInfo allocTableFromString:event];

    if (_tableId && ![_tableId isEqualToString:table.tableId]) {
        [self _resetAndClearTable];
    }
    self._tableId = table.tableId;

    ColorEnum myColor = NC_COLOR_NONE; // Default: an observer.
    if      ([_username isEqualToString:table.redId])   { myColor = NC_COLOR_RED;   }
    else if ([_username isEqualToString:table.blackId]) { myColor = NC_COLOR_BLACK; }
    _myColor = myColor;

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
    [_board setRedLabel:redInfo];
    [_board setBlackLabel:blackInfo];
    [self setInitialTime:table.itimes];
    [self setRedTime:table.redTimes];
    [self setBlackTime:table.blackTimes];

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
        //NSLog(@"%s: MOVE [%d%d -> %d%d].", __FUNCTION__, row1, col1, row2, col2);
        
        int sqSrc = TOSQUARE(row1, col1);
        int sqDst = TOSQUARE(row2, col2);
        int move = MOVE(sqSrc, sqDst);
        
        [_game doMove:ROW(sqSrc) fromCol:COLUMN(sqSrc)
                toRow:ROW(sqDst) toCol:COLUMN(sqDst)];
        
        NSNumber *moveInfo = [NSNumber numberWithInteger:move];
        [_board onNewMove:moveInfo inSetupMode:YES];
    }
}

- (void) _handleNetworkEvent_MOVE:(NSString*)event
{
    NSArray* components = [event componentsSeparatedByString:@";"];
    NSString* tableId = [components objectAtIndex:0];
    NSString* moveStr = [components objectAtIndex:2];

    if ( ! [_tableId isEqualToString:tableId] ) {
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
    
    [_game doMove:ROW(sqSrc) fromCol:COLUMN(sqSrc)
            toRow:ROW(sqDst) toCol:COLUMN(sqDst)];
    
    NSNumber *moveInfo = [NSNumber numberWithInteger:move];
    [_board onNewMove:moveInfo inSetupMode:NO];
}

- (void) _handleNetworkEvent_E_END:(NSString*)event
{
    NSArray* components = [event componentsSeparatedByString:@";"];
    NSString* tableId = [components objectAtIndex:0];
    NSString* gameResult = [components objectAtIndex:1];
    
    NSLog(@"%s: Table:[%@] - Game Over: [%@].", __FUNCTION__, tableId, gameResult);

    if ( [_tableId isEqualToString:tableId] ) {
        _isGameOver = YES;
        [_board onGameOver];
    }
}

- (void) _handleNetworkEvent_RESET:(NSString*)event
{
    NSArray* components = [event componentsSeparatedByString:@";"];
    NSString* tableId = [components objectAtIndex:0];
    
    NSLog(@"%s: Table:[%@] - Game Reset.", __FUNCTION__, tableId);
    if ( [_tableId isEqualToString:tableId] ) {
        [self _resetAndClearTable];
    }
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

    if ( ! [_tableId isEqualToString:tableId] ) {
        NSLog(@"%s: E_JOIN:[%@ as %@] from table:[%@] ignored.", __FUNCTION__, playerInfo, color, tableId);
        return;
    }
    if ([color isEqualToString:@"Red"]) {
        self._redId = pid;
        [_board setRedLabel:playerInfo];
    } else if ([color isEqualToString:@"Black"]) {
        self._blackId = pid;
        [_board setBlackLabel:playerInfo];
    } else if ([color isEqualToString:@"None"]) {
        NSLog(@"%s: Player: [%@] joined as an observer.", __FUNCTION__, playerInfo);
        if ([pid isEqualToString:self._redId]) {
            self._redId = nil;
            [_board setRedLabel:@"*"];
        } else if ([pid isEqualToString:self._blackId]) {
            self._blackId = nil;
            [_board setBlackLabel:@"*"];
        }
    }
}

- (void) _handleNetworkEvent_LEAVE:(NSString*)event
{
    NSArray* components = [event componentsSeparatedByString:@";"];
    NSString* tableId = [components objectAtIndex:0];
    NSString* pid = [components objectAtIndex:1];

    if ( ! [_tableId isEqualToString:tableId] ) {
        NSLog(@"%s: E_LEAVE:[%@] from table:[%@] ignored.", __FUNCTION__, pid, tableId);
        return;
    }
    if ([pid isEqualToString:self._redId]) {
        self._redId = nil;
        [_board setRedLabel:@"*"];
    } else if ([pid isEqualToString:self._blackId]) {
        self._blackId = nil;
        [_board setBlackLabel:@"*"];
    }
}

- (void) _handleNetworkEvent_UPDATE:(NSString*)event
{
    NSArray* components = [event componentsSeparatedByString:@";"];
    NSString* tableId = [components objectAtIndex:0];
    NSString* pid = [components objectAtIndex:1];
    NSString* itimes = [components objectAtIndex:3];

    if ( ! [_tableId isEqualToString:tableId] ) {
        NSLog(@"%s: [%@] UPDATE time [%@] at table:[%@] ignored.", __FUNCTION__, pid, itimes, tableId);
        return;
    }

    [self setInitialTime:itimes];
    [self setRedTime:itimes];
    [self setBlackTime:itimes];
}

- (void) _handleNetworkEvent_MSG:(NSString*)event
{
    NSArray* components = [event componentsSeparatedByString:@";"];
    NSString* pid = [components objectAtIndex:0];
    NSString* msg = [components objectAtIndex:1];

    NSLog(@"%s: [%@] sent MSG [%@].", __FUNCTION__, pid, msg);
    [self _onNewMessage:msg from:pid];
}

- (void) _handleNetworkEvent_DRAW:(NSString*)event
{
    NSArray* components = [event componentsSeparatedByString:@";"];
    NSString* tableId = [components objectAtIndex:0];
    NSString* pid = [components objectAtIndex:1];
    
    NSLog(@"%s: [%@] sent DRAW at table [%@].", __FUNCTION__, pid, tableId);

    NSString* msg = @"Requesting a DRAW";
    [self _onNewMessage:msg from:pid];
}

- (void) _handleNetworkEvent_INVITE:(NSString*)event toTable:(NSString*)tableId
{
    NSArray* components = [event componentsSeparatedByString:@";"];
    NSString* pid = [components objectAtIndex:0];
    NSString* rating = [components objectAtIndex:1];

    NSString* playerInfo = [NSString stringWithFormat:@"%@ (%@)", pid, rating];
    NSLog(@"%s: [%@] sent INVITE to [%@].", __FUNCTION__, playerInfo, tableId);

    NSString* msg = [NSString stringWithFormat:@"*INVITE to Table [%@]", tableId ? tableId : @""];
    [self _onNewMessage:msg from:playerInfo];
}

#pragma mark -
#pragma mark Other helper functions

- (NSString*) _generateGuestUserName
{
    const unsigned int MAX_GUEST_ID = 10000;

    const int randNum = [self _generateRandomNumber:MAX_GUEST_ID];
    NSString* sGuestId = [NSString stringWithFormat:@"%@ip%d", NC_GUEST_PREFIX, randNum];
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
