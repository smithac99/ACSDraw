//
//  ACSDGrid.mm
//  ACSDraw
//
//  Created by alan on 14/02/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "ACSDGrid.h"
#import "GraphicView.h"
#import "ACSDPage.h"

@implementation ACSDGrid

+ (NSString*)graphicTypeName
   {
	return @"Grid";
   }

-(id)initWithName:(NSString*)n fill:(ACSDFill*)f stroke:(ACSDStroke*)str rect:(NSRect)r layer:(ACSDLayer*)l
   {
    if (self = [super initWithName:n fill:f stroke:str rect:r layer:l])
	   {
		GraphicView *gView = [[[[self.layer page]graphicViews]allObjects]objectAtIndex:0];
		if (gView)
		   {
			rows = [gView defaultMatrixRows];
			columns = [gView defaultMatrixColumns];
		   }
	   }
	return self;
   }

- (id) initWithCoder:(NSCoder*)coder
   {
	self = [super initWithCoder:coder];
	rows = [coder decodeIntForKey:@"ACSDGrid_rows"];
	columns = [coder decodeIntForKey:@"ACSDGrid_columns"];
	cellWidth = [coder decodeFloatForKey:@"ACSDGrid_cellWidth"];
	cellHeight = [coder decodeFloatForKey:@"ACSDGrid_cellHeight"];
	gridMode = [coder decodeIntForKey:@"ACSDGrid_gridMode"];
	return self;
   }

- (void) encodeWithCoder:(NSCoder*)coder
   {
	[super encodeWithCoder:coder];
	[coder encodeInt:rows forKey:@"ACSDGrid_rows"];
	[coder encodeInt:columns forKey:@"ACSDGrid_columns"];
	[coder encodeFloat:cellWidth forKey:@"ACSDGrid_cellWidth"];
	[coder encodeFloat:cellHeight forKey:@"ACSDGrid_cellHeight"];
	[coder encodeInt:gridMode forKey:@"ACSDGrid_gridMode"];
   }

- (void)setRows:(int)r
   {
	rows = r;
   }

- (void)setColumns:(int)c
   {
	columns = c;
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
	return cellHeight;
   }

- (float)cellWidth
   {
	return cellWidth;
   }

- (int)gridMode
   {
	return gridMode;
   }

-(BOOL)setGraphicBoundsTo:(NSRect)newBounds from:(NSRect)oldBounds 
   {
    if (NSEqualRects(newBounds, oldBounds))
		return NO;
	else
	   {
		[super setGraphicBoundsTo:newBounds from:oldBounds];
		BOOL changed = NO;
		if (gridMode == GRID_MODE_FIXED_CELL_DIMENSION)
		   {
			int colCount = (int)ceil((bounds.size.width / cellWidth));
			if (colCount != columns)
			   {
				columns = colCount;
				changed = YES;
			   }
			int rowCount = (int)ceil((bounds.size.height / cellHeight));
			if (rowCount != rows)
			   {
				rows = rowCount;
				changed = YES;
			   }
		   }
		else
		   {
			cellWidth = bounds.size.width / columns;
			cellHeight = bounds.size.height / rows;
		   }
		if (changed)
			[self invalidateGraphicSizeChanged:YES shapeChanged:YES redraw:YES notify:YES];
		else
			[self invalidateGraphicSizeChanged:NO shapeChanged:NO redraw:NO notify:YES];
		return YES;
       }
   }

-(void)setGraphicRows:(int)n notify:(BOOL)notify
   {
	if (n == rows || n <= 0)
		return;
	[self invalidateGraphicSizeChanged:NO shapeChanged:NO redraw:NO notify:NO];
	[[[self undoManager] prepareWithInvocationTarget:self] setGraphicRows:rows notify:YES];
//	if (gridMode == GRID_MODE_FIXED_NO_CELLS)
//		bounds.size.height = [self cellHeight] * n;
//	else
		cellHeight = bounds.size.height / n;
	[self setRows:n];
	[self invalidateGraphicSizeChanged:YES shapeChanged:YES redraw:YES notify:notify];
    [[self undoManager] setActionName:@"Change Number Of Rows"];
   }

-(void)setGraphicColumns:(int)n notify:(BOOL)notify
   {
	if (n == columns || n <= 0)
		return;
	[self invalidateGraphicSizeChanged:NO shapeChanged:NO redraw:NO notify:NO];
	[[[self undoManager] prepareWithInvocationTarget:self] setGraphicColumns:columns notify:YES];
//	if (gridMode == GRID_MODE_FIXED_NO_CELLS)
//		bounds.size.width = [self cellWidth] * n;
//	else
		cellWidth = bounds.size.width / n;
	[self setColumns:n];
	[self invalidateGraphicSizeChanged:YES shapeChanged:YES redraw:YES notify:notify];
    [[self undoManager] setActionName:@"Change Number Of Columns"];
   }

-(void)setGraphicGridMode:(int)i notify:(BOOL)notify
   {
	BOOL csf = i != 0;
	if (csf == gridMode)
		return;
	[[[self undoManager] prepareWithInvocationTarget:self] setGraphicGridMode:gridMode notify:YES];
	gridMode = csf;
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
	if (gridMode == GRID_MODE_FIXED_NO_CELLS)
		bounds.size.height = cellHeight * rows;
	else
		rows = (int)ceil((bounds.size.height / cellHeight));
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
	if (gridMode == GRID_MODE_FIXED_NO_CELLS)
		bounds.size.width = cellWidth * rows;
	else
		columns = (int)ceil((bounds.size.width / cellWidth));
	[self invalidateGraphicSizeChanged:YES shapeChanged:YES redraw:YES notify:notify];
    [[self undoManager] setActionName:@"Change Cell Height"];
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
    if (self.rotation == 0.0)
		return [self cellPath];
	return [transform transformBezierPath:[self cellPath]];
   }

- (NSBezierPath *)bezierPath
   {
    NSBezierPath *p = [NSBezierPath bezierPathWithRect:bounds];
	return p;
   }

- (void)drawObject:(NSRect)aRect view:(GraphicView*)gView options:(NSMutableDictionary*)options
{
	NSBezierPath *path = [self transformedBezierPath];
	if (fill)
		[fill fillPath:path];
	if (stroke)
	{
		[stroke strokePath:path];
		[stroke strokePath:[self transformedCellPath]];
	}
}


@end
