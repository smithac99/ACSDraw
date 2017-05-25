/* TextPanelController */

#import <Cocoa/Cocoa.h>
#import "PanelController.h"

@interface TextPanelController : PanelController
{
    IBOutlet id alignmentMatrix;
    IBOutlet id bottomMargin;
    IBOutlet id hLabelSlider;
    IBOutlet id hLabelText;
    IBOutlet id labelFlipped;
    IBOutlet id leftMargin;
    IBOutlet id nameField;
    IBOutlet id rightMargin;
    IBOutlet id textFlowMatrix;
    IBOutlet id textLabel;
    IBOutlet id toolTipText;
    IBOutlet id topMargin;
    IBOutlet id vLabelSlider;
    IBOutlet id vLabelText;
    IBOutlet id flowPad;

}

+ (id)sharedTextPanelController;
- (IBAction)nameFieldHit:(id)sender;
- (IBAction)textLabelHit:(id)sender;
- (IBAction)vLabelTextHit:(id)sender;
- (IBAction)hLabelTextHit:(id)sender;
- (IBAction)vLabelSliderHit:(id)sender;
- (IBAction)hLabelSliderHit:(id)sender;
- (IBAction)labelFlippedHit:(id)sender;
- (IBAction)toolTipTextHit:(id)sender;
- (IBAction)leftMarginHit:(id)sender;
- (IBAction)rightMarginHit:(id)sender;
- (IBAction)topMarginHit:(id)sender;
- (IBAction)bottomMarginHit:(id)sender;
- (IBAction)alignmentMatrixHit:(id)sender;
- (IBAction)textFlowMatrixHit:(id)sender;
- (IBAction)flowPadHit:(id)sender;

@end
