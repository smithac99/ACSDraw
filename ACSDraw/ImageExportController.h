//
//  ImageExportController.h
//  ACSDraw
//
//  Created by alan on 15/01/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface ImageExportController : NSObject 
{
	float compressionQuality,aspect;
	IBOutlet NSSlider *compressionQualitySlider;
	IBOutlet NSPopUpButton *fileTypeMenu;
	IBOutlet NSTextField *compressionQualityTextField,*imageWidthTextField,*imageHeightTextField;
	NSInteger selectedUTI;
	int imageWidth,imageHeight;
	BOOL maintainAspectRatio;
}

@property int imageWidth,imageHeight;
@property BOOL maintainAspectRatio;
@property (retain) IBOutlet NSView *accessoryView;
@property BOOL ignoreSavePanel;



-(void)setControls:(NSMutableDictionary*)exportImageSettings;
-(void)updateSettingsFromControls:(NSMutableDictionary*)exportImageSettings;
- (BOOL)prepareSavePanel:(NSSavePanel *)savePanel;

- (IBAction)fileTypeMenuHit:(id)sender;
- (IBAction)compressionQualitySliderHit:(id)sender;
- (IBAction)compressionQualityTextFieldHit:(id)sender;
-(NSString*)uti;
-(NSString*)chosenSuffix;


@end
