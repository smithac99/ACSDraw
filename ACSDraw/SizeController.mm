//
//  SizeController.mm
//  ACSDraw
//
//  Created by alan on 08/02/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "SizeController.h"
#import "GraphicView.h"
#import "ACSDGraphic.h"
#import "ACSDRect.h"
#import "ACSDGrid.h"
#import "ACSDFreeHand.h"

NSString *ACSDShowCoordinatesNotification = @"ACSDShowCoordinates";

@implementation SizeController

-(id)init
{
	if ((self = [super initWithTitle:@"Size"]))
	{
        showsWidth = showsHeight = YES;
        showsLeft = showsBottom = YES;
	}
	return self;
}

- (void)setTransientCoordinateFieldsVisible:(BOOL)visible
{
	[dX setHidden:!visible];
	[dXLabel setHidden:!visible];
	[dY setHidden:!visible];
	[dYLabel setHidden:!visible];
	[theta setHidden:!visible];
	[thetaLabel setHidden:!visible];	
	[dist setHidden:!visible];
	[distLabel setHidden:!visible];	
}

- (void)changeCoordinateVisibility:(NSNotification *)notification
{
    [self setTransientCoordinateFieldsVisible:[[[notification userInfo]objectForKey:@"vis"]boolValue]];
}

-(void)rebuildForGraphics:(NSArray*)graphics
{
	float topY = 0.0;
	NSRect frame;
	id graphic = nil;
	if ([graphics count] == 1)
		graphic = [graphics objectAtIndex:0];
	if (graphic && [graphic respondsToSelector:@selector(cellHeight)])
	{
		if ([gridView superview] == nil)
		{
			[self.contentView addSubview:gridView];
			frame = [gridView frame];
			frame.origin.y = topY;
			topY += frame.size.height;
			frame.size.width = [self.contentView frame].size.width;
			[gridView setFrame:frame];
			[coordinateView removeFromSuperview];
		}
	}
	else
	{
		[gridView removeFromSuperview];
		[coordinateView removeFromSuperview];
	}
	if ([coordinateView superview] == nil)
	{
		[self.contentView addSubview:coordinateView];
		frame = [coordinateView frame];
		frame.origin.y = topY;
		frame.size.width = [self.contentView frame].size.width;
		[coordinateView setFrame:frame];
	}
	topY = NSMaxY([coordinateView frame]);
	if ((graphic && [graphic respondsToSelector:@selector(cornerRadius)]))
	{
		if ([cornerRadiusView superview] == nil)
		{
			[self.contentView addSubview:cornerRadiusView];
			frame = [cornerRadiusView frame];
			frame.origin.y = topY;
			topY += frame.size.height;
			frame.size.width = [self.contentView frame].size.width;
			[cornerRadiusView setFrame:frame];
		}
	}
	else
	{
		[cornerRadiusView removeFromSuperview];
	}
	if ([positionView superview] == nil)
		[self.contentView addSubview:positionView];
	if (NSMinY([positionView frame]) != topY)
	{
		frame = [positionView frame];
		frame.origin.y = topY;
		frame.size.width = [self.contentView frame].size.width;
		[positionView setFrame:frame];
	}
	topY = NSMaxY([positionView frame]);
	frame = [self.contentView frame];
	frame.size.height = topY;
	[self.contentView setFrame:frame];
	if ([self.contentView superview])
	{
		NSRect wf = [[self.contentView window]frame];
		NSRect ccvf = [[self.contentView superview] frame];
		NSRect vf = [self.contentView frame];
		float hDiff = ccvf.size.height - vf.size.height;
		if (hDiff != 0)
		{
			wf.size.height -= hDiff;
			wf.origin.y += hDiff;
			ccvf.size.height -= hDiff;
			[[self.contentView window]setFrame:wf display:NO];
			[[self.contentView window]invalidateShadow];
			[[self.contentView window]update];
		}
	}
    [self adjustKeyLoop];
}

-(bool)rebuildRequiredSelectedGraphics:(NSArray*)graphics
{
	if ([coordinateView superview] == nil)
		return YES;
	id graphic = nil;
	if ([graphics count] == 1)
		graphic = [graphics objectAtIndex:0];
	if (graphic)
	{
		if ([graphic respondsToSelector:@selector(cornerRadius)] == ([cornerRadiusView superview] == nil))
			return YES;
		if ([graphic respondsToSelector:@selector(cellHeight)] == ([gridView superview] == nil))
			return YES;
	}
	else if ([cornerRadiusView superview] != nil || [gridView superview] != nil)
		return YES;
	return NO;
}

-(void)ableFields:(BOOL)able
{
	[positionX setEnabled:able];
	[positionY setEnabled:able];
	[sizeHeight setEnabled:able];
	[sizeWidth setEnabled:able];
	[scaleX setEnabled:able];
	[scaleY setEnabled:able];
	[graphicOpacitySlider setEnabled:able];
}

-(void)setPlaceHolders:(NSString*)s
{
	[[positionX cell]setPlaceholderString:s];
	[[positionY cell]setPlaceholderString:s];
	[[sizeHeight cell]setPlaceholderString:s];
	[[sizeWidth cell]setPlaceholderString:s];
	[[scaleX cell]setPlaceholderString:s];
    [[scaleY cell]setPlaceholderString:s];
    [[rotationText cell]setPlaceholderString:s];
	[[graphicOpacityText cell]setPlaceholderString:s];
}

-(void)setGridControlsForGraphic:(ACSDGrid*)g
{
	[gridCellHeight setFloatValue:[g cellHeight]];
	[gridCellWidth setFloatValue:[g cellWidth]];
	[gridCols setIntValue:[g columns]];
	[gridRows setIntValue:[g rows]];
	int gMode = [g gridMode];
	[gridMode selectItemAtIndex:gMode];
	if (gMode == GRID_MODE_FIXED_NO_CELLS)
	{
		[gridCellWidth setEnabled:NO];
		[gridCellHeight setEnabled:NO];
		[gridCols setEnabled:YES];
		[gridRows setEnabled:YES];
	}
	else
	{
		[gridCellWidth setEnabled:YES];
		[gridCellHeight setEnabled:YES];
		[gridCols setEnabled:NO];
		[gridRows setEnabled:NO];
	}
}

-(void)setDimensionControls:(NSArray*)graphics
{
	ACSDGraphic *g = nil;
	if ([graphics count] == 1)
		g = [graphics objectAtIndex:0];
	if (g)
	{
		NSRect r = [g bounds];
		if ([g moving])
			r = NSOffsetRect(r,[g moveOffset].x,[g moveOffset].y);
		//[positionX setFloatValue:r.origin.x];
		//[positionY setFloatValue:r.origin.y];
		if (showsHeight)
			[sizeHeight setFloatValue:r.size.height];
		else
			[sizeHeight setFloatValue:NSMaxY(r)];
		if (showsWidth)
			[sizeWidth setFloatValue:r.size.width];
		else
			[sizeWidth setFloatValue:NSMaxX(r)];
        if (showsLeft)
            [positionX setFloatValue:r.origin.x];
        else
            [positionX setFloatValue:NSMidX(r)];
        if (showsBottom)
            [positionY setFloatValue:r.origin.y];
        else
            [positionY setFloatValue:NSMidY(r)];

	}
}

-(void)updateControls
{
	actionsDisabled = YES;
	NSSet *selectedObjects = [[self inspectingGraphicView] selectedGraphics];
	ACSDGraphic *g;
	if ([selectedObjects count] == 1)
	{
		g = [selectedObjects anyObject];
		if (self.changed & SC_ROTATION_CHANGE)
			self.rotation = g.rotation;
		if (self.changed & SC_OPACITY_CHANGE)
			self.opacity = g.alpha;
		if (self.changed & SC_SCALEX_CHANGE)
			self.xScale = g.xScale;
		if (self.changed & SC_SCALEY_CHANGE)
			self.yScale = g.yScale;
	}
	else
	{
		g = nil;
		[rotationText setStringValue:@""];
		[graphicOpacityText setStringValue:@""];
		[scaleX setStringValue:@""];
		[scaleY setStringValue:@""];
	}
	self.fieldsEditable = ([selectedObjects count] > 0);
	actionsDisabled = NO;
}

-(void)setAlignControls
{
	self.alignMatrix.hidden = YES;
	if ([self inspectingGraphicView])
	{
		for (ACSDGraphic *g in [[[self inspectingGraphicView] selectedGraphics]allObjects])
			//if ([g link]!=nil)
			{
				self.alignButton.hidden = NO;
				int val = g.linkAlignmentFlags;
				int vert = (val >> 2) & 0x3;
				int horiz = val & 0x3;
				int row = (vert + 1) % 3;
				int col = (horiz + 1) % 3;
				[self.alignMatrix selectCellAtRow:row column:col];

				return;
			}
	}
	//self.alignButton.hidden = YES;
}

-(void)setGraphicControls
{
	NSArray *graphics = nil;
	NSUInteger ct = 0;
	ACSDGraphic *g = nil;
	if ([self inspectingGraphicView])
	{
		graphics = [[[self inspectingGraphicView] selectedGraphics]allObjects];
		ct = [graphics count];
	}
	if (ct == 1)
		g = [graphics objectAtIndex:0];
	if (ct <= 1)
		[self setPlaceHolders:@""];
	if ([self rebuildRequiredSelectedGraphics:graphics])
		[self rebuildForGraphics:graphics];
	[self setAlignControls];
	if (g)
	{
		[self setDimensionControls:graphics];
		[self ableFields:YES];
		if ([g respondsToSelector:@selector(setGraphicCornerRadius:notify:)])
		{
			[[cornerRadiusText formatter] setMaximum:[NSNumber numberWithFloat:[(id<ACSDGraphicCornerRadius>)g maxCornerRadius]]];
			[cornerRadiusText setFloatValue:[(id<ACSDGraphicCornerRadius>)g cornerRadius]];
			[cornerRadiusSlider setFloatValue:[(id<ACSDGraphicCornerRadius>)g cornerRadius]*100.0 / [(id<ACSDGraphicCornerRadius>)g maxCornerRadius]];
		}
		if ([g isKindOfClass:[ACSDGrid class]])
			[self setGridControlsForGraphic:(ACSDGrid*)g];
		/*		else if ([g isKindOfClass:[ACSDFreeHand class]])
		 [smoothnessSlider setIntValue:-[(ACSDFreeHand*)g level]];*/
	}
	else
	{
		[positionX setStringValue:@""];
		[positionY setStringValue:@""];
		[sizeHeight setStringValue:@""];
		[sizeWidth setStringValue:@""];
		//[rotationText setStringValue:@""];
		[scaleX setStringValue:@""];
		[scaleY setStringValue:@""];
		//[graphicOpacityText setStringValue:@""];
		if (ct == 0)
		{
			[self ableFields:NO];
		}
		else
		{
			[self ableFields:YES];
			[self setPlaceHolders:@"multiple"];
		}
	}
	//	[self showHideControls:g];
}

-(void)awakeFromNib
{
	[super awakeFromNib];
	rowForContextualMenu = -1;
	displayRowForContextualMenu = -1;
	[self setTransientCoordinateFieldsVisible:NO];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(coordinatesChanged:) name:ACSDMouseDidMoveNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(dimensionsChanged:) name:ACSDDimensionChangeNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(cellHeightChanged:) name:cellHeightDidChangeNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(cellWidthChanged:) name:cellWidthDidChangeNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(changeCoordinateVisibility:) name:ACSDShowCoordinatesNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(addChangeFromNotification:) name:ACSDSizePanelParamChangeNotification object:nil];
}

-(IBAction)rotationHit:(id)sender
{
    if ([[sender stringValue]isEqual:@""] || [self actionsDisabled])
        return;
	self.rotation = [sender floatValue];
}

-(IBAction)opacityHit:(id)sender
{
    if ([[sender stringValue]isEqual:@""] || [self actionsDisabled])
        return;
	self.opacity = [sender floatValue];
}

-(IBAction)xScaleHit:(id)sender
{
	if ([[sender stringValue]isEqual:@""] || [self actionsDisabled])
		return;
	self.xScale = [sender floatValue];
}

-(IBAction)yScaleHit:(id)sender
{
	if ([[sender stringValue]isEqual:@""] || [self actionsDisabled])
		return;
	self.yScale = [sender floatValue];
}

-(void)adjustKeyLoop
{
	[positionX setNextKeyView:positionY];
	[positionY setNextKeyView:sizeWidth];
	[sizeWidth setNextKeyView:sizeHeight];
    if ([cornerRadiusView superview] == nil)
    {
        [sizeHeight setNextKeyView:rotationText];
    }
    else
    {
        [sizeHeight setNextKeyView:cornerRadiusText];
        [cornerRadiusText setNextKeyView:rotationText];
    }
	[rotationText setNextKeyView:scaleX];
    [scaleX setNextKeyView:scaleY];
    [scaleY setNextKeyView:graphicOpacityText];
    [graphicOpacityText setNextKeyView:positionX];

}
- (void)coordinatesChanged:(NSNotification *)notification
{
    NSPoint pt = [[[notification userInfo]objectForKey:@"xy"]pointValue];
	GraphicView *gv = [self inspectingGraphicView];
	if (gv)
	{
		NSSize sz = [gv bounds].size;
		[xCoord setStringValue:[NSString stringWithFormat:@"%g / %g",pt.x,pt.x - sz.width]];
		[yCoord setStringValue:[NSString stringWithFormat:@"%g / %g",pt.y,pt.y - sz.height]];
	}
	else
	{
		[xCoord setFloatValue:pt.x];
		[yCoord setFloatValue:pt.y];
	}
	NSValue *val = [[notification userInfo]objectForKey:@"dxdy"];
	if (val)
	   {
		NSSize sz = [val sizeValue];
		[dX setFloatValue:sz.width];
		[dY setFloatValue:sz.height];
	   }
	NSNumber *th = [[notification userInfo]objectForKey:@"theta"];
	if (th)
	   {
		float f = [th floatValue];
		[theta setStringValue:[NSString stringWithFormat:@"%1.3f",f]];
	   }
	NSNumber *dd = [[notification userInfo]objectForKey:@"dist"];
	if (dd)
	{
		[dist setStringValue:[NSString stringWithFormat:@"%1.3f",[dd floatValue]]];
	}
}

- (void)cellHeightChanged:(NSNotification *)notification
{
    float f = [[[notification userInfo]objectForKey:@"cellheight"]floatValue];
	[gridCellHeight setFloatValue:f];
}

- (void)cellWidthChanged:(NSNotification *)notification
{
    float f = [[[notification userInfo]objectForKey:@"cellwidth"]floatValue];
	[gridCellWidth setFloatValue:f];
}

- (void)dimensionsChanged:(NSNotification *)notification
{
	BOOL oldDis = [self setActionsDisabled:YES];
	[self setDimensionControls:[[[self inspectingGraphicView] selectedGraphics]allObjects]];
	[self setActionsDisabled:oldDis];
}


- (IBAction)cornerRadiusSliderHit:(id)sender
{
    NSArray *selectedGraphics = [[[self inspectingGraphicView] selectedGraphics]allObjects];
    if ([selectedGraphics count] > 0)
	   {
        float percent = [sender floatValue];
        for (ACSDGraphic *obj in selectedGraphics)
		{
			if ([obj respondsToSelector:@selector(setGraphicCornerRadius:notify:)])
			{
				float r = [(id<ACSDGraphicCornerRadius>)obj maxCornerRadius] * percent / 100.0;
				if (r != [cornerRadiusText floatValue])
					[cornerRadiusText setFloatValue:r];
				[(id<ACSDGraphicCornerRadius>)obj setGraphicCornerRadius:r notify:NO];
			}
		}
        [[[self inspectingGraphicView] undoManager] setActionName:@"Set Corner Radius"];
       }
}

- (IBAction)cornerRadiusTextHit:(id)sender
{
    if ([[sender stringValue]isEqual:@""] || [self actionsDisabled])
		return;
    NSArray *selectedGraphics = [[[self inspectingGraphicView] selectedGraphics]allObjects];
    if ([selectedGraphics count] > 0)
	   {
        float r = [sender floatValue];
        for (id obj in selectedGraphics)
		{
			if ([obj respondsToSelector:@selector(setGraphicCornerRadius:notify:)])
			{
				[(id<ACSDGraphicCornerRadius>)obj setGraphicCornerRadius:r notify:NO];
				float percent = r / [(id<ACSDGraphicCornerRadius>)obj maxCornerRadius] * 100.0;
				if (percent != [cornerRadiusSlider floatValue])
					[cornerRadiusSlider setFloatValue:percent];
			}
		}
        [[[self inspectingGraphicView] undoManager] setActionName:@"Set Corner Radius"];
       }
}

- (IBAction)gridCellHeightHit:(id)sender
{
    if ([[sender stringValue]isEqual:@""] || [self actionsDisabled])
		return;
    NSArray *selectedGraphics = [[[self inspectingGraphicView] selectedGraphics]allObjects];
    if ([selectedGraphics count] < 1)
		return;
	float h = [sender floatValue];
	for (id g in selectedGraphics)
		[g setGraphicCellHeight:h notify:NO];
	if ([selectedGraphics count] == 1)
		[self setGridControlsForGraphic:[selectedGraphics objectAtIndex:0]];
}

- (IBAction)gridCellWidthHit:(id)sender
{
    if ([[sender stringValue]isEqual:@""] || [self actionsDisabled])
		return;
    NSArray *selectedGraphics = [[[self inspectingGraphicView] selectedGraphics]allObjects];
    if ([selectedGraphics count] < 1)
		return;
	float w = [sender floatValue];
	for (id g in selectedGraphics)
		[g setGraphicCellWidth:w notify:NO];
	if ([selectedGraphics count] == 1)
		[self setGridControlsForGraphic:[selectedGraphics objectAtIndex:0]];
}

- (IBAction)gridColsHit:(id)sender
{
    if ([[sender stringValue]isEqual:@""] || [self actionsDisabled])
		return;
    NSArray *selectedGraphics = [[[self inspectingGraphicView] selectedGraphics]allObjects];
    if ([selectedGraphics count] < 1)
		return;
	int cols = [sender intValue];
	for (id g in selectedGraphics)
		[g setGraphicColumns:cols notify:NO];
	if ([selectedGraphics count] == 1)
		[self setGridControlsForGraphic:[selectedGraphics objectAtIndex:0]];
}

- (IBAction)gridModeHit:(id)sender
{
    if ([self actionsDisabled])
		return;
    NSArray *selectedGraphics = [[[self inspectingGraphicView] selectedGraphics]allObjects];
    if ([selectedGraphics count] < 1)
		return;
	NSInteger mode = [sender indexOfSelectedItem];
	for (id g in selectedGraphics)
		[g setGraphicGridMode:(int)mode notify:NO];
	if ([selectedGraphics count] == 1)
		[self setGridControlsForGraphic:[selectedGraphics objectAtIndex:0]];
}

- (IBAction)gridRowsHit:(id)sender
{
    if ([[sender stringValue]isEqual:@""] || [self actionsDisabled])
		return;
    NSArray *selectedGraphics = [[[self inspectingGraphicView] selectedGraphics]allObjects];
    if ([selectedGraphics count] < 1)
		return;
	int rows = [sender intValue];
	for (id g in selectedGraphics)
		[g setGraphicRows:rows notify:NO];
	if ([selectedGraphics count] == 1)
		[self setGridControlsForGraphic:[selectedGraphics objectAtIndex:0]];
}

- (IBAction)pressureSliderHit:(id)sender
{
    if ([[sender stringValue]isEqual:@""] || [self actionsDisabled])
		return;
    NSArray *selectedGraphics = [[[self inspectingGraphicView] selectedGraphics]allObjects];
    if ([selectedGraphics count] > 0)
	{
        float pressure = [sender floatValue];
		for (id g in selectedGraphics)
            [g uSetPressureLevel:pressure];
        [[[self inspectingGraphicView] undoManager] setActionName:@"Set Pressure"];
	}
}

-(void)setRotation:(float)f
{
	if (f != _rotation)
	{
		_rotation = f;
		[self updateObjects:[[[self inspectingGraphicView] selectedGraphics]allObjects] withValue:[NSNumber numberWithFloat:_rotation] forKey:@"rotation" changeid:SC_ROTATION_CHANGE invalidateFlags:INVAL_FLAGS_SHAPE_CHANGE|INVAL_FLAGS_SIZE_CHANGE|INVAL_FLAGS_REDRAW actionName:@"Change Rotation"];
	}
	if ((f != [rotationText floatValue]) || [[rotationText stringValue]isEqual:@""])
		[rotationText setFloatValue:f];
}

-(void)setOpacity:(float)f
{
	if (f != _opacity)
	{
		_opacity = f;
		[self updateObjects:[[[self inspectingGraphicView] selectedGraphics]allObjects] withValue:[NSNumber numberWithFloat:_opacity] forKey:@"alpha" changeid:SC_OPACITY_CHANGE invalidateFlags:INVAL_FLAGS_REDRAW actionName:@"Change Opacity"];
	}
	if (f != [graphicOpacityText floatValue])
		[graphicOpacityText setFloatValue:f];
	if (f != [graphicOpacitySlider floatValue])
		[graphicOpacitySlider setFloatValue:f];
}

-(void)setXScale:(float)f
{
	if (f != _xScale)
	{
		_xScale = f;
		[self updateObjects:[[[self inspectingGraphicView] selectedGraphics]allObjects] withValue:[NSNumber numberWithFloat:_xScale] forKey:@"xScale" changeid:SC_SCALEX_CHANGE invalidateFlags:INVAL_FLAGS_REDRAW|INVAL_FLAGS_SIZE_CHANGE|INVAL_FLAGS_SHAPE_CHANGE actionName:@"Change X Scale"];
	}
	if (f != [scaleX floatValue])
		[scaleX setFloatValue:f];
}

-(void)setYScale:(float)f
{
	if (f != _yScale)
	{
		_yScale = f;
		[self updateObjects:[[[self inspectingGraphicView] selectedGraphics]allObjects] withValue:[NSNumber numberWithFloat:_yScale] forKey:@"yScale" changeid:SC_SCALEY_CHANGE invalidateFlags:INVAL_FLAGS_REDRAW|INVAL_FLAGS_SIZE_CHANGE actionName:@"Change Y Scale"];
	}
	if (f != [scaleY floatValue])
		[scaleY setFloatValue:f];
}

- (IBAction)smoothnessSliderHit:(id)sender
{
    NSArray *selectedGraphics = [[[self inspectingGraphicView] selectedGraphics]allObjects];
    if ([selectedGraphics count] > 0)
	{
        int level = -[sender intValue];
		for (id g in selectedGraphics)
            [g uSetLevel:level];
        [[[self inspectingGraphicView] undoManager] setActionName:@"Set Smoothness"];
	}
}

- (IBAction)heightHit:(id)sender
{
    if ([[sender stringValue]isEqual:@""] || [self actionsDisabled])
		return;
    NSArray *selectedGraphics = [[[self inspectingGraphicView] selectedGraphics]allObjects];
    if ([selectedGraphics count] > 0)
	{
        float height = [sender floatValue];
		BOOL changed = NO;
		for (ACSDGraphic *g in selectedGraphics)
			if (showsHeight)
				changed = [g setHeight:height] || changed;
			else
				changed = [g setTop:height] || changed;
		if (changed)
			[[[self inspectingGraphicView] undoManager] setActionName:(showsHeight)?@"Set Height":@"Set Top"];
	}
}

- (IBAction)widthHit:(id)sender
{
    if ([[sender stringValue]isEqual:@""] || [self actionsDisabled])
		return;
    NSArray *selectedGraphics = [[[self inspectingGraphicView] selectedGraphics]allObjects];
    if ([selectedGraphics count] > 0)
	{
        float width = [sender floatValue];
		BOOL changed = NO;
		for (ACSDGraphic *g in selectedGraphics)
			if (showsWidth)
				changed = [g setWidth:width] || changed;
			else
				changed = [g setRight:width] || changed;
		if (changed)
			[[[self inspectingGraphicView] undoManager] setActionName:(showsWidth)?@"Set Width":@"Set Right"];
	}
}

- (IBAction)xHit:(id)sender
{
    if ([[sender stringValue]isEqual:@""] || [self actionsDisabled])
		return;
    NSArray *selectedGraphics = [[[self inspectingGraphicView] selectedGraphics]allObjects];
    if ([selectedGraphics count] > 0)
	{
        float f = [sender floatValue];
		BOOL changed = NO;
		for (ACSDGraphic *g in selectedGraphics)
            if (showsLeft)
                changed = [g setX:f] || changed;
            else
                changed = [g setCentreX:f] || changed;
		if (changed)
			[[[self inspectingGraphicView] undoManager] setActionName:@"Set X"];
	}
}

- (IBAction)yHit:(id)sender
{
    if ([[sender stringValue]isEqual:@""] || [self actionsDisabled])
		return;
    NSArray *selectedGraphics = [[[self inspectingGraphicView] selectedGraphics]allObjects];
    if ([selectedGraphics count] > 0)
	   {
        float f = [sender floatValue];
		BOOL changed = NO;
		   for (ACSDGraphic *g in selectedGraphics)
               if (showsBottom)
                   changed = [g setY:f] || changed;
               else
                   changed = [g setCentreY:f] || changed;
		if (changed)
			[[[self inspectingGraphicView] undoManager] setActionName:@"Set Y"];
       }
}

- (IBAction)widthRightHit:(id)sender
{
	showsWidth = !showsWidth;
	if (showsWidth)
		[widthRight setTitle:@"Width"];
	else
		[widthRight setTitle:@"Right"];
	[self setGraphicControls];
}

- (IBAction)heightTopHit:(id)sender
{
	showsHeight = !showsHeight;
	if (showsHeight)
		[heightTop setTitle:@"Height"];
	else
		[heightTop setTitle:@"Top"];
	[self setGraphicControls];
}
- (IBAction)leftXHit:(id)sender
{
    showsLeft = !showsLeft;
    if (showsLeft)
        [leftX setTitle:@"Left"];
    else
        [leftX setTitle:@"X"];
    [self setGraphicControls];
}

- (IBAction)bottomYHit:(id)sender
{
    showsBottom = !showsBottom;
    if (showsBottom)
        [bottomY setTitle:@"Bottom"];
    else
        [bottomY setTitle:@"Y"];
    [self setGraphicControls];
}


-(IBAction)showHideAlignMatrix:(id)sender
{
	self.alignMatrix.hidden = ! self.alignMatrix.hidden;
}

-(IBAction)alignMatrixHit:(id)sender
{
	NSInteger row = self.alignMatrix.selectedRow;
	NSInteger col = self.alignMatrix.selectedColumn;
	int vert = (row + 2) % 3;
	int horiz = (col + 2) % 3;
	int val = (vert << 2) | horiz;
	
	[self updateObjects:[[[self inspectingGraphicView] selectedGraphics]allObjects] withValue:@(val) forKey:@"linkAlignmentFlags" changeid:SC_ALIGN_CHANGE invalidateFlags:0 actionName:@"Change Link Alignment"];
	//self.alignMatrix.hidden = YES;
}
@end
