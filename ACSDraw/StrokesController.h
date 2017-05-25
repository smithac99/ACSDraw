//
//  StrokesController.h
//  ACSDraw
//
//  Created by alan on 08/02/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "ViewController.h"
#import "TableViewDelegate.h"

@class ACSDGraphic;

#define START_OF_LINE 0
#define END_OF_LINE 1

@interface StrokesController : ViewController
{
    IBOutlet id arrowRBMatrix;
    IBOutlet id arrowTableView;
    IBOutlet id capRBMatrix;
    IBOutlet id dashText;
    IBOutlet id joinPopUp;
    IBOutlet id lineEndingMinus;
    IBOutlet id lineEndingPlus;
    IBOutlet id lineView;
    IBOutlet id lineWidthSlider;
    IBOutlet id matrixStrokeBox;
    IBOutlet id matrixStrokeRB;
    IBOutlet id phaseText;
    IBOutlet id strokeMinus;
    IBOutlet id strokePlus;
    IBOutlet id strokeSwitch;
    IBOutlet id strokeTableView;
    IBOutlet id strokeWell;
	NSMutableArray *strokeList;
	NSMutableArray *lineEndingList;
    NSView *matrixStrokeBoxSuperView;
}

- (IBAction)arrowRBHit:(id)sender;
- (IBAction)capRBMatrixHit:(id)sender;
- (IBAction)dashTextHit:(id)sender;
- (IBAction)deleteLineEnding:(id)sender;
- (IBAction)duplicateLineEnding:(id)sender;
- (IBAction)duplicateStroke:(id)sender;
- (IBAction)deleteStroke:(id)sender;
- (IBAction)editLineEnding:(id)sender;
- (IBAction)joinPopUpHit:(id)sender;
- (IBAction)lineEndingMinusHit:(id)sender;
- (IBAction)lineEndingPlusHit:(id)sender;
- (IBAction)lineWidthSliderHit:(id)sender;
- (IBAction)phaseTextHit:(id)sender;
- (IBAction)strokeListHit:(id)sender;
- (IBAction)strokeMatrixHit:(id)sender;
- (IBAction)strokeMinusHit:(id)sender;
- (IBAction)strokePlusHit:(id)sender;
- (IBAction)strokeSwitchHit:(id)sender;
- (IBAction)strokeWellHit:(id)sender;

- (NSTableView*)strokeTableView;
- (NSMutableArray*)strokeList;
-(void)refreshStrokes;
-(void)refreshLineEndings;
- (void)setLineEndingList:(NSMutableArray*)f;
- (void)setStrokeList:(NSMutableArray*)s;
- (void)showHideMatrixControls:(ACSDGraphic *)graphic;
- (BOOL)validateMenuItem:(id)menuItem;


@end
