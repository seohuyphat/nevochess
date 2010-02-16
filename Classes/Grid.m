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

#import "Grid.h"
#import "Bit.h"
#import "QuartzUtils.h"

@implementation Grid


- (id) initWithRows: (unsigned)nRows columns: (unsigned)nColumns
            spacing: (CGSize)spacing
           position: (CGPoint)pos
{
    NSParameterAssert(nRows>0 && nColumns>0);
    self = [super init];
    if( self ) {
        _nRows = nRows;
        _nColumns = nColumns;
        _spacing = spacing;
        _lineColor = CGColorRetain(kRedColor);

        self.bounds = CGRectMake(-1, -1, nColumns*spacing.width+2, nRows*spacing.height+2);
        self.position = pos;
        self.anchorPoint = CGPointMake(0,0);
        self.zPosition = kBoardZ;
        self.needsDisplayOnBoundsChange = YES;
        
        unsigned n = nRows*nColumns;
        _cells = [[NSMutableArray alloc] initWithCapacity:n];
        id null = [NSNull null];
        while( n-- > 0 ) { [_cells addObject:null]; }
        [self setNeedsDisplay];
        
        // Create the River.
        CGRect frame;
        frame.origin.x = spacing.width/2;
        frame.origin.y = 4 * spacing.height + spacing.height/2;
        frame.size.height = spacing.height;
        frame.size.width = spacing.width * 8;
        _river = [[GridCell alloc] initWithGrid:self row:nRows column:nColumns frame:frame];
        [self addSublayer:_river];
        _river.backgroundColor =  GetCGPatternNamed(@"board_320x480.png");
        _river.borderColor = kRedColor;
        _river.borderWidth = 1.0;
    }
    return self;
}


- (id) initWithRows: (unsigned)nRows columns: (unsigned)nColumns
              frame: (CGRect)frame
{
    CGFloat spacing = floor(MIN( (frame.size.width -2)/(CGFloat)nColumns,
                               (frame.size.height-2)/(CGFloat)nRows) );
    return [self initWithRows: nRows columns: nColumns
                      spacing: CGSizeMake(spacing,spacing)
                     position: frame.origin];
}

- (void)dealloc {
    CGColorRelease(_lineColor);
    [_cells release];
    [_river release];
    [super dealloc];
}

- (void)setcolor:(CGColorRef *)var withNewColor:(CGColorRef)color
{
    if( color != *var ) {
        // Garbage collection does not apply to CF objects like CGColors!
        CGColorRelease(*var);
        *var = CGColorRetain(color);
    }
}

- (CGColorRef) lineColor                     {return _lineColor;}
- (void) setLineColor: (CGColorRef)lineColor {[self setcolor:&_lineColor withNewColor:lineColor];}

@synthesize rows=_nRows, columns=_nColumns, spacing=_spacing;
@synthesize _river;

#pragma mark -
#pragma mark GEOMETRY:


- (GridCell*) cellAtRow: (unsigned)row column: (unsigned)col
{
    if( row < _nRows && col < _nColumns ) {
        id cell = [_cells objectAtIndex: row*_nColumns+col];
        if( cell != [NSNull null] )
            return cell;
    }
    return nil;
}


/** Subclasses can override this, to change the cell's class or frame. */
- (GridCell*) allocCellAtRow: (unsigned)row column: (unsigned)col 
               suggestedFrame: (CGRect)frame
{
    return [[GridCell alloc] initWithGrid: self 
                                        row: row column: col
                                      frame: frame];
}


- (GridCell*) addCellAtRow: (unsigned)row column: (unsigned)col
{
    NSParameterAssert(row<_nRows);
    NSParameterAssert(col<_nColumns);
    unsigned index = row*_nColumns+col;
    GridCell *cell = [_cells objectAtIndex: index];
    if( (id)cell == [NSNull null] ) {
        CGRect frame = CGRectMake(col*_spacing.width, row*_spacing.height,
                                  _spacing.width,_spacing.height);
        cell = [self allocCellAtRow: row column: col suggestedFrame: frame];
        if( cell ) {
            [_cells replaceObjectAtIndex: index withObject: cell];
            [self addSublayer: cell];
            [self setNeedsDisplay];
        }
    }
    return cell;
}


- (void) addAllCells
{
    for( int row=_nRows-1; row>=0; row-- )  // makes 'upper' cells be in 'back'
        for( int col=0; col<_nColumns; col++ ) 
            [self addCellAtRow: row column: col];
}

- (void) removeAllCells
{
    for( int row=_nRows-1; row>=0; row-- )   // makes 'upper' cells be in 'back'
        for( int col=0; col<_nColumns; col++ ) 
            [self removeCellAtRow: row column: col];
}


- (void) removeCellAtRow: (unsigned)row column: (unsigned)col
{
    NSParameterAssert(row<_nRows);
    NSParameterAssert(col<_nColumns);
    unsigned index = row*_nColumns+col;
    id cell = [_cells objectAtIndex: index];
    if( cell != [NSNull null] )
        [cell removeFromSuperlayer];
    // HUY PHAN: (not needed): [cell release];
    [_cells replaceObjectAtIndex: index withObject: [NSNull null]];
    [self setNeedsDisplay];
}


#pragma mark -
#pragma mark DRAWING:


- (void) drawCellsInContext: (CGContextRef)ctx
{
    // Subroutine of -drawInContext:. Draws all the cells, with or without a fill.
    for( unsigned row=0; row<_nRows; row++ )
        for( unsigned col=0; col<_nColumns; col++ ) {
            GridCell *cell = [self cellAtRow: row column: col];
            if( cell )
                [cell drawInParentContext: ctx];
        }
}


- (void)drawInContext:(CGContextRef)ctx
{
    // Custom CALayer drawing implementation. Delegates to the cells to draw themselves
    // in me; this is more efficient than having each cell have its own drawing.
    CGContextSetStrokeColorWithColor(ctx,_lineColor);
    CGContextSetLineWidth(ctx, 1.5);
    [self drawCellsInContext:ctx];
}


@end



#pragma mark -

@implementation GridCell

@synthesize _grid, _row, _column;
@synthesize dotted, cross;

- (void)dealloc
{
    [_grid release];
    [super dealloc];
}

- (id) initWithGrid: (Grid*)grid 
                row: (unsigned)row column: (unsigned)col
              frame: (CGRect)frame
{
    self = [super init];
    if (self != nil) {
        _grid = grid;
        _row = row;
        _column = col;
        self.position = frame.origin;
        CGRect bounds = frame;
        bounds.origin.x -= floor(bounds.origin.x);  // make sure my coords fall on pixel boundaries
        bounds.origin.y -= floor(bounds.origin.y);
        self.bounds = bounds;
        self.anchorPoint = CGPointMake(0,0);
        self.borderColor = kHighlightColor;         // Used when highlighting (see -setHighlighted:)
    }
    return self;
}

- (NSString*) description
{
    return [NSString stringWithFormat: @"%@(%u,%u)", [self class],_column,_row];
}

- (void) setBit: (Bit*)bit
{
    if( bit != self._bit ) {
        self._bit = bit;
        if( bit ) {
            // Center it:
            CGSize size = self.bounds.size;
            bit.position = CGPointMake(floor(size.width/2.0),
                                       floor(size.height/2.0));
        }
    }
}

- (void) drawInParentContext: (CGContextRef)ctx
{
    CGRect frame = self.frame;
    const CGFloat midx=floor(CGRectGetMidX(frame))+0.5, 
    midy=floor(CGRectGetMidY(frame))+0.5;
    CGPoint p[4] = {{CGRectGetMinX(frame),midy},
        {CGRectGetMaxX(frame),midy},
        {midx,CGRectGetMinY(frame)},
        {midx,CGRectGetMaxY(frame)}};
    if( ! self.s )  p[2].y = midy;
    if( ! self.n )  p[3].y = midy;
    if( ! self.w )  p[0].x = midx;
    if( ! self.e )  p[1].x = midx;
    CGContextStrokeLineSegments(ctx, p, 4);
    
    
    if( dotted ) {
        
        const CGFloat midx_offset = CGRectGetWidth(frame)/4;
        const CGFloat midy_offset = CGRectGetHeight(frame)/4;
        CGPoint pos[16] = {{midx - 2, midy + 2}, {midx - 2, midy + 2 + midy_offset}, {midx - 2, midy + 2}, {midx - 2 - midx_offset, midy + 2},
            {midx + 2, midy + 2}, {midx + 2, midy + 2 + midy_offset}, {midx + 2, midy + 2}, {midx + 2 + midx_offset, midy + 2},
            {midx - 2, midy - 2}, {midx - 2, midy - 2 - midy_offset}, {midx - 2, midy - 2}, {midx - 2 - midx_offset, midy - 2},
            {midx + 2, midy - 2}, {midx + 2, midy - 2 - midy_offset}, {midx + 2, midy - 2}, {midx + 2 + midx_offset, midy - 2}};
        if( ! self.s ) {pos[8].x = pos[9].x = pos[10].x = pos[11].x = pos[12].x = pos[13].x = pos[14].x = pos[15].x = midx;
            pos[8].y = pos[9].y = pos[10].y = pos[11].y = pos[12].y = pos[13].y = pos[14].y = pos[15].y = midy;}
        
        if( ! self.n ) {pos[0].x = pos[1].x = pos[2].x = pos[3].x = pos[4].x = pos[5].x = pos[6].x = pos[7].x = midx;
            pos[0].y = pos[1].y = pos[2].y = pos[3].y = pos[4].y = pos[5].y = pos[6].y = pos[7].y = midy;}
        
        if( ! self.w ) {pos[0].x = pos[1].x = pos[2].x = pos[3].x = pos[8].x = pos[9].x = pos[10].x = pos[11].x = midx;
            pos[0].y = pos[1].y = pos[2].y = pos[3].y = pos[8].y = pos[9].y = pos[10].y = pos[11].y = midy;}
        
        if( ! self.e ) {pos[4].x = pos[5].x = pos[6].x = pos[7].x = pos[12].x = pos[13].x = pos[14].x = pos[15].x = midx;
            pos[4].y = pos[5].y = pos[6].y = pos[7].y = pos[12].y = pos[13].y = pos[14].y = pos[15].y = midy;}
        
        CGContextStrokeLineSegments(ctx, pos, 16);
    }
    
    if( cross ) {
        CGPoint crossp[4] = {{midx - CGRectGetWidth(frame), midy - CGRectGetHeight(frame)}, 
            {midx + CGRectGetWidth(frame), midy + CGRectGetHeight(frame)},
            {midx - CGRectGetWidth(frame), midy + CGRectGetHeight(frame)},
            {midx + CGRectGetWidth(frame), midy - CGRectGetHeight(frame)}};
        CGContextStrokeLineSegments(ctx, crossp, 4);
    }                                                                                                                                      
}

- (void) setHighlighted: (BOOL)highlighted
{
    _highlighted = highlighted;
    self.cornerRadius = ceil(_grid.spacing.width / 4);
    self.borderWidth = (highlighted ?3 :0);
}

- (GridCell*) nw     {return [_grid cellAtRow: _row+1 column: _column-1];}
- (GridCell*) n      {return [_grid cellAtRow: _row+1 column: _column  ];}
- (GridCell*) ne     {return [_grid cellAtRow: _row+1 column: _column+1];}
- (GridCell*) e      {return [_grid cellAtRow: _row   column: _column+1];}
- (GridCell*) se     {return [_grid cellAtRow: _row-1 column: _column+1];}
- (GridCell*) s      {return [_grid cellAtRow: _row-1 column: _column  ];}
- (GridCell*) sw     {return [_grid cellAtRow: _row-1 column: _column-1];}
- (GridCell*) w      {return [_grid cellAtRow: _row   column: _column-1];}

@end
