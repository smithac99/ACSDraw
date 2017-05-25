/* ColourPanelController */

#import <Cocoa/Cocoa.h>
#import "PanelController.h"

@interface ColourPanelController : PanelController
{
	IBOutlet NSSlider *brightnessSlider;
	IBOutlet id brightnessTextField;
	IBOutlet NSSlider *contrastSlider;
	IBOutlet id contrastTextField;
	IBOutlet NSSlider *saturationSlider;
	IBOutlet id saturationTextField;
}

- (IBAction)saturationTextFieldHit:(id)sender;
- (IBAction)saturationSliderHit:(id)sender;
- (IBAction)brightnessTextFieldHit:(id)sender;
- (IBAction)brightnessSliderHit:(id)sender;
- (IBAction)contrastTextFieldHit:(id)sender;
- (IBAction)contrastSliderHit:(id)sender;


@end
