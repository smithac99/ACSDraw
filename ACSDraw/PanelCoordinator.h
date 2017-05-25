//
//  PanelCoordinator.h
//  ACSDraw
//
//  Created by alan on 22/01/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class ColourPanelController;
@class DocPanelController;
@class FillPanelController;
@class PagesPanelController; 
@class SizePanelController;
@class ShadowPanelController;
@class StrokePanelController;
@class TextPanelController;

extern NSString *ACSDShowCoordinatesNotification;

@interface PanelCoordinator : NSObject 
{
	IBOutlet ColourPanelController *colourPanelController;
	IBOutlet DocPanelController *docPanelController;
	IBOutlet FillPanelController *fillPanelController;
	IBOutlet PagesPanelController *pagesPanelController;
	IBOutlet SizePanelController *sizePanelController;
	IBOutlet ShadowPanelController *shadowPanelController;
	IBOutlet StrokePanelController *strokePanelController;
	IBOutlet TextPanelController *textPanelController;
}

+ (id)sharedPanelCoordinator;
-(void)setUpPanels;
-(void)showPanel:(int)i;

@end
