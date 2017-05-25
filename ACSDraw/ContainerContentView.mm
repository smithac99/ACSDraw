//
//  ContainerContentView.mm
//  ACSDraw
//
//  Created by alan on 07/02/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "ContainerContentView.h"


@implementation ContainerContentView

- (id)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code here.
    }
    return self;
}

- (void)drawRect:(NSRect)rect 
{
	[[NSColor grayColor]set];
	NSRectFill([self bounds]);
}

@end
