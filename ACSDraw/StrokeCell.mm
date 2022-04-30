//
//  StrokeCell.mm
//  ACSDraw
//
//  Created by Alan Smith on Sun Jan 27 2002.
//  Copyright (c) 2001 __MyCompanyName__. All rights reserved.
//

#import "StrokeCell.h"
#import "ACSDStroke.h"
#import "ACSDLineEnding.h"
#import "ACSDGraphic.h"


@implementation StrokeCell

+(NSDictionary*)fontDictionary
{
    static NSDictionary *dict = nil;
    if (! dict)
    {
           dict = @{NSFontAttributeName:[NSFont systemFontOfSize:9]};
    }
    return dict;
}

+(float)textMarginSize
{
	NSSize sz = [@"000.00" sizeWithAttributes:[StrokeCell fontDictionary]];
	return sz.width + 4;
}

- (id)init
{
	if ((self = [super init]))
    {
		textMarginSize = [StrokeCell textMarginSize];
    }
	return self;
}

- (NSCellType)type
{
    return NSNullCellType;
}

- (void)drawInteriorWithFrame:(NSRect)cellFrame inView:(NSView *)controlView
{
    NSPoint pt1,pt2;
	NSRect colRect = cellFrame;
	[NSGraphicsContext saveGraphicsState];
	[NSBezierPath clipRect:cellFrame];
    id obj = [self objectValue];
	if ([obj isKindOfClass:[ACSDStroke class]])
    {
		stroke = obj;
    }
	if (stroke && [stroke colour])
    {
		[[stroke colour]set];
		pt1 = colRect.origin;
		pt1.y += (colRect.size.height / 2.0);
		pt2 = pt1;
		pt2.x += colRect.size.width;
		NSBezierPath *path = [NSBezierPath bezierPath];
		ACSDLineEnding *le1 = [stroke lineStart];
		ACSDLineEnding *le2 = [stroke lineEnd];
		if (le1 && [le1 graphic])
        {
		    float lw = [stroke lineWidth];
			float yscale = lw * [le1 scale];
			float xscale = yscale * [le1 aspect];
			NSRect b = [[le1 graphic]bounds];
			float width = xscale * b.size.width;
			pt1.x += width;
			[NSGraphicsContext saveGraphicsState];
			NSAffineTransform *tf = [NSAffineTransform transform];
			[tf translateXBy:pt1.x yBy:pt1.y];
			[tf concat];
			float x = b.origin.x + b.size.width / 2;
			float y = b.origin.y + b.size.height / 2;
			tf = [NSAffineTransform transform];
			[tf translateXBy:x yBy:y];
			NSAffineTransform *tf2 = [NSAffineTransform transform];
			[tf2 scaleXBy:-xscale yBy:yscale];
			[tf prependTransform:tf2];
			tf2 = [NSAffineTransform transform];
			[tf2 translateXBy:-x yBy:-y];
			[tf appendTransform:tf2];
			[tf concat];
			[[le1 graphic]drawObject:NSZeroRect view:nil options:nil];
			[NSGraphicsContext restoreGraphicsState];
        }
		if (le2 && [le2 graphic])
        {
		    float lw = [stroke lineWidth];
			float yscale = lw * [le2 scale];
			float xscale = yscale * [le2 aspect];
			NSRect b = [[le2 graphic]bounds];
			float width = xscale * b.size.width;
			[NSGraphicsContext saveGraphicsState];
			NSAffineTransform *tf = [NSAffineTransform transform];
			pt2.x -= width;
			[tf translateXBy:pt2.x yBy:pt2.y];
			[tf concat];
			float x = b.origin.x + b.size.width / 2;
			float y = b.origin.y + b.size.height / 2;
			tf = [NSAffineTransform transform];
			[tf translateXBy:x yBy:y];
			NSAffineTransform *tf2 = [NSAffineTransform transform];
			[tf2 scaleXBy:xscale yBy:yscale];
			[tf prependTransform:tf2];
			tf2 = [NSAffineTransform transform];
			[tf2 translateXBy:-x yBy:-y];
			[tf appendTransform:tf2];
			[tf concat];
			[[le2 graphic]drawObject:NSZeroRect view:nil options:nil];
			[NSGraphicsContext restoreGraphicsState];
        }
		[path moveToPoint:pt1];
		[path lineToPoint:pt2];
		[stroke strokePath:path];
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
