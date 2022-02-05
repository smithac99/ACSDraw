//
//  FillsController.mm
//  ACSDraw
//
//  Created by alan on 08/02/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "FillsController.h"
#import "ColourCell.h"
#import "SelCell.h"
#import "ACSDGraphic.h"
#import "GradientDisplay.h"
#import "GradientControl.h"
#import "ColourCell.h"
#import "PatternDisplay.h"
#import "ACSDPattern.h"
#import "ArrayAdditions.h"
#import "ACSDTableView.h"
#import "ACSDImage.h"
#import "GraphicView.h"
#import "FillListTableSource.h"
#import "FillView.h"
#import "SelView.h"

enum
{
	FILL_RADIO_NO_FILL,
	FILL_RADIO_FILL,
	FILL_RADIO_GRADIENT,
	FILL_RADIO_PATTERN
};

@implementation FillsController


-(id)init
{
	if (self = [super initWithTitle:@"Fills"])
	{
	}
	return self;
}

- (void)dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (NSMutableArray*)fillList
{
	return [[[self inspectingGraphicView]document]fills];
}

- (void)zeroControls
{
	[fillTableView setAllowsEmptySelection:YES];
	[fillTableView selectRowIndexes:[NSIndexSet indexSet] byExtendingSelection:NO];
	[fillTableView reloadData];
}

- (void)reloadSels:(NSNotification *)notification
{
    [fillTableView reloadDataForRowIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, [[self fillList]count])] columnIndexes:[NSIndexSet indexSetWithIndex:1]];
}

- (void)reloadAll:(NSNotification *)notification
{
    [self addChange:FC_FILL_LIST_CHANGE];
}

-(void)graphicChanged:(NSNotification *)notification
{
    [self addChange:FC_GRAPHIC_SELECTION_CHANGE];
}

-(void)inactivateColourWells:(NSNotification *)notification
{
    [fillDisplay deactivate];
    [gradientWell1 deactivate];
}

-(void)awakeFromNib
{
	rowForContextualMenu = -1;
	displayRowForContextualMenu = -1;
	[gradientControl setup];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reloadAll:) name:ACSDFillAdded object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(unsetRowForContextualMenu:) name:NSMenuDidEndTrackingNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(mainWindowChanged:) name:NSWindowDidBecomeMainNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(mainWindowResigned:) name:NSWindowDidResignMainNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(graphicChanged:) name:ACSDGraphicDidChangeNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(graphicChanged:) name:ACSDGraphicViewSelectionDidChangeNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(graphicChanged:) name:ACSDPageChanged object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(inactivateColourWells:) name:ACSDInactivateFillWells object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(update:) name:NSWindowDidUpdateNotification object:[self.contentView window]];
}

#pragma mark -
#pragma mark rebuild

-(bool)rebuildRequiredForFill:(ACSDFill*)fill
{
	if (rebuildPending)
		return YES;
	if (fill == nil && ([[[staticView superview]subviews]count] > 1))
		return YES;
	if (![fill canFill])
		return YES;
	return (([fill isMemberOfClass:[ACSDFill class]] && [fillView superview] == nil)
			||([fill isMemberOfClass:[ACSDGradient class]] && [gradientView superview] == nil)
			||([fill isMemberOfClass:[ACSDPattern class]] && [patternView superview] == nil));
}

-(void)addViewToFillPanel:(NSView*)view
{
	if (view && [view superview])
		return;
	NSWindow *w = [self.contentView window];
	NSRect staticR = [staticView frame];
	NSRect viewR;
	if (view)
		viewR = [view frame];
	else
		viewR = NSZeroRect;
	NSRect wFrame = [w frame];
	float diff = staticR.origin.y - viewR.size.height;
	if (diff != 0.0)
	{
		wFrame.origin.y += diff;
		wFrame.size.height -= diff;
		[w setFrame:wFrame display:NO animate:NO];
	}
	if (view)
	{
		viewR.origin.y = 0.0;
		[view setFrame:viewR];
		[self.contentView addSubview:view];
	}
	[w invalidateShadow];
}

-(void)rebuildForFill:(ACSDFill*)fill
{
	rebuildPending = NO;
	if ([fillView superview])
		[fillView removeFromSuperview];
	if ([patternView superview])
		[patternView removeFromSuperview];
	if ([gradientView superview])
		[gradientView removeFromSuperview];
	if ([fill isMemberOfClass:[ACSDFill class]])
	{
		if ([fill canFill])
			[self addViewToFillPanel:fillView];
		else
			[self addViewToFillPanel:nil];
	}
	else if ([fill isMemberOfClass:[ACSDGradient class]])
		[self addViewToFillPanel:gradientView];
	else if ([fill isMemberOfClass:[ACSDPattern class]])
		[self addViewToFillPanel:patternView];
}

#pragma mark -

- (void)setControlsForFill:(ACSDFill*)fill
{
	if ([self rebuildRequiredForFill:fill])
		if ([self.contentView window] == nil)
			rebuildPending = YES;
		else
			[self rebuildForFill:fill];
	if (fill == nil)
	   {
		BOOL temp = [self actionsDisabled];
		[self setActionsDisabled:YES];
		[fillTableView setAllowsEmptySelection:YES];
		[fillTableView selectRowIndexes:[NSIndexSet indexSet] byExtendingSelection:NO];
		[self setActionsDisabled:temp];
	   }
	else
	   {
		int mode = FILL_RADIO_NO_FILL;
		if ([fill isMemberOfClass:[ACSDFill class]])
		{
			if ([fill canFill])
				mode = FILL_RADIO_FILL;
		}
		else if ([fill isMemberOfClass:[ACSDGradient class]])
			mode = FILL_RADIO_GRADIENT;
		else if ([fill isMemberOfClass:[ACSDPattern class]])
			mode = FILL_RADIO_PATTERN;
		NSInteger sel = [fillRBMatrix selectedColumn];
		if (sel != mode)
			[fillRBMatrix selectCellAtRow:0 column:mode];
		if (mode == FILL_RADIO_FILL)
		{
			[fillDisplay setColor:[fill colour]];
		}
		else if (mode == FILL_RADIO_GRADIENT)
		{
			[gradientWell1 setEnabled:YES];
			[gradientDisplay setGradient:(ACSDGradient*)fill];
			[gradientControl setGradient:(ACSDGradient*)fill];
			[gradientDisplay setNeedsDisplay:YES];
			[gradientControl setNeedsDisplay:YES];
			self.gradientType = ((ACSDGradient*)fill).gradientType;
			NSPoint pt = ((ACSDGradient*)fill).radialCentre;
			self.gradientX = pt.x;
			self.gradientY = pt.y;
		}
		else if (mode == FILL_RADIO_PATTERN)
		{
			[patternDisplay setPattern:(ACSDPattern*)fill];
			[scaleTextField setFloatValue:[(ACSDPattern*)fill scale]];
			[scaleSlider setFloatValue:log10([(ACSDPattern*)fill scale])];
			[spacingTextField setFloatValue:[(ACSDPattern*)fill spacing]];
			[spacingSlider setFloatValue:log10([(ACSDPattern*)fill spacing])];
			[offsetTextField setFloatValue:[(ACSDPattern*)fill offset]];
			[offsetSlider setFloatValue:[(ACSDPattern*)fill offset]];
			[offsetTypeRBMatrix selectCellAtRow:0 column:[(ACSDPattern*)fill offsetMode]];
			[patternModeRBMatrix selectCellAtRow:0 column:[(ACSDPattern*)fill mode]];
			
			[opacityTextField setFloatValue:[(ACSDPattern*)fill alpha]];
			[opacitySlider setFloatValue:[(ACSDPattern*)fill alpha]];
		}
	}
}

-(void)becomeActive
{
	if (rebuildPending)
		[self changeAll];
}

- (void)fillTableSelectionChange:(NSInteger)row
{
	NSArray *fillList = [self fillList];
	if (row < 0 || row > [fillList count])
		return;
	ACSDFill *fill = [fillList objectAtIndex:row]; 
	[self addChange:FC_FILL_SELECTION_CHANGE];
	if (![self inspectingGraphicView])
		return;
	NSInteger count;
	BOOL changed = NO;
	if ((count = [[[self inspectingGraphicView] selectedGraphics] count]) > 0)
	   {
		for (ACSDGraphic *graphic in [[[self inspectingGraphicView] selectedGraphics] allObjects])
			changed = [graphic setGraphicFill:fill notify:NO] || changed;
		if (changed)
			[[[self inspectingGraphicView] undoManager] setActionName:@"Change Fill"];
	   }
	[[self inspectingGraphicView] setDefaultFill:fill];
/*	if (row == -1 || [fillTableView oldSelectedRow] == -1)
		[self reloadFills:nil];
	else
	   {
		[fillTableView refreshSelectionIndicatorForRow:row];
		[fillTableView refreshSelectionIndicatorForRow:[fillTableView oldSelectedRow]];
	   }*/
}

- (ACSDFill*)currentFill
{
	NSArray *fillList = [self fillList];
	NSInteger idx = [fillTableView selectedRow];
	if (idx >= 0 && idx < [fillList count])
		return [fillList objectAtIndex:idx];
	return nil;
}

#pragma mark -
#pragma mark actions

- (IBAction)fillWellHit:(id)sender
{
	NSArray *fillList = [self fillList];
	NSInteger rowIndex = [fillTableView selectedRow];
	if (rowIndex < 0 || rowIndex >= [fillList count])
		return;
    NSColor *color = [sender color];
	ACSDFill *fill = [fillList objectAtIndex:rowIndex];
	if (![color isEqual:[fill colour]])
	   {
        [fill changeColour:color view:[self inspectingGraphicView]];
		[fillTableView reloadRowAtIndex:rowIndex];
       }
}

- (IBAction)fillSwitchHit:(id)sender
{
}

- (IBAction)gradientSwitchHit:(id)sender
{
}

- (void)duplicateFillAtIndex:(NSInteger)row select:(BOOL)sel
{
	NSArray *fillList = [self fillList];
	NSInteger rowIndex = [fillTableView selectedRow];
	if (rowIndex < 0 || rowIndex >= [fillList count])
		return;
	[[[self inspectingGraphicView] document]insertFill:[[fillList objectAtIndex:row]copy] atIndex:row+1];
	if (sel)
		[fillTableView selectRowIndexes:[NSIndexSet indexSetWithIndex:row + 1] byExtendingSelection:NO];
	[[[self inspectingGraphicView] undoManager] setActionName:@"Duplicate Fill"];
}

- (IBAction)duplicateFill:(id)sender
{
	NSArray *fillList = [self fillList];
	if (!fillList || ![self inspectingGraphicView])
		return;
	int i = rowForContextualMenu;
	if (i < 0)
		return;
	[self duplicateFillAtIndex:i select:NO];
}

- (IBAction)fillPlusHit:(id)sender
{
	NSArray *fillList = [self fillList];
	if (fillList)
	{
		NSInteger row = [fillTableView selectedRow];
		if (row >= 0)
			[self duplicateFillAtIndex:row select:YES];
	}
}

- (void)deleteFillAtIndex:(NSInteger)row
{
	NSArray *fillList = [self fillList];
	if (!fillList || ![self inspectingGraphicView])
		return;
	if (row < 0)
		return;
	if ([[fillList objectAtIndex:row]nonDeletedCount] == 0)
	{
		[[[self inspectingGraphicView] document]deleteFillAtIndex:row];
		[[[self inspectingGraphicView] undoManager] setActionName:@"Delete Fill"];
	}
}

- (IBAction)deleteFill:(id)sender
{
	[self deleteFillAtIndex:rowForContextualMenu];
}

- (IBAction)fillMinusHit:(id)sender
{
	[self deleteFillAtIndex:[fillTableView selectedRow]];
}

- (IBAction)fillRBHit:(id)sender
{
	//	ACSDFill *fill = [fillList objectAtIndex:[fillTableView selectedRow]];
}


#pragma mark -
#pragma mark gradients

- (void)setGradientType:(int)gt
{
	NSArray *fillList = [self fillList];
	NSInteger idx = [fillTableView selectedRow];
	if (idx < 0)
		return;
	ACSDGradient *fill = [fillList objectAtIndex:idx];
	_gradientType = gt;
	if (fill.gradientType != gt)
	{
		[fill changeGradientType:gt];
		[fillTableView reloadRowAtIndex:idx];
		[gradientDisplay setNeedsDisplay:YES];
	}
	_gradientType = gt;
	self.linearMode = (gt == GRADIENT_LINEAR);
}

- (void)setGradientX:(float)f
{
	NSArray *fillList = [self fillList];
	NSInteger idx = [fillTableView selectedRow];
	if (idx < 0)
		return;
	_gradientX = f;
	ACSDGradient *fill = [fillList objectAtIndex:idx];
	NSPoint pt = fill.radialCentre;
	if (pt.x != f)
	{
		pt.x = f;
		[fill changeRadialCentre:pt];
		[fillTableView reloadRowAtIndex:idx];
		[gradientDisplay setNeedsDisplay:YES];
	}
}

- (void)setGradientY:(float)f
{
	NSArray *fillList = [self fillList];
	NSInteger idx = [fillTableView selectedRow];
	if (idx < 0)
		return;
	_gradientY = f;
	ACSDGradient *fill = [fillList objectAtIndex:idx];
	NSPoint pt = fill.radialCentre;
	if (pt.y != f)
	{
		pt.y = f;
		[fill changeRadialCentre:pt];
		[fillTableView reloadRowAtIndex:idx];
		[gradientDisplay setNeedsDisplay:YES];
	}
}

- (IBAction)gradientWell1Hit:(id)sender
{
	NSArray *fillList = [self fillList];
	NSInteger idx = [fillTableView selectedRow];
	NSColor *color = [sender color];
	ACSDGradient *fill = [fillList objectAtIndex:idx];
	if (![color isEqual:[fill leftColour]])
	{
		[fill setLeftColour:color inView:[self inspectingGraphicView]];
		[fillTableView reloadRowAtIndex:idx];
		[gradientDisplay setNeedsDisplay:YES];
	}
}

#pragma mark -
#pragma mark patterns

- (IBAction)editPattern:(id)sender
{
	NSArray *fillList = [self fillList];
	if (!fillList || ![self inspectingGraphicView])
		return;
	int i = rowForContextualMenu;
	if (i < 0)
		return;
	if ([fillList[i]isKindOfClass:[ACSDPattern class]])
		[[[self inspectingGraphicView] document] createPatternWindowWithPattern:fillList[i]isNew:NO];
}

- (IBAction)patternModeRBMatrixHit:(id)sender
{
	NSArray *fillList = [self fillList];
	NSInteger idx = [fillTableView selectedRow];
	ACSDPattern *pattern = [fillList objectAtIndex:idx];
	[pattern changeMode:(int)[patternModeRBMatrix selectedColumn] view:[self inspectingGraphicView]];
	[fillTableView reloadRowAtIndex:idx];
	[patternDisplay setNeedsDisplay:YES];
}

- (IBAction)scaleSliderHit:(id)sender
{
	NSArray *fillList = [self fillList];
	NSInteger idx = [fillTableView selectedRow];
	float scale10 = [sender floatValue];
	float scale;
	scale = pow(10,scale10);
	ACSDPattern *pattern = [fillList objectAtIndex:idx];
	if (scale != [pattern scale])
	   {
		[pattern changeScale:scale view:[self inspectingGraphicView]];
		   [fillTableView reloadRowAtIndex:idx];
		[patternDisplay setNeedsDisplay:YES];
		[scaleTextField setFloatValue:scale];
	   }
}

- (IBAction)spacingSliderHit:(id)sender
{
	NSArray *fillList = [self fillList];
	NSInteger idx = [fillTableView selectedRow];
	float spacing10 = [sender floatValue];
	float spacing;
	spacing = pow(10,spacing10);
	ACSDPattern *pattern = [fillList objectAtIndex:idx];
	if (spacing != [pattern spacing])
	{
		[pattern changeSpacing:spacing view:[self inspectingGraphicView]];
		[fillTableView reloadRowAtIndex:idx];
		[patternDisplay setNeedsDisplay:YES];
		[spacingTextField setFloatValue:spacing];
	}
}

- (IBAction)offsetSliderHit:(id)sender
{
	NSArray *fillList = [self fillList];
	NSInteger idx = [fillTableView selectedRow];
	float offset = [sender floatValue];
	ACSDPattern *pattern = [fillList objectAtIndex:idx];
	if (offset != [pattern offset])
	{
		[pattern changeOffset:offset view:[self inspectingGraphicView]];
		[fillTableView reloadRowAtIndex:idx];
		[patternDisplay setNeedsDisplay:YES];
		[offsetTextField setFloatValue:offset];
	}
}

- (IBAction)offsetTypeRBMatrixHit:(id)sender
{
	NSArray *fillList = [self fillList];
	NSInteger idx = [fillTableView selectedRow];
	int otype = (int)[offsetTypeRBMatrix selectedColumn];
	ACSDPattern *pattern = [fillList objectAtIndex:idx];
	if (otype != [pattern offsetMode])
	{
		[pattern changeOffsetMode:otype view:[self inspectingGraphicView]];
		[fillTableView reloadRowAtIndex:idx];
		[patternDisplay setNeedsDisplay:YES];
	}
}

- (IBAction)opacitySliderHit:(id)sender
{
	NSArray *fillList = [self fillList];
	NSInteger idx = [fillTableView selectedRow];
	float opacity = [sender floatValue];
	ACSDPattern *pattern = [fillList objectAtIndex:idx];
	if (opacity != [pattern alpha])
	{
		[pattern changeAlpha:opacity view:[self inspectingGraphicView]];
		[fillTableView reloadRowAtIndex:idx];
		[patternDisplay setNeedsDisplay:YES];
		[opacityTextField setFloatValue:opacity];
	}
}

- (IBAction)scaleTextFieldHit:(id)sender
{
	NSArray *fillList = [self fillList];
	NSInteger idx = [fillTableView selectedRow];
	float scale = [sender floatValue];
	float scale10 = log10(scale);
	ACSDPattern *pattern = [fillList objectAtIndex:idx];
	if (scale != [pattern scale])
	{
		[pattern changeScale:scale view:[self inspectingGraphicView]];
		[fillTableView reloadRowAtIndex:idx];
		[patternDisplay setNeedsDisplay:YES];
		[scaleSlider setFloatValue:scale10];
	}
}

- (IBAction)spacingTextFieldHit:(id)sender
{
	NSArray *fillList = [self fillList];
	NSInteger idx = [fillTableView selectedRow];
	float spacing = [sender floatValue];
	float spacing10 = log10(spacing);
	ACSDPattern *pattern = [fillList objectAtIndex:idx];
	if (spacing != [pattern spacing])
	{
		[pattern changeSpacing:spacing view:[self inspectingGraphicView]];
		[fillTableView reloadRowAtIndex:idx];
		[patternDisplay setNeedsDisplay:YES];
		[spacingSlider setFloatValue:spacing10];
	}
}

- (IBAction)offsetTextFieldHit:(id)sender
{
	NSArray *fillList = [self fillList];
	NSInteger idx = [fillTableView selectedRow];
	float offset = [sender floatValue];
	ACSDPattern *pattern = [fillList objectAtIndex:idx];
	if (offset != [pattern offset])
	{
		[pattern changeOffset:offset view:[self inspectingGraphicView]];
		[fillTableView reloadRowAtIndex:idx];
		[patternDisplay setNeedsDisplay:YES];
		[offsetSlider setFloatValue:offset];
	}
}

- (IBAction)opacityTextFieldHit:(id)sender
{
	NSArray *fillList = [self fillList];
	NSInteger idx = [fillTableView selectedRow];
	float opacity = [sender floatValue];
	ACSDPattern *pattern = [fillList objectAtIndex:idx];
	if (opacity != [pattern alpha])
	{
		[pattern changeAlpha:opacity view:[self inspectingGraphicView]];
		[fillTableView reloadRowAtIndex:idx];
		[patternDisplay setNeedsDisplay:YES];
		[opacitySlider setFloatValue:opacity];
	}
}

#pragma mark -

-(void)updateSource
{
	[fillTableView reloadData];
}

-(void)updateSelectedFill
{
	NSArray *fillList = [self fillList];
	NSInteger ct = [[[self inspectingGraphicView] selectedGraphics] count];
	ACSDGraphic *g = nil;
	if (ct == 1)
		g = [[[[self inspectingGraphicView] selectedGraphics] allObjects]objectAtIndex:0];
	if (g)
	{
		[fillTableView setAllowsEmptySelection:NO];
		NSInteger pos = [fillList indexOfObject:[g fill]];
		if (pos == NSNotFound)
			return;
		[fillTableView selectRowIndexes:[NSIndexSet indexSetWithIndex:pos] byExtendingSelection:NO];
	}
	else if (ct == 0)
	{
	}
	else
	{
		NSArray *arr = [[[self inspectingGraphicView] selectedGraphics] allObjects];
		ACSDFill *f = [(ACSDGraphic*)[arr objectAtIndex:0]fill];
		if ([arr andMakeObjectsPerformSelector:@selector(graphicUsesFill:) withObject:f])
		{
			NSInteger pos = [fillList indexOfObject:[g fill]];
			if (pos == NSNotFound)
				return;
			[fillTableView selectRowIndexes:[NSIndexSet indexSetWithIndex:pos] byExtendingSelection:NO];
		}
		else
			[fillTableView selectRowIndexes:[NSIndexSet indexSet] byExtendingSelection:NO];
	}
}

-(void)updateControlsForFill
{
	[self setControlsForFill:[self currentFill]];
}

-(void)redisplayTable
{
    [fillTableView reloadDataForRowIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, [[self fillList]count])] columnIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, [[fillTableView tableColumns]count])]];
    [fillTableView noteNumberOfRowsChanged];
}

-(void)updateControls
{
	[self setActionsDisabled:YES];
	if (self.changed & FC_SOURCE_CHANGE)
	{
		[self updateSource];
		[self addChange:FC_GRAPHIC_SELECTION_CHANGE|FC_FILL_SELECTION_CHANGE];
	}
    if (self.changed &FC_FILL_LIST_CHANGE)
    {
        [self redisplayTable];
    }
	if (self.changed & FC_GRAPHIC_SELECTION_CHANGE)
	{
		[self updateSelectedFill];
		[self addChange:FC_FILL_SELECTION_CHANGE];
	}
	if (self.changed & FC_FILL_SELECTION_CHANGE)
	{
		[self updateControlsForFill];
	}
	[self setActionsDisabled:NO];
}

#pragma mark -
#pragma mark table stuff

- (void)tableViewSelectionDidChange:(NSNotification *)notif
{
	if ([self actionsDisabled])
		return;
	if ([notif object] == fillTableView)
		[self fillTableSelectionChange:[fillTableView selectedRow]];
}

- (BOOL)tableView:(NSTableView *)aTableView shouldSelectRow:(int)rowIndex
{
	if (aTableView == fillTableView)
	   {
		   NSArray *fillList = [self fillList];
		ACSDFill *fill = [fillList objectAtIndex:rowIndex];
		return ![[self inspectingGraphicView] recursionForObject:fill];
	   }
	else
		return YES;
}

- (BOOL)selectionShouldChangeInTableView:(NSTableView *)aTableView
{
	//[fillTableView setOldSelectedRow:[aTableView selectedRow]];
	return YES;
}

/*- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn
			row:(int)rowIndex
{
	NSArray *fillList = [self fillList];
	if (rowIndex >= 0 && rowIndex < (int)[fillList count])
	{
		ACSDFill *f = [self fillList][rowIndex];
		if ([[aTableColumn identifier]isEqualTo:@"sel"])
			return @([f showIndicator]);
		return f;
	}
	return nil;
}*/

- (NSInteger)numberOfRowsInTableView:(NSTableView *)aTableView
{
	return [[self fillList]count];
}

- (NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)rowIndex
{
	if (rowIndex < 0 || rowIndex >= [[self fillList]count])
		return nil;
	if ([[tableColumn identifier]isEqual:@"sel"])
	{
		SelView *v = [tableView makeViewWithIdentifier:@"sel" owner:self];
		if (v == nil || ![v isKindOfClass:[SelView class]])
		{
			v = [[SelView alloc]initWithFrame:NSMakeRect(0, 0, [tableView bounds].size.width, 20)];
			v.identifier = @"sel";
		}
		ACSDFill *f = [self fillList][rowIndex];
		v.objectValue = @([f showIndicator]);
		return v;
	}
	else if ([[tableColumn identifier]isEqual:@"col"])
	{
		FillView *v = [tableView makeViewWithIdentifier:@"col" owner:self];
		if (v == nil || ![v isKindOfClass:[FillView class]])
		{
			v = [[FillView alloc]initWithFrame:NSMakeRect(0, 0, [tableView bounds].size.width, 20)];
			v.identifier = @"col";
		}
		ACSDFill *f = [self fillList][rowIndex];
		v.objectValue = f;
		return v;
	}
	return nil;

}
#pragma mark -

- (BOOL)validateMenuItem:(id)menuItem
{
	SEL action = [menuItem action];
	NSArray *fillList = [self fillList];
	if (fillList && rowForContextualMenu > -1)
	   {
		//[fillTableView reDisplayRow:rowForContextualMenu];
	   }
	if (action == @selector(showFillUsers:))
		return YES;
	if (action == @selector(duplicateFill:))
		return (fillList && rowForContextualMenu > -1);
	if (action == @selector(deleteFill:))
		return (fillList && (rowForContextualMenu > -1) && ([[fillList objectAtIndex:rowForContextualMenu]nonDeletedCount] == 0));
	if (action == @selector(editPattern:))
	   {
		if (fillList)
		{
			int i = rowForContextualMenu;
			if (i > -1 && [[fillList objectAtIndex:i]isKindOfClass:[ACSDPattern class]])
				return YES;
		}
		return NO;
	   }
	return NO;
}

-(IBAction)showFillUsers:(id)sender
{
    NSUInteger modifierFlags = [[[staticView window]currentEvent]modifierFlags];
    BOOL extend = (modifierFlags & NSShiftKeyMask) != 0;
	NSArray *fillList = [self fillList];
	ACSDFill *fill = [fillList objectAtIndex:rowForContextualMenu];
	[[self inspectingGraphicView]selectGraphicsInCurrentLayerFromSet:[fill graphics]extend:extend];
}


@end
