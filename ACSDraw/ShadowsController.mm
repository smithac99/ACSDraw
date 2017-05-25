//
//  ShadowsController.mm
//  ACSDraw
//
//  Created by alan on 08/02/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "ShadowsController.h"
#import "ShadowType.h"
#import "ShadowCell.h"
#import "SelCell.h"
#import "ACSDGraphic.h"
#import "ACSDTableView.h"
#import "GraphicView.h"
#import "ShadowListTableSource.h"


@implementation ShadowsController

-(id)init
{
	if (self = [super initWithTitle:@"Shadows"])
	{
	}
	return self;
}

- (void)dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)zeroControls
{
//	[self setShadowList:nil];
}


- (void)setShadowList:(NSMutableArray*)f
{
	if (shadowList == f)
		return;
	shadowList = f;
	[(ShadowListTableSource*)[shadowTableView dataSource]setShadowList:f];
}

-(void)setDocumentControls:(ACSDrawDocument*)doc
{
	[self setShadowList:[doc shadows]];
}

-(void)setGraphicControls
{
	NSInteger ct = [[[self inspectingGraphicView] selectedGraphics] count];
	id g = nil;
	ShadowType *shado = nil;
	if (ct > 1)
	   {
		[shadowTableView setAllowsEmptySelection:YES];
		[shadowTableView selectRowIndexes:[NSIndexSet indexSet] byExtendingSelection:NO];
		return;
	   }
	[shadowTableView setAllowsEmptySelection:NO];
	if (ct == 1)
	   {
		g = [[[[self inspectingGraphicView] selectedGraphics] allObjects]objectAtIndex:0];
		shado = [g shadowType];
		if (shado == nil)
		{
			[shadowTableView selectRowIndexes:[NSIndexSet indexSetWithIndex:0] byExtendingSelection:NO];
			return;
		}
	   }
	if (g && shado)
	   {
		NSUInteger pos = [shadowList indexOfObject:shado];
		if (pos == NSNotFound)
			NSLog(@"Shadow not found in list");
		else
		{
			if (pos == [shadowTableView selectedRow])
				[shadowTableView refreshSelectionIndicatorForRow:pos];
			else
				[shadowTableView selectRowIndexes:[NSIndexSet indexSetWithIndex:pos] byExtendingSelection:NO];
			return;
		}
	   }
}

- (IBAction)shadowWellHit:(id)sender
{
    NSColor *color = [sender color];
	ShadowType *sh = [shadowList objectAtIndex:[shadowTableView selectedRow]];
	if (![color isEqual:[sh colour]])
	   {
        [sh setColour:color];
		[shadowTableView reloadData];
       }
}

-(void)refreshShadows
{
	[shadowTableView reloadData];
}

- (void)reloadShadows:(NSNotification *)notification
{
	[self refreshShadows];
}

-(void)duplicateShadowAtRow:(NSInteger)row
{
	ShadowType *sh = [[shadowList objectAtIndex:row]copy];
	[shadowList insertObject:sh atIndex:row + 1];
	[shadowTableView reloadData];
	[shadowTableView selectRowIndexes:[NSIndexSet indexSetWithIndex:row + 1] byExtendingSelection:NO];
}

- (IBAction)duplicateShadow:(id)sender
{
	if (rowForContextualMenu > -1)
		[self duplicateShadowAtRow:rowForContextualMenu];
}

- (IBAction)shadowPlusHit:(id)sender
{
	if (shadowList)
	   {
	    NSInteger row = [shadowTableView selectedRow];
		if (row >= 0)
		    [self duplicateShadowAtRow:row];
	   }
}

- (void)deleteShadowAtIndex:(NSInteger)row
{
	if (!shadowList || ![self inspectingGraphicView])
		return;
	if (row < 0)
		return;
	if ([[shadowList objectAtIndex:row]nonDeletedCount] == 0)
	   {
		[[[self inspectingGraphicView] document]deleteShadowAtIndex:row];
		[[[self inspectingGraphicView] undoManager] setActionName:@"Delete Shadow"];
	   }
}

- (IBAction)deleteShadow:(id)sender
{
	[self deleteShadowAtIndex:rowForContextualMenu];
}

- (IBAction)shadowMinusHit:(id)sender
{
	[self deleteShadowAtIndex:[shadowTableView selectedRow]];
}

- (IBAction)radiusSliderHit:(id)sender
{
	NSInteger i = [shadowTableView selectedRow];
	if (i >= 0)
	{
		float val = [sender floatValue];
		ShadowType *sType = [shadowList objectAtIndex:i];
		if (val != [sType blurRadius])
		{
			[sType setBlurRadius:val];
			[shadowTableView reloadData];
		}
	}
}

- (IBAction)xOffsetSliderHit:(id)sender
{
	NSInteger i = [shadowTableView selectedRow];
	if (i >= 0)
	{
		float val = [sender floatValue];
		ShadowType *sType = [shadowList objectAtIndex:i];
		if (val != [sType xOffset])
		{
			[sType setOffset:NSMakeSize(val,[sType yOffset])];
			[shadowTableView reloadData];
		}
	}
}

- (IBAction)yOffsetSliderHit:(id)sender
{
	NSInteger i = [shadowTableView selectedRow];
	if (i >= 0)
	{
		float val = [sender floatValue];
		ShadowType *sType = [shadowList objectAtIndex:i];
		if (val != [sType yOffset])
		{
			[sType setOffset:NSMakeSize([sType xOffset],val)];
			[shadowTableView reloadData];
		}
	}
}

-(void)awakeFromNib
{
	[super awakeFromNib];
	rowForContextualMenu = -1;
	displayRowForContextualMenu = -1;
	[[[shadowTableView tableColumns]objectAtIndex:0] setDataCell:[[ShadowCell alloc]init]];
	[[[shadowTableView tableColumns]objectAtIndex:4] setDataCell:[[SelCell alloc]init]];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reloadShadows:) name:ACSDRefreshShadowsNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(unsetRowForContextualMenu:) name:NSMenuDidEndTrackingNotification object:nil];
}

-(void)setControlsForShadow:(ShadowType*)shado
{
	if (![self inspectingGraphicView])
		return;
	if (shado == nil)
	   {
		[shadowWell setColor:[NSColor clearColor]];
		[shadowWell setEnabled:NO];
	   }
	else
	   {
		BOOL flag = [shado colour] != nil;
		[shadowWell setColor:(flag ? [shado colour] : [NSColor clearColor])];
		[shadowWell setEnabled:flag];
		if (flag)
		{
			if ([shado blurRadius] > 25.0)
				[[radiusSlider formatter]setMaximum:[NSNumber numberWithFloat:[shado blurRadius]*1.5]];
			else
				[[radiusSlider formatter]setMaximum:[NSNumber numberWithFloat:25.0]];
			if (fabs([shado xOffset]) > 20.0)
			{
				[xOffsetSlider setMaxValue:[shado xOffset]*1.5];
				[xOffsetSlider setMinValue:-[shado xOffset]*1.5];
			}
			else
			{
				[xOffsetSlider setMaxValue:20.0];
				[xOffsetSlider setMinValue:-20.0];
			}
			if (fabs([shado yOffset]) > 20.0)
			{
				[yOffsetSlider setMaxValue:[shado yOffset]*1.5];
				[yOffsetSlider setMinValue:-[shado yOffset]*1.5];
			}
			else
			{
				[yOffsetSlider setMaxValue:20.0];
				[yOffsetSlider setMinValue:-20.0];
			}
		}
		[radiusSlider setFloatValue:(flag ? [shado blurRadius] : 0.0)];
		[radiusSlider setEnabled:flag];
		[xOffsetSlider setFloatValue:(flag ? [shado xOffset] : 0.0)];
		[xOffsetSlider setEnabled:flag];
		[yOffsetSlider setFloatValue:(flag ? [shado yOffset] : 0.0)];
		[yOffsetSlider setEnabled:flag];
		
		NSInteger count;
		BOOL changed = NO;
		if ((count = [[[self inspectingGraphicView] selectedGraphics] count]) > 0)
		{
			NSArray *graphics = [[[self inspectingGraphicView] selectedGraphics] allObjects];
			for (int i = 0;i < count;i++)
			{
				ACSDGraphic *graphic = [graphics objectAtIndex:i];
				changed = [graphic setGraphicShadowType:shado notify:NO]  || changed;
				[[self inspectingGraphicView] invalidateGraphic:graphic];
			}
			if (changed)
				[[[self inspectingGraphicView] undoManager] setActionName:@"Change Shadow"];
		}
		[[self inspectingGraphicView] setDefaultShadow:shado];
	   }
}

- (void)shadowTableSelectionChange:(NSInteger)row
{
	ShadowType *shado = nil;
	if (row > -1)
		shado = [shadowList objectAtIndex:row];
	[self setControlsForShadow:shado];
	if (row == -1 || [shadowTableView oldSelectedRow] == -1)
		[self refreshShadows];
	else
	   {
		[shadowTableView refreshSelectionIndicatorForRow:row];
		[shadowTableView refreshSelectionIndicatorForRow:[shadowTableView oldSelectedRow]];
	   }
}

- (void)tableViewSelectionDidChange:(NSNotification *)notif
{
	if ([self actionsDisabled])
		return;
	if ([notif object] == shadowTableView)
		[self shadowTableSelectionChange:[shadowTableView selectedRow]];
}

- (BOOL)selectionShouldChangeInTableView:(NSTableView *)aTableView
{
	[shadowTableView setOldSelectedRow:[aTableView selectedRow]];
	return YES;
}

- (BOOL)validateMenuItem:(id)menuItem
{
	if (shadowList && rowForContextualMenu > -1)
		[shadowTableView reDisplayRow:rowForContextualMenu];
	SEL action = [menuItem action];
	if (action == @selector(deleteShadow:))
	   {
		if (shadowList)
		{
			int i = rowForContextualMenu;
			if (i > -1 && ([[shadowList objectAtIndex:i]nonDeletedCount] == 0))
				return YES;
		}
		return NO;
	   }
	return YES;
}


@end
