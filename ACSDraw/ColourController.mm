//
//  ColourController.mm
//  ACSDraw
//
//  Created by alan on 08/02/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "ColourController.h"
#import "GraphicView.h"
#import "ACSDImage.h"


@implementation ColourController

@synthesize saturation,saturationEnabled,brightness,brightnessEnabled,contrast,contrastEnabled;

-(id)init
{
	if ((self = [super initWithTitle:@"Colour"]))
	{
	}
	return self;
}

- (void)zeroControls
{
    BOOL temp = [self setActionsDisabled:YES];
	self.saturation = 0.0;
	self.brightness = 0.0;
	self.contrast = 0.0;
	[unsharpmaskIntensitySlider setFloatValue:0.0];
	[unsharpmaskRadiusSlider setFloatValue:0.0];
	[unsharpmaskIntensityTextField setStringValue:@""];
	[unsharpmaskRadiusTextField setStringValue:@""];
	[histogramView setHistogramData:nil];
	self.saturationEnabled = NO;
	self.brightnessEnabled = NO;
	self.contrastEnabled = NO;
	[unsharpmaskRadiusSlider setEnabled:NO];
	[unsharpmaskIntensitySlider setEnabled:NO];
	[unsharpmaskRadiusTextField setEnabled:NO];
	[unsharpmaskIntensityTextField setEnabled:NO];
    [self setActionsDisabled:temp];
}

-(void)setGraphicControls
{
    BOOL temp = [self setActionsDisabled:YES];
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
		self.saturation = [(ACSDGraphic*)g saturation];
		self.brightness = [(id)g brightness];
		self.contrast = [(ACSDGraphic*)g contrast];
		float unsharpmaskRadius = [(id)g unsharpmaskRadius];
		if ([unsharpmaskRadiusSlider floatValue] != unsharpmaskRadius)
			[unsharpmaskRadiusSlider setFloatValue:unsharpmaskRadius];
		if ([unsharpmaskRadiusTextField floatValue] != unsharpmaskRadius || [[unsharpmaskRadiusTextField stringValue]isEqual:@""])
			[unsharpmaskRadiusTextField setFloatValue:unsharpmaskRadius];
		float unsharpmaskIntensity = [(id)g unsharpmaskIntensity];
		if ([unsharpmaskIntensitySlider floatValue] != unsharpmaskIntensity)
			[unsharpmaskIntensitySlider setFloatValue:unsharpmaskIntensity];
		if ([unsharpmaskIntensityTextField floatValue] != unsharpmaskRadius || [[unsharpmaskIntensityTextField stringValue]isEqual:@""])
			[unsharpmaskIntensityTextField setFloatValue:unsharpmaskIntensity];
		self.brightnessEnabled = YES;
		self.contrastEnabled = YES;
		self.saturationEnabled = YES;
		[unsharpmaskRadiusSlider setEnabled:YES];
		[unsharpmaskIntensitySlider setEnabled:YES];
		[unsharpmaskRadiusTextField setEnabled:YES];
		[unsharpmaskIntensityTextField setEnabled:YES];
		if ([g respondsToSelector:@selector(histogram)])
			[histogramView setHistogramData:[g histogram]];
		else
			[histogramView setHistogramData:nil];
		[histogramView setNeedsDisplay:YES];
	}
	else
		[self zeroControls];
    [self setActionsDisabled:temp];
}

-(void)updateHistogram:(NSNotification*)n
{
	id g = nil;
	NSInteger ct = 0;
	NSArray *graphics = nil;
	if ([self inspectingGraphicView])
	{
		graphics = [[[self inspectingGraphicView] selectedGraphics]allObjects];
		ct = [graphics count];
	}
	if (ct == 1)
		g = [graphics objectAtIndex:0];
	if ([g respondsToSelector:@selector(histogram)])
		[histogramView setHistogramData:[g histogram]];
	else
		[histogramView setHistogramData:nil];
	[histogramView setNeedsDisplay:YES];
}

-(void)awakeFromNib
{
	[super awakeFromNib];
	rowForContextualMenu = -1;
	displayRowForContextualMenu = -1;
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateHistogram:) name:ACSDHistogramDidChangeNotification object:nil];
}

- (IBAction)resetButtonHit:(id)sender
{
	float zsaturation = 1.0;
	float zbrightness = 0.0;
	float zcontrast = 1.0;
    NSArray *selectedGraphics = [[[self inspectingGraphicView] selectedGraphics]allObjects];
    NSInteger ct = [selectedGraphics count];
    if (ct > 0)
	{
        for (int i = 0;i < ct;i++)
		{
			id g = [selectedGraphics objectAtIndex:i];
			if ([g respondsToSelector:@selector(saturation)])
			{
				[g setGraphicSaturation:zsaturation notify:YES];
				[g setGraphicBrightness:zbrightness notify:YES];
				[g setGraphicContrast:zcontrast notify:YES];
			}
		}
	}
	self.saturation = zsaturation;
/*	if ([saturationSlider floatValue] != saturation)
		[saturationSlider setFloatValue:saturation];
	if ([saturationTextField floatValue] != saturation)
		[saturationTextField setFloatValue:saturation];*/
	self.brightness = zbrightness;
	/*if ([brightnessSlider floatValue] != brightness)
		[brightnessSlider setFloatValue:brightness];
	if ([brightnessTextField floatValue] != brightness)
		[brightnessTextField setFloatValue:brightness];*/
	self.contrast = zcontrast;
	/*if ([contrastSlider floatValue] != contrast)
		[contrastSlider setFloatValue:contrast];
	if ([contrastTextField floatValue] != contrast)
		[contrastTextField setFloatValue:contrast];*/
	[[[self inspectingGraphicView] undoManager] setActionName:@"Reset Saturation/Brightness/Contrast"];
}

/*- (IBAction)saturationTextFieldHit:(id)sender
{
	float saturation = [sender floatValue];
    NSArray *selectedGraphics = [[[self inspectingGraphicView] selectedGraphics]allObjects];
    int ct = [selectedGraphics count];
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
    int ct = [selectedGraphics count];
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
}*/

-(void)setSaturation:(float)sat
{
	if (saturation == sat)
		return;
	saturation = sat;
	if (actionsDisabled)
		return;
	BOOL changed = NO;
	for (ACSDGraphic *g in [[[self inspectingGraphicView] selectedGraphics]allObjects])
		if ([g respondsToSelector:@selector(saturation)])
			changed = [g setGraphicSaturation:saturation notify:YES] || changed;
	if (changed)
        [[[self inspectingGraphicView] undoManager] setActionName:@"Set Saturation"];
}

- (IBAction)saturationUpHit:(id)sender
{
	self.saturation = saturation + 0.01;
}

- (IBAction)saturationDownHit:(id)sender
{
	self.saturation = saturation - 0.01;

}

-(void)setContrast:(float)c
{
	if (contrast == c)
		return;
	contrast = c;
	if (actionsDisabled)
		return;
	BOOL changed = NO;
	for (ACSDGraphic *g in [[[self inspectingGraphicView] selectedGraphics]allObjects])
		if ([g respondsToSelector:@selector(contrast)])
			changed = [g setGraphicContrast:contrast notify:YES] || changed;
	if (changed)
        [[[self inspectingGraphicView] undoManager] setActionName:@"Set Contrast"];
}

- (IBAction)contrastUpHit:(id)sender
{
	self.contrast = contrast + 0.01;
}

- (IBAction)contrastDownHit:(id)sender
{
	self.contrast = contrast - 0.01;
	
}

-(void)setBrightness:(float)bri
{
	if (brightness == bri)
		return;
	brightness = bri;
	if (actionsDisabled)
		return;
	BOOL changed = NO;
	for (ACSDGraphic *g in [[[self inspectingGraphicView] selectedGraphics]allObjects])
		if ([g respondsToSelector:@selector(brightness)])
			changed = [g setGraphicBrightness:brightness notify:YES] || changed;
	if (changed)
        [[[self inspectingGraphicView] undoManager] setActionName:@"Set Brightness"];
}

- (IBAction)brightnessUpHit:(id)sender
{
	self.brightness = brightness + 0.01;
}

- (IBAction)brightnessDownHit:(id)sender
{
	self.brightness = brightness - 0.01;
	
}

/*- (IBAction)brightnessTextFieldHit:(id)sender
{
	float brightness = [sender floatValue];
    NSArray *selectedGraphics = [[[self inspectingGraphicView] selectedGraphics]allObjects];
    int ct = [selectedGraphics count];
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
    int ct = [selectedGraphics count];
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
    int ct = [selectedGraphics count];
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
    int ct = [selectedGraphics count];
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
*/
- (IBAction)unsharpmaskRadiusTextFieldHit:(id)sender
{
	float f = [sender floatValue];
	BOOL changed = NO;
	for (ACSDGraphic *g in [[self inspectingGraphicView] selectedGraphics])
		if ([g respondsToSelector:@selector(setGraphicUnsharpmaskRadius:notify:)])
			changed = [(ACSDImage*)g setGraphicUnsharpmaskRadius:f notify:YES] || changed;
	if (changed)
		[[[self inspectingGraphicView] undoManager] setActionName:@"Set Unsharp Mask Radius"];
	if ([unsharpmaskRadiusSlider floatValue] != f)
		[unsharpmaskRadiusSlider setFloatValue:f];
}

- (IBAction)unsharpmaskRadiusSliderHit:(id)sender
{
	float f = [sender floatValue];
	BOOL changed = NO;
	for (ACSDGraphic *g in [[self inspectingGraphicView] selectedGraphics])
		if ([g respondsToSelector:@selector(setGraphicUnsharpmaskRadius:notify:)])
				changed = [(ACSDImage*)g setGraphicUnsharpmaskRadius:f notify:YES] || changed;
	if (changed)
		[[[self inspectingGraphicView] undoManager] setActionName:@"Set Unsharp Mask Radius"];
	if ([unsharpmaskRadiusTextField floatValue] != f)
		[unsharpmaskRadiusTextField setFloatValue:f];
}

- (IBAction)unsharpmaskIntensitySliderHit:(id)sender
{
	float f = [sender floatValue];
	BOOL changed = NO;
	for (ACSDGraphic *g in [[self inspectingGraphicView] selectedGraphics])
		if ([g respondsToSelector:@selector(setGraphicUnsharpmaskIntensity:notify:)])
			changed = [(ACSDImage*)g setGraphicUnsharpmaskIntensity:f notify:YES] || changed;
	if (changed)
		[[[self inspectingGraphicView] undoManager] setActionName:@"Set Unsharp Mask Intensity"];
	if ([unsharpmaskIntensityTextField floatValue] != f)
		[unsharpmaskIntensityTextField setFloatValue:f];
}

- (IBAction)unsharpmaskIntensityTextFieldHit:(id)sender
{
	float f = [sender floatValue];
	BOOL changed = NO;
	for (ACSDGraphic *g in [[self inspectingGraphicView] selectedGraphics])
		if ([g respondsToSelector:@selector(setGraphicUnsharpmaskIntensity:notify:)])
			changed = [(ACSDImage*)g setGraphicUnsharpmaskIntensity:f notify:YES] || changed;
	if (changed)
		[[[self inspectingGraphicView] undoManager] setActionName:@"Set Unsharp Mask Intensity"];
	if ([unsharpmaskIntensitySlider floatValue] != f)
		[unsharpmaskIntensitySlider setFloatValue:f];
}

- (IBAction)gaussianRadiusSliderHit:(id)sender
{
	float f = [sender floatValue];
	BOOL changed = NO;
	for (ACSDGraphic *g in [[self inspectingGraphicView] selectedGraphics])
		if ([g respondsToSelector:@selector(setGraphicGaussianBlurRadius:notify:)])
			changed = [(ACSDImage*)g setGraphicGaussianBlurRadius:f notify:YES] || changed;
	if (changed)
		[[[self inspectingGraphicView] undoManager] setActionName:@"Set Gaussian Blur Radius"];
	if ([gaussianRadiusTextField floatValue] != f)
		[gaussianRadiusTextField setFloatValue:f];
}

-(void)doGaussianRadius:(id)sender
{
	float f = [sender floatValue];
	BOOL changed = NO;
	for (ACSDGraphic *g in [[self inspectingGraphicView] selectedGraphics])
		if ([g respondsToSelector:@selector(setGraphicGaussianBlurRadius:notify:)])
			changed = [(ACSDImage*)g setGraphicGaussianBlurRadius:f notify:YES] || changed;
	if (changed)
		[[[self inspectingGraphicView] undoManager] setActionName:@"Set Gaussian Blur Radius"];
	if ([gaussianRadiusSlider floatValue] != f)
		[gaussianRadiusSlider setFloatValue:f];
}
- (IBAction)gaussianRadiusTextFieldHit:(id)sender
{
	[self performSelectorOnMainThread:@selector(doGaussianRadius:) withObject:sender waitUntilDone:NO];
/*	float f = [sender floatValue];
	BOOL changed = NO;
	for (ACSDGraphic *g in [[self inspectingGraphicView] selectedGraphics])
		if ([g respondsToSelector:@selector(setGraphicGaussianBlurRadius:notify:)])
			changed = [(ACSDImage*)g setGraphicGaussianBlurRadius:f notify:YES] || changed;
	if (changed)
		[[[self inspectingGraphicView] undoManager] setActionName:@"Set Gaussian Blur Radius"];
	if ([gaussianRadiusSlider floatValue] != f)
		[gaussianRadiusSlider setFloatValue:f];*/
}

@end
