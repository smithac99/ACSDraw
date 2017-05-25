#import "LineEndPreview.h"
#import "ACSDGraphic.h"
#import "LineEndingWindowController.h"
#import "AffineTransformAdditions.h"

@implementation LineEndPreview

- (id)initWithFrame:(NSRect)frameRect
   {
	if ((self = [super initWithFrame:frameRect]) != nil) {
		// Add initialization code here
	}
	return self;
   }

- (void)drawRect:(NSRect)rect
   {
    [[NSColor whiteColor] set];
	NSRectFill(rect);
    [[NSColor blackColor] set];
	NSRect r = [self bounds];
    NSPoint pt1,pt2;
	pt1 = r.origin;
	pt1.y += (r.size.height / 2.0);
	pt2 = pt1;
	pt2.x += (r.size.width/2);
	NSBezierPath *path = [NSBezierPath bezierPath];
	float lw = [[[[self window]windowController]zoomSlider]floatValue];
	ACSDLineEnding *lineEnding = [[[self window]windowController]temporaryLineEnding];
	if (lineEnding && [lineEnding graphic])
	   {
		[lineEnding drawLineEndingAtPoint:pt2 angle:getAngleForPoints(pt2,pt1) lineWidth:lw];
	   }
	[path moveToPoint:pt1];
	[path lineToPoint:pt2];
	[path setLineWidth:lw];
	[path stroke];
   }
@end
