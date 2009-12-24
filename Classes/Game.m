/*
 
 File: Game.m
 
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


#import "Game.h"
#import "Bit.h"

@implementation Game


@synthesize _players, _currentPlayer, _winner;

+ (NSString*) displayName
{
    NSString* name = [self description];
    if( [name hasSuffix: @"Game"] )
        name = [name substringToIndex: name.length-4];
    return name;
}

- (void)dealloc
{
    [_players release];
    [super dealloc];
}


- (id) initWithBoard: (CALayer*)board
{
    self = [super init];
    if (self != nil) {
        _board = board;
        // Store a pointer to myself as the value of the "Game" property
        // of my root layer. (CALayers can have arbitrary KV properties stored into them.)
        // This is used by the -[CALayer game] category method defined below, to find the Game.
        [board setValue: self forKey: @"Game"];
    }
    return self;
}



- (void) setNumberOfPlayers: (unsigned)n
{
    _players = [[NSMutableArray alloc] initWithCapacity: n];
    for( int i=1; i<=n; i++ ) {
        Player *player = [[Player alloc] initWithGame: self];
        player._name = [NSString stringWithFormat: @"Player %i",i];
        [_players addObject: player];
        [player release];
    }
    _winner = nil;
    _currentPlayer = nil;
}


- (void) nextPlayer
{
    if( ! _currentPlayer ) {
        NSLog(@"*** The %@ Begins! ***", self.class);
        _currentPlayer = [_players objectAtIndex: 0];
    } else {
        _currentPlayer = _currentPlayer.nextPlayer;
    }
    NSLog(@"Current player is %@",_currentPlayer);
}


- (void) endTurn
{
    NSLog(@"--- End of turn");
    Player *winner = [self checkForWinner];
    if( winner ) {
        NSLog(@"*** The %@ Ends! The winner is %@ ! ***", self.class, winner);
        _winner = winner;
    } else
        [self nextPlayer];
}


#pragma mark -
#pragma mark GAMEPLAY METHODS TO BE OVERRIDDEN:


- (BOOL) canBit: (Bit*)bit moveFrom: (id<BitHolder>)src
{
    return YES;
}

- (BOOL) canBit: (Bit*)bit moveFrom: (id<BitHolder>)src to: (id<BitHolder>)dst
{
    return YES;
}

- (void) bit: (Bit*)bit movedFrom: (id<BitHolder>)src to: (id<BitHolder>)dst
{
    [self endTurn];
}

- (BOOL) clickedBit: (Bit*)bit
{
    return YES;
}

- (Player*) checkForWinner
{
    return nil;
}


@end




@implementation Player

@synthesize _game;
@synthesize _name;

- (void)dealloc
{
    [_game release];
    [_name release];
    [super dealloc];
}

- (id) initWithGame: (Game*)game
{
    self = [super init];
    if (self != nil) {
        self._game = game;
    }
    return self;
}


- (BOOL) isCurrent      {return self == _game._currentPlayer;}
- (BOOL) isFriendly     {return self == _game._currentPlayer;}   // could be overridden for games with partners
- (BOOL) isUnfriendly   {return ! self.friendly;}

- (int) index
{
    return [_game._players indexOfObjectIdenticalTo: self];
}

- (Player*) nextPlayer
{
    return [_game._players objectAtIndex: (self.index+1) % _game._players.count];
}

- (Player*) previousPlayer
{
    return [_game._players objectAtIndex: (self.index-1) % _game._players.count];
}

- (NSString*) description
{
    return [NSString stringWithFormat: @"%@[%@]", self.class,self._name];
}

@end




@implementation CALayer (Game)

- (Game*) game
{
    // The Game object stores a pointer to itself as the value of the "Game" property
    // of its root layer. (CALayers can have arbitrary KV properties stored into them.)
    for( CALayer *layer = self; layer; layer=layer.superlayer ) {
        Game *game = [layer valueForKey: @"Game"];
        if( game )
            return game;
    }
    NSAssert1(NO,@"Couldn't look up Game from %@",self);
    return nil;
}

@end
