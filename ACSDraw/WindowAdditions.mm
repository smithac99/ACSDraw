//
//  WindowAdditions.mm
//  ACSDraw
//
//  Created by alan on 08/02/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "WindowAdditions.h"


@implementation NSWindow(WindowAdditions)

-(void)setFrameTopRightPoint:(NSPoint)point
{
	NSRect f = [self frame];
	f.origin.x = point.x - f.size.width;
	f.origin.y = point.y - f.size.height;
	[self setFrame:f display:NO];
}

@end
