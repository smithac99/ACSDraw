//
//  PalletteViewController.h
//  ACSDraw
//
//  Created by alan on 07/02/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
@class ViewController;
@class StrokesController;
@class FillsController;
@class ShadowsController;
@class AnimationsController;
@class ContainerPalletteController;

@interface PalletteViewController : NSObject 
{
	NSMutableArray *pallettePanels;
	NSMutableDictionary *controllerDict;
	NSArray *topLevelObjects;
}

@property (strong) IBOutlet id triggerController;
@property (strong) IBOutlet id colourController;
@property (strong) IBOutlet id textController;
@property (strong) IBOutlet id docController;
@property (strong) IBOutlet id fillController;
@property (strong) IBOutlet id pagesController;
@property (strong) IBOutlet id sizeController;
@property (strong) IBOutlet id shadowController;
@property (strong) IBOutlet id strokeController;
@property (strong) IBOutlet id animationsController;
@property (strong) IBOutlet id graphicOtherController;

+ (PalletteViewController*)sharedPalletteViewController;
-(void)createPanels;
-(void)activatePanel:(int)i;
-(ContainerPalletteController*)newPanelWithController:(ViewController*)v atTopLeft:(NSPoint)topLeft;
-(void)showAllPallettes;
-(void)hideAllPallettes;

@end
