#import "TextPanelController.h"
#import "GraphicView.h"
#import "ACSDGraphic.h"
#import "ACSDText.h"
#import "DragView.h"
#import "PanelCoordinator.h"

TextPanelController *_sharedTextPanelController = nil;

@implementation TextPanelController

+ (id)sharedTextPanelController
{
	if (!_sharedTextPanelController)
		[PanelCoordinator sharedPanelCoordinator];
    return _sharedTextPanelController;
}

-(void)awakeFromNib
{
	_sharedTextPanelController = self;
	[super awakeFromNib];
	rowForContextualMenu = -1;
	displayRowForContextualMenu = -1;
}

- (IBAction)nameFieldHit:(id)sender
{
    NSArray *selectedGraphics = [[[self inspectingGraphicView] selectedGraphics]allObjects];
    NSInteger ct = [selectedGraphics count];
    if (ct != 1)
		return;
	[[selectedGraphics objectAtIndex:0] setGraphicName:[nameField stringValue]];
}

- (IBAction)textLabelHit:(id)sender
{
    NSArray *selectedGraphics = [[[self inspectingGraphicView] selectedGraphics]allObjects];
    NSInteger ct = [selectedGraphics count];
    if (ct != 1)
		return;
	[[selectedGraphics objectAtIndex:0] setGraphicLabelText:[textLabel textStorage]notify:NO];
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

- (IBAction)toolTipTextHit:(id)sender
{
    NSArray *selectedGraphics = [[[self inspectingGraphicView] selectedGraphics]allObjects];
    NSInteger ct = [selectedGraphics count];
    if (ct > 0)
	   {
        NSString *str = [sender stringValue];
        for (int i = 0;i < ct;i++)
		{
		    id obj = [selectedGraphics objectAtIndex:i];
			if ([obj respondsToSelector:@selector(setGraphicToolTip:)])
				[obj setGraphicToolTip:str];
		}
        [[[self inspectingGraphicView] undoManager] setActionName:@"Change Tool Tip"];
       }
}

- (IBAction)leftMarginHit:(id)sender
{
    NSArray *selectedGraphics = [[[self inspectingGraphicView] selectedGraphics]allObjects];
    NSInteger ct = [selectedGraphics count];
    if (ct > 0)
	   {
        float lm = [sender floatValue];
        for (int i = 0;i < ct;i++)
		{
		    id obj = [selectedGraphics objectAtIndex:i];
			if ([obj respondsToSelector:@selector(setGraphicLeftMargin:notify:)])
				[obj setGraphicLeftMargin:lm notify:NO];
		}
        [[[self inspectingGraphicView] undoManager] setActionName:@"Change Left Margin"];
       }
}

- (IBAction)rightMarginHit:(id)sender
{
    NSArray *selectedGraphics = [[[self inspectingGraphicView] selectedGraphics]allObjects];
    NSInteger ct = [selectedGraphics count];
    if (ct > 0)
	   {
        float lm = [sender floatValue];
        for (int i = 0;i < ct;i++)
		{
		    id obj = [selectedGraphics objectAtIndex:i];
			if ([obj respondsToSelector:@selector(setGraphicRightMargin:notify:)])
				[obj setGraphicRightMargin:lm notify:NO];
		}
        [[[self inspectingGraphicView] undoManager] setActionName:@"Change Right Margin"];
       }
}

- (IBAction)topMarginHit:(id)sender
{
    NSArray *selectedGraphics = [[[self inspectingGraphicView] selectedGraphics]allObjects];
    NSInteger ct = [selectedGraphics count];
    if (ct > 0)
	   {
        float lm = [sender floatValue];
        for (int i = 0;i < ct;i++)
		{
		    id obj = [selectedGraphics objectAtIndex:i];
			if ([obj respondsToSelector:@selector(setGraphicTopMargin:notify:)])
				[obj setGraphicTopMargin:lm notify:NO];
		}
        [[[self inspectingGraphicView] undoManager] setActionName:@"Change Top Margin"];
       }
}

- (IBAction)bottomMarginHit:(id)sender
{
    NSArray *selectedGraphics = [[[self inspectingGraphicView] selectedGraphics]allObjects];
    NSInteger ct = [selectedGraphics count];
    if (ct > 0)
	   {
        float lm = [sender floatValue];
        for (int i = 0;i < ct;i++)
		{
		    id obj = [selectedGraphics objectAtIndex:i];
			if ([obj respondsToSelector:@selector(setGraphicBottomMargin:notify:)])
				[(id)obj setGraphicBottomMargin:lm notify:NO];
		}
        [[[self inspectingGraphicView] undoManager] setActionName:@"Change Bottom Margin"];
       }
}

- (IBAction)flowPadHit:(id)sender
{
    NSArray *selectedGraphics = [[[self inspectingGraphicView] selectedGraphics]allObjects];
    NSInteger ct = [selectedGraphics count];
    if (ct > 0)
	   {
        float lm = [sender floatValue];
        for (int i = 0;i < ct;i++)
		{
		    id obj = [selectedGraphics objectAtIndex:i];
			if ([obj respondsToSelector:@selector(setGraphicFlowPad:notify:)])
				[(id)obj setGraphicFlowPad:lm notify:NO];
		}
        [[[self inspectingGraphicView] undoManager] setActionName:@"Change Flow Pad"];
       }
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

-(void)setGraphicControls
{
	NSInteger ct = [[[self inspectingGraphicView] selectedGraphics] count];
	id g = nil;
	if (ct == 1)
		g = [[[[self inspectingGraphicView] selectedGraphics] allObjects]objectAtIndex:0];
	if (g)
	   {
		[nameField setStringValue:[g name]];
		[nameField setEnabled:YES];
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
		[toolTipText setStringValue:[g toolTip]];
		[toolTipText setEnabled:YES];
	   }
	else
	   {
		[nameField setStringValue:@""];
		[nameField setEnabled:NO];
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
		[textFlowMatrix setEnabled:NO];
		[toolTipText setStringValue:@""];
		[toolTipText setEnabled:NO];
	   }
	
	if (g && [g respondsToSelector:@selector(leftMargin)])
	   {
		[leftMargin setFloatValue:[g leftMargin]];
		[leftMargin setEnabled:YES];
		[rightMargin setFloatValue:[g rightMargin]];
		[rightMargin setEnabled:YES];
		[topMargin setFloatValue:[g topMargin]];
		[topMargin setEnabled:YES];
		[bottomMargin setFloatValue:[g bottomMargin]];
		[bottomMargin setEnabled:YES];
		[flowPad setFloatValue:[g flowPad]];
		[flowPad setEnabled:YES];
		[alignmentMatrix setState:1 atRow:[g verticalAlignment] column:0];
		[alignmentMatrix setEnabled:YES];
		[textFlowMatrix selectCellAtRow:[g flowMethod]column:0];
		[textFlowMatrix setEnabled:YES];
	   }
	else
	   {
		[leftMargin setStringValue:@""];
		[leftMargin setEnabled:NO];
		[rightMargin setStringValue:@""];
		[rightMargin setEnabled:NO];
		[topMargin setStringValue:@""];
		[topMargin setEnabled:NO];
		[bottomMargin setStringValue:@""];
		[bottomMargin setEnabled:NO];
		[flowPad setStringValue:@""];
		[flowPad setEnabled:NO];
		[alignmentMatrix setEnabled:NO];
		[textFlowMatrix setEnabled:NO];
	   }
}



@end
