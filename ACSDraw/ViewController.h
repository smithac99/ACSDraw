//
//  ViewController.h
//  ACSDraw
//
//  Created by alan on 07/02/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
@class GraphicView;
@class ACSDTableView;

@interface ViewController : NSObject
{
	NSString *title;
	__weak GraphicView *inspectingGraphicView;
	BOOL actionsDisabled,rebuildPending;
	int rowForContextualMenu,displayRowForContextualMenu;
	ACSDTableView *tableViewForContextualMenu;
}

@property (retain) IBOutlet NSView *contentView;

@property NSUInteger changed;
@property BOOL fieldsEditable,wasShowing;

-(id)initWithTitle:(NSString*)t;
-(NSString*)title;
-(NSView*)contentView;
-(GraphicView*)inspectingGraphicView;
- (void)setMainWindow:(NSWindow *)mainWindow;
- (BOOL)setActionsDisabled:(BOOL)disabled;
- (BOOL)actionsDisabled;
-(NSUndoManager*)undoManager;
-(void)becomeActive;
-(void)changeAll;
-(void)addChange:(NSUInteger)ch;
-(void)addChangeFromNotification:(NSNotification*)notif;
-(BOOL)uSetValue:(id)val forKey:(id)key obj:(id)obj changeid:(NSUInteger)changeid invalidateFlags:(NSInteger)invalFlags;
-(void)updateObjects:(NSArray*)objects withValue:(id)val forKey:(id)key changeid:(NSUInteger)changeid invalidateFlags:(NSInteger)invalFlags actionName:(NSString*)actionName;
-(void)updateControls;
-(void)update:(NSNotification *)notification;
- (void)mainWindowChanged:(NSNotification *)notification;
- (void)mainWindowResigned:(NSNotification *)notification;

-(void)setRowForContextualMenu:(int)i;
-(ACSDTableView*)tableViewForContextualMenu;
-(void)setTableViewForContextualMenu:(ACSDTableView*)tv;
- (void)unsetRowForContextualMenu:(NSNotification *)notification;
-(BOOL)visible;

@end
