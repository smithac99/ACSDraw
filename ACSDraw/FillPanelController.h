/* FillPanelController */

#import <Cocoa/Cocoa.h>
#import "PanelController.h"
@class ACSDFill;
@class ACSDGraphic;

@interface FillPanelController : PanelController
{
	IBOutlet id staticView;
	IBOutlet id fillView;
	IBOutlet id fillDisplay;
    IBOutlet id fillMinus;
    IBOutlet id fillPlus;
    IBOutlet id fillRBMatrix;
    IBOutlet id fillTableView;
	IBOutlet id gradientView;
	IBOutlet id gradientControl;
	IBOutlet id gradientDisplay;
	IBOutlet id gradientWell1;
	IBOutlet id graphicOpacitySlider;
	IBOutlet id graphicOpacityText;
    IBOutlet id patternView;
    IBOutlet id patternDisplay;
    IBOutlet id patternModeRBMatrix;
    IBOutlet id scaleSlider;
    IBOutlet id scaleTextField;
    IBOutlet id spacingSlider;
    IBOutlet id offsetSlider;
    IBOutlet id offsetTypeRBMatrix;
    IBOutlet id opacitySlider;
    IBOutlet id spacingTextField;
    IBOutlet id offsetTextField;
    IBOutlet id opacityTextField;
	NSMutableArray *fillList;
}

+ (id)sharedFillPanelController;
- (NSMutableArray*)fillList;
- (void)setFillList:(NSMutableArray*)f;
- (void)reloadFills:(NSNotification *)notification;
- (BOOL)validateMenuItem:(id)menuItem;
- (ACSDFill*)currentFill;

- (IBAction)editPattern:(id)sender;
- (IBAction)deleteFill:(id)sender;
- (IBAction)duplicateFill:(id)sender;
- (IBAction)editPattern:(id)sender;
- (IBAction)fillMinusHit:(id)sender;
- (IBAction)fillPlusHit:(id)sender;
- (IBAction)fillRBHit:(id)sender;
- (IBAction)fillSwitchHit:(id)sender;
- (IBAction)fillWellHit:(id)sender;
- (IBAction)gradientSwitchHit:(id)sender;
- (IBAction)gradientWell1Hit:(id)sender;
- (IBAction)offsetSliderHit:(id)sender;
- (IBAction)offsetTextFieldHit:(id)sender;
- (IBAction)offsetTypeRBMatrixHit:(id)sender;
- (IBAction)opacitySliderHit:(id)sender;
- (IBAction)opacityTextFieldHit:(id)sender;
- (IBAction)patternModeRBMatrixHit:(id)sender;
- (IBAction)scaleSliderHit:(id)sender;
- (IBAction)scaleTextFieldHit:(id)sender;
- (IBAction)spacingSliderHit:(id)sender;
- (IBAction)spacingTextFieldHit:(id)sender;


@end

