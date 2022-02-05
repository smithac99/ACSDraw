//
//  FillsController.h
//  ACSDraw
//
//  Created by alan on 08/02/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "ViewController.h"
@class ACSDFill;

enum
{
	FC_SOURCE_CHANGE=1,
	FC_GRAPHIC_SELECTION_CHANGE=2,
    FC_FILL_SELECTION_CHANGE=4,
    FC_FILL_LIST_CHANGE=8
};

@interface FillsController : ViewController 
{
	IBOutlet id staticView;
	IBOutlet id fillView;
    __weak IBOutlet NSColorWell *fillDisplay;
    IBOutlet id fillMinus;
    IBOutlet id fillPlus;
    IBOutlet id fillRBMatrix;
    IBOutlet ACSDTableView *fillTableView;
        
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
}

@property (nonatomic) int gradientType;
@property BOOL linearMode;
@property (nonatomic) float gradientX,gradientY;

- (NSMutableArray*)fillList;
- (BOOL)validateMenuItem:(id)menuItem;
- (ACSDFill*)currentFill;

- (IBAction)editPattern:(id)sender;
- (IBAction)deleteFill:(id)sender;
- (IBAction)duplicateFill:(id)sender;
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
-(IBAction)showFillUsers:(id)sender;

@end
