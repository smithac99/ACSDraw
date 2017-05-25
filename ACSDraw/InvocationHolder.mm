//
//  InvocationHolder.mm
//  ACSDraw
//
//  Created by alan on 19/03/06.
//  Copyright 2006 Alan C Smith. All rights reserved.
//

#import "InvocationHolder.h"


@implementation InvocationHolder


+(InvocationHolder*)holderForInvocation:(NSInvocation*)i name:(NSString*)n
{
	return [[InvocationHolder alloc]initWithInvocation:i name:n];
}

-(id)initWithInvocation:(NSInvocation*)i name:(NSString*)n
{
	if (self = [super init])
	{
		self.invocation = i;
		self.name = n;
	}
	return self;
}

@end
