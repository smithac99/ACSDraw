//
//  XXColor.mm
//  ACSDraw
//
//  Created by alan on 29/05/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "XXColor.h"


@implementation XXColor

- (void) encodeWithCoder:(NSCoder*)coder
{
	[coder encodeFloat:_r forKey:@"r"];
	[coder encodeFloat:_g forKey:@"g"];
	[coder encodeFloat:_b forKey:@"b"];
	[coder encodeFloat:_a forKey:@"a"];
}

- (id) initWithCoder:(NSCoder*)coder
{
	self = [super init];
	_r = [coder decodeFloatForKey:@"r"];
	_g = [coder decodeFloatForKey:@"g"];
	_b = [coder decodeFloatForKey:@"b"];
	_a = [coder decodeFloatForKey:@"a"];
	return self;
}

@end
