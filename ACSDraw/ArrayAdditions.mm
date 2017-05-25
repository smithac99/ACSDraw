//
//  ArrayAdditions.mm
//  ACSDraw
//
//  Created by alan on 01/05/06.
//  Copyright 2006 Alan C Smith. All rights reserved.
//

#import "ArrayAdditions.h"


@implementation NSArray(ArrayAdditions)

- (void)reverseMakeObjectsPerformSelector:(SEL)theSelector
   {
	NSMethodSignature *aSignature;
	NSInvocation *anInvocation;
    NSEnumerator *objEnum = [self reverseObjectEnumerator];
    id obj;
    while ((obj = [objEnum nextObject]) != nil)
	   {
		aSignature = [[obj class] instanceMethodSignatureForSelector:theSelector];
		anInvocation = [NSInvocation invocationWithMethodSignature:aSignature];
		[anInvocation setSelector:theSelector];
		[anInvocation setTarget:obj];
		[anInvocation invoke];
	   }
   }

- (void)reverseMakeObjectsPerformSelector:(SEL)theSelector withObject:(__unsafe_unretained id)arg
   {
	NSMethodSignature *aSignature;
	NSInvocation *anInvocation;
    NSEnumerator *objEnum = [self reverseObjectEnumerator];
    id obj;
    while ((obj = [objEnum nextObject]) != nil)
	   {
		aSignature = [[obj class] instanceMethodSignatureForSelector:theSelector];
		anInvocation = [NSInvocation invocationWithMethodSignature:aSignature];
		[anInvocation setSelector:theSelector];
		[anInvocation setTarget:obj];
		[anInvocation setArgument:&arg atIndex:2];
		[anInvocation invoke];
	   }
   }

- (BOOL)andMakeObjectsPerformSelector:(SEL)theSelector
   {
	NSMethodSignature *aSignature;
	NSInvocation *anInvocation;
	
    NSEnumerator *objEnum = [self objectEnumerator];
    id obj;
    while ((obj = [objEnum nextObject]) != nil)
	   {
		aSignature = [[obj class] instanceMethodSignatureForSelector:theSelector];
		anInvocation = [NSInvocation invocationWithMethodSignature:aSignature];
		[anInvocation setSelector:theSelector];
		[anInvocation setTarget:obj];
		[anInvocation invoke];
		BOOL temp;
		[anInvocation getReturnValue:&temp];
		if (!temp)
			return false;
	   }
	return true;
   }

- (void)makeObjectsPerformSelector:(SEL)theSelector withObject:(__unsafe_unretained id)arg1 andObject:(__unsafe_unretained id)arg2
   {
	NSMethodSignature *aSignature;
	NSInvocation *anInvocation;	
    NSEnumerator *objEnum = [self objectEnumerator];
    id obj;
    while ((obj = [objEnum nextObject]) != nil)
	   {
		if ([obj respondsToSelector:theSelector])
		   {
			aSignature = [[obj class] instanceMethodSignatureForSelector:theSelector];
			anInvocation = [NSInvocation invocationWithMethodSignature:aSignature];
			[anInvocation setSelector:theSelector];
			[anInvocation setTarget:obj];
			[anInvocation setArgument:&arg1 atIndex:2];
			[anInvocation setArgument:&arg2 atIndex:3];
			[anInvocation invoke];
		   }
	   }
   }

- (BOOL)andMakeObjectsPerformSelector:(SEL)theSelector withObject:(__unsafe_unretained id)arg
   {
	NSMethodSignature *aSignature;
	NSInvocation *anInvocation;	
    NSEnumerator *objEnum = [self objectEnumerator];
    id obj;
    while ((obj = [objEnum nextObject]) != nil)
	   {
		if (![obj respondsToSelector:theSelector])
			return NO;
		aSignature = [[obj class] instanceMethodSignatureForSelector:theSelector];
		anInvocation = [NSInvocation invocationWithMethodSignature:aSignature];
		[anInvocation setSelector:theSelector];
		[anInvocation setTarget:obj];
		[anInvocation setArgument:&arg atIndex:2];
		[anInvocation invoke];
		BOOL temp;
		[anInvocation getReturnValue:&temp];
		if (!temp)
			return false;
	   }
	return true;
   }

- (BOOL)orMakeObjectsPerformSelector:(SEL)theSelector
   {
	NSMethodSignature *aSignature;
	NSInvocation *anInvocation;
	
    NSEnumerator *objEnum = [self objectEnumerator];
    id obj;
    while ((obj = [objEnum nextObject]) != nil)
	   {
		aSignature = [[obj class] instanceMethodSignatureForSelector:theSelector];
		anInvocation = [NSInvocation invocationWithMethodSignature:aSignature];
		[anInvocation setSelector:theSelector];
		[anInvocation setTarget:obj];
		[anInvocation invoke];
		BOOL temp;
		[anInvocation getReturnValue:&temp];
		if (temp)
			return true;
	   }
	return false;
   }

- (BOOL)orMakeAllObjectsPerformSelector:(SEL)theSelector
   {
	BOOL result = NO;
	NSMethodSignature *aSignature;
	NSInvocation *anInvocation;
	
    NSEnumerator *objEnum = [self objectEnumerator];
    id obj;
    while ((obj = [objEnum nextObject]) != nil)
	   {
		aSignature = [[obj class] instanceMethodSignatureForSelector:theSelector];
		anInvocation = [NSInvocation invocationWithMethodSignature:aSignature];
		[anInvocation setSelector:theSelector];
		[anInvocation setTarget:obj];
		[anInvocation invoke];
		BOOL temp;
		[anInvocation getReturnValue:&temp];
		result |= temp;
	   }
	return result;
   }

- (BOOL)orMakeObjectsPerformSelector:(SEL)theSelector withObject:(__unsafe_unretained id)arg
   {
	NSMethodSignature *aSignature;
	NSInvocation *anInvocation;	
    NSEnumerator *objEnum = [self objectEnumerator];
    id obj;
    while ((obj = [objEnum nextObject]) != nil)
	   {
		if ([obj respondsToSelector:theSelector])
		   {
			aSignature = [[obj class] instanceMethodSignatureForSelector:theSelector];
			anInvocation = [NSInvocation invocationWithMethodSignature:aSignature];
			[anInvocation setSelector:theSelector];
			[anInvocation setTarget:obj];
			[anInvocation setArgument:&arg atIndex:2];
			[anInvocation invoke];
			BOOL temp;
			[anInvocation getReturnValue:&temp];
			if (temp)
				return true;
		   }
	   }
	return false;
   }

- (BOOL)orMakeAllObjectsPerformSelector:(SEL)theSelector withObject:(__unsafe_unretained id)arg
   {
	BOOL result = NO;
	NSMethodSignature *aSignature;
	NSInvocation *anInvocation;	
    NSEnumerator *objEnum = [self objectEnumerator];
    id obj;
    while ((obj = [objEnum nextObject]) != nil)
	   {
		if ([obj respondsToSelector:theSelector])
		   {
			aSignature = [[obj class] instanceMethodSignatureForSelector:theSelector];
			anInvocation = [NSInvocation invocationWithMethodSignature:aSignature];
			[anInvocation setSelector:theSelector];
			[anInvocation setTarget:obj];
			[anInvocation setArgument:&arg atIndex:2];
			[anInvocation invoke];
			BOOL temp;
			[anInvocation getReturnValue:&temp];
			result |= temp;
		   }
	   }
	return result;
   }

-(NSArray*)objectsWhichRespond:(BOOL)response toSelector:(SEL)theSelector
   {
	NSMutableArray* arr = [NSMutableArray arrayWithCapacity:[self count]];
	NSMethodSignature *aSignature;
	NSInvocation *anInvocation;	
    NSEnumerator *objEnum = [self objectEnumerator];
    id obj;
    while ((obj = [objEnum nextObject]) != nil)
	   {
		if ([obj respondsToSelector:theSelector])
		   {
			aSignature = [[obj class] instanceMethodSignatureForSelector:theSelector];
			anInvocation = [NSInvocation invocationWithMethodSignature:aSignature];
			[anInvocation setSelector:theSelector];
			[anInvocation setTarget:obj];
			[anInvocation invoke];
			BOOL temp;
			[anInvocation getReturnValue:&temp];
			if (temp)
				[arr addObject:obj];
		   }
	   }
	return arr;
   }

- (id)firstObjectWhichRespondsYesToSelector:(SEL)theSelector withObject:(__unsafe_unretained id)arg
   {
	NSMethodSignature *aSignature;
	NSInvocation *anInvocation;
    NSEnumerator *objEnum = [self objectEnumerator];
    id obj;
    while ((obj = [objEnum nextObject]) != nil)
	   {
		aSignature = [[obj class] instanceMethodSignatureForSelector:theSelector];
		anInvocation = [NSInvocation invocationWithMethodSignature:aSignature];
		[anInvocation setSelector:theSelector];
		[anInvocation setTarget:obj];
		[anInvocation setArgument:&arg atIndex:2];
		[anInvocation invoke];
		BOOL temp;
		[anInvocation getReturnValue:&temp];
		if (temp)
			return obj;
	   }
	return nil;
   }

- (id)lastObjectWhichRespondsYesToSelector:(SEL)theSelector withObject:(__unsafe_unretained id)arg
   {
	NSMethodSignature *aSignature;
	NSInvocation *anInvocation;
    NSEnumerator *objEnum = [self reverseObjectEnumerator];
    id obj;
    while ((obj = [objEnum nextObject]) != nil)
	   {
		aSignature = [[obj class] instanceMethodSignatureForSelector:theSelector];
		anInvocation = [NSInvocation invocationWithMethodSignature:aSignature];
		[anInvocation setSelector:theSelector];
		[anInvocation setTarget:obj];
		[anInvocation setArgument:&arg atIndex:2];
		[anInvocation invoke];
		BOOL temp;
		[anInvocation getReturnValue:&temp];
		if (temp)
			return obj;
	   }
	return nil;
   }


-(NSArray*)copiedObjects
   {
	NSMutableArray* arr = [NSMutableArray arrayWithCapacity:[self count]];
    NSEnumerator *objEnum = [self objectEnumerator];
    id obj;
    while ((obj = [objEnum nextObject]) != nil)
		[arr addObject:[obj copy]];
	return arr;
   }

-(NSIndexSet*)indexesOfObjectsWhichRespond:(BOOL)response toSelector:(SEL)theSelector
   {
	NSMutableIndexSet *results = [[NSMutableIndexSet alloc]init];
	NSMethodSignature *aSignature;
	NSInvocation *anInvocation;	
    NSEnumerator *objEnum = [self objectEnumerator];
    id obj;
    for (int i = 0;(obj = [objEnum nextObject]) != nil;i++)
	   {
		if ([obj respondsToSelector:theSelector])
		   {
			aSignature = [[obj class] instanceMethodSignatureForSelector:theSelector];
			anInvocation = [NSInvocation invocationWithMethodSignature:aSignature];
			[anInvocation setSelector:theSelector];
			[anInvocation setTarget:obj];
			[anInvocation invoke];
			BOOL temp;
			[anInvocation getReturnValue:&temp];
			if (temp == response)
				[results addIndex:i];
		   }
	   }
	return results;
   }

-(BOOL)allObjectsAreKindOfClass:(Class)aClass
   {
    NSEnumerator *objEnum = [self objectEnumerator];
    id obj;
    while ((obj = [objEnum nextObject]) != nil)
		if (![obj isKindOfClass:aClass])
			return NO;
	return YES;
   }

-(id)objectAtReversedIndex:(NSUInteger)index
{
    return [self objectAtIndex:[self count] - 1 - index];
}
@end
