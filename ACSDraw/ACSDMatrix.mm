//
//  ACSDMatrix.mm
//  ACSDraw
//
//  Created by alan on Sat Mar 22 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import "ACSDMatrix.h"
#import "SVGWriter.h"
#import "ACSDLayer.h"
#import "ACSDPage.h"
#import "ShadowType.h"
#import "GraphicView.h"

NSString *cellHeightDidChangeNotification = @"cellHeightDidChange";
NSString *cellWidthDidChangeNotification = @"cellWidthDidChange";

@implementation ACSDMatrix


+ (NSString*)graphicTypeName
{
    return @"Matrix";
}


-(id)initWithName:(NSString*)n fill:(ACSDFill*)f stroke:(ACSDStroke*)str rect:(NSRect)r layer:(ACSDLayer*)l
{
    if (self = [super initWithName:n fill:f stroke:str rect:r layer:l])
    {
        leftMargin = rightMargin = topMargin = bottomMargin = 0.0;
        verticalAlignment = VERTICAL_ALIGNMENT_TOP;
        GraphicView *gView = [[[[self.layer page]graphicViews]allObjects]objectAtIndex:0];
        if (gView)
        {
            rows = [gView defaultMatrixRows];
            columns = [gView defaultMatrixColumns];
        }
        cellContents = [[NSMutableArray alloc]initWithCapacity:10];
        [self setCellStroke:str];
        cellSizeFixed = NO;
        noCellsFixed = NO;
        for (int i = 0;i < rows;i++)
        {
            NSMutableArray *a = [NSMutableArray arrayWithCapacity:columns];
            for (int j = 0;j < columns;j++)
            [a addObject:[[NSTextStorage alloc] init]];
            [cellContents addObject:a];
        }
        strokeType = STROKE_BOTH;
    }
    return self;
}

-(id)initWithName:(NSString*)n fill:(ACSDFill*)f stroke:(ACSDStroke*)str rect:(NSRect)r layer:(ACSDLayer*)l
           xScale:(float)xs yScale:(float)ys rotation:(float)rot shadowType:(ShadowType*)st label:(ACSDLabel*)lab alpha:(float)a
        topMargin:(float)tm leftMargin:(float)lm bottomMargin:(float)bm rightMargin:(float)rm verticalAlignment:(VerticalAlignment)vA
             rows:(int)ro columns:(int)c cellContents:(NSArray*)cc cellStroke:(ACSDStroke*)cstr
        cellWidth:(float)cw cellHeight:(float)ch strokeType:(StrokeType)strt cellSizeFixed:(BOOL) csf noCellsFixed:(BOOL)ncf
{
    if (self = [super initWithName:n fill:f stroke:str rect:r
                             layer:l xScale:xs yScale:ys rotation:rot shadowType:st label:lab alpha:a])
    {
        leftMargin = lm;
        rightMargin = rm;
        topMargin = tm;
        bottomMargin = bm;
        verticalAlignment = vA;
        rows = ro;
        columns = c;
        cellContents = [[NSMutableArray alloc]initWithCapacity:10];
        [self setCellStroke:cstr];
        for (int i = 0;i < rows;i++)
        {
            NSMutableArray *a = [NSMutableArray arrayWithCapacity:columns];
            NSArray *originalRow = [cc objectAtIndex:i];
            for (int j = 0;j < columns;j++)
            [a addObject:[[NSTextStorage alloc] initWithAttributedString:[originalRow objectAtIndex:j]]];
            [cellContents addObject:a];
        }
        strokeType = strt;
        cellSizeFixed = csf;
        noCellsFixed = ncf;
    }
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (id) initWithCoder:(NSCoder*)coder
{
    self = [super initWithCoder:coder];
    rows = [coder decodeIntForKey:@"ACSDMatrix_rows"];
    columns = [coder decodeIntForKey:@"ACSDMatrix_columns"];
    topMargin = [coder decodeFloatForKey:@"ACSDMatrix_topMargin"];
    leftMargin = [coder decodeFloatForKey:@"ACSDMatrix_leftMargin"];
    bottomMargin = [coder decodeFloatForKey:@"ACSDMatrix_bottomMargin"];
    rightMargin = [coder decodeFloatForKey:@"ACSDMatrix_rightMargin"];
    verticalAlignment = (VerticalAlignment)[coder decodeIntForKey:@"ACSDMatrix_verticalAlignment"];
    cellContents = [coder decodeObjectForKey:@"ACSDMatrix_cellContents"];
    cellStroke = [coder decodeObjectForKey:@"ACSDMatrix_cellStroke"];
    cellWidth = [coder decodeFloatForKey:@"ACSDMatrix_cellWidth"];
    cellHeight = [coder decodeFloatForKey:@"ACSDMatrix_cellHeight"];
    cellSizeFixed = [coder decodeBoolForKey:@"ACSDMatrix_cellSizeFixed"];
    noCellsFixed = [coder decodeBoolForKey:@"ACSDMatrix_noCellsFixed"];
    if (!cellContents)
    {
        cellContents = [[NSMutableArray alloc]initWithCapacity:10];
        for (int i = 0;i < rows;i++)
        {
            NSMutableArray *a = [NSMutableArray arrayWithCapacity:columns];
            for (int j = 0;j < columns;j++)
            [a addObject:[[NSTextStorage alloc] init]];
            [cellContents addObject:a];
        }
    }
    if (stroke == cellStroke)
        strokeType = STROKE_BOTH;
    else
        strokeType = STROKE_OUTLINE;
    return self;
}

- (void) encodeWithCoder:(NSCoder*)coder
{
    [super encodeWithCoder:coder];
    [coder encodeInt:rows forKey:@"ACSDMatrix_rows"];
    [coder encodeInt:columns forKey:@"ACSDMatrix_columns"];
    [coder encodeFloat:topMargin forKey:@"ACSDMatrix_topMargin"];
    [coder encodeFloat:leftMargin forKey:@"ACSDMatrix_leftMargin"];
    [coder encodeFloat:bottomMargin forKey:@"ACSDMatrix_bottomMargin"];
    [coder encodeFloat:rightMargin forKey:@"ACSDMatrix_rightMargin"];
    [coder encodeInt:verticalAlignment forKey:@"ACSDMatrix_verticalAlignment"];
    [coder encodeFloat:cellWidth forKey:@"ACSDMatrix_cellWidth"];
    [coder encodeFloat:cellHeight forKey:@"ACSDMatrix_cellHeight"];
    [coder encodeBool:cellSizeFixed forKey:@"ACSDMatrix_cellSizeFixed"];
    [coder encodeBool:noCellsFixed forKey:@"ACSDMatrix_noCellsFixed"];
    [coder encodeObject:cellContents forKey:@"ACSDMatrix_cellContents"];
    [coder encodeConditionalObject:cellStroke forKey:@"ACSDMatrix_cellStroke"];
}

- (id)copyWithZone:(NSZone *)zone 
{
    return [[[self class] alloc]initWithName:self.name fill:fill stroke:stroke rect:bounds layer:self.layer
                                      xScale:xScale yScale:yScale rotation:rotation shadowType:shadowType label:textLabel alpha:alpha
                                   topMargin:topMargin leftMargin:leftMargin bottomMargin:bottomMargin rightMargin:rightMargin verticalAlignment:verticalAlignment
                                        rows:rows columns:columns cellContents:cellContents cellStroke:cellStroke
                                   cellWidth:cellWidth cellHeight:cellHeight strokeType:strokeType cellSizeFixed:cellSizeFixed noCellsFixed:noCellsFixed];
}

- (void)setStrokeType:(StrokeType)s
{
    strokeType = s;
}

- (void)setRows:(int)r
{
    rows = r;
}

- (void)setColumns:(int)c
{
    columns = c;
}
- (void)setTopMargin:(float)f
{
    topMargin = f;
}
- (void)setLeftMargin:(float)f
{
    leftMargin = f;
}
- (void)setRightMargin:(float)f
{
    rightMargin = f;
}
- (void)setBottomMargin:(float)f
{
    bottomMargin = f;
}
- (void)setVerticalAlignment:(VerticalAlignment)v
{
    verticalAlignment = v;
}

- (void)setCellContents:(NSMutableArray*)cc
{
    cellContents = cc;
}

-(void)setCellStroke:(ACSDStroke*)s
{
    if (cellStroke)
    {
        [cellStroke removeGraphic:self];
    }
    if (s)
    {
        cellStroke = s;
        [cellStroke addGraphic:self];
    }
}

- (int)rows
{
    return rows;
}

- (int)columns
{
    return columns;
}

- (float)cellHeight
{
    //	return bounds.size.height/rows;
    return cellHeight;
}

- (float)cellWidth
{
    //	return bounds.size.width/columns;
    return cellWidth;
}

-(BOOL)cellSizeFixed
{
    return cellSizeFixed;
}

-(BOOL)noCellsFixed
{
    return noCellsFixed;
}

-(BOOL)isEditable
{
    return YES;
}

- (float)topMargin
{
    return topMargin;
}

- (float)leftMargin
{
    return leftMargin;
}

- (float)bottomMargin
{
    return bottomMargin;
}

- (float)rightMargin
{
    return rightMargin;
}

- (VerticalAlignment)verticalAlignment
{
    return verticalAlignment;
}

- (StrokeType)strokeType
{
    return strokeType;
}

-(ACSDStroke*)cellStroke
{
    return cellStroke;
}

-(ACSDStroke*)graphicStroke
{
    if (strokeType == STROKE_OUTLINE)
        return [self stroke];
    if (strokeType == STROKE_CELLS)
        return [self cellStroke];
    return [self stroke];
}


-(void) adjustArraysForCells
{
    for (int i = (int)[cellContents count];i < rows;i++)
    {
        NSMutableArray *a = [NSMutableArray arrayWithCapacity:columns];
        for (int j = 0;j < columns;j++)
        [a addObject:[[NSTextStorage alloc] init]];
        [cellContents addObject:a];
    }
    for (int i = (int)[cellContents count]-1;i >= rows;i--)
    {
        [cellContents removeObjectAtIndex:i];
    }
    for (int i = 0;i < rows;i++)
    {
        NSMutableArray *a = [cellContents objectAtIndex:i];
        for (int j = (int)[a count];j < columns;j++)
        [a addObject:[[NSTextStorage alloc] init]];
        for (int j = (int)[a count] - 1;j >= columns;j--)
        [a removeObjectAtIndex:j];
    }
}

- (void)otherTrackKnobNotifiesView:(GraphicView*)gView
{
    NSDictionary *dict = [NSDictionary dictionaryWithObject:[NSNumber numberWithFloat:cellHeight] forKey:@"cellheight"];
    [[NSNotificationCenter defaultCenter] postNotificationName:cellHeightDidChangeNotification object:gView userInfo:dict];
    dict = [NSDictionary dictionaryWithObject:[NSNumber numberWithFloat:cellWidth] forKey:@"cellwidth"];
    [[NSNotificationCenter defaultCenter] postNotificationName:cellWidthDidChangeNotification object:gView userInfo:dict];
}

-(BOOL)setGraphicBoundsTo:(NSRect)newBounds from:(NSRect)oldBounds 
{
    if (NSEqualRects(newBounds, oldBounds))
        return NO;
    else
    {
        [super setGraphicBoundsTo:newBounds from:oldBounds];
        BOOL changed = NO;
        if (cellSizeFixed)
        {
            int colCount = (int)ceil((bounds.size.width / cellWidth));
            if (colCount != columns)
            {
                //				if (!manipulatingBounds)
                //					[[[self undoManager] prepareWithInvocationTarget:self] setGraphicColumns:colCount];
                columns = colCount;
                changed = YES;
            }
            int rowCount = (int)ceil((bounds.size.height / cellHeight));
            if (rowCount != rows)
            {
                //				if (!manipulatingBounds)
                //					[[[self undoManager] prepareWithInvocationTarget:self] setGraphicRows:rowCount];
                rows = rowCount;
                changed = YES;
            }
        }
        else
        {
            cellWidth = bounds.size.width / columns;
            cellHeight = bounds.size.height / rows;
        }
        [self adjustArraysForCells];
        if (changed)
            [self invalidateGraphicSizeChanged:YES shapeChanged:YES redraw:YES notify:YES];
        else
            [self invalidateGraphicSizeChanged:NO shapeChanged:NO redraw:NO notify:YES];
        return YES;
    }
}

-(ACSDStroke*)setGraphicStrokeType:(StrokeType)s
{
    if (strokeType == s)
        return [self graphicStroke];
    if (s == STROKE_BOTH)
    {
        [self invalidateGraphicSizeChanged:NO shapeChanged:NO redraw:NO notify:NO];
        if (strokeType == STROKE_OUTLINE)
            [self setCellStroke:[self stroke]];
        else
            [self setStroke:[self cellStroke]];
        [self invalidateGraphicSizeChanged:YES shapeChanged:NO redraw:YES notify:NO];
    }
    [self setStrokeType:s];
    return [self graphicStroke];
}

-(BOOL)setGraphicStroke:(ACSDStroke*)s notify:(BOOL)notify
{
    if (strokeType == STROKE_OUTLINE)
    {
        [super setGraphicStroke:s notify:notify];
        return YES;
    }
    if (strokeType == STROKE_CELLS)
    {
        [self invalidateGraphicSizeChanged:NO shapeChanged:NO redraw:NO notify:NO];
        [self setCellStroke:s];
        [self invalidateGraphicSizeChanged:YES shapeChanged:NO redraw:YES notify:NO];
        return YES;
    }
    [self invalidateGraphicSizeChanged:NO shapeChanged:NO redraw:NO notify:NO];
    [self setStroke:s];
    [self setCellStroke:s];
    [self invalidateGraphicSizeChanged:YES shapeChanged:NO redraw:YES notify:NO];
    return YES;
}

-(void)setGraphicRows:(int)n notify:(BOOL)notify
{
    if (n == rows || n <= 0)
        return;
    [self invalidateGraphicSizeChanged:NO shapeChanged:NO redraw:NO notify:NO];
    [[[self undoManager] prepareWithInvocationTarget:self] setGraphicRows:rows notify:YES];
    if (cellSizeFixed)
        bounds.size.height = [self cellHeight] * n;
    else
        cellHeight = bounds.size.height / n;
    [self setRows:n];
    [self adjustArraysForCells];
    [self invalidateGraphicSizeChanged:YES shapeChanged:YES redraw:YES notify:notify];
    [[self undoManager] setActionName:@"Change Number Of Rows"];
}

-(void)setGraphicColumns:(int)n notify:(BOOL)notify
{
    if (n == columns || n <= 0)
        return;
    [self invalidateGraphicSizeChanged:NO shapeChanged:NO redraw:NO notify:NO];
    [[[self undoManager] prepareWithInvocationTarget:self] setGraphicColumns:columns notify:YES];
    if (cellSizeFixed)
        bounds.size.width = [self cellWidth] * n;
    else
        cellWidth = bounds.size.width / n;
    [self setColumns:n];
    [self adjustArraysForCells];
    [self invalidateGraphicSizeChanged:YES shapeChanged:YES redraw:YES notify:notify];
    [[self undoManager] setActionName:@"Change Number Of Columns"];
}

-(void)setGraphicCellSizeFixed:(int)i notify:(BOOL)notify
{
    BOOL csf = i != 0;
    if (csf == cellSizeFixed)
        return;
    [[[self undoManager] prepareWithInvocationTarget:self] setGraphicCellSizeFixed:cellSizeFixed notify:YES];
    cellSizeFixed = csf;
    if (notify)
        [[NSNotificationCenter defaultCenter] postNotificationName:ACSDGraphicDidChangeNotification object:self];
}

-(void)setGraphicNoCellsFixed:(int)i notify:(BOOL)notify
{
    BOOL ncf = i != 0;
    if (ncf == noCellsFixed)
        return;
    [[[self undoManager] prepareWithInvocationTarget:self] setGraphicCellSizeFixed:noCellsFixed notify:YES];
    noCellsFixed = ncf;
    if (notify)
        [[NSNotificationCenter defaultCenter] postNotificationName:ACSDGraphicDidChangeNotification object:self];
}

-(void)setGraphicCellHeight:(float)f notify:(BOOL)notify
{
    if (f == cellHeight || f <= 0.0)
        return;
    [self invalidateGraphicSizeChanged:NO shapeChanged:NO redraw:NO notify:NO];
    [[[self undoManager] prepareWithInvocationTarget:self] setGraphicCellHeight:cellHeight notify:YES];
    cellHeight = f;
    if (noCellsFixed)
        bounds.size.height = cellHeight * rows;
    else
        rows = (int)ceil((bounds.size.height / cellHeight));
    [self adjustArraysForCells];
    [self invalidateGraphicSizeChanged:YES shapeChanged:YES redraw:YES notify:notify];
    [[self undoManager] setActionName:@"Change Cell Height"];
}

-(void)setGraphicCellWidth:(float)f notify:(BOOL)notify
{
    if (f == cellWidth || f <= 0.0)
        return;
    [self invalidateGraphicSizeChanged:NO shapeChanged:NO redraw:NO notify:NO];
    [[[self undoManager] prepareWithInvocationTarget:self] setGraphicCellWidth:cellWidth notify:YES];
    cellWidth = f;
    if (noCellsFixed)
        bounds.size.width = cellWidth * rows;
    else
        columns = (int)ceil((bounds.size.width / cellWidth));
    [self adjustArraysForCells];
    [self invalidateGraphicSizeChanged:YES shapeChanged:YES redraw:YES notify:notify];
    [[self undoManager] setActionName:@"Change Cell Height"];
}

- (BOOL)setGraphicLeftMargin:(float)m notify:(BOOL)notify
{
    if (m == leftMargin)
        return NO;
    [self invalidateGraphicSizeChanged:NO shapeChanged:NO redraw:NO notify:NO];
    [[[self undoManager] prepareWithInvocationTarget:self] setGraphicLeftMargin:leftMargin notify:YES];
    [self setLeftMargin:m];
    [self invalidateGraphicSizeChanged:YES shapeChanged:YES redraw:YES notify:notify];
    return YES;
}

- (BOOL)setGraphicRightMargin:(float)m notify:(BOOL)notify
{
    if (m == rightMargin)
        return NO;
    [self invalidateGraphicSizeChanged:NO shapeChanged:NO redraw:NO notify:NO];
    [[[self undoManager] prepareWithInvocationTarget:self] setGraphicRightMargin:rightMargin notify:YES];
    [self setRightMargin:m];
    [self invalidateGraphicSizeChanged:YES shapeChanged:YES redraw:YES notify:notify];
    return YES;
}

- (BOOL)setGraphicTopMargin:(float)m notify:(BOOL)notify
{
    if (m == topMargin)
        return NO;
    [self invalidateGraphicSizeChanged:NO shapeChanged:NO redraw:NO notify:NO];
    [[[self undoManager] prepareWithInvocationTarget:self] setGraphicTopMargin:topMargin notify:YES];
    [self setTopMargin:m];
    [self invalidateGraphicSizeChanged:YES shapeChanged:YES redraw:YES notify:notify];
    return YES;
}

- (BOOL)setGraphicBottomMargin:(float)m notify:(BOOL)notify
{
    if (m == bottomMargin)
        return NO;
    [self invalidateGraphicSizeChanged:NO shapeChanged:NO redraw:NO notify:NO];
    [[[self undoManager] prepareWithInvocationTarget:self] setGraphicBottomMargin:bottomMargin notify:YES];
    [self setBottomMargin:m];
    [self invalidateGraphicSizeChanged:YES shapeChanged:YES redraw:YES notify:notify];
    return YES;
}

- (void)setGraphicVerticalAlignment:(VerticalAlignment)a notify:(BOOL)notify
{
    [self invalidateGraphicSizeChanged:NO shapeChanged:NO redraw:NO notify:NO];
    [[[self undoManager] prepareWithInvocationTarget:self] setGraphicVerticalAlignment:verticalAlignment notify:YES];
    [self setVerticalAlignment:a];
    [self invalidateGraphicSizeChanged:YES shapeChanged:YES redraw:YES notify:notify];
}

- (NSTextStorage *)cellContentsFromRow:(int)row column:(int)col
{
    NSMutableArray *arr = [cellContents objectAtIndex:row];
    return [arr objectAtIndex:col];
}

- (void)endEditingInView:(GraphicView *)view
{
    if ([view editingGraphic] == self)
    {
        NSTextView *editor = (NSTextView *)[view editor];
        [editor setDelegate:nil];
        [editor removeFromSuperview];
        [[self cellContentsFromRow:editedRow column:editedColumn] removeLayoutManager:[editor layoutManager]];
        [view setEditorInUse:NO];
        [view setEditingGraphic:nil];
    }
}

- (NSRect)boundsRectForRow:(int)row andColumn:(int)column
{
    float oX = cellWidth * column;
    float oY = cellHeight * row;
    oX += bounds.origin.x;
    oY += bounds.origin.y;
    return NSMakeRect(oX,oY,cellWidth,cellHeight);
}

- (void)getRow:(int *)row andColumn:(int *)column forPoint:(NSPoint)pt
{
    float x = pt.x - bounds.origin.x;
    float y = pt.y - bounds.origin.y;
    *row = (int)(y / cellHeight);
    *column = (int)(x / cellWidth);
}

- (void)startEditingWithEvent:(NSEvent *)event inView:(GraphicView *)view
{
    NSPoint hitPoint = [view convertPoint:[event locationInWindow] fromView:nil];
    [self getRow:&editedRow andColumn:&editedColumn forPoint:hitPoint];
    if (editedRow < 0 || editedRow >= rows || editedColumn < 0 || editedColumn >= columns)
        return;
    NSTextView *editor = [view editor];
    NSTextStorage *cont = [self cellContentsFromRow:editedRow column:editedColumn];
    NSRect b = [self boundsRectForRow:editedRow andColumn:editedColumn];
    //    [[editor textContainer] setWidthTracksTextView:NO];
    [[editor textContainer] setContainerSize:b.size];
    NSPoint pt = b.origin;
    b.origin.x += (b.size.width/2.0);
    b.origin.y += (b.size.height/2.0);
    NSAffineTransform *trans = [NSAffineTransform transform];
    [trans translateXBy:b.origin.x yBy:b.origin.y];
    [trans rotateByDegrees:rotation];
    [trans translateXBy:-b.origin.x yBy:-b.origin.y];
    pt = [trans transformPoint:pt];
    [editor setFrame:b];
    [editor setFrameRotation:rotation];
    [editor setFrameOrigin:pt];
    [cont addLayoutManager:[editor layoutManager]];
    [view addSubview:editor];
    [view setEditingGraphic:self];
    [editor setSelectedRange:NSMakeRange(0, [cont length])];
    [editor setDelegate:self];
    
    // Make sure we redisplay
    [self invalidateGraphicSizeChanged:NO shapeChanged:NO redraw:YES notify:NO];
    
    [[view window] makeFirstResponder:editor];
    if (event)
        [editor mouseDown:event];
}

- (void)drawObject:(NSRect)aRect view:(GraphicView*)gView options:(NSMutableDictionary*)options
{
    NSBezierPath *path = [self transformedBezierPath];
    if (fill)
        [fill fillPath:path];
    if (stroke)
        [stroke strokePath:path];
    if (cellStroke)
    {
        path = [self transformedCellPath];
        [cellStroke strokePath:path];
    }
    if (gView && ([gView creatingGraphic] == self))
        return;
    if (![self visible])
        return;
    if (rotation != 0.0)
    {
        [NSGraphicsContext saveGraphicsState];
        [transform concat];
    }
    for (int i = 0;i < rows;i++)
    {
        NSMutableArray *rowArr = [cellContents objectAtIndex:i];
        for (int j = 0;j < columns;j++)
        {
            if (gView && ([gView editingGraphic] == self) && (editedRow == i && editedColumn == j))
                continue;
            NSTextStorage *cont = [rowArr objectAtIndex:j];
            NSRect b = [self boundsRectForRow:i andColumn:j];;
            b.origin.x += leftMargin;
            b.size.width -= (leftMargin + rightMargin);
            b.origin.y += topMargin;
            b.size.height -= (topMargin + bottomMargin);
            if ([cont length] > 0)
            {
                NSLayoutManager *lm = [gView layoutManager];
                NSTextContainer *tc = [[lm textContainers] objectAtIndex:0];
                NSRange glyphRange;
                [tc setContainerSize:b.size];
                [cont addLayoutManager:lm];
                glyphRange = [lm glyphRangeForTextContainer:tc];
                if (glyphRange.length > 0)
                {
                    if (verticalAlignment != VERTICAL_ALIGNMENT_TOP)
                    {
                        NSRect r = [lm usedRectForTextContainer:tc];
                        float diff = b.size.height - r.size.height;
                        if (diff > 0.0)
                        {
                            if (verticalAlignment ==  VERTICAL_ALIGNMENT_BOTTOM)
                                b.origin.y += diff;
                            else
                                b.origin.y += (diff / 2.0);
                        }
                    }
                    [lm drawBackgroundForGlyphRange:glyphRange atPoint:b.origin];
                    [lm drawGlyphsForGlyphRange:glyphRange atPoint:b.origin];
                }
                [cont removeLayoutManager:lm];
            }
        }
    }
    if (rotation != 0.0)
        [NSGraphicsContext restoreGraphicsState];
}

- (NSBezierPath *)cellPath
{
    NSBezierPath *p = [NSBezierPath bezierPath];
    float deltaX = cellWidth;
    float deltaY = cellHeight;
    float x = bounds.origin.x;
    float y = bounds.origin.y + deltaY;
    for (int i = 1;i < rows;i++)
    {
        [p moveToPoint:NSMakePoint(x,y)];
        [p relativeLineToPoint:NSMakePoint(bounds.size.width,0)];
        y += deltaY;
    }
    x = bounds.origin.x + deltaX;
    y = bounds.origin.y;
    for (int i = 0;i < columns;i++)
    {
        [p moveToPoint:NSMakePoint(x,y)];
        [p relativeLineToPoint:NSMakePoint(0,bounds.size.height)];
        x += deltaX;
    }
    return p;
}

- (NSBezierPath *)transformedCellPath
{
    if (rotation == 0.0)
        return [self cellPath];
    return [transform transformBezierPath:[self cellPath]];
}

- (NSBezierPath *)bezierPath
{
    NSBezierPath *p = [NSBezierPath bezierPathWithRect:bounds];
    return p;
}

-(void)writeSVGCellTextRow:(int)i column:(int)j writer:(SVGWriter*)svgWriter
{
    [[svgWriter contents]appendString:@"<text transform=\""];
    if (transform)
        [[svgWriter contents]appendString:string_from_transform(transform)];
    [[svgWriter contents]appendString:@"\">\n"];
    NSTextStorage *cont = [self cellContentsFromRow:i column:j];
    NSLayoutManager *lm=nil;
    GraphicView *gView = [[[[self.layer page]graphicViews]allObjects]objectAtIndex:0];
    if (gView)
        lm = [gView layoutManager];
    NSTextContainer *tc = [[lm textContainers] objectAtIndex:0];
    NSRect b = [self boundsRectForRow:i andColumn:j];
    b.origin.x += leftMargin;
    b.size.width -= (leftMargin + rightMargin);
    b.origin.y += topMargin;
    b.size.height -= (topMargin + bottomMargin);
    [tc setContainerSize:b.size];
    [cont addLayoutManager:lm];
    NSRange glyphRange = [lm glyphRangeForTextContainer:tc];
    if (verticalAlignment != VERTICAL_ALIGNMENT_TOP)
    {
        NSRect r = [lm usedRectForTextContainer:tc];
        float diff = b.size.height - r.size.height;
        if (diff > 0.0)
        {
            if (verticalAlignment ==  VERTICAL_ALIGNMENT_BOTTOM)
                b.origin.y += diff;
            else
                b.origin.y += (diff / 2.0);
        }
    }
    NSUInteger glyphCount = [lm numberOfGlyphs];
    for (NSUInteger glyphIndex = 0;glyphIndex < glyphCount;)
    {
        NSRect glyphRect = [lm lineFragmentRectForGlyphAtIndex:glyphIndex effectiveRange:&glyphRange];
        NSPoint loc = glyphRect.origin;
        NSAttributedString *lineString = [cont attributedSubstringFromRange:glyphRange];
        for (unsigned int i = 0;i < glyphRange.length;)
        {
            NSRange attributeRange;
            NSDictionary *attributeDict	= [lineString attributesAtIndex:i effectiveRange:&attributeRange];
            if (attributeRange.location < i)
            {
                attributeRange.length -= (i - attributeRange.location);
                attributeRange.location = i;
            }
            NSRange tabRange = [[lineString string]rangeOfString:@"\t" options:NSLiteralSearch range:attributeRange];
            if (tabRange.location != NSNotFound)
            {
                if (tabRange.location >= [lineString length])
                    NSLog(@"shouldn't happen");
                
                attributeRange.length = tabRange.location + 1 - attributeRange.location;
            }
            NSPoint glyphLoc = [lm locationForGlyphAtIndex:glyphRange.location + i];
            NSFont *font = [attributeDict objectForKey:NSFontAttributeName];
            NSColor *col = [attributeDict objectForKey:NSForegroundColorAttributeName];
            NSFontTraitMask fontMask = [[NSFontManager sharedFontManager]traitsOfFont:font];
            [[svgWriter contents] appendFormat:@"<tspan x=\"%g\" y=\"%g\" font-family=\"%@\" font-size=\"%f\"",
             glyphLoc.x + b.origin.x,loc.y + b.origin.y + glyphLoc.y,[font familyName],[font pointSize]];
            if (fontMask & NSBoldFontMask)
                [[svgWriter contents] appendString:@" font-weight=\"bold\""];
            if (fontMask & NSItalicFontMask)
                [[svgWriter contents] appendString:@" font-style=\"italic\""];
            NSString *printString = substitute_characters([[lineString attributedSubstringFromRange:attributeRange]string]);
            [[svgWriter contents] appendFormat:@" fill=\"%@\" > %@ </tspan>\n",string_from_nscolor(col),printString];
            i += attributeRange.length;
        }
        glyphIndex += glyphRange.length;
    }
    [[svgWriter contents]appendString:@"</text>\n"];
    [cont removeLayoutManager:lm];
}

-(void)writeSVGData:(SVGWriter*)svgWriter
{
    [[svgWriter contents]appendFormat:@"<g id=\"%@\" ",self.name];
    if (shadowType)
        [shadowType writeSVGData:svgWriter];
    [[svgWriter contents]appendString:@">\n"];
    if (fill || stroke)
    {
        [[svgWriter contents]appendFormat:@"<path d=\"%@\" ",string_from_path([self transformedBezierPath])];
        if (fill)
            [fill writeSVGData:svgWriter];
        if (stroke)
            [stroke writeSVGData:svgWriter];
        [[svgWriter contents]appendString:@" />\n"];
    }
    if (cellStroke)
    {
        [[svgWriter contents]appendFormat:@"<path d=\"%@\" ",string_from_path([self transformedCellPath])];
        [cellStroke writeSVGData:svgWriter];
        [[svgWriter contents]appendString:@" />\n"];
    }
    for (int i = 0;i < rows;i++)
    for (int j = 0;j < columns;j++)
    [self writeSVGCellTextRow:i column:j writer:svgWriter];
    [[svgWriter contents]appendString:@"</g>\n"];
}

@end
