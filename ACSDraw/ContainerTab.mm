//
//  ContainerTab.mm
//  ACSDraw
//
//  Created by alan on 07/02/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "ContainerTab.h"


@implementation ContainerTab

-(id)initWithTitle:(NSString*)t
{
	if (self = [super init])
	{
		title = [t copy];
	}
	return self;
}

-(void)setFrame:(NSRect)r
{
	frame = r;
}

@end
