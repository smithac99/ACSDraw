//
//  ViewController.mm
//  ACSDraw
//
//  Created by alan on 07/02/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "ViewController.h"
#import "ACSDrawDocument.h"
#import "GraphicView.h"
#import "ACSDGraphic.h"
#import "ACSDTableView.h"


@implementation ViewController

-(id)initWithTitle:(NSString*)t
{
	if ((self = [super init]))
	{
		title = [t retain];
	}
	return self;
}

-(void)dealloc
{
	if (title)
		[title release];
	self.contentView = nil;
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[super dealloc];
}

-(void)changeAll
{
	self.changed = ~0;
}

-(void)addChange:(NSUInteger)ch
{
	self.changed = self.changed | ch;
}

-(void)addChangeFromNotification:(NSNotification*)notif
{
	NSUInteger val = [[[notif userInfo]objectForKey:@"param"]integerValue];
	[self addChange:val];
}

-(void)updateControls
{
	
}
-(void)update:(NSNotification *)notification
{
	if (self.changed)
	{
		[self updateControls];
		self.changed = 0;
	}
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

-(NSString*)title
{
	return title;
}

-(void)setGraphicControls
{
}

-(void)setDocumentControls:(ACSDrawDocument*)doc
{
}

- (void)zeroControls
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

- (void)mainWindowChanged:(NSNotification *)notification
{
    [self setMainWindow:[notification object]];
	[self changeAll];
}

- (void)mainWindowResigned:(NSNotification *)notification
{
    [self setMainWindow:nil];
	[self changeAll];
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
	[self changeAll];
}


- (void)awakeFromNib
{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(mainWindowChanged:) name:NSWindowDidBecomeMainNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(mainWindowResigned:) name:NSWindowDidResignMainNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(graphicChanged:) name:ACSDGraphicDidChangeNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(selectionChanged:) name:ACSDGraphicViewSelectionDidChangeNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(selectionChanged:) name:ACSDPageChanged object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(update:) name:NSWindowDidUpdateNotification object:[self.contentView window]];
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

-(void)becomeActive
{
}

-(BOOL)uSetValue:(id)val forKey:(id)key obj:(id)obj changeid:(NSUInteger)changeid invalidateFlags:(NSInteger)invalFlags
{
	if (![[obj valueForKey:key]isEqual:val])
	{
		[[[inspectingGraphicView undoManager] prepareWithInvocationTarget:self] uSetValue:[obj valueForKey:key] forKey:key obj:obj changeid:changeid invalidateFlags:invalFlags];
		[obj setValue:val forKey:key invalidateFlags:invalFlags];
		[self addChange:changeid];
		return YES;
	}
	return NO;
}

-(void)updateObjects:(NSArray*)objects withValue:(id)val forKey:(id)key changeid:(NSUInteger)changeid invalidateFlags:(NSInteger)invalFlags actionName:(NSString*)actionName
{
	if (!actionsDisabled)
	{
		BOOL changed = NO;
		for (ACSDGraphic *g in objects)
			changed = [self uSetValue:val forKey:key obj:g changeid:changeid invalidateFlags:invalFlags] || changed;
		if (changed)
			[[inspectingGraphicView undoManager] setActionName:actionName];
	}
}

@end
