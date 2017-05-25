//
//  PositionalObject.mm
//  ACSDraw
//
//  Created by Alan Smith on Sat Feb 02 2002.
//  Copyright (c) 2001 __MyCompanyName__. All rights reserved.
//

#import "PositionalObject.h"


@implementation PositionalObject

@synthesize position,object;

- (id)initWithPosition:(NSInteger)pos object:(id)obj
{
	if (self = [super init])
	{
		position = pos;
		object = [obj retain];
	}
	return self;
}

- (void)dealloc
{
	[object release];
	[super dealloc];
}

- (void) encodeWithCoder:(NSCoder*)coder
{
	[coder encodeInteger:position forKey:@"PositionalObject_Position"];
	[coder encodeObject:object forKey:@"PositionalObject_Object"];
}

- (id) initWithCoder:(NSCoder*)coder
{
	position = [coder decodeIntegerForKey:@"PositionalObject_Position"];
	object = [[coder decodeObjectForKey:@"PositionalObject_Object"]retain];
	return self;
}

@end
