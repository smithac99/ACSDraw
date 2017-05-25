#import "SizePanelController.h"
#import "GraphicView.h"
#import "ACSDGraphic.h"
#import "ACSDRect.h"
#import "DragView.h"
#import "ACSDMatrix.h"
#import "ACSDFreeHand.h"
#import "PanelCoordinator.h"

SizePanelController *_sharedSizePanelController = nil;

@implementation SizePanelController

+ (id)sharedSizePanelController
{
	if (!_sharedSizePanelController)
		[PanelCoordinator sharedPanelCoordinator];
    return _sharedSizePanelController;
}


- (void)setTransientCoordinateFieldsVisible:(BOOL)visible
{
	[dX setHidden:!visible];
	[dXLabel setHidden:!visible];
	[dY setHidden:!visible];
	[dYLabel setHidden:!visible];
	[theta setHidden:!visible];
	[thetaLabel setHidden:!visible];	
}

- (void)changeCoordinateVisibility:(NSNotification *)notification
{
    [self setTransientCoordinateFieldsVisible:[[[notification userInfo]objectForKey:@"vis"]boolValue]];
}

-(void)rebuildForGraphics:(NSArray*)graphics
{
	float topY = 0.0;
	NSRect frame;
	NSView *contentView = [window contentView];
	if ([coordinateView superview] == nil)
	{
		[contentView addSubview:coordinateView];
		frame = [coordinateView frame];
		frame.origin.y = topY;
		frame.size.width = [contentView frame].size.width;
		[coordinateView setFrame:frame];
	}
	topY = NSMaxY([coordinateView frame]);
	id graphic = nil;
	if ([graphics count] == 1)
		graphic = [graphics objectAtIndex:0];
	if (graphic && [graphic respondsToSelector:@selector(cornerRadius)])
	{
		if ([cornerRadiusView superview] == nil)
		{
			[contentView addSubview:cornerRadiusView];
			frame = [cornerRadiusView frame];
			frame.origin.y = topY;
			topY += frame.size.height;
			frame.size.width = [contentView frame].size.width;
			[cornerRadiusView setFrame:frame];
		}
	}
	else
	{
		[cornerRadiusView removeFromSuperview];
	}
//	[positionView removeFromSuperview];
	if ([positionView superview] == nil)
		[contentView addSubview:positionView];
	if (NSMinY([positionView frame]) != topY)
	{
		frame = [positionView frame];
		frame.origin.y = topY;
		frame.size.width = [contentView frame].size.width;
		[positionView setFrame:frame];
	}
	topY = NSMaxY([positionView frame]);
	float diff = [contentView bounds].size.height - [dragView frame].size.height - topY;
	NSRect wFrame = [window frame];
	wFrame.origin.y += diff;
	wFrame.size.height -= diff;
	[window setFrame:wFrame display:YES animate:NO];
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
	}
	else if ([cornerRadiusView superview] != nil)
		return YES;
	return NO;
}

-(void)ableFields:(BOOL)able
{
	[positionX setEnabled:able];
	[positionY setEnabled:able];
	[sizeHeight setEnabled:able];
	[sizeWidth setEnabled:able];
	[rotationText setEnabled:able];
	[scaleX setEnabled:able];
	[scaleY setEnabled:able];
	[graphicOpacitySlider setEnabled:able];
	[graphicOpacityText setEnabled:able];
}

-(void)setPlaceHolders:(NSString*)s
{
	[[positionX cell]setPlaceholderString:s];
	[[positionY cell]setPlaceholderString:s];
	[[sizeHeight cell]setPlaceholderString:s];
	[[sizeWidth cell]setPlaceholderString:s];
	[[rotationText cell]setPlaceholderString:s];
	[[scaleX cell]setPlaceholderString:s];
	[[scaleY cell]setPlaceholderString:s];
	[[graphicOpacityText cell]setPlaceholderString:s];
}

-(void)setGraphicControls
{
	NSArray *graphics = nil;
	NSInteger ct = 0;
	id g = nil;
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
	if (g)
	   {
		NSRect r = [g bounds];
		if ([g moving])
			r = NSOffsetRect(r,[g moveOffset].x,[g moveOffset].y);
		[positionX setFloatValue:r.origin.x];
		[positionY setFloatValue:r.origin.y];
		[sizeHeight setFloatValue:r.size.height];
		[sizeWidth setFloatValue:r.size.width];
		[rotationText setFloatValue:[g rotation]];
		[scaleX setFloatValue:[g xScale]];
		[scaleY setFloatValue:[g yScale]];
		[graphicOpacitySlider setFloatValue:[g alpha]];
		[graphicOpacityText setFloatValue:[g alpha]];
		[self ableFields:YES];
		if ([g respondsToSelector:@selector(setGraphicCornerRadius:notify:)])
		{
			[[cornerRadiusText formatter] setMaximum:[NSNumber numberWithFloat:[g maxCornerRadius]]];
			[cornerRadiusText setFloatValue:[g cornerRadius]];
			[cornerRadiusSlider setFloatValue:[g cornerRadius]*100.0 / [g maxCornerRadius]];
		}
/*		if ([g isKindOfClass:[ACSDMatrix class]])
			[self setMatrixControlsForGraphic:g];
		else if ([g isKindOfClass:[ACSDFreeHand class]])
			[smoothnessSlider setIntValue:-[(ACSDFreeHand*)g level]];*/
	   }
	else
	{
		[positionX setStringValue:@""];
		[positionY setStringValue:@""];
		[sizeHeight setStringValue:@""];
		[sizeWidth setStringValue:@""];
		[rotationText setStringValue:@""];
		[scaleX setStringValue:@""];
		[scaleY setStringValue:@""];
		[graphicOpacityText setStringValue:@""];
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
	_sharedSizePanelController = self;
	[super awakeFromNib];
	rowForContextualMenu = -1;
	displayRowForContextualMenu = -1;
	[self setTransientCoordinateFieldsVisible:NO];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(coordinatesChanged:) name:ACSDMouseDidMoveNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(dimensionsChanged:) name:ACSDDimensionChangeNotification object:nil];
//    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(cellHeightChanged:) name:cellHeightDidChangeNotification object:nil];
//	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(cellWidthChanged:) name:cellWidthDidChangeNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(changeCoordinateVisibility:) name:ACSDShowCoordinatesNotification object:nil];
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
		while (f > 180.0)
			f -= 360.0;
		[theta setFloatValue:f];
	   }
}

- (void)cellHeightChanged:(NSNotification *)notification
{
    float f = [[[notification userInfo]objectForKey:@"cellheight"]floatValue];
	[matrixCellHeight setFloatValue:f];
}

- (void)cellWidthChanged:(NSNotification *)notification
{
    float f = [[[notification userInfo]objectForKey:@"cellwidth"]floatValue];
	[matrixCellWidth setFloatValue:f];
}

- (void)dimensionsChanged:(NSNotification *)notification
{
    NSRect r = [[[notification userInfo]objectForKey:@"bounds"]rectValue];
	BOOL oldDis = [self setActionsDisabled:YES];
	if (r.origin.x != [positionX floatValue])
		[positionX setFloatValue:r.origin.x];
	if (r.origin.y != [positionY floatValue])
		[positionY setFloatValue:r.origin.y];
	if (r.size.height != [sizeHeight floatValue])
		[sizeHeight setFloatValue:r.size.height];
	if (r.size.width != [sizeWidth floatValue])
		[sizeWidth setFloatValue:r.size.width];
	id o = [[notification userInfo]objectForKey:@"cornerRadius"];
	if (o)
	{
		float f = [o floatValue];
		if (f != [cornerRadiusText floatValue])
			[cornerRadiusText setFloatValue:f];
		float percent = f / [[[notification userInfo]objectForKey:@"maxCornerRadius"]floatValue] * 100.0;
		if (percent != [cornerRadiusSlider floatValue])
			[cornerRadiusSlider setFloatValue:percent];
	}
	[self setActionsDisabled:oldDis];
}

- (IBAction)cornerRadiusSliderHit:(id)sender
{
    NSArray *selectedGraphics = [[[self inspectingGraphicView] selectedGraphics]allObjects];
    NSInteger ct = [selectedGraphics count];
    if (ct > 0)
	   {
        float percent = [sender floatValue];
        for (NSInteger i = 0;i < ct;i++)
		{
            id obj = [selectedGraphics objectAtIndex:i];
			if ([obj respondsToSelector:@selector(setGraphicCornerRadius:notify:)])
			{
				float r = [obj maxCornerRadius] * percent / 100.0;
				if (r != [cornerRadiusText floatValue])
					[cornerRadiusText setFloatValue:r];
				[obj setGraphicCornerRadius:r notify:NO];
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
    NSInteger ct = [selectedGraphics count];
    if (ct > 0)
	   {
        float r = [sender floatValue];
        for (int i = 0;i < ct;i++)
		{
            id obj = [selectedGraphics objectAtIndex:i];
			if ([obj respondsToSelector:@selector(setGraphicCornerRadius:notify:)])
			{
				[obj setGraphicCornerRadius:r notify:NO];
				float percent = r / [obj maxCornerRadius] * 100.0;
				if (percent != [cornerRadiusSlider floatValue])
					[cornerRadiusSlider setFloatValue:percent];
			}
		}
        [[[self inspectingGraphicView] undoManager] setActionName:@"Set Corner Radius"];
       }
}

- (IBAction)graphicOpacitySliderHit:(id)sender
{
    NSArray *selectedGraphics = [[[self inspectingGraphicView] selectedGraphics]allObjects];
    NSInteger ct = [selectedGraphics count];
    if (ct < 1)
		return;
	float opacity = [sender floatValue];
	for (NSInteger i = 0;i < ct;i++)
	   {
		[[selectedGraphics objectAtIndex:i] setGraphicAlpha:opacity notify:NO];
	   }
	[graphicOpacityText setFloatValue:opacity];
}

- (IBAction)graphicOpacityTextHit:(id)sender
{
    if ([[sender stringValue]isEqual:@""] || [self actionsDisabled])
		return;
    NSArray *selectedGraphics = [[[self inspectingGraphicView] selectedGraphics]allObjects];
    NSInteger ct = [selectedGraphics count];
    if (ct < 1)
		return;
	float opacity = [sender floatValue];
	for (NSInteger i = 0;i < ct;i++)
	   {
		[[selectedGraphics objectAtIndex:i] setGraphicAlpha:opacity notify:NO];
	   }
	[graphicOpacitySlider setFloatValue:opacity];
}

- (IBAction)matrixCellHeightHit:(id)sender
{
}

- (IBAction)matrixCellWidthHit:(id)sender
{
}

- (IBAction)matrixColsHit:(id)sender
{
}

- (IBAction)matrixFixedCellSizeHit:(id)sender
{
}

- (IBAction)matrixFixedNoCellsHit:(id)sender
{
}

- (IBAction)matrixRowsHit:(id)sender
{
}

- (IBAction)pressureSliderHit:(id)sender
{
    if ([[sender stringValue]isEqual:@""] || [self actionsDisabled])
		return;
    NSArray *selectedGraphics = [[[self inspectingGraphicView] selectedGraphics]allObjects];
    NSInteger ct = [selectedGraphics count];
    if (ct > 0)
	   {
        float pressure = [sender floatValue];
        for (NSInteger i = 0;i < ct;i++)
            [[selectedGraphics objectAtIndex:i] uSetPressureLevel:pressure];
        [[[self inspectingGraphicView] undoManager] setActionName:@"Set Pressure"];
       }
}

- (IBAction)rotationTextHit:(id)sender
{
    if ([[sender stringValue]isEqual:@""] || [self actionsDisabled])
		return;
    NSArray *selectedGraphics = [[[self inspectingGraphicView] selectedGraphics]allObjects];
    NSInteger ct = [selectedGraphics count];
    if (ct > 0)
	   {
        float rotation = [sender floatValue];
		BOOL changed = NO;
        for (NSInteger i = 0;i < ct;i++)
            changed = changed || [[selectedGraphics objectAtIndex:i] setGraphicRotation:rotation notify:NO];
		if (changed)
			[[[self inspectingGraphicView] undoManager] setActionName:@"Set Rotation"];
       }
}

- (IBAction)scaleXHit:(id)sender
{
    if ([[sender stringValue]isEqual:@""] || [self actionsDisabled])
		return;
	NSArray *selectedGraphics = [[[self inspectingGraphicView] selectedGraphics]allObjects];
    NSInteger ct = [selectedGraphics count];
    if (ct > 0)
	   {
        float f = [sender floatValue];
		BOOL changed = NO;
        for (NSInteger i = 0;i < ct;i++)
            changed = changed || [[selectedGraphics objectAtIndex:i] setGraphicXScale:f notify:NO];
		if (changed)
			[[[self inspectingGraphicView] undoManager] setActionName:@"Change X Scale"];
       }
}

- (IBAction)scaleYHit:(id)sender
{
    if ([[sender stringValue]isEqual:@""] || [self actionsDisabled])
		return;
    NSArray *selectedGraphics = [[[self inspectingGraphicView] selectedGraphics]allObjects];
    NSInteger ct = [selectedGraphics count];
    if (ct > 0)
	   {
        float f = [sender floatValue];
		BOOL changed = NO;
        for (NSInteger i = 0;i < ct;i++)
            changed = changed || [[selectedGraphics objectAtIndex:i] setGraphicYScale:f notify:NO];
		if (changed)
			[[[self inspectingGraphicView] undoManager] setActionName:@"Change Y Scale"];
       }
}

- (IBAction)smoothnessSliderHit:(id)sender
{
    NSArray *selectedGraphics = [[[self inspectingGraphicView] selectedGraphics]allObjects];
    NSInteger ct = [selectedGraphics count];
    if (ct > 0)
	   {
        int level = -[sender intValue];
        for (NSInteger i = 0;i < ct;i++)
            [[selectedGraphics objectAtIndex:i] uSetLevel:level];
        [[[self inspectingGraphicView] undoManager] setActionName:@"Set Smoothness"];
       }
}

- (IBAction)heightHit:(id)sender
{
    if ([[sender stringValue]isEqual:@""] || [self actionsDisabled])
		return;
    NSArray *selectedGraphics = [[[self inspectingGraphicView] selectedGraphics]allObjects];
    NSInteger ct = [selectedGraphics count];
    if (ct > 0)
	   {
        float height = [sender floatValue];
		BOOL changed = NO;
        for (NSInteger i = 0;i < ct;i++)
            changed = changed || [(ACSDGraphic*)[selectedGraphics objectAtIndex:i] setHeight:height];
		if (changed)
			[[[self inspectingGraphicView] undoManager] setActionName:@"Set Height"];
       }
}

- (IBAction)widthHit:(id)sender
{
    if ([[sender stringValue]isEqual:@""] || [self actionsDisabled])
		return;
    NSArray *selectedGraphics = [[[self inspectingGraphicView] selectedGraphics]allObjects];
    NSInteger ct = [selectedGraphics count];
    if (ct > 0)
	   {
        float width = [sender floatValue];
		BOOL changed = NO;
        for (NSInteger i = 0;i < ct;i++)
            changed = changed || [(ACSDGraphic*)[selectedGraphics objectAtIndex:i] setWidth:width];
		if (changed)
			[[[self inspectingGraphicView] undoManager] setActionName:@"Set Width"];
       }
}

- (IBAction)xHit:(id)sender
{
    if ([[sender stringValue]isEqual:@""] || [self actionsDisabled])
		return;
    NSArray *selectedGraphics = [[[self inspectingGraphicView] selectedGraphics]allObjects];
    NSInteger ct = [selectedGraphics count];
    if (ct > 0)
	   {
        float f = [sender floatValue];
		BOOL changed = NO;
        for (NSInteger i = 0;i < ct;i++)
            changed = changed || [(ACSDGraphic*)[selectedGraphics objectAtIndex:i] setX:f];
		if (changed)
			[[[self inspectingGraphicView] undoManager] setActionName:@"Set X"];
       }
}

- (IBAction)yHit:(id)sender
{
    if ([[sender stringValue]isEqual:@""] || [self actionsDisabled])
		return;
    NSArray *selectedGraphics = [[[self inspectingGraphicView] selectedGraphics]allObjects];
    NSInteger ct = [selectedGraphics count];
    if (ct > 0)
	   {
        float f = [sender floatValue];
		BOOL changed = NO;
        for (NSInteger i = 0;i < ct;i++)
            changed = changed || [(ACSDGraphic*)[selectedGraphics objectAtIndex:i] setY:f];
		if (changed)
			[[[self inspectingGraphicView] undoManager] setActionName:@"Set Y"];
       }
}


@end
