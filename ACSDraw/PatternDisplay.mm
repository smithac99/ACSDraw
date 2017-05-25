#import "PatternDisplay.h"

@implementation PatternDisplay

- (id)initWithFrame:(NSRect)frameRect
   {
	if ((self = [super initWithFrame:frameRect]) != nil)
	   {
		pattern = nil;
	   }
	return self;
   }

- (void)drawRect:(NSRect)rect
   {
	[[NSColor whiteColor]set];
	NSRectFill(rect);
	if (pattern)
	   {
		FlippableView *tempV = [pattern setCurrentDrawingDestination:self];
		[pattern fillPath:[NSBezierPath bezierPathWithRect:rect]];
		[pattern setCurrentDrawingDestination:tempV];
	   }
   }

- (void)setPattern:(ACSDPattern*)patt
   {
	pattern = patt; 
   }

@end
