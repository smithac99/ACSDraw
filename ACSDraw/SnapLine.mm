//
//  SnapLine.mm
//  ACSDraw
//
//  Created by alan on 01/04/06.
//  Copyright 2006 Alan C Smith. All rights reserved.
//

#import "SnapLine.h"


@implementation SnapLine

-(id)initWithGraphicView:(NSView*)gView orientation:(int)orn
   {
	if (self = [super init])
	   {
		graphicView = gView;
		location = 0.0;
		orientation = orn;
		visible = NO;
		colour = [[NSColor cyanColor]retain];
	   }	
	return self;
   }

-(void)dealloc
   {
	if (colour)
		[colour release];
	[super dealloc];
   }

-(float)location
   {
	return location;
   }

-(void)setLocation:(float)loc
   {
	if (!(graphicView && visible))
	   {
		location = loc;
		return;
	   }
	[graphicView setNeedsDisplayInRect:displayRect];
	location = loc;
	displayRect = [self rectForDisplay];
	[graphicView setNeedsDisplayInRect:displayRect];
   }

-(NSPoint)fromPoint
   {
	NSPoint pt;
	if (orientation == SNAPLINE_HORIZONTAL)
	   {
		pt.x = [graphicView bounds].origin.x;
		pt.y = location;
	   }
	else
	   {
		pt.x = location;
		pt.y = [graphicView bounds].origin.y;
	   }
	return pt;
   }

-(NSPoint)toPoint
   {
	NSPoint pt;
	if (orientation == SNAPLINE_HORIZONTAL)
	   {
		pt.x = NSMaxX([graphicView bounds]);
		pt.y = location;
	   }
	else
	   {
		pt.x = location;
		pt.y = NSMaxY([graphicView bounds]);
	   }
	return pt;
   }

-(NSRect)rectForDisplay
   {
	NSRect r = [graphicView bounds];
	if (orientation == SNAPLINE_HORIZONTAL)
	   {
		r.origin.y = location - 1.0;
		r.size.height = 2.0;
	   }
	else
	   {
		r.origin.x = location - 1.0;
		r.size.width = 2.0;
	   }
	return r;
   }

- (BOOL)visible
   {
	return visible;
   }

- (void)setVisible:(BOOL)d
   {
	if (d == visible)
		return;
	if (visible)
		[graphicView setNeedsDisplayInRect:displayRect];
	visible = d;
	if (visible)
	   {
		displayRect = [self rectForDisplay];
		[graphicView setNeedsDisplayInRect:displayRect];
	   }
   }

- (void)drawRect:(NSRect)aRect
   {
	if (visible && NSIntersectsRect(aRect, displayRect))
	   {
		[NSGraphicsContext saveGraphicsState];
		[NSBezierPath setDefaultLineWidth:0.0];
		[colour set];
		[NSBezierPath strokeLineFromPoint:[self fromPoint] toPoint:[self toPoint]];
		[NSGraphicsContext restoreGraphicsState];
	   }
   }

@end
