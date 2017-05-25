//
//  XXImageAdditions.mm
//  ACSDraw
//
//  Created by alan on 30/05/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "XXImageAdditions.h"


@implementation XXImage(XXImageAdditions)

+(id)XXImageWithNSImage:(NSImage*)im
{
	return [[XXImage alloc]initWithNSImage:im];
}

-(id)initWithNSImage:(NSImage*)im
{
	if (self = [super init])
	{
		data = [im TIFFRepresentation];
	}
	return self;
}

@end
