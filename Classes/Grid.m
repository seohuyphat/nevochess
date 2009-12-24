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
#import "Game.h"
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
        _cellClass = [GridCell class];
        _lineColor = CGColorRetain(kRedColor);
        //_cellColor = CGColorRetain(kWhiteColor);
        _cellColor = nil;
        _allowsMoves = YES;
        _usesDiagonals = YES;

        self.bounds = CGRectMake(-1, -1, nColumns*spacing.width+2, nRows*spacing.height+2);
        self.position = pos;
        self.anchorPoint = CGPointMake(0,0);
        self.zPosition = kBoardZ;
        self.needsDisplayOnBoundsChange = YES;
        
        unsigned n = nRows*nColumns;
        _cells = [[NSMutableArray alloc]  initWithCapacity: n];
        id null = [NSNull null];
        while( n-- > 0 )
            [_cells addObject: null];

        [self setNeedsDisplay];
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
    CGColorRelease(_cellColor);
    CGColorRelease(_lineColor);
    [_cells release];
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

- (CGColorRef) cellColor                        {return _cellColor;}
- (void) setCellColor: (CGColorRef)cellColor    {[self setcolor:&_cellColor withNewColor:cellColor];}

- (CGColorRef) lineColor                        {return _lineColor;}
- (void) setLineColor: (CGColorRef)lineColor    {[self setcolor:&_lineColor withNewColor:lineColor];}

@synthesize cellClass=_cellClass, rows=_nRows, columns=_nColumns, spacing=_spacing,
            usesDiagonals=_usesDiagonals, allowsMoves=_allowsMoves, allowsCaptures=_allowsCaptures;


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
    return [[_cellClass alloc] initWithGrid: self 
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
    for( int row=_nRows-1; row>=0; row-- )                // makes 'upper' cells be in 'back'
        for( int col=0; col<_nColumns; col++ ) 
            [self addCellAtRow: row column: col];
}

- (void) removeAllCells
{
    for( int row=_nRows-1; row>=0; row-- )                // makes 'upper' cells be in 'back'
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


- (void) drawCellsInContext: (CGContextRef)ctx fill: (BOOL)fill
{
    // Subroutine of -drawInContext:. Draws all the cells, with or without a fill.
    for( unsigned row=0; row<_nRows; row++ )
        for( unsigned col=0; col<_nColumns; col++ ) {
            GridCell *cell = [self cellAtRow: row column: col];
            if( cell )
                [cell drawInParentContext: ctx fill: fill];
        }
}


- (void)drawInContext:(CGContextRef)ctx
{
    // Custom CALayer drawing implementation. Delegates to the cells to draw themselves
    // in me; this is more efficient than having each cell have its own drawing.
    if( _cellColor ) {
        CGContextSetFillColorWithColor(ctx, _cellColor);
        [self drawCellsInContext: ctx fill: YES];
    }
    if( _lineColor ) {
        CGContextSetStrokeColorWithColor(ctx,_lineColor);
        CGContextSetLineWidth(ctx, 1.5);
        [self drawCellsInContext:ctx fill: NO];
    }
}


@end



#pragma mark -

@implementation GridCell


@synthesize _grid, _row, _column;
@synthesize _neighbors;

- (void)dealloc
{
    [_grid release];
    [_neighbors release];
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
        _neighbors = [[NSMutableArray alloc] initWithCapacity:8];
    }
    return self;
}

- (NSString*) description
{
    return [NSString stringWithFormat: @"%@(%u,%u)", [self class],_column,_row];
}


- (void) drawInParentContext: (CGContextRef)ctx fill: (BOOL)fill
{
    // Default implementation just fills or outlines the cell.
    CGRect frame = self.frame;
    if( fill )
        CGContextFillRect(ctx,frame);
    else
        CGContextStrokeRect(ctx, frame);
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

- (Bit*) canDragBit: (Bit*)bit
{
    if( _grid.allowsMoves && bit==self._bit )
        return [super canDragBit: bit];
    else
        return nil;
}

- (BOOL) canDropBit: (Bit*)bit atPoint: (CGPoint)point
{
    return self._bit == nil || _grid.allowsCaptures;
}


- (BOOL) fwdIsN 
{
    return self.game._currentPlayer.index == 0;
}


- (NSArray*) neighbors
{
    BOOL orthogonal = ! _grid.usesDiagonals;
    [_neighbors removeAllObjects];
    for( int dy=-1; dy<=1; dy++ )
        for( int dx=-1; dx<=1; dx++ )
            if( (dx || dy) && !(orthogonal && dx && dy) ) {
                GridCell *cell = [_grid cellAtRow: _row+dy column: _column+dx];
                if( cell )
                    [_neighbors addObject: cell];
            }
    return [[_neighbors retain] autorelease];
}


// Recursive subroutine used by getGroup:.
- (void) x_addToGroup: (NSMutableSet*)group liberties: (NSMutableSet*)liberties owner: (Player*)owner
{
    Bit *bit = self._bit;
    if( bit == nil ) {
        if( [liberties containsObject: self] )
            return; // already traversed
        [liberties addObject: self];
    } else if( bit._owner==owner ) {
        if( [group containsObject: self] )
            return; // already traversed
        [group addObject: self];
        for( GridCell *c in self.neighbors )
            [c x_addToGroup: group liberties: liberties owner: owner];
    }
}


- (NSSet*) getGroup: (int*)outLiberties
{
    NSMutableSet *group=[NSMutableSet set], *liberties=nil;
    if( outLiberties )
        liberties = [NSMutableSet set];
    [self x_addToGroup: group liberties: liberties owner: self._bit._owner];
    if( outLiberties )
        *outLiberties = liberties.count;
    return group;
}


#pragma mark -
#pragma mark DRAG-AND-DROP:


// An image from another app can be dragged onto a Dispenser to change the Piece's appearance.


//- (NSDragOperation)draggingEntered:(id <NSDraggingInfo>)sender
//{
//    NSPasteboard *pb = [sender draggingPasteboard];
//    if( [NSImage canInitWithPasteboard: pb] )
//        return NSDragOperationCopy;
//    else
//        return NSDragOperationNone;
//}
//
//- (BOOL)performDragOperation:(id <NSDraggingInfo>)sender
//{
//    CGImageRef image = GetCGImageFromPasteboard([sender draggingPasteboard]);
//    if( image ) {
//        _grid.cellColor = CreatePatternColor(image);
//        [_grid setNeedsDisplay];
//        return YES;
//    } else
//        return NO;
//}


@end




#pragma mark -

@implementation RectGrid


- (id) initWithRows: (unsigned)nRows columns: (unsigned)nColumns
            spacing: (CGSize)spacing
           position: (CGPoint)pos
{
    self = [super initWithRows: nRows columns: nColumns spacing: spacing position: pos];
    if( self ) {
        _cellClass = [Square class];
    }
    return self;
}


- (CGColorRef) altCellColor                         {return _altCellColor;}
- (void) setAltCellColor: (CGColorRef)altCellColor  {[self setcolor:&_altCellColor withNewColor:altCellColor];}


@end



#pragma mark -

@implementation Square


- (void) drawInParentContext: (CGContextRef)ctx fill: (BOOL)fill
{
    if( fill ) {
        CGColorRef c = ((RectGrid*)_grid).altCellColor;
        if( c ) {
            if( ! ((_row+_column) & 1) )
                c = _grid.cellColor;
            CGContextSetFillColorWithColor(ctx, c);
        }
    }
    [super drawInParentContext: ctx fill: fill];
}


- (void) setHighlighted: (BOOL)highlighted
{
    _highlighted = highlighted;
    self.cornerRadius = ceil(_grid.spacing.width / 4);
    self.borderWidth = (highlighted ?3 :0);
}


- (Square*) nw     {return (Square*)[_grid cellAtRow: _row+1 column: _column-1];}
- (Square*) n      {return (Square*)[_grid cellAtRow: _row+1 column: _column  ];}
- (Square*) ne     {return (Square*)[_grid cellAtRow: _row+1 column: _column+1];}
- (Square*) e      {return (Square*)[_grid cellAtRow: _row   column: _column+1];}
- (Square*) se     {return (Square*)[_grid cellAtRow: _row-1 column: _column+1];}
- (Square*) s      {return (Square*)[_grid cellAtRow: _row-1 column: _column  ];}
- (Square*) sw     {return (Square*)[_grid cellAtRow: _row-1 column: _column-1];}
- (Square*) w      {return (Square*)[_grid cellAtRow: _row   column: _column-1];}

// Directions relative to the current player:
- (Square*) fl     {return self.fwdIsN ?self.nw :self.se;}
- (Square*) f      {return self.fwdIsN ?self.n  :self.s;}
- (Square*) fr     {return self.fwdIsN ?self.ne :self.sw;}
- (Square*) r      {return self.fwdIsN ?self.e  :self.w;}
- (Square*) br     {return self.fwdIsN ?self.se :self.nw;}
- (Square*) b      {return self.fwdIsN ?self.s  :self.n;}
- (Square*) bl     {return self.fwdIsN ?self.sw :self.ne;}
- (Square*) l      {return self.fwdIsN ?self.w  :self.e;}


//- (BOOL)performDragOperation:(id <NSDraggingInfo>)sender
//{
//    CGImageRef image = GetCGImageFromPasteboard([sender draggingPasteboard]);
//    if( image ) {
//        CGColorRef color = CreatePatternColor(image);
//        RectGrid *rectGrid = (RectGrid*)_grid;
//        if( rectGrid.altCellColor && ((_row+_column) & 1) )
//            rectGrid.altCellColor = color;
//        else
//            rectGrid.cellColor = color;
//        [rectGrid setNeedsDisplay];
//        return YES;
//    } else
//        return NO;
//}

@end

#pragma mark XiangQi river square 
@implementation XiangQiGrid
@synthesize river;

- (void)dealloc
{
    [river release];
    [super dealloc];
}

- (id) initWithRows: (unsigned)nRows columns: (unsigned)nColumns
            spacing: (CGSize)spacing
           position: (CGPoint)pos
{
    CGRect frame;
    frame.origin.x = spacing.width/2;
    frame.origin.y = 4 * spacing.height + spacing.height/2;
    frame.size.height = spacing.height;
    frame.size.width = spacing.width * 8;
    self = [super initWithRows: nRows columns: nColumns spacing: spacing position: pos];
    river = [[Square alloc] initWithGrid:self row:nRows column:nColumns frame:frame];
    [self addSublayer:river];
    river.backgroundColor =  GetCGPatternNamed(@"board_320x480.png");
    river.borderColor = kRedColor;
    river.borderWidth = 1.0;
    return self;
}

- (void)drawInContext:(CGContextRef)ctx
{
    [super drawInContext:ctx];
}

@end


#pragma mark - XiangQi Square

@implementation XiangQiSquare
@synthesize _dotted;
@synthesize cross;

- (void) drawInParentContext: (CGContextRef)ctx fill: (BOOL)fill
{
    if( fill )
        [super drawInParentContext: ctx fill: fill];
    else {
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
        
        
        if( _dotted ) {

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
}

@end
