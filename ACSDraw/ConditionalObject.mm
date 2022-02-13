//
//  ConditionalObject.mm
//  ACSDraw
//
//  Created by alan on 30/01/07.
//  Copyright 2007 Alan C Smith. All rights reserved.
//

#import "ConditionalObject.h"


@implementation ConditionalObject

+ (ConditionalObject*)conditionalObject:(id)o
{
	ConditionalObject *co = [[ConditionalObject alloc]initWithObject:o];
	return co;
}

-(id)initWithObject:(id)o
{
	if (self = [super init])
		_obj = o;
	return self;
}

NSString *conditionalObjectKey = @"coKey";

- (void) encodeWithCoder:(NSCoder*)coder
{
	if (_obj)
		[coder encodeConditionalObject:_obj forKey:conditionalObjectKey];
}

- (id) initWithCoder:(NSCoder*)coder
{
	self = [self init];
	_obj = [coder decodeObjectForKey:conditionalObjectKey];
	return self;
}

@end
