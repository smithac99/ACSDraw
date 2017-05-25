//
//  ShadowCell.mm
//  ACSDraw
//
//  Created by alan on Sun Jan 25 2004.
//  Copyright (c) 2004 __MyCompanyName__. All rights reserved.
//

#import "ShadowCell.h"
#import "ShadowType.h"


@implementation ShadowCell

- (void)drawInteriorWithFrame:(NSRect)cellFrame inView:(NSView *)controlView
   {
	ShadowType *shad = nil;
//	if ([self objectValue] && [[self objectValue] isKindOfClass:[ShadowType class]])
//		shad = [self objectValue];
	id obj = [self objectValue];
	if ([obj isKindOfClass:[ShadowType class]])
		shad = obj;		
    NSPoint pt1,pt2;
	NSRect colRect = cellFrame;
	[NSGraphicsContext saveGraphicsState];
	[NSBezierPath clipRect:cellFrame];
	if (shad && [shad itsShadow])
	   {
		float leftx = colRect.origin.x;
		float halfWidth = colRect.size.width / 2;
		if ([shad xOffset] < 0.0)
			leftx += halfWidth; 
		float bottomy = colRect.origin.y;
		float halfHeight = colRect.size.height / 2;
		if ([shad yOffset] < 0.0)
			bottomy += halfHeight;
		NSRect sRect = NSMakeRect(leftx,bottomy,halfWidth,halfHeight);
		[[shad itsShadow]set];
		[[NSColor blackColor]set];
		NSRectFill(sRect);
	   }
	else
	   {
		[[NSColor cyanColor] set];
		[NSBezierPath setDefaultLineWidth:1.0];
		[NSBezierPath strokeRect:colRect];
		pt1 = colRect.origin;
		pt2 = pt1;
		pt2.x += colRect.size.width;
		pt2.y += colRect.size.height;
		[NSBezierPath setDefaultLineWidth:0.0];
		[NSBezierPath strokeLineFromPoint:pt1 toPoint:pt2];
		float temp = pt1.y;
		pt1.y = pt2.y;
		pt2.y = temp;
		[NSBezierPath strokeLineFromPoint:pt1 toPoint:pt2];
	   }
	[NSGraphicsContext restoreGraphicsState];
   }

- (BOOL)isEditable
   {
    return NO;
   }

@end
