//
//  ColourCell.mm
//  ACSDraw
//
//  Created by Alan Smith on Mon Jan 28 2002.
//  Copyright (c) 2001 __MyCompanyName__. All rights reserved.
//

#import "ColourCell.h"
#import "ACSDFill.h"
#import "FillListTableSource.h"


@implementation ColourCell

- (NSCellType)type
   {
    return NSNullCellType;
   }


- (void)drawInteriorWithFrame:(NSRect)cellFrame inView:(NSView *)controlView
   {
	ACSDFill *fill=nil;
	id obj = [self objectValue];
	if ([obj isKindOfClass:[ACSDFill class]])
		fill = obj;
	NSRect r = NSInsetRect(cellFrame,2,4);
	if (fill && [fill canFill])
		[fill fillPath:[NSBezierPath bezierPathWithRect:r]];
	else
	   {
		[[NSColor cyanColor] set];
		[NSBezierPath setDefaultLineWidth:1.0];
		[NSBezierPath strokeRect:cellFrame];
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
