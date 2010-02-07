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

#import "NetworkConnection.h"

@interface NetworkConnection (PrivateMethods)
- (void) _openIOStreams;
- (void) _closeIOStreams;
- (void) _flushOutgoingData;
- (unsigned int) _sendOutgoingData;
- (unsigned int) _receiveIncomingData;
@end

///////////////////////////////////////////////////////////////////////////////
//
//    Implementation of Public methods
//
///////////////////////////////////////////////////////////////////////////////

@implementation NetworkConnection

@synthesize delegate;
@synthesize state=_connectionState;
@synthesize _username, _password;

- (id) init
{
    NSLog(@"%s: ENTER.", __FUNCTION__);
    self = [super init];
    if (self != nil) {
        _connectionState = NC_CONN_STATE_NONE;
        self._username = nil;
        self._password = nil;

        _outData = [[NSMutableData alloc] init];
        _inData = [[NSMutableData alloc] init];
        _outByteIndex = 0;
        _inByteIndex = 0;
        _outAvailable = false;
    }
    return self;
}

- (void)dealloc
{
    NSLog(@"%s: ENTER.", __FUNCTION__);
    self._username = nil;
    self._password = nil;
    [super dealloc];
}

- (void) connect
{
    [self _openIOStreams];
}

- (void) disconnect
{
    [self _closeIOStreams];
}

- (void) setLoginInfo:(NSString *)username password:(NSString*)passwd
{
    self._username = [NSString stringWithString:username];
    self._password = [NSString stringWithString:passwd];
}

- (void) send_LOGIN
{
    NSString* outStr = [NSString stringWithFormat:@"op=LOGIN&pid=%@&password=%@\n", _username, _password];
    [_outData appendBytes:(const void *)[outStr UTF8String] length:[outStr length]];
    [self _flushOutgoingData];
}

- (void) send_LOGOUT
{    
    NSString* outStr = [NSString stringWithFormat:@"op=LOGOUT&pid=%@\n", _username];
    [_outData appendBytes:(const void *)[outStr UTF8String] length:[outStr length]];
    [self _flushOutgoingData];
}

- (void) send_LIST
{    
    NSString* outStr = [NSString stringWithFormat:@"op=LIST&pid=%@\n", _username];
    [_outData appendBytes:(const void *)[outStr UTF8String] length:[outStr length]];
    [self _flushOutgoingData];
}

- (void) send_NEW:(NSString*)itimes
{
    NSString* outStr = [NSString stringWithFormat:@"op=NEW&pid=%@&itimes=%@\n", _username, itimes];
    [_outData appendBytes:(const void *)[outStr UTF8String] length:[outStr length]];
    [self _flushOutgoingData];
}

- (void) send_JOIN:(NSString*)tableId color:(NSString*)joinColor
{    
    NSString* outStr = [NSString stringWithFormat:@"op=JOIN&pid=%@&tid=%@&color=%@\n", _username, tableId, joinColor];
    [_outData appendBytes:(const void *)[outStr UTF8String] length:[outStr length]];
    [self _flushOutgoingData];
}

- (void) send_LEAVE:(NSString*)tableId
{    
    NSString* outStr = [NSString stringWithFormat:@"op=LEAVE&pid=%@&tid=%@\n", _username, tableId];
    [_outData appendBytes:(const void *)[outStr UTF8String] length:[outStr length]];
    [self _flushOutgoingData];
}

- (void) send_MOVE:(NSString*)tableId move:(NSString*)moveStr
{
    NSString* outStr = [NSString stringWithFormat:@"op=MOVE&pid=%@&tid=%@&move=%@\n", _username, tableId, moveStr];
    [_outData appendBytes:(const void *)[outStr UTF8String] length:[outStr length]];
    [self _flushOutgoingData];
}

- (void) send_RESIGN:(NSString*)tableId
{    
    NSString* outStr = [NSString stringWithFormat:@"op=RESIGN&pid=%@&tid=%@\n", _username, tableId];
    [_outData appendBytes:(const void *)[outStr UTF8String] length:[outStr length]];
    [self _flushOutgoingData];
}

- (void) send_DRAW:(NSString*)tableId
{    
    NSString* outStr = [NSString stringWithFormat:@"op=DRAW&pid=%@&tid=%@\n", _username, tableId];
    [_outData appendBytes:(const void *)[outStr UTF8String] length:[outStr length]];
    [self _flushOutgoingData];
}

- (void) send_MSG:(NSString*)tableId msg:(NSString*)msg
{
    NSString* outStr = [NSString stringWithFormat:@"op=MSG&pid=%@&tid=%@&msg=%@\n", _username, tableId, msg];
    [_outData appendBytes:(const void *)[outStr UTF8String] length:[outStr length]];
    [self _flushOutgoingData];
}

- (void) _openIOStreams
{
    const NSString *urlStr = @"games.playxiangqi.com";
    const UInt32 port = 80;
    
    _connectionState = NC_CONN_STATE_CONNECTING;
    
    CFReadStreamRef readStream;
    CFWriteStreamRef writeStream;
    CFStreamCreatePairWithSocketToHost(NULL, (CFStringRef)urlStr, port, &readStream, &writeStream);
    
    _inStream = (NSInputStream *)readStream;
    _outStream = (NSOutputStream *)writeStream;

    [_inStream retain];
    [_outStream retain];
    CFRelease(readStream);
    CFRelease(writeStream);

    [_inStream setDelegate:self];
    [_outStream setDelegate:self];
    [_inStream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    [_outStream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    [_inStream open];
    [_outStream open];
    
    _connectionState = NC_CONN_STATE_CONNECTED;
} 

- (void) _closeIOStreams
{
    if (_connectionState == NC_CONN_STATE_NONE) {
        return; // Already disconnected.
    }

    if (_outStream)
    {
        [_outStream close];
        [_outStream removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
        [_outStream release];
        _outStream = nil;
    }
    if (_inStream)
    {
        [_inStream close];
        [_inStream removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
        [_inStream release];
        _inStream = nil;
    }
    _connectionState = NC_CONN_STATE_NONE;
}

- (void) _flushOutgoingData
{    
    if (_outAvailable) {
        [self _sendOutgoingData];
    }
}

/**
 * An NSStream delegate callback that's called when events happen on our 
 * network stream.
 */
- (void)stream:(NSStream *)stream handleEvent:(NSStreamEvent)eventCode
{
    switch(eventCode)
    {
        case NSStreamEventOpenCompleted:
        {
            //[self _send_LOGIN];
            NSLog(@"%s: Got NSStreamEventOpenCompleted.", __FUNCTION__);
            if ([stream isKindOfClass: [NSInputStream class]]) {
                NSLog(@"%s: ....... NSInputStream", __FUNCTION__);
            } else if ([stream isKindOfClass: [NSOutputStream class]]) {
                NSLog(@"%s: ....... NSOutputStream", __FUNCTION__);
                [delegate handleNetworkEvent:NC_CONN_EVENT_OPEN event:nil];
            } else {
                NSLog(@"%s: ....... UNKNOWN", __FUNCTION__);
            }
            break;
        }
        case NSStreamEventHasSpaceAvailable:
        {
            unsigned int nBytesSent = [self _sendOutgoingData];
            // NOTE: if the "gate is open" but we do not have data to write,
            //       then we "mark" this condition so that we can write
            //       data out directly (without being blocked).
            _outAvailable = (nBytesSent == 0);
            break;
        }
        case NSStreamEventHasBytesAvailable:
        {
            [self _receiveIncomingData];
            break;
        }
        case NSStreamEventEndEncountered:
        {
            NSLog(@"%s: Got NSStreamEventEndEncountered.", __FUNCTION__);
            [self _closeIOStreams];
            [delegate handleNetworkEvent:NC_CONN_EVENT_END event:nil];
            break;
        }
        case NSStreamEventErrorOccurred:
        {
            NSLog(@"%s: Got NSStreamEventErrorOccurred.", __FUNCTION__);
            [delegate handleNetworkEvent:NC_CONN_EVENT_ERROR event:nil];
            break;
        }
    }
}

/**
 * @return the number of bytes written.
 */
- (unsigned int) _sendOutgoingData
{
    const int dataLen = [_outData length];
    if (dataLen == 0) {
        NSLog(@"No more data to send.");
        return 0;
    }
    
    _outAvailable = false;
    
    uint8_t *readBytes = (uint8_t *)[_outData mutableBytes];
    readBytes += _outByteIndex; // instance variable to move pointer
    unsigned int len = ((dataLen - _outByteIndex >= 1024) ?
                        1024 : (dataLen-_outByteIndex));
    uint8_t buf[len];
    (void)memcpy(buf, readBytes, len);
    len = [_outStream write:(const uint8_t *)buf maxLength:len];
    NSLog(@"Sent [%d]", len);
    _outByteIndex += len;
    if (_outByteIndex == dataLen) {
        _outByteIndex = 0;
        [_outData setLength:0];
    }
    return len;
}

/**
 * @return the number of bytes received.
 */
- (unsigned int) _receiveIncomingData
{
    uint8_t buf[1024];
    unsigned int len = 0;
    len = [_inStream read:buf maxLength:sizeof(buf)];
    if(len == 0) {
        NSLog(@"No input buffer to receive!");
        return 0;
    }
    [_inData appendBytes:(const void *)buf length:len];
    NSLog(@"Received [%d]", len);
    
    // Note: Each event is separated by an "\n\n" token.
    //   - Start processing event by event.
    const int dataLen = [_inData length];
    uint8_t *inBytes = (uint8_t *)[_inData mutableBytes];
    uint8_t b; // The current byte being examined.
    bool bSawOne = false;  // just saw one '\n'?
    for (int i = _inByteIndex; i < dataLen; ++i)
    {
        b = *(inBytes + i);
        if ( !bSawOne && b == '\n' )
        {
            bSawOne = true;
        }
        else if ( bSawOne && b == '\n' )
        {
            NSRange range;
            range.location = i-1;
            range.length = 1;
            [_inData resetBytesInRange:range];
            NSString* currentEvent = [NSString stringWithUTF8String:(const char*)(inBytes+_inByteIndex)];
            //NSLog(@"%s: A new event [%@].", __FUNCTION__, currentEvent);
            [delegate handleNetworkEvent:NC_CONN_EVENT_DATA event:currentEvent];
            _inByteIndex = i+1;
        }
        else
        {
            if ( bSawOne ) {
                bSawOne = false;
            }
        }
    }
    
    // Return the buffer if we consumed ALL.
    if (_inByteIndex == dataLen) {
        _inByteIndex = 0;
        [_inData setLength:0];
        NSLog(@"%s: ... RESET buffer.", __FUNCTION__);
    }
    return len;
}

@end