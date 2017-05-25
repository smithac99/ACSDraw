//
//  PanelController.mm
//  ACSDraw
//
//  Created by alan on 19/01/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "PanelController.h"
#import "ACSDTableView.h"
#import "MainWindowController.h"
#import "ACSDrawDocument.h"
#import "ACSDGraphic.h"
#import "GraphicView.h"
#import "DragView.h"


@implementation PanelController

- (void)dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
    [super dealloc];
}

-(GraphicView*)inspectingGraphicView
{
	return inspectingGraphicView;
}

- (NSUndoManager*)undoManager
{
	if (inspectingGraphicView)
		return [inspectingGraphicView undoManager];
	return nil;
}

- (BOOL)setActionsDisabled:(BOOL)disabled
{
	BOOL oldVal = actionsDisabled;
	actionsDisabled = disabled;
	return oldVal;
}

- (BOOL)actionsDisabled
{
    return actionsDisabled;
}

- (void)zeroControls
{
}

-(bool)rebuildRequiredSelectedGraphics:(NSArray*)graphics
{
	return NO;
}

-(void)rebuildContent
{
}

-(void)setGraphicControls
{
}

-(void)setDocumentControls:(ACSDrawDocument*)doc
{
}

- (void)setMainWindow:(NSWindow *)mainWindow
{
    if (mainWindow == nil)
	   {
		[self setActionsDisabled:YES];
		[self zeroControls];
		[self setActionsDisabled:NO];
		inspectingGraphicView = nil;
		return;
	   }
	[self setActionsDisabled:YES];
	id controller = [mainWindow windowController];
    if (controller && [controller respondsToSelector:@selector(graphicView)])
        inspectingGraphicView = [controller graphicView];
    else
		inspectingGraphicView = nil;
	[self setDocumentControls:[controller document]];
	[self setGraphicControls];
	[self setActionsDisabled:NO];
}

-(PanelController*)peer
{
	return peer;
}

-(PanelController*)linkedPeer
{
	return linkedPeer;
}

-(void)setLinkedPeer:(PanelController*)pc
{
	linkedPeer = pc;
}

-(void)linkPeer:(PanelController*)pc
{
//	if (pc && linkedPeer)
//		[pc linkPeer:linkedPeer];
//	linkedPeer = pc;
	if (linkedPeer == nil)
		linkedPeer = self;
	[pc setLinkedPeer:linkedPeer];
	[self setLinkedPeer:pc];
}

-(void)unlink
{
	if (linkedPeer == self || linkedPeer == nil)
		return;
	PanelController* before = self;
	while ([before linkedPeer] && [before linkedPeer] != self)
		before = [before linkedPeer];
	if ([before linkedPeer] == self)
	{
		[before setLinkedPeer:[self linkedPeer]];
		[self setLinkedPeer:nil];
	}
}

-(void)alignWith:(PanelController*)pc
{
	NSWindow *w1 = [self window];
	NSRect  w1Frame = [w1 frame];
	float left = NSMinX(w1Frame);
	float top = NSMaxY(w1Frame);
	NSWindow *w2 = [pc window];
	NSRect w2Frame = [w2 frame];
	float xDiff = left - NSMinX(w2Frame);
	float yDiff = top - NSMaxY(w2Frame);
	NSPoint origin = w1Frame.origin;
	origin.x -= xDiff; 
	origin.y -= yDiff; 
    [w1 setFrameOrigin:origin];
}

-(void)dockWith:(PanelController*)pc
{
	[self alignWith:pc];
	[pc linkPeer:self];
}

-(void)dockIfAppropriate:(NSPoint)screenPt
{
	if (linkedPeer && linkedPeer != self)
		return;
	PanelController* p = peer;
	while (p && p != self)
	{
		if ([[p dragView]containsScreenPoint:screenPt])
		{
			[self dockWith:p];
			return;
		}
		p = [p peer];
	}
}

-(NSWindow*)window
{
	return window;
}

- (void)mainWindowChanged:(NSNotification *)notification
{
    [self setMainWindow:[notification object]];
}

- (void)mainWindowResigned:(NSNotification *)notification
{
    [self setMainWindow:nil];
}

- (void)graphicChanged:(NSNotification *)notification
{
    if (inspectingGraphicView)
	   {
        if ([inspectingGraphicView graphicIsSelected:[notification object]])
            [self setGraphicControls];
       }
}

- (void)selectionChanged:(NSNotification *)notification
{
    if ([notification object] == inspectingGraphicView)
		[self setGraphicControls];
}


- (void)awakeFromNib
{
    [(NSPanel *)[self window] setBecomesKeyOnlyIfNeeded:YES];
//    [self setMainWindow:[NSApp mainWindow]];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(mainWindowChanged:) name:NSWindowDidBecomeMainNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(mainWindowResigned:) name:NSWindowDidResignMainNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(graphicChanged:) name:ACSDGraphicDidChangeNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(selectionChanged:) name:ACSDGraphicViewSelectionDidChangeNotification object:nil];
}

-(void)setUpTitles
{
	float totWidth = 0.0;
	int noItems = 0;
	PanelController *p = self;
	do
	{
		totWidth += [[p dragView]minTitleWidth];
		p = [p peer];
		noItems++;
	} while (p && p!= self);
	float spare = (PANEL_WIDTH - 20 - totWidth) / noItems;
	float l = 0;
	p = self;
	do
	{
		[[p dragView]setLeft:l];
		l += ([[p dragView]minTitleWidth] + spare);
		[[p dragView]setRight:l-4];
		[[p dragView]setNeedsDisplay:YES];
		p = [p peer];
	} while (p && p!= self);
}

-(float)minPeerY
{
	float minY = NSMaxY([[NSScreen mainScreen]visibleFrame]);
	PanelController *p = self;
	do
	{
		minY = fmin(minY,[[p window]frame].origin.y);
		p = [p peer];
	} while (p && p!= self);
	return minY;
}

-(DragView*)dragView
{
	return dragView;
}

- (BOOL)control:(NSControl *)control textView:(NSTextView *)textView doCommandBySelector:(SEL)command
{
	if (command == @selector(insertNewline:))
	   {
		[[self window]makeFirstResponder:control];
		return YES;
	   }
	return NO;
}

-(int)rowForContextualMenu
{
	return rowForContextualMenu;
}

-(int)displayRowForContextualMenu
{
	return displayRowForContextualMenu;
}

-(void)setRowForContextualMenu:(int)i
{
	rowForContextualMenu = i;
	displayRowForContextualMenu = i;
}

-(ACSDTableView*)tableViewForContextualMenu
{
	return tableViewForContextualMenu;
}

-(void)setTableViewForContextualMenu:(ACSDTableView*)tv
{
	tableViewForContextualMenu = tv;
}

- (void)unsetRowForContextualMenu:(NSNotification *)notification
{
	displayRowForContextualMenu = -1;
	[[self tableViewForContextualMenu] reDisplayRow:rowForContextualMenu];
}


@end
