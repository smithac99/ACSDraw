//
//  TextController.mm
//  ACSDraw
//
//  Created by alan on 08/02/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "TextController.h"
#import "GraphicView.h"
#import "ACSDGraphic.h"
#import "ACSDText.h"


@implementation TextController
-(id)init
{
	if ((self = [super initWithTitle:@"Text"]))
	{
	}
	return self;
}

-(void)dealloc
{
	self.sourcePath = nil;
	self.toolTip = nil;
	[super dealloc];
}
-(void)awakeFromNib
{
	[super awakeFromNib];
	rowForContextualMenu = -1;
	displayRowForContextualMenu = -1;
}

- (IBAction)textLabelHit:(id)sender
{
	for (ACSDGraphic *g in [[self inspectingGraphicView] selectedGraphics])
		[g setGraphicLabelText:[textLabel textStorage]notify:NO];
}

- (void)textDidChange:(NSNotification *)notif
{
	if (![self inspectingGraphicView])
		return;
	[self textLabelHit:self];
}

- (IBAction)vLabelTextHit:(id)sender
{
    NSArray *selectedGraphics = [[[self inspectingGraphicView] selectedGraphics]allObjects];
    NSInteger ct = [selectedGraphics count];
    if (ct != 1)
		return;
	[[selectedGraphics objectAtIndex:0] setGraphicLabelVPos:[vLabelText floatValue]notify:NO];
}

- (IBAction)hLabelTextHit:(id)sender
{
    NSArray *selectedGraphics = [[[self inspectingGraphicView] selectedGraphics]allObjects];
    NSInteger ct = [selectedGraphics count];
    if (ct != 1)
		return;
	[[selectedGraphics objectAtIndex:0] setGraphicLabelHPos:[hLabelText floatValue]notify:NO];
}

- (IBAction)vLabelSliderHit:(id)sender
{
    NSArray *selectedGraphics = [[[self inspectingGraphicView] selectedGraphics]allObjects];
    NSInteger ct = [selectedGraphics count];
    if (ct != 1)
		return;
	float f = [vLabelSlider floatValue];
	[[selectedGraphics objectAtIndex:0] setGraphicLabelVPos:f notify:NO];
	[vLabelText setFloatValue:f];
}

- (IBAction)hLabelSliderHit:(id)sender
{
    NSArray *selectedGraphics = [[[self inspectingGraphicView] selectedGraphics]allObjects];
    NSInteger ct = [selectedGraphics count];
    if (ct != 1)
		return;
	float f = [hLabelSlider floatValue];
	[[selectedGraphics objectAtIndex:0] setGraphicLabelHPos:f notify:NO];
	[hLabelText setFloatValue:f];
}

- (IBAction)labelFlippedHit:(id)sender
{
    NSArray *selectedGraphics = [[[self inspectingGraphicView] selectedGraphics]allObjects];
    NSInteger ct = [selectedGraphics count];
    if (ct > 0)
	   {
        int v = [sender intValue];
        for (int i = 0;i < ct;i++)
		{
		    id obj = [selectedGraphics objectAtIndex:i];
			if ([obj respondsToSelector:@selector(setGraphicLabelFlipped:notify:)])
				[obj setGraphicLabelFlipped:v notify:NO];
		}
        [[[self inspectingGraphicView] undoManager] setActionName:@"Change Flipped"];
       }
}

- (IBAction)leftMarginHit:(id)sender
{
	float lm = [sender floatValue];
	BOOL changed = NO;
	for (id obj in [[self inspectingGraphicView] selectedGraphics])
		if ([obj respondsToSelector:@selector(setGraphicLeftMargin:notify:)])
			changed = [obj setGraphicLeftMargin:lm notify:NO] || changed;
    if (changed)
        [[[self inspectingGraphicView] undoManager] setActionName:@"Change Left Margin"];
}

- (IBAction)rightMarginHit:(id)sender
{
	float lm = [sender floatValue];
	BOOL changed = NO;
	for (id obj in [[self inspectingGraphicView] selectedGraphics])
		if ([obj respondsToSelector:@selector(setGraphicRightMargin:notify:)])
			changed = [obj setGraphicRightMargin:lm notify:NO] || changed;
    if (changed)
        [[[self inspectingGraphicView] undoManager] setActionName:@"Change Right Margin"];
}

- (IBAction)topMarginHit:(id)sender
{
	float lm = [sender floatValue];
	BOOL changed = NO;
	for (id obj in [[self inspectingGraphicView] selectedGraphics])
		if ([obj respondsToSelector:@selector(setGraphicTopMargin:notify:)])
			changed = [obj setGraphicTopMargin:lm notify:NO] || changed;
    if (changed)
        [[[self inspectingGraphicView] undoManager] setActionName:@"Change Top Margin"];
}

- (IBAction)bottomMarginHit:(id)sender
{
	float lm = [sender floatValue];
	BOOL changed = NO;
	for (id obj in [[self inspectingGraphicView] selectedGraphics])
		if ([obj respondsToSelector:@selector(setGraphicBottomMargin:notify:)])
			changed = [obj setGraphicBottomMargin:lm notify:NO] || changed;
    if (changed)
        [[[self inspectingGraphicView] undoManager] setActionName:@"Change Bottom Margin"];
}

- (IBAction)flowPadHit:(id)sender
{
 	float lm = [sender floatValue];
	BOOL changed = NO;
	for (id obj in [[self inspectingGraphicView] selectedGraphics])
		if ([obj respondsToSelector:@selector(setGraphicFlowPad:notify:)])
			changed = [obj setGraphicFlowPad:lm notify:NO] || changed;
    if (changed)
        [[[self inspectingGraphicView] undoManager] setActionName:@"Change Flow Pad"];
}


- (IBAction)alignmentMatrixHit:(id)sender
{
    NSArray *selectedGraphics = [[[self inspectingGraphicView] selectedGraphics]allObjects];
    NSInteger ct = [selectedGraphics count];
    if (ct > 0)
	   {
		NSInteger val = [sender selectedRow];
		   for (id obj in selectedGraphics)
		{
			if ([obj respondsToSelector:@selector(setGraphicVerticalAlignment:notify:)])
				[obj setGraphicVerticalAlignment:(VerticalAlignment)val notify:NO];
		}
        [[[self inspectingGraphicView] undoManager] setActionName:@"Change Alignment"];
       }
}

- (IBAction)textFlowMatrixHit:(id)sender
{
    NSArray *selectedGraphics = [[[self inspectingGraphicView] selectedGraphics]allObjects];
    NSInteger ct = [selectedGraphics count];
    if (ct > 0)
	   {
		NSInteger val = [sender selectedRow];
		for (id obj in selectedGraphics)
		{
			if ([obj respondsToSelector:@selector(setGraphicFlowMethod:notify:)])
				[obj setGraphicFlowMethod:(int)val notify:NO];
		}
        [[[self inspectingGraphicView] undoManager] setActionName:@"Change Text Flow"];
       }
}

-(void)setToolTip:(NSString *)toolTip
{
	if (![toolTip isEqualToString:_toolTip])
	{
		[_toolTip release];
		_toolTip = [toolTip retain];
		[self updateObjects:[[[self inspectingGraphicView] selectedGraphics]allObjects] withValue:toolTip forKey:@"toolTip" changeid:TC_TOOL_TIP_CHANGE	invalidateFlags:0 actionName:@"Change Tooltip"];
	}
}

-(void)setSourcePath:(NSString *)sourcePath
{
    if ([sourcePath length] == 0 && [_sourcePath length] == 0)
        return;
	if (![sourcePath isEqualToString:_sourcePath])
	{
		[_sourcePath release];
		_sourcePath = [sourcePath retain];
		[self updateObjects:[[[self inspectingGraphicView] selectedGraphics]allObjects] withValue:sourcePath forKey:@"sourcePath" changeid:TC_SOURCE_CHANGE	invalidateFlags:0 actionName:@"Change Source"];
        if ([NSEvent modifierFlags] & NSCommandKeyMask)
            [[self inspectingGraphicView] reloadImages:[[[self inspectingGraphicView] selectedGraphics]allObjects]];

	}
}

- (void)graphicChanged:(NSNotification *)notification
{
	if (inspectingGraphicView)
	{
		if ([inspectingGraphicView graphicIsSelected:[notification object]])
			[self setGraphicControls];
	}
	[self changeAll];
}

-(void)updateControls
{
	actionsDisabled = YES;
	NSSet *selectedObjects = [[self inspectingGraphicView] selectedGraphics];
	ACSDGraphic *g;
	if ([selectedObjects count] == 1)
	{
		g = [selectedObjects anyObject];
		if (self.changed & TC_SOURCE_CHANGE)
			self.sourcePath = g.sourcePath;
		if (self.changed & TC_TOOL_TIP_CHANGE)
			self.toolTip = g.toolTip;
	}
	else
	{
		g = nil;
		self.sourcePath = @"";
		self.toolTip = @"";
	}
	self.fieldsEditable = ([selectedObjects count] > 0);
	actionsDisabled = NO;
}

-(void)ableGeneralFields:(BOOL)able
{
	[textLabel setEditable:able];
	[vLabelText setEnabled:able];
	[vLabelSlider setEnabled:able];
	[hLabelText setEnabled:able];
	[hLabelSlider setEnabled:able];
	[labelFlipped setEnabled:able];
}

-(void)setGeneralPlaceHolders:(NSString*)s
{
//	[[textLabel cell]setPlaceholderString:s];
	[[vLabelText cell]setPlaceholderString:s];
	[[hLabelText cell]setPlaceholderString:s];
    [[toolTipText cell]setPlaceholderString:s];
    [[sourceText cell]setPlaceholderString:s];
}

-(void)ableACSDTextFields:(BOOL)able
{
	[alignmentMatrix setEnabled:able];
	[leftMargin setEnabled:able];
	[rightMargin setEnabled:able];
	[topMargin setEnabled:able];
	[bottomMargin setEnabled:able];
	[textFlowMatrix setEnabled:able];
	[flowPad setEnabled:able];
}

-(void)setACSDTextPlaceHolders:(NSString*)s
{
	[[leftMargin cell]setPlaceholderString:s];
	[[rightMargin cell]setPlaceholderString:s];
	[[topMargin cell]setPlaceholderString:s];
	[[bottomMargin cell]setPlaceholderString:s];
}

-(void)zeroTextLabelStuff
{
	[[textLabel textStorage]setAttributedString:[[[NSAttributedString alloc]initWithString:@""]autorelease]];
	[textLabel setEditable:NO];
	[vLabelText setStringValue:@""];
	[vLabelText setEnabled:NO];
	[vLabelSlider setFloatValue:0.0];
	[vLabelSlider setEnabled:NO];
	[hLabelText setStringValue:@""];
	[hLabelText setEnabled:NO];
	[hLabelSlider setFloatValue:0.0];
	[hLabelSlider setEnabled:NO];
	[labelFlipped setIntValue:0];
	[labelFlipped setEnabled:NO];
}

-(void)setGraphicControls
{
	NSInteger ct = [[[self inspectingGraphicView] selectedGraphics] count];
	id g = nil;
	if (ct == 1)
		g = [[[[self inspectingGraphicView] selectedGraphics] allObjects]objectAtIndex:0];
	if (ct <= 1)
	{
		[self setGeneralPlaceHolders:@""];
		[self setACSDTextPlaceHolders:@""];
	}
	if (g)
	{
		if ([g textLabel])
		{
			[[textLabel textStorage]setAttributedString:[g labelText]];
			[textLabel setEditable:YES];
			[vLabelText setFloatValue:[[g textLabel]verticalPosition]];
			[vLabelText setEnabled:YES];
			[vLabelSlider setFloatValue:[[g textLabel]verticalPosition]];
			[vLabelSlider setEnabled:YES];
			[hLabelText setFloatValue:[[g textLabel]horizontalPosition]];
			[hLabelText setEnabled:YES];
			[hLabelSlider setFloatValue:[[g textLabel]horizontalPosition]];
			[hLabelSlider setEnabled:YES];
			[labelFlipped setIntValue:[[g textLabel]flipped]];
			[labelFlipped setEnabled:YES];
		}
		else
			[self zeroTextLabelStuff];
	}
	else
	{
		[self zeroTextLabelStuff];
		if (ct == 0)
			[self ableGeneralFields:NO];
		else
		{
			[self ableGeneralFields:YES];
			[self setGeneralPlaceHolders:@"multiple"];
		}
	}
	
	if (ct < 2)
		[self setACSDTextPlaceHolders:@""];
	if (g && [g respondsToSelector:@selector(leftMargin)])
	{
		[leftMargin setFloatValue:[(id<TextCharacteristics>)g leftMargin]];
		[rightMargin setFloatValue:[(id<TextCharacteristics>)g rightMargin]];
		[topMargin setFloatValue:[(id<TextCharacteristics>)g topMargin]];
		[bottomMargin setFloatValue:[(id<TextCharacteristics>)g bottomMargin]];
		[flowPad setFloatValue:[g flowPad]];
		[alignmentMatrix setState:1 atRow:[(id<TextCharacteristics>)g verticalAlignment] column:0];
		[textFlowMatrix selectCellAtRow:[g flowMethod]column:0];
		[self ableACSDTextFields:YES];
	}
	else
	{
		[leftMargin setStringValue:@""];
		[rightMargin setStringValue:@""];
		[topMargin setStringValue:@""];
		[bottomMargin setStringValue:@""];
		[flowPad setStringValue:@""];
		[alignmentMatrix setEnabled:NO];
		[textFlowMatrix setEnabled:NO];
	}
	if (ct == 0)
	{
		[self ableACSDTextFields:NO];
	}
	else if (ct > 1)
	{
		[self ableACSDTextFields:YES];
		[self setACSDTextPlaceHolders:@"multiple"];
	}
}

@end
