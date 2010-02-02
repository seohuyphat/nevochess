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

#import <Foundation/Foundation.h>

typedef enum
{
    NC_CONN_STATE_NONE,
    NC_CONN_STATE_CONNECTING,
    NC_CONN_STATE_CONNECTED
} ConnectionStateEnum;

typedef enum
{
    NC_CONN_EVENT_OPEN,
    NC_CONN_EVENT_DATA,
    NC_CONN_EVENT_END
} ConnectionEventEnum;

@protocol NetworkHandler <NSObject>
- (void) handleNetworkEvent:(ConnectionEventEnum)code event:(NSString*)event;
@end

@interface NetworkConnection : NSObject
{
    ConnectionStateEnum _connectionState;
    NSString*           _username;
    NSString*           _password;

    NSMutableData*      _outData;
    NSMutableData*      _inData;
    unsigned int        _outByteIndex;
    unsigned int        _inByteIndex;
    
    NSInputStream*      _inStream;
    NSOutputStream*     _outStream;
    bool                _outAvailable;
    
    id <NetworkHandler> delegate;
}

@property (nonatomic, retain) id <NetworkHandler> delegate;
@property (nonatomic, retain) NSString* _username;
@property (nonatomic, retain) NSString* _password;
@property(readonly) ConnectionStateEnum state;

- (id) init;
- (void) connect;
- (void) disconnect;
- (void) setLoginInfo:(NSString *)username password:(NSString*)passwd;

- (void) send_LOGIN;
- (void) send_LOGOUT;
- (void) send_LIST;
- (void) send_NEW:(NSString*)itimes;
- (void) send_JOIN:(NSString*)tableId color:(NSString*)joinColor;
- (void) send_LEAVE:(NSString*)tableId;
- (void) send_MOVE:(NSString*)tableId move:(NSString*)moveStr;
- (void) send_RESIGN:(NSString*)tableId;
- (void) send_DRAW:(NSString*)tableId;

@end
