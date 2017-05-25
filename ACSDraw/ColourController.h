//
//  ColourController.h
//  ACSDraw
//
//  Created by alan on 08/02/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "ViewController.h"
#import "HistogramView.h"

@interface ColourController : ViewController 
{
	IBOutlet NSSlider *unsharpmaskRadiusSlider;
	IBOutlet id unsharpmaskRadiusTextField;
	IBOutlet NSSlider *unsharpmaskIntensitySlider;
	IBOutlet id unsharpmaskIntensityTextField;
	IBOutlet NSSlider *gaussianRadiusSlider;
	IBOutlet id gaussianRadiusTextField;
	IBOutlet NSButton *saturationUp,*saturationDown;
	IBOutlet HistogramView *histogramView;
	float saturation,brightness,contrast;
	BOOL saturationEnabled,brightnessEnabled,contrastEnabled;
}

@property (nonatomic) float saturation,brightness,contrast;
@property BOOL saturationEnabled,brightnessEnabled,contrastEnabled;

- (IBAction)saturationUpHit:(id)sender;
- (IBAction)saturationDownHit:(id)sender;
- (IBAction)brightnessUpHit:(id)sender;
- (IBAction)brightnessDownHit:(id)sender;
- (IBAction)contrastUpHit:(id)sender;
- (IBAction)contrastDownHit:(id)sender;
- (IBAction)resetButtonHit:(id)sender;
- (IBAction)unsharpmaskRadiusTextFieldHit:(id)sender;
- (IBAction)unsharpmaskRadiusSliderHit:(id)sender;
- (IBAction)unsharpmaskIntensitySliderHit:(id)sender;
- (IBAction)unsharpmaskIntensityTextFieldHit:(id)sender;
- (IBAction)gaussianRadiusSliderHit:(id)sender;
- (IBAction)gaussianRadiusTextFieldHit:(id)sender;

@end
