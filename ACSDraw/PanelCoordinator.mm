//
//  PanelCoordinator.mm
//  ACSDraw
//
//  Created by alan on 22/01/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "PanelCoordinator.h"

#import "ColourPanelController.h"
#import "DocPanelController.h"
#import "FillPanelController.h"
#import "PagesPanelController.h" 
#import "SizePanelController.h"
#import "ShadowPanelController.h"
#import "StrokePanelController.h"
#import "TextPanelController.h"

PanelCoordinator *_sharedPanelCoordinator = nil;
//NSString *ACSDShowCoordinatesNotification = @"ACSDShowCoordinates";

@implementation PanelCoordinator

+ (id)sharedPanelCoordinator
{
	if (!_sharedPanelCoordinator)
		_sharedPanelCoordinator = [[PanelCoordinator alloc]init];
    return _sharedPanelCoordinator;
}

-(id)init
{
	if (self = [super init])
	{
		[NSBundle loadNibNamed:@"Inspector" owner:self];
	}
	return self;
}

-(void)linkAllPeersFor:(PanelController*)head
{
	[head linkPeer:nil];
	[head linkPeer:head];
	PanelController *pc = [head peer];
	while (pc != head)
	{
		[pc linkPeer:nil];
		[head linkPeer:pc];
		pc = [pc linkedPeer];
	}
}

-(void)homePanels
{
	NSRect  screenFrame = [[NSScreen mainScreen]visibleFrame];
	NSWindow *w = [sizePanelController window];
	NSRect  windowFrame = [w frame];
	NSPoint origin = windowFrame.origin;
	origin.x += NSMaxX(screenFrame) - NSMaxX(windowFrame); 
	origin.y += NSMaxY(screenFrame) - NSMaxY(windowFrame); 
    [w setFrameOrigin:origin];
	[docPanelController dockWith:sizePanelController];
	[pagesPanelController dockWith:sizePanelController];
	[sizePanelController setUpTitles];
    [docPanelController setMainWindow:[NSApp mainWindow]];
    [pagesPanelController setMainWindow:[NSApp mainWindow]];
    [sizePanelController setMainWindow:[NSApp mainWindow]];
    [[pagesPanelController window] orderFront:self];
    [[docPanelController window] orderFront:self];
    [[sizePanelController window] orderFront:self];
	origin.y = [sizePanelController minPeerY]-5.0;
	w = [strokePanelController window];
	windowFrame = [w frame];
	origin.y -= windowFrame.size.height;
    [w setFrameOrigin:origin];
	[strokePanelController linkPeer:strokePanelController];
	[fillPanelController dockWith:strokePanelController];
	[shadowPanelController dockWith:strokePanelController];
	[strokePanelController setUpTitles];
    [strokePanelController setMainWindow:[NSApp mainWindow]];
    [fillPanelController setMainWindow:[NSApp mainWindow]];
    [shadowPanelController setMainWindow:[NSApp mainWindow]];
    [[shadowPanelController window] orderFront:self];
    [[fillPanelController window] orderFront:self];
    [[strokePanelController window] orderFront:self];
	origin.y = [strokePanelController minPeerY]-5.0;
	w = [textPanelController window];
	windowFrame = [w frame];
	origin.y -= windowFrame.size.height;
    [w setFrameOrigin:origin];
	[textPanelController linkPeer:textPanelController];
	[colourPanelController dockWith:textPanelController];
	[textPanelController setUpTitles];
    [textPanelController setMainWindow:[NSApp mainWindow]];
    [colourPanelController setMainWindow:[NSApp mainWindow]];
    [[colourPanelController window] orderFront:self];
    [[textPanelController window] orderFront:self];
}

-(void)setUpPanels
{
	[self homePanels];
}

-(void)showPanel:(int)i
{
	switch(i)
	{
		case 0: [[sizePanelController window]orderFront:self];
			break;
		case 1: [[docPanelController window]orderFront:self];
			break;
		case 2: [[pagesPanelController window]orderFront:self];
			break;
		case 3: [[strokePanelController window]orderFront:self];
			break;
		case 4: [[fillPanelController window]orderFront:self];
			break;
		case 5: [[shadowPanelController window]orderFront:self];
			break;
		case 6: [[textPanelController window]orderFront:self];
			break;
		case 7: [[colourPanelController window]orderFront:self];
			break;
			
	}
}

@end
