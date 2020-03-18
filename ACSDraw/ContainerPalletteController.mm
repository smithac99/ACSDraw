//
//  ContainerPalletteController.mm
//  ACSDraw
//
//  Created by alan on 07/02/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "ContainerPalletteController.h"
#import "ContainerTabSubview.h"
#import "ViewController.h"
#import "PalletteViewController.h"
#import "ACSDFieldEditor.h"
#import "ACSDTableView.h"
#import "SMTextView.h"

@implementation ContainerPalletteController

+(ContainerPalletteController*)palletteControllerWithIdentifier:(int)i
{
	return [[(ContainerPalletteController*)[ContainerPalletteController alloc]initWithIdentifier:i]autorelease];
}

-(id)initWithIdentifier:(int)i
{
	if (self = [super init])
	{
		NSArray *objs;
		[[NSBundle mainBundle]loadNibNamed:@"PallettePanel" owner:self topLevelObjects:&objs];
		topLevelObjects = [[NSArray arrayWithArray:objs]retain];
		viewControllers = [[NSMutableArray arrayWithCapacity:3]retain];
		tabSubviews = [[NSMutableArray arrayWithCapacity:3]retain];
		currentItem = -1;
		identifier = i;
	}
	return self;
}

-(void)dealloc
{
	[viewControllers release];
	[tabSubviews release];
	[topLevelObjects release];
	[_fieldEditor release];
	[super dealloc];
}

-(int)identifier
{
	return identifier;
}

-(NSWindow*)window
{
	return pallette;
}

-(void)awakeFromNib
{
    [(NSPanel *)[self window] setBecomesKeyOnlyIfNeeded:YES];
}

-(void)adjustWindowForContainerView:(NSView*)cv
{
	NSRect wf = [[containerContentView window]frame];
	NSRect ccvf = [containerContentView frame];
	if (cv)
	{
		NSRect cvf = [cv frame];
		float hDiff = ccvf.size.height - cvf.size.height;
		wf.size.height -= hDiff;
		wf.origin.y += hDiff;
		ccvf.size.height -= hDiff;
		[[containerContentView window]setFrame:wf display:NO];
	}
}

-(void)setCurrentContentView:(NSView*)v
{
	while ([[containerContentView subviews]count] > 0)
		[[[containerContentView subviews]objectAtIndex:0]removeFromSuperview];
	if (v == nil)
		return;
/*	NSRect wf = [[containerContentView window]frame];
	NSRect ccvf = [containerContentView frame];
	NSRect vf = [v frame];
	float hDiff = ccvf.size.height - vf.size.height;
	wf.size.height -= hDiff;
	wf.origin.y += hDiff;
	ccvf.size.height -= hDiff;
	[[containerContentView window]setFrame:wf display:NO];*/
	[self adjustWindowForContainerView:v];
	[containerContentView addSubview:v];
//	[[containerContentView window]invalidateShadow];
//	[[containerContentView window]update];
}

-(void)sortOutTabViews
{
	int count = (int)[tabSubviews count];
	if (count < 1)
		return;
	int tab_width = [containerTabView bounds].size.width / count;
	for (int i = 0;i < count;i++)
	{
		ContainerTabSubview *tsv = [tabSubviews objectAtIndex:i];
		NSRect sframe = [tsv frame];
		sframe.origin.x = i * tab_width;
		sframe.size.width = tab_width;
		[tsv setFrame:sframe];
	}
}

-(void)setActiveItem:(int)i
{
	if (i == currentItem && (i == -1 || [[tabSubviews objectAtIndex:currentItem]active]))
		return;
	if (currentItem >= 0 && currentItem < (signed)[tabSubviews count])
	{
		[[tabSubviews objectAtIndex:currentItem]setActive:NO];
	}
	currentItem = i;
	if (i > -1)
	{
		[[tabSubviews objectAtIndex:currentItem]setActive:YES];
		[self setCurrentContentView:[[viewControllers objectAtIndex:currentItem] contentView]];
		[[viewControllers objectAtIndex:currentItem]becomeActive];
	}
	else
		[self setCurrentContentView:nil];
}

-(void)removeTab:(ContainerTabSubview*)tsv
{
	NSUInteger i = [tabSubviews indexOfObjectIdenticalTo:tsv];
	if (i == NSNotFound)
		return;
/*	if ((signed)i == currentItem)
	{
		int next = [tabSubviews count] - 1;
		if (next == (signed)i)
			next--;
		[self setActiveItem:next];
	}*/
	[tabSubviews removeObjectAtIndex:i];
	[viewControllers removeObjectAtIndex:i];
	if (currentItem >= (signed)[tabSubviews count])
		currentItem--;
	[self setActiveItem:currentItem];
	[tsv removeFromSuperview];
	if ([tabSubviews count] < 1)
		[pallette orderOut:self];
}

-(NSWindow*)detachTab:(ContainerTabSubview*)tsv
{
	NSUInteger i = [tabSubviews indexOfObjectIdenticalTo:tsv];
	if (i == NSNotFound)
		return nil;
	ViewController *vc = [viewControllers objectAtIndex:i];
	[self removeTab:tsv];
	NSRect f = [pallette frame];
	NSPoint topLeft = f.origin;
	topLeft.y = NSMaxY(f);
	return [[PalletteViewController sharedPalletteViewController]newPanelWithController:vc atTopLeft:topLeft];
}

-(void)tabHit:(ContainerTabSubview*)tsv
{
	int i = (int)[tabSubviews indexOfObjectIdenticalTo:tsv];
	[self setActiveItem:i];
}

-(void)registerViewController:(ViewController*)vc
{
	NSUInteger ui = [viewControllers indexOfObjectIdenticalTo:vc];
	if (ui == NSNotFound)
	{
		[viewControllers addObject:vc];
		ContainerTabSubview *tsv = [[[ContainerTabSubview alloc]initWithFrame:[containerTabView bounds] title:[vc title] controller:self]autorelease];
		[tabSubviews addObject:tsv];
		[containerTabView addSubview:tsv];
		[self sortOutTabViews];
		[vc setMainWindow:[NSApp mainWindow]];
		ui = [viewControllers count] - 1;
	}
	[self setActiveItem:(int)ui];
}

- (id)windowWillReturnFieldEditor:(NSWindow *)sender toObject:(id)anObject
{
	if ([anObject respondsToSelector:@selector(tag)] && [anObject tag] == 7)
	{
		if (!self.fieldEditor)
        {
			self.fieldEditor = [[[ACSDFieldEditor alloc] init]autorelease];
			[self.fieldEditor setFieldEditor:YES];
		}
		return self.fieldEditor;
	}
    else if ([anObject isKindOfClass:[ACSDTableView class]])
    {
        if (!self.tableFieldEditor)
        {
            self.tableFieldEditor = [[[SMTextView alloc] init]autorelease];
            [self.tableFieldEditor setFieldEditor:YES];
        }
        self.tableFieldEditor.tableView = anObject;
        return self.tableFieldEditor;
    }
	return nil;
}

@end
