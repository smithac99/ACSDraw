#import "LineView.h"
#import "ACSDStroke.h"
#import "ACSDLineEnding.h"
#import "ACSDGraphic.h"
#import "StrokePanelController.h"

@implementation LineView

- (id)initWithFrame:(NSRect)frameRect
{
	if ((self = [super initWithFrame:frameRect]) != nil) {
		// Add initialization code here
	}
	return self;
}

- (void)drawStroke:(ACSDStroke*)stroke
   {
    NSPoint pt1,pt2;
	NSRect colRect = [self bounds];
	[NSGraphicsContext saveGraphicsState];
//	[NSBezierPath clipRect:cellFrame];
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
	[NSGraphicsContext restoreGraphicsState];
   }

- (void)drawRect:(NSRect)rect
   {
    [[NSColor whiteColor] set];
	NSRectFill(rect);
	NSMutableArray *strokeList = [controller strokeList];
	if (strokeList && [strokeList count] > 0)
	   {
	    NSTableView *strokeTableView = [controller strokeTableView];
		NSInteger sel;
		if ((sel = [strokeTableView selectedRow]) >= 0)
			[self drawStroke:[strokeList objectAtIndex:sel]];
	   }
   }

@end
