/*
 
 File: Piece.h
 
 Abstract: A playing piece. A concrete subclass of Bit that displays an image..
 
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

#import "Piece.h"
#import "QuartzUtils.h"
#import "Grid.h"

// ---------------------------------------------------------------------------
#pragma mark -
@implementation Piece

@synthesize holder;
@synthesize color=_color;

- (id) initWithColor:(ColorEnum)color imageName:(NSString*)imageName scale:(CGFloat)scale
{
    if (self = [super init])
    {
        _color = color;
        _animated = NO;
        _imageName = [imageName retain];
        [self setImage:GetCGImageNamed(imageName) scale:scale];
        self.zPosition = kPieceZ;
    }
    return self;
}

- (void) dealloc
{
    //NSLog(@"%s: ENTER. [%@]", __FUNCTION__, self);
    [holder release];
    [_imageName release];
    _imageName = nil;
    [super dealloc];
}

- (NSString*) description
{
    return [NSString stringWithFormat:@"%@[%@]", [self class],
            _imageName.lastPathComponent.stringByDeletingPathExtension];
}

- (CGFloat) scale
{
    NSNumber *scale = [self valueForKeyPath:@"transform.scale"];
    return scale.floatValue;
}

- (void) setScale: (CGFloat)scale
{
    [self setValue:[NSNumber numberWithFloat:scale] forKeyPath:@"transform.scale"];
}

- (int) rotation
{
    NSNumber *rot = [self valueForKeyPath:@"transform.rotation"];
    return round( rot.doubleValue * 180.0 / M_PI );
}

- (void) setRotation: (int)rotation
{
    [self setValue:[NSNumber numberWithDouble:rotation*M_PI/180.0]
        forKeyPath:@"transform.rotation"];
}

- (BOOL) pickedUp
{
    return self.zPosition >= kPickedUpZ;
}

- (void) setPickedUp: (BOOL)up
{
    if ( up == self.pickedUp ) return;
    
    CGFloat opacity, z, scale;
    if( up ) {
        opacity = 0.9;
        scale = 1.1;
        z = kPickedUpZ;
        _restingZ = self.zPosition;
    } else {
        opacity = 1.0;
        scale = 1.0/1.1;
        z = _restingZ;
    }
    
    self.zPosition = z;
    self.opacity = opacity;
    self.scale *= scale;
}

- (void) destroyWithAnimation:(BOOL)animated
{
    if (animated) {
        // "Pop" the Bit by expanding it 4x as it fades away:
        self.scale = 4;
        self.opacity = 0.0;
        // Removing the view from its superlayer right now would cancel the animations.
        // Instead, defer the removal until sometime shortly after the animations finish:
        [self performSelector:@selector(removeFromSuperlayer) withObject:nil afterDelay:1.0];
    }
    else {
        [self removeFromSuperlayer];
    }
}

- (void) putbackInLayer:(CALayer*)superLayer
{
    // Temporarily disabling a layer's actions
    [CATransaction begin];
    [CATransaction setValue:(id)kCFBooleanTrue forKey:kCATransactionDisableActions];
    self.scale = 1.0;
    self.opacity = 1.0;
    [superLayer addSublayer:self];
    [CATransaction commit];
}

- (void) setImage:(CGImageRef)image scale:(CGFloat)scale
{
    self.contents = (id) image;
    self.contentsGravity = kCAGravityResizeAspect;
    self.minificationFilter = kCAFilterLinear;
    int width = 0, height = 0;
    if( scale >= 4.0 ) {
        width = scale;  // interpret scale as target dimensions
        height = scale;
    }
    else {
        width = CGImageGetWidth(image);
        height = CGImageGetHeight(image);
        if( scale > 0 ) {
            width = ceil( width * scale );
            height= ceil( height* scale );
        }
    }
    self.bounds = CGRectMake(0, 0, width, height);
}

- (void) setImage:(CGImageRef)image
{
    CGSize size = self.bounds.size;
    [self setImage:image scale:MAX(size.width,size.height)];
}

- (BOOL) highlighted { return holder.highlighted; }
- (void) setHighlighted:(BOOL)highlighted { holder.highlighted = highlighted; }

- (BOOL) animated
{
    return _animated;
}

- (void) setAnimated:(BOOL)animated
{
    _animated = animated;
    holder.animated = animated;

    if (animated)
    {
        CGFloat ds = 5.0;
        CGRect oriBounds = holder.bounds;
        CGRect ubounds = oriBounds;
        ubounds.size.width += ds*2;
        ubounds.size.height += ds*2;

        // 'bounds' animation
        CABasicAnimation* boundsAnimation = [CABasicAnimation animationWithKeyPath:@"bounds"];
        boundsAnimation.duration=1.0;
        boundsAnimation.repeatCount=HUGE_VALF;
        boundsAnimation.autoreverses=YES;
        boundsAnimation.fromValue=[NSValue valueWithCGRect:oriBounds];
        boundsAnimation.toValue=[NSValue valueWithCGRect:ubounds];
        [holder addAnimation:boundsAnimation forKey:@"animate_bounds"];
    }
    else {
        [holder removeAnimationForKey:@"animate_bounds"];
    }
}

- (void)animationDidStop:(CAAnimation *)anim finished:(BOOL)flag
{
    if (_animated) {
        self.animated = YES; // Resume "position" animation with "bounds" animation.
    } else {
        //NSLog(@"%s: ENTER. [%@] Animationed canceled!!!!", __FUNCTION__, self);
    }
}

- (void) movePieceTo:(CGPoint)newPosition animated:(BOOL)animated;
{
    if (animated) {
        _animated = YES; // ... to be continued with "bounds" animation!
        CABasicAnimation* animation = [CABasicAnimation animationWithKeyPath:@"position"];
        animation.delegate = self;
        animation.duration = 0.4;
        animation.fromValue = [NSValue valueWithCGPoint:self.position];
        animation.toValue = [NSValue valueWithCGPoint:newPosition];
        [self addAnimation:animation forKey:@"animate_position"];
        
    }
    self.position = newPosition;
}

@end
