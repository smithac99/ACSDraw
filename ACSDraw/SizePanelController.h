/* SizePanelController */

#import <Cocoa/Cocoa.h>
#import "PanelController.h"

extern NSString *ACSDShowCoordinatesNotification;

@interface SizePanelController : PanelController
{
    IBOutlet NSView *coordinateView;
    IBOutlet NSSlider *cornerRadiusSlider;
    IBOutlet NSTextField *cornerRadiusText;
    IBOutlet NSView *cornerRadiusView;
    IBOutlet id dX;
    IBOutlet id dXLabel;
    IBOutlet id dY;
    IBOutlet id dYLabel;
    IBOutlet id graphicOpacitySlider;
    IBOutlet id graphicOpacityText;
    IBOutlet id matrixCellHeight;
    IBOutlet id matrixCellWidth;
    IBOutlet id matrixCols;
    IBOutlet id matrixRows;
    IBOutlet id matrixFixedCellSize;
    IBOutlet id matrixFixedNoRows;
    IBOutlet id matrixSizeBox;
    IBOutlet NSView *positionView;
    IBOutlet id positionX;
    IBOutlet id positionY;
    IBOutlet id pressureSlider;
    IBOutlet id rotationText;
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
    NSView *matrixView;
}

+ (id)sharedSizePanelController;

- (IBAction)cornerRadiusSliderHit:(id)sender;
- (IBAction)cornerRadiusTextHit:(id)sender;
- (IBAction)graphicOpacitySliderHit:(id)sender;
- (IBAction)graphicOpacityTextHit:(id)sender;
- (IBAction)heightHit:(id)sender;
- (IBAction)matrixCellHeightHit:(id)sender;
- (IBAction)matrixCellWidthHit:(id)sender;
- (IBAction)matrixColsHit:(id)sender;
- (IBAction)matrixFixedCellSizeHit:(id)sender;
- (IBAction)matrixFixedNoCellsHit:(id)sender;
- (IBAction)matrixRowsHit:(id)sender;
- (IBAction)pressureSliderHit:(id)sender;
- (IBAction)rotationTextHit:(id)sender;
- (IBAction)scaleXHit:(id)sender;
- (IBAction)scaleYHit:(id)sender;
- (IBAction)smoothnessSliderHit:(id)sender;
- (IBAction)widthHit:(id)sender;
- (IBAction)xHit:(id)sender;
- (IBAction)yHit:(id)sender;

@end
