//
//  SelView.m
//  ACSDraw
//
//  Created by alan on 31/01/15.
//
//

#import "SelView.h"
#import "LayerTableView.h"

@implementation SelView

- (void)drawRect:(NSRect)dirtyRect
{
    [super drawRect:dirtyRect];
	BOOL ind = [[self objectValue]boolValue];
	if (ind)
	{
		[NSGraphicsContext saveGraphicsState];
		[NSBezierPath clipRect:[self bounds]];
		NSImage *im = [LayerTableView selectionImage:ind];
		NSSize sz = [im size];
		float xdiff = ([self bounds].size.width - sz.width) / 2.0;
		float ydiff = ([self bounds].size.height - sz.height) / 2.0;
		NSRect r;
		r.origin = NSMakePoint(0.0,0.0);
		r.size = sz;
        [im drawAtPoint:NSMakePoint([self bounds].origin.x + xdiff,[self bounds].origin.y + ydiff) fromRect:r operation:NSCompositingOperationSourceOver fraction:1.0];
		[NSGraphicsContext restoreGraphicsState];
	}
}

@end
