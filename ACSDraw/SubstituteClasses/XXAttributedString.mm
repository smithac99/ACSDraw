//
//  XXAttributedString.mm
//  ACSDraw
//
//  Created by alan on 29/05/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "XXAttributedString.h"


@implementation XXAttributedString


- (void) encodeWithCoder:(NSCoder*)coder
{
	[coder encodeObject:self.string forKey:@"string"];
	[coder encodeObject:self.fontName forKey:@"fontName"];
	[coder encodeFloat:self.fontSize forKey:@"fontSize"];
}

- (id) initWithCoder:(NSCoder*)coder
{
	self = [super init];
	self.string = [coder decodeObjectForKey:@"string"];
	self.fontName = [coder decodeObjectForKey:@"fontName"];
	self.fontSize = [coder decodeFloatForKey:@"fontSize"];
	return self;
}

@end
