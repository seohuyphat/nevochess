/*

File: Grid.h

Abstract: Abstract superclass of regular geometric grids of GridCells that Bits can be placed on.

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
@class GridCell;

// Hit-testing callbacks (to identify which layers caller is interested in):
typedef BOOL (*LayerMatchCallback)(CALayer*);

BOOL layerIsBit( CALayer* layer );
BOOL layerIsGridCell( CALayer* layer );
// ----------------------------------------------------------------------------

/** Regular geometric grids of GridCells that Bits can be placed on.
 *  (customized for Xiangqi).
 */
@interface Grid : CALayer
{
    unsigned        _nRows, _nColumns;
    CGSize          _spacing;                                                                       
    CGColorRef      _lineColor;
    CGColorRef      _highlightColor;
    CGColorRef      _animateColor;
    CGPoint         _cellOffset;
    NSMutableArray* _cells; // Really a 2D array, in row-major order.
    GridCell*       _river;
}

/** Initializes a new Grid with the given dimensions and cell size, and position in superview.
    Note that a new Grid has no cells! Either call -addAllCells, or -addCellAtRow:column:. */
- (id) initWithRows:(unsigned)nRows columns:(unsigned)nColumns
            spacing:(CGSize)spacing position:(CGPoint)pos
         cellOffset:(CGPoint)cellOffset
    backgroundColor:(CGColorRef)backgroundColor;

@property (readonly) unsigned rows, columns;    // Dimensions of the grid
@property (readonly) CGSize spacing;            // x,y spacing of GridCells
@property CGColorRef lineColor;      // Cell background color, line color (or nil)
@property CGColorRef highlightColor;
@property CGColorRef animateColor;
@property (nonatomic, retain) GridCell* _river;

/** Returns the GridCell at the given coordinates, or nil if there is no cell there.
    It's OK to call this with off-the-board coordinates; it will just return nil.*/
- (GridCell*) cellAtRow:(unsigned)row column: (unsigned)col;

/** Adds cells at all coordinates, creating a complete grid. */
- (void) addAllCells;

- (void) removeAllCells;

/** Adds a GridCell at the given coordinates. */
- (GridCell*) addCellAtRow:(unsigned)row column:(unsigned)col;

/** Removes a particular cell, leaving a blank space. */
- (void) removeCellAtRow:(unsigned)row column:(unsigned)col;

@end


/** A single cell in a grid (customized for Xiangqi). */
@interface GridCell : CALayer
{
    Bit*     _bit;
    BOOL     _highlighted;
    BOOL     _animated;
    Grid*    _grid;
    unsigned _row, _column;
    BOOL     dotted;
    BOOL     cross;
}

- (id) initWithGrid:(Grid*)grid row:(unsigned)row column:(unsigned)col
              frame:(CGRect)frame;

/** Current Bit, or nil if empty */
@property (nonatomic, retain) Bit* _bit;

/** Conveniences for comparing self.bit with nil */
@property (nonatomic, readonly, getter=isEmpty) BOOL empty;

/** BitHolders will be highlighted while the target of a drag operation */
@property (nonatomic, setter=setHighlighted:) BOOL _highlighted;
@property (nonatomic, setter=setAnimated:) BOOL _animated;

@property (nonatomic, retain) Grid* _grid;
@property (nonatomic) unsigned _row, _column;
@property (nonatomic) BOOL dotted;
@property (nonatomic) BOOL cross;
@property (readonly) GridCell *nw, *n, *ne, *e, *se, *s, *sw, *w; // Absolute directions (n = increasing row#)

// protected:
- (void) drawInParentContext:(CGContextRef)ctx;
@end
