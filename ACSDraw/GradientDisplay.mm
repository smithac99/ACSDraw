#import "GradientDisplay.h"

@implementation GradientDisplay

- (void)drawRect:(NSRect)aRect
   {
	if (self.gradient)
		[self.gradient fillPath:[NSBezierPath bezierPathWithRect:[self bounds]]];
	else
	   {
		[[NSColor clearColor]set];
		NSRectFill(aRect);
	   }
   }

@end
