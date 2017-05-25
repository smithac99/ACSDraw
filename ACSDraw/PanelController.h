//
//  PanelController.h
//  ACSDraw
//
//  Created by alan on 19/01/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
@class GraphicView;
@class ACSDTableView;
@class DragView;
@class ACSDrawDocument;

#define PANEL_WIDTH 282

@interface PanelController : NSObject 
{
	int rowForContextualMenu,displayRowForContextualMenu;
	ACSDTableView *tableViewForContextualMenu;
	GraphicView *inspectingGraphicView;
	NSWindow *window;
	BOOL actionsDisabled;
    IBOutlet DragView *dragView;
	IBOutlet PanelController *peer;
	PanelController *linkedPeer;
}

-(GraphicView*)inspectingGraphicView;
-(NSWindow*)window;
- (void)zeroControls;
-(void)setGraphicControls;
-(void)setDocumentControls:(ACSDrawDocument*)doc;
-(void)setRowForContextualMenu:(int)i;
-(int)displayRowForContextualMenu;
-(int)rowForContextualMenu;
-(ACSDTableView*)tableViewForContextualMenu;
-(void)setTableViewForContextualMenu:(ACSDTableView*)tv;
- (void)unsetRowForContextualMenu:(NSNotification *)notification;
-(bool)rebuildRequiredSelectedGraphics:(NSArray*)graphics;
-(void)rebuildContent;
- (BOOL)setActionsDisabled:(BOOL)disabled;
- (BOOL)actionsDisabled;
-(PanelController*)peer;
-(PanelController*)linkedPeer;
-(void)linkPeer:(PanelController*)pc;
-(void)dockWith:(PanelController*)pc;
-(DragView*)dragView;
-(void)setUpTitles;
- (void)setMainWindow:(NSWindow *)mainWindow;
-(float)minPeerY;
-(void)alignWith:(PanelController*)pc;
-(void)setLinkedPeer:(PanelController*)pc;
-(void)unlink;
-(void)dockIfAppropriate:(NSPoint)screenPt;

@end
