//
//  FillView.m
//  ACSDraw
//
//  Created by alan on 31/01/15.
//
//

#import "FillView.h"
#import "ACSDFill.h"

@implementation FillView

- (void)drawRect:(NSRect)dirtyRect
{
	ACSDFill *fill=nil;
	id obj = [self objectValue];
	if ([obj isKindOfClass:[ACSDFill class]])
		fill = obj;
	NSRect r = NSInsetRect([self bounds],2,4);
	if (fill && [fill canFill])
		[fill fillPath:[NSBezierPath bezierPathWithRect:r]];
	else
	{
		[[NSColor cyanColor] set];
		[NSBezierPath setDefaultLineWidth:1.0];
		[NSBezierPath strokeRect:r];
		NSPoint pt1 = r.origin;
		NSPoint pt2 = pt1;
		pt2.x += r.size.width;
		pt2.y += r.size.height;
		[NSBezierPath setDefaultLineWidth:0.0];
		[NSBezierPath strokeLineFromPoint:pt1 toPoint:pt2];
		float temp = pt1.y;
		pt1.y = pt2.y;
		pt2.y = temp;
		[NSBezierPath strokeLineFromPoint:pt1 toPoint:pt2];
	}
}

@end
