#import "PatternPreview.h"
#import "ACSDGraphic.h"
#import "ACSDPattern.h"
#import "PatternWindowController.h"


@implementation PatternPreview

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
	ACSDPattern *pattern = [[[self window]windowController]updatedTemporaryPattern];
	[pattern setCurrentDrawingDestination:self];
	NSBezierPath *rectPath = [NSBezierPath bezierPathWithRect:[self bounds]];
	[pattern fillPath:rectPath];
   }

@end
