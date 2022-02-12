//
//  ObjectView.mm
//  ACSDraw
//
//  Created by alan on 15/02/06.
//  Copyright 2006 Alan C Smith. All rights reserved.
//

#import "ObjectView.h"


@implementation ObjectView

- (id)initWithObject:(ACSDGraphic*)object
{
	NSRect displayBounds = [object displayBounds];
	graphic = object;
	xOffset = displayBounds.origin.x;
	yOffset = displayBounds.origin.y;
	displayBounds.origin.x = 0.0;
	displayBounds.origin.y = 0.0;
    self = [super initWithFrame:displayBounds];
    return self;
}

- (void)drawRect:(NSRect)rect
{
	NSAffineTransform *tf = [NSAffineTransform transform];
	[tf translateXBy:-xOffset yBy:-yOffset];
	[tf concat];
	[graphic drawObject:rect view:nil options:nil];
}

- (NSPoint)offset
{
	return NSMakePoint(xOffset,yOffset);
}	


@end
