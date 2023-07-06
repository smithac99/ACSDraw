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

- (void)keyDown:(NSEvent *)event
{
    NSString *str = [event charactersIgnoringModifiers];
    unichar uc = 0;
    if ([str length] > 0)
        uc = [str characterAtIndex:0];

    if (uc == 9)
    {
        NSLog(@"got there");
    }
    else
        [self interpretKeyEvents:[NSArray arrayWithObject:event]];
}

@end
