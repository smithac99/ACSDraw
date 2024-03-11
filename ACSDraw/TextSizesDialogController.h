//
//  TextSizesDialogController.h
//  ACSDraw
//
//  Created by Alan Smith on 11/03/2024.
//

#import <Foundation/Foundation.h>
#import "MainWindowController.h"


@interface TextSizesDialogController : NSObject
{
}
@property (weak) IBOutlet MainWindowController *windowController;
@property (weak) IBOutlet NSPanel *textPanel;
@property (weak) IBOutlet NSSlider *fontSizeSlider;
@property (weak) IBOutlet NSSlider *lineHeightSlider;
@property (weak) IBOutlet NSSlider *trackingSlider;

-(void)showDialog;

@end

