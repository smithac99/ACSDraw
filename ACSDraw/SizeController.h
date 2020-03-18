//
//  SizeController.h
//  ACSDraw
//
//  Created by alan on 08/02/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "ViewController.h"

extern NSString *ACSDShowCoordinatesNotification;

enum
{
	SC_OBJECT_CHANGE = 1,
	SC_ROTATION_CHANGE = 2,
	SC_OPACITY_CHANGE = 4,
	SC_SCALEX_CHANGE = 8,
	SC_SCALEY_CHANGE = 16,
	SC_ALIGN_CHANGE = 32
};


@interface SizeController : ViewController
{
    IBOutlet NSView *coordinateView;
    IBOutlet NSSlider *cornerRadiusSlider;
    IBOutlet NSTextField *cornerRadiusText;
    IBOutlet NSView *cornerRadiusView;
    IBOutlet id dist;
    IBOutlet id distLabel;
    IBOutlet id dX;
    IBOutlet id dXLabel;
    IBOutlet id dY;
    IBOutlet id dYLabel;
    IBOutlet id graphicOpacitySlider;
    IBOutlet id graphicOpacityText;
    IBOutlet id gridCellHeight;
    IBOutlet id gridCellWidth;
    IBOutlet id gridCols;
    IBOutlet id gridRows;
    IBOutlet id gridMode;
    IBOutlet NSView *positionView;
    IBOutlet id positionX;
    IBOutlet id positionY;
    IBOutlet id pressureSlider;
    IBOutlet id scaleX;
    IBOutlet id scaleY;
    IBOutlet id sizeHeight;
    IBOutlet id sizeWidth;
    IBOutlet id smoothnessSlider;
    IBOutlet id smoothnessView;
    IBOutlet id theta;
    IBOutlet id thetaLabel;
    IBOutlet id xCoord;
    IBOutlet id yCoord;
    IBOutlet id widthRight;
    IBOutlet id heightTop;
	IBOutlet id rotationText;
    IBOutlet NSView *gridView;
    IBOutlet id leftX;
    IBOutlet id bottomY;
    BOOL showsWidth,showsHeight,showsLeft,showsBottom;

}

@property (nonatomic)float rotation,opacity,xScale,yScale;
@property (assign) IBOutlet NSButton *alignButton;
@property (assign) IBOutlet NSMatrix *alignMatrix;

- (IBAction)cornerRadiusSliderHit:(id)sender;
- (IBAction)cornerRadiusTextHit:(id)sender;
- (IBAction)heightHit:(id)sender;
- (IBAction)gridCellHeightHit:(id)sender;
- (IBAction)gridCellWidthHit:(id)sender;
- (IBAction)gridColsHit:(id)sender;
- (IBAction)gridModeHit:(id)sender;
- (IBAction)gridRowsHit:(id)sender;
- (IBAction)pressureSliderHit:(id)sender;
-(IBAction)rotationHit:(id)sender;
-(IBAction)xScaleHit:(id)sender;
-(IBAction)yScaleHit:(id)sender;
- (IBAction)smoothnessSliderHit:(id)sender;
- (IBAction)widthHit:(id)sender;
- (IBAction)xHit:(id)sender;
- (IBAction)yHit:(id)sender;
- (IBAction)widthRightHit:(id)sender;
- (IBAction)heightTopHit:(id)sender;
-(void)adjustKeyLoop;

@end
