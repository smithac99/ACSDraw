#import "ColourPanelController.h"
#import "GraphicView.h"
#import "ACSDGraphic.h"
#import "ACSDRect.h"
#import "ACSDImage.h"
#import "DragView.h"
#import "PanelCoordinator.h"

ColourPanelController *_sharedColourPanelController = nil;

@implementation ColourPanelController

+ (id)sharedColourPanelController
{
	if (!_sharedColourPanelController)
		[PanelCoordinator sharedPanelCoordinator];
    return _sharedColourPanelController;
}

- (void)zeroControls
{
	[brightnessSlider setFloatValue:0.0];
	[contrastSlider setFloatValue:0.0];
	[saturationSlider setFloatValue:0.0];
	[saturationTextField setStringValue:@""];
	[brightnessTextField setStringValue:@""];
	[contrastTextField setStringValue:@""];
	[brightnessSlider setEnabled:NO];
	[contrastSlider setEnabled:NO];
	[saturationSlider setEnabled:NO];
	[saturationTextField setEnabled:NO];
	[brightnessTextField setEnabled:NO];
	[contrastTextField setEnabled:NO];
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
	if (g && [g respondsToSelector:@selector(saturation)])
	   {
		float saturation = [(id)g saturation];
		if ([saturationSlider floatValue] != saturation)
			[saturationSlider setFloatValue:saturation];
		if ([saturationTextField floatValue] != saturation || [[saturationTextField stringValue]isEqual:@""])
			[saturationTextField setFloatValue:saturation];
		float brightness = [(id)g brightness];
		if ([brightnessSlider floatValue] != brightness)
			[brightnessSlider setFloatValue:brightness];
		if ([brightnessTextField floatValue] != brightness || [[brightnessTextField stringValue]isEqual:@""])
			[brightnessTextField setFloatValue:brightness];
		float contrast = [(id)g contrast];
		if ([contrastSlider floatValue] != contrast)
			[contrastSlider setFloatValue:contrast];
		if ([contrastTextField floatValue] != contrast || [[contrastTextField stringValue]isEqual:@""])
			[contrastTextField setFloatValue:contrast];
		[brightnessSlider setEnabled:YES];
		[contrastSlider setEnabled:YES];
		[saturationSlider setEnabled:YES];
		[saturationTextField setEnabled:YES];
		[brightnessTextField setEnabled:YES];
		[contrastTextField setEnabled:YES];
	   }
	else
		[self zeroControls];
}

-(void)awakeFromNib
{
	_sharedColourPanelController = self;
	[super awakeFromNib];
	rowForContextualMenu = -1;
	displayRowForContextualMenu = -1;
}

- (IBAction)resetButtonHit:(id)sender
{
	float saturation = 1.0;
	float brightness = 0.0;
	float contrast = 1.0;
    NSArray *selectedGraphics = [[[self inspectingGraphicView] selectedGraphics]allObjects];
    NSInteger ct = [selectedGraphics count];
    if (ct > 0)
	{
        for (int i = 0;i < ct;i++)
		{
			id g = [selectedGraphics objectAtIndex:i];
			if ([g respondsToSelector:@selector(saturation)])
			{
				[g setGraphicSaturation:saturation notify:YES];
				[g setGraphicBrightness:brightness notify:YES];
				[g setGraphicContrast:contrast notify:YES];
			}
		}
	}
	if ([saturationSlider floatValue] != saturation)
		[saturationSlider setFloatValue:saturation];
	if ([saturationTextField floatValue] != saturation)
		[saturationTextField setFloatValue:saturation];
	if ([brightnessSlider floatValue] != brightness)
		[brightnessSlider setFloatValue:brightness];
	if ([brightnessTextField floatValue] != brightness)
		[brightnessTextField setFloatValue:brightness];
	if ([contrastSlider floatValue] != contrast)
		[contrastSlider setFloatValue:contrast];
	if ([contrastTextField floatValue] != contrast)
		[contrastTextField setFloatValue:contrast];
	[[[self inspectingGraphicView] undoManager] setActionName:@"Reset Saturation/Brightness/Contrast"];
}

- (IBAction)saturationTextFieldHit:(id)sender
{
	float saturation = [sender floatValue];
    NSArray *selectedGraphics = [[[self inspectingGraphicView] selectedGraphics]allObjects];
    NSInteger ct = [selectedGraphics count];
    if (ct > 0)
	   {
        for (int i = 0;i < ct;i++)
		{
			id g = [selectedGraphics objectAtIndex:i];
			if ([g respondsToSelector:@selector(saturation)])
				[g setGraphicSaturation:saturation notify:YES];
		}
        [[[self inspectingGraphicView] undoManager] setActionName:@"Set Saturation"];
       }
	if ([saturationSlider floatValue] != saturation)
		[saturationSlider setFloatValue:saturation];
}

- (IBAction)saturationSliderHit:(id)sender
{
	float saturation = [sender floatValue];
    NSArray *selectedGraphics = [[[self inspectingGraphicView] selectedGraphics]allObjects];
    NSInteger ct = [selectedGraphics count];
    if (ct > 0)
	   {
        for (int i = 0;i < ct;i++)
		{
			id g = [selectedGraphics objectAtIndex:i];
			if ([g respondsToSelector:@selector(saturation)])
				[g setGraphicSaturation:saturation notify:YES];
		}
        [[[self inspectingGraphicView] undoManager] setActionName:@"Set Saturation"];
       }
	if ([saturationTextField floatValue] != saturation)
		[saturationTextField setFloatValue:saturation];
}

- (IBAction)brightnessTextFieldHit:(id)sender
{
	float brightness = [sender floatValue];
    NSArray *selectedGraphics = [[[self inspectingGraphicView] selectedGraphics]allObjects];
    NSInteger ct = [selectedGraphics count];
    if (ct > 0)
	   {
        for (int i = 0;i < ct;i++)
		{
			id g = [selectedGraphics objectAtIndex:i];
			if ([g respondsToSelector:@selector(brightness)])
				[g setGraphicBrightness:brightness notify:YES];
		}
        [[[self inspectingGraphicView] undoManager] setActionName:@"Set Brightness"];
       }
	if ([brightnessSlider floatValue] != brightness)
		[brightnessSlider setFloatValue:brightness];
}

- (IBAction)brightnessSliderHit:(id)sender
{
	float brightness = [sender floatValue];
    NSArray *selectedGraphics = [[[self inspectingGraphicView] selectedGraphics]allObjects];
    NSInteger ct = [selectedGraphics count];
    if (ct > 0)
	   {
        for (int i = 0;i < ct;i++)
		{
			id g = [selectedGraphics objectAtIndex:i];
			if ([g respondsToSelector:@selector(brightness)])
				[g setGraphicBrightness:brightness notify:YES];
		}
        [[[self inspectingGraphicView] undoManager] setActionName:@"Set Brightness"];
       }
	if ([brightnessTextField floatValue] != brightness)
		[brightnessTextField setFloatValue:brightness];
}

- (IBAction)contrastTextFieldHit:(id)sender
{
	float contrast = [sender floatValue];
    NSArray *selectedGraphics = [[[self inspectingGraphicView] selectedGraphics]allObjects];
    NSInteger ct = [selectedGraphics count];
    if (ct > 0)
	   {
        for (int i = 0;i < ct;i++)
		{
			id g = [selectedGraphics objectAtIndex:i];
			if ([g respondsToSelector:@selector(contrast)])
				[g setGraphicContrast:contrast notify:YES];
		}
        [[[self inspectingGraphicView] undoManager] setActionName:@"Set Contrast"];
       }
	if ([contrastSlider floatValue] != contrast)
		[contrastSlider setFloatValue:contrast];
}

- (IBAction)contrastSliderHit:(id)sender
{
	float contrast = [sender floatValue];
    NSArray *selectedGraphics = [[[self inspectingGraphicView] selectedGraphics]allObjects];
    NSInteger ct = [selectedGraphics count];
    if (ct > 0)
	   {
        for (int i = 0;i < ct;i++)
		{
			id g = [selectedGraphics objectAtIndex:i];
			if ([g respondsToSelector:@selector(contrast)])
				[g setGraphicContrast:contrast notify:YES];
		}
        [[[self inspectingGraphicView] undoManager] setActionName:@"Set Contrast"];
       }
	if ([contrastTextField floatValue] != contrast)
		[contrastTextField setFloatValue:contrast];
}


@end
