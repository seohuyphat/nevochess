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
#import "LoginViewController.h"
#import "TableListViewController.h"
#import "MessageListViewController.h"
#import "NetworkConnection.h"

@interface NetworkBoardViewController : BoardViewController <LoginDelegate,
    TableListDelegate, MessageListDelegate, NetworkHandler, UIActionSheetDelegate>
{
    NSString*          _username;
    NSString*          _password;
    NSString*          _rating;
    NetworkConnection* _connection;

    NSString*          _redId; // TODO: We should use the 'players' in Game class.
    NSString*          _blackId;

    BOOL               _isGameOver;

    BOOL               _loginCanceled;
    BOOL               _loginAuthenticated;
    BOOL               _logoutPending;

    LoginViewController*       _loginController;
    TableListViewController*   _tableListController;
    MessageListViewController* _messageListController;
    UIBarButtonItem*           _actionButton;
    UIBarButtonItem*           _messagesButton;
}

@property (nonatomic, retain) NSString* _username;
@property (nonatomic, retain) NSString* _password;
@property (nonatomic, retain) NSString* _rating;
@property (nonatomic, retain) NSString* _redId;
@property (nonatomic, retain) NSString* _blackId;
@property (nonatomic, retain) NetworkConnection* _connection;
@property (nonatomic, retain) LoginViewController* _loginController;
@property (nonatomic, retain) TableListViewController* _tableListController;
@property (nonatomic, retain) MessageListViewController* _messageListController;

- (IBAction)homePressed:(id)sender;
- (IBAction)resetPressed:(id)sender;

- (void) onLocalMoveMade:(int)move;

@end
