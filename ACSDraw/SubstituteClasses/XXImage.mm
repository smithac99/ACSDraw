//
//  XXImage.mm
//  ACSDraw
//
//  Created by alan on 30/05/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "XXImage.h"


@implementation XXImage

- (void) encodeWithCoder:(NSCoder*)coder
{
	[coder encodeObject:data forKey:@"data"];
}

- (id) initWithCoder:(NSCoder*)coder
{
	self = [super init];
	data = [coder decodeObjectForKey:@"data"];
	return self;
}


@end
