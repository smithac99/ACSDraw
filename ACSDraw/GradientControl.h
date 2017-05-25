/* GradientControl */

#import <Cocoa/Cocoa.h>
#import "ACSDGradient.h"

@interface GradientControl : NSView
   {
	NSRulerView *rulerView;
	NSRulerMarker *selectedRulerMarker;
	ACSDGradient *gradient;
	IBOutlet NSView *gradientDisplay;
	IBOutlet NSColorWell *gradientColourWell;
	IBOutlet NSSlider *gradientAngleSlider;
	IBOutlet NSTextField *gradientAngleTextField;
	CGFloat margin;
   }

-(void)setGradient:(ACSDGradient*)g;
-(void)setup;
- (IBAction)gradientAngleSliderHit:(id)sender;
- (IBAction)gradientAngleTextFieldHit:(id)sender;
- (IBAction)gradientWellHit:(id)sender;

@end
