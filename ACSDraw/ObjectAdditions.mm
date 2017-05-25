//
//  ObjectAdditions.mm
//  ACSDraw
//
//  Created by alan on 29/01/07.
//  Copyright 2007 Alan C Smith. All rights reserved.
//

#import "ObjectAdditions.h"


@implementation NSObject(ObjectAdditions)

-(void)performSelector:(SEL)theSelector withObjectsFromArray:(NSArray*)array
   {
	NSMethodSignature *aSignature;
	NSInvocation *anInvocation;
	
    NSEnumerator *objEnum = [array objectEnumerator];
    __unsafe_unretained id obj;
    while ((obj = [objEnum nextObject]) != nil)
	   {
		aSignature = [[self class] instanceMethodSignatureForSelector:theSelector];
		anInvocation = [NSInvocation invocationWithMethodSignature:aSignature];
		[anInvocation setSelector:theSelector];
		[anInvocation setTarget:self];
		[anInvocation setArgument:&obj atIndex:2];
		[anInvocation invoke];
	   }
   }

@end
