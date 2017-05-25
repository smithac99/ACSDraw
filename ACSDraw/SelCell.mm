//
//  SelCell.mm
//  ACSDraw
//
//  Created by alan on 22/08/06.
//  Copyright 2006 Alan C Smith. All rights reserved.
//

#import "SelCell.h"
#import "ACSDLayer.h"
#import "LayerTableView.h"


@implementation SelCell

- (NSCellType)type
   {
    return NSNullCellType;
   }

- (void)drawInteriorWithFrame:(NSRect)cellFrame inView:(NSView *)controlView
   {
	BOOL ind = [[self objectValue]boolValue];
	if (ind)
	   {
		[NSGraphicsContext saveGraphicsState];
		[NSBezierPath clipRect:cellFrame];
		NSImage *im = [LayerTableView selectionImage:ind];
		NSSize sz = [im size];
		float xdiff = (cellFrame.size.width - sz.width) / 2.0;
		float ydiff = (cellFrame.size.height - sz.height) / 2.0;
		NSRect r;
		r.origin = NSMakePoint(0.0,0.0);
		r.size = sz;
		[im drawAtPoint:NSMakePoint(cellFrame.origin.x + xdiff,cellFrame.origin.y + ydiff) fromRect:r operation:NSCompositeSourceOver fraction:1.0];
		[NSGraphicsContext restoreGraphicsState];
	   }
   }

- (BOOL)isEditable
   {
    return NO;
   }

@end
