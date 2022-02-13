//
//  FlippableView.mm
//  ACSDraw
//
//  Created by alan on 17/02/06.
//  Copyright 2006 Alan C Smith. All rights reserved.
//

#import "FlippableView.h"


@implementation FlippableView

- (id)initWithFrame:(NSRect)frameRect
{
	if (self = [super initWithFrame:frameRect])
	{
		flipped = NO;
	}
	return self;
}

- (BOOL)isFlipped
{
	return flipped;
}

-(void)setFlipped:(BOOL)f
{
	flipped = f;
}


@end
