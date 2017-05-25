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
	ConditionalObject *co = [[[ConditionalObject alloc]initWithObject:o]autorelease];
	return co;
   }

-(id)initWithObject:(id)o
   {
	if (self = [super init])
		obj = o;
	return self;
   }

NSString *conditionalObjectKey = @"coKey";

- (void) encodeWithCoder:(NSCoder*)coder
   {
	if (obj)
		[coder encodeConditionalObject:obj forKey:conditionalObjectKey];
   }

- (id) initWithCoder:(NSCoder*)coder
   {
	self = [self init];
	obj = [coder decodeObjectForKey:conditionalObjectKey];
	return self;
   }

-(id)obj
   {
	return obj;
   }

@end
