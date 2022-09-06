//
//  ArrowCell.mm
//  ACSDraw
//
//  Created by alan on Wed Jan 28 2004.
//  Copyright (c) 2004 __MyCompanyName__. All rights reserved.
//

#import "ArrowCell.h"
#import "ACSDLineEnding.h"
#import "ACSDGraphic.h"


@implementation ArrowCell

- (void)drawInteriorWithFrame:(NSRect)cellFrame inView:(NSView *)controlView
   {
	ACSDLineEnding *arrow = nil;
	NSRect colRect = cellFrame;
	[NSGraphicsContext saveGraphicsState];
       //[NSGraphicsContext setGraphicsState:0];
	[NSBezierPath clipRect:cellFrame];
	if ([self objectValue] && [[self objectValue] isKindOfClass:[ACSDLineEnding class]])
	   {
		arrow = [self objectValue];
		if ([[arrow graphics]count] > 0)
		   {
			[[NSColor colorWithCalibratedRed:1.0 green:0.8 blue:0.8 alpha:1.0]set];
			NSRectFill(colRect);
		   }
	   }
    NSPoint pt1,pt2;
	if (arrow && [arrow graphic])
	   {
		ACSDGraphic *graphic = [arrow graphic];
		NSAffineTransform *tf = [NSAffineTransform transform];
		[tf translateXBy:colRect.origin.x + 3 yBy:colRect.origin.y + colRect.size.height / 2];
		[tf concat];
		NSRect bounds = [graphic bounds];
		colRect = NSInsetRect(cellFrame,3.0,3.0);
		float ratio = (bounds.size.width * [arrow aspect]) / colRect.size.width;
		float ratio2 = bounds.size.height / colRect.size.height;
		if (ratio < ratio2)
			ratio = ratio2;
		float x = bounds.origin.x + bounds.size.width / 2;
		float y = bounds.origin.y + bounds.size.height / 2;
		tf = [NSAffineTransform transform];
		[tf translateXBy:x yBy:y];
		NSAffineTransform *tf2 = [NSAffineTransform transform];
		[tf2 scaleXBy:[arrow aspect]/ratio yBy:1/ratio];
		[tf prependTransform:tf2];
		tf2 = [NSAffineTransform transform];
		[tf2 translateXBy:-x yBy:-y];
		[tf appendTransform:tf2];
		[NSGraphicsContext saveGraphicsState];
		[tf concat];
		[[NSColor blackColor]set];
//		tf = [NSAffineTransform transform];
//		[tf translateXBy:(bounds.origin.x) yBy:(bounds.origin.y + bounds.size.height / 2)];
//		[tf concat];
		[graphic drawObject:colRect view:nil options:nil];
		[NSGraphicsContext restoreGraphicsState];
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
//	[self drawFocusRingFrame:cellFrame controlView:controlView];
	[NSGraphicsContext restoreGraphicsState];
   }

- (BOOL)isEditable
   {
    return NO;
   }


@end
