//
//  TextController.h
//  ACSDraw
//
//  Created by alan on 08/02/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "ViewController.h"

enum
{
	TC_OBJECT_CHANGE = 1,
	TC_ALIGNMENT_CHANGE = 1<<1,
	TC_BOTTOM_MARGIN_CHANGE = 1<<2,
	TC_H_LABEL_CHANGE = 1<<3,
	TC_LABEL_FLIP_CHANGE = 1<<4,
	TC_LEFT_MARGIN_CHANGE = 1<<5,
	TC_NAME_CHANGE = 1<<6,
	TC_RIGHT_MARGIN_CHANGE = 1<<7,
	TC_TEXT_FLOW_CHANGE = 1<<8,
	TC_TEXT_LABEL_CHANGE = 1<<9,
	TC_TOOL_TIP_CHANGE = 1<<10,
	TC_SOURCE_CHANGE = 1<<11,
	TC_TOP_MARGIN_CHANGE = 1<<12,
	TC_V_LABEL_CHANGE = 1<<13,
	TC_FLOWPAD = 1<<14
	
};
@interface TextController : ViewController
{
    IBOutlet id alignmentMatrix;
    IBOutlet id bottomMargin;
    IBOutlet id hLabelSlider;
    IBOutlet id hLabelText;
    IBOutlet id labelFlipped;
    IBOutlet id leftMargin;
    IBOutlet id rightMargin;
    IBOutlet id textFlowMatrix;
    IBOutlet id textLabel;
    IBOutlet id toolTipText;
    IBOutlet id sourceText;
    IBOutlet id topMargin;
    IBOutlet id vLabelSlider;
    IBOutlet id vLabelText;
    IBOutlet id flowPad;

}

- (IBAction)textLabelHit:(id)sender;
- (IBAction)vLabelTextHit:(id)sender;
- (IBAction)hLabelTextHit:(id)sender;
- (IBAction)vLabelSliderHit:(id)sender;
- (IBAction)hLabelSliderHit:(id)sender;
- (IBAction)labelFlippedHit:(id)sender;
- (IBAction)leftMarginHit:(id)sender;
- (IBAction)rightMarginHit:(id)sender;
- (IBAction)topMarginHit:(id)sender;
- (IBAction)bottomMarginHit:(id)sender;
- (IBAction)alignmentMatrixHit:(id)sender;
- (IBAction)textFlowMatrixHit:(id)sender;
- (IBAction)flowPadHit:(id)sender;

@property (retain,nonatomic) NSString *sourcePath,*toolTip;

@end
