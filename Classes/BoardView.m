/*
 
 File: BoardView.m
 
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

#import "BoardView.h"
#import "Bit.h"
#import "BitHolder.h"
#import "QuartzUtils.h"
#import "NevoChessAppDelegate.h"

@implementation BoardView


@synthesize game=_game, gameboard=_gameboard;


- (void)dealloc
{
    [_gameboard removeFromSuperlayer];
    [_gameboard release];
    [_game release];
    [super dealloc];
}

- (void) awakeFromNib
{
    NSLog(@"%s: ENTER.", __FUNCTION__);
    ((NevoChessAppDelegate*)[[UIApplication sharedApplication] delegate]).navigationController.navigationBarHidden = YES;

    if( _gameboard ) {
        [_gameboard removeFromSuperlayer];
        _gameboard = nil;
    }
    _gameboard = [[CALayer alloc] init];
    _gameboard.frame = [self gameBoardFrame];
    self.layer.backgroundColor = GetCGPatternNamed(@"board_320x480.png");
    [self.layer insertSublayer:_gameboard atIndex:0]; // ... in the back.
    
    _game = [[CChessGame alloc] initWithBoard: _gameboard];
    int nDifficulty = [[NSUserDefaults standardUserDefaults] integerForKey:@"difficulty_setting"];
    [_game setSearchDepth:nDifficulty];
}

- (CGRect) gameBoardFrame
{
    CGRect bounds = self.layer.bounds;
/*
    bounds.origin.x += 2;
    bounds.origin.y += 2;
    bounds.size.width -= 4;
    bounds.size.height -= 24;
    self.layer.bounds = bounds;
*/
    return bounds;
}


#pragma mark -
#pragma mark HIT-TESTING:


/** Locates the layer at a given point in window coords.
    If the leaf layer doesn't pass the layer-match callback, the nearest ancestor that does is returned.
    If outOffset is provided, the point's position relative to the layer is stored into it. */
- (CALayer*) hitTestPoint: (CGPoint)locationInWindow
       LayerMatchCallback: (LayerMatchCallback)match
                   offset: (CGPoint*)outOffset
{
    CGPoint where = locationInWindow;
    where = [_gameboard convertPoint: where fromLayer: self.layer];
    CALayer *layer = [_gameboard hitTest: where];
    while( layer ) {
        if( match(layer) ) {
            CGPoint bitPos = [self.layer convertPoint: layer.position 
                              fromLayer: layer.superlayer];
            if( outOffset )
                *outOffset = CGPointMake( bitPos.x-where.x, bitPos.y-where.y);
            return layer;
        } else
            layer = layer.superlayer;
    }
    return nil;
}

@end
