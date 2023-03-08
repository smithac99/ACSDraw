//
//  PalletteViewController.mm
//  ACSDraw
//
//  Created by alan on 07/02/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//


#import "PalletteViewController.h"
#import "ContainerPalletteController.h"
#import "WindowAdditions.h"
#import "SizeController.h"
#import "StrokesController.h"


@implementation PalletteViewController

+ (PalletteViewController*)sharedPalletteViewController
{
	static PalletteViewController* _sharedPalletteViewController = nil;
	if (!_sharedPalletteViewController)
		_sharedPalletteViewController = [[PalletteViewController alloc]init];
    return _sharedPalletteViewController;
}

-(id)init
{
	if ((self = [super init]))
	{
		NSArray *arr = nil;
		[[NSBundle mainBundle] loadNibNamed:@"Pallettes" owner:self topLevelObjects:&arr];
		topLevelObjects = [NSArray arrayWithArray:arr];
		pallettePanels = [NSMutableArray arrayWithCapacity:10];
		controllerDict = [NSMutableDictionary dictionaryWithCapacity:10];
	}
	return self;
}

-(ContainerPalletteController*)createPanel
{
	ContainerPalletteController* c = [ContainerPalletteController palletteControllerWithIdentifier:(int)[pallettePanels count]];
	[pallettePanels addObject:c];
	return c;
}

-(float)checkY:(float)y
{
    if (y > 40)
        return y;
    return 40;
}
-(void)createPanels
{
	NSRect  screenFrame = [[NSScreen mainScreen]visibleFrame];
	NSPoint nextTopRight = NSMakePoint(NSMaxX(screenFrame),NSMaxY(screenFrame));
	ContainerPalletteController* c = [self createPanel];
	[c registerViewController:self.docController];
	[controllerDict setObject:c forKey:[self.docController title]];
	[c registerViewController:self.pagesController];
	[controllerDict setObject:c forKey:[self.pagesController title]];
	[c registerViewController:self.sizeController];
	[controllerDict setObject:c forKey:[self.sizeController title]];
	[[c window]setFrameTopRightPoint:nextTopRight];
	[[c window] orderFront:self];
	[self.sizeController adjustKeyLoop];
	nextTopRight.y = [self checkY:nextTopRight.y -[[c window]frame].size.height];
	c = [self createPanel];
	[c registerViewController:self.strokeController];
	[controllerDict setObject:c forKey:[self.strokeController title]];
	[c registerViewController:self.fillController];
	[controllerDict setObject:c forKey:[self.fillController title]];
	[c registerViewController:self.shadowController];
	[controllerDict setObject:c forKey:[self.shadowController title]];
	[[c window]setFrameTopRightPoint:nextTopRight];
	[[c window] orderFront:self];
    nextTopRight.y = [self checkY:nextTopRight.y -[[c window]frame].size.height];
	c = [self createPanel];
	[c registerViewController:self.triggerController];
	[controllerDict setObject:c forKey:[self.triggerController title]];
	[c registerViewController:self.colourController];
	[controllerDict setObject:c forKey:[self.colourController title]];
	[c registerViewController:self.textController];
	[controllerDict setObject:c forKey:[self.textController title]];
	[[c window]setFrameTopRightPoint:nextTopRight];
	[[c window] orderFront:self];
    nextTopRight.y = [self checkY:nextTopRight.y -[[c window]frame].size.height];
	c = [self createPanel];
	[c registerViewController:self.animationsController];
	[controllerDict setObject:c forKey:[self.animationsController title]];
	[[c window]setFrameTopRightPoint:nextTopRight];
	[[c window] orderFront:self];
    [c registerViewController:self.graphicOtherController];
    [controllerDict setObject:c forKey:[self.graphicOtherController title]];
    [[c window]setFrameTopRightPoint:nextTopRight];
    [[c window] orderFront:self];
    nextTopRight.y = [self checkY:nextTopRight.y -[[c window]frame].size.height];
}

-(void)activateController:(ViewController*)v
{
	ContainerPalletteController* c = [controllerDict objectForKey:[v title]];
	if (c)
	{
		[c registerViewController:v];
		[[c window] orderFront:self];
	}
}

-(ContainerPalletteController*)newPanelWithController:(ViewController*)v atTopLeft:(NSPoint)topLeft
{
	ContainerPalletteController* c = [self createPanel];
	[c registerViewController:v];
	[controllerDict setObject:c forKey:[v title]];
	[[c window]setFrameTopLeftPoint:topLeft];
	[[c window] orderFront:self];
    return c;
}

-(ViewController*)panelController:(int)i
{
    switch(i)
    {
        case 0: return self.sizeController;
            break;
        case 1: return self.docController;
            break;
        case 2: return self.pagesController;
            break;
        case 3: return self.strokeController;
            break;
        case 4: return self.fillController;
            break;
        case 5: return self.shadowController;
            break;
        case 6: return self.textController;
            break;
        case 7: return self.colourController;
            break;
        case 8: return self.animationsController;
            break;
        case 9: return self.graphicOtherController;
            break;
    }
    return nil;
}

-(void)activatePanel:(int)i
{
    [self activateController:[self panelController:i]];
}

-(void)showPanel:(int)i
{
    [[[[self panelController:i]contentView]window]orderFront:nil];
}

-(void)hidePanel:(int)i
{
    [[[[self panelController:i]contentView]window]orderOut:nil];
}

-(void)showAllPallettes
{
    for (int i = 0;i < 10;i++)
        [self showPanel:i];
}

-(void)hideAllPallettes
{
    for (int i = 0;i < 10;i++)
    {
        ViewController *vc = [self panelController:i];
        vc.wasShowing = vc.visible;
        [self hidePanel:i];
    }
}


@end
