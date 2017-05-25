//
//  GreyView.mm
//  ACSDraw
//
//  Created by alan on 19/01/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "GreyView.h"


@implementation GreyView

- (id)initWithFrame:(NSRect)frame 
{
    self = [super initWithFrame:frame];
    if (self) 
	{
        // Initialization code here.
    }
    return self;
}

- (void)drawRect:(NSRect)rect 
{
	[[NSColor colorWithCalibratedWhite:0.8 alpha:1.0]set];
	NSRectFill(rect);
}

@end
