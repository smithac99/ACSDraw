//
//  SelectionSet.mm
//  ACSDraw
//
//  Created by Alan Smith on Sun Feb 03 2002.
//  Copyright (c) 2001 __MyCompanyName__. All rights reserved.
//

#import "SelectionSet.h"
#import "ACSDGraphic.h"


@implementation SelectionSet

- (id)initWithCapacity:(unsigned)numItems
   {
	if (self = [super init])
		objects = [[NSMutableSet alloc]initWithCapacity:numItems];
	return self;
   }

- (void)dealloc
   {
	if (objects)
		[objects release];
	[super dealloc];
   }

- (void)addObject:(id)anObject
   {
	if ([anObject isKindOfClass:[ACSDGraphic class]])
		[anObject setSelectionTimeStamp:[NSDate date]];
	[objects addObject:anObject];
   }

- (void)addObjectsFromArray:(NSArray*)array
   {
	for (id a in array)
		[self addObject:a];
   }

- (void)removeObject:(id)anObject
   {
	if ([anObject isKindOfClass:[ACSDGraphic class]])
		[anObject setSelectionTimeStamp:nil];
	[objects removeObject:anObject];
   }

- (void)removeAllObjects
   {
    NSEnumerator *objEnum = [objects objectEnumerator];
    id curGraphic;
    while ((curGraphic = [objEnum nextObject]) != nil) 
		if ([curGraphic isKindOfClass:[ACSDGraphic class]])
			[curGraphic setSelectionTimeStamp:nil];
	[objects removeAllObjects];
   }

- (void)forwardInvocation:(NSInvocation *)anInvocation
   {
    if ([objects respondsToSelector:
            [anInvocation selector]])
        [anInvocation invokeWithTarget:objects];
    else
        [super forwardInvocation:anInvocation];
   }

- (NSMethodSignature *)methodSignatureForSelector:(SEL)aSelector
   {
	return [objects methodSignatureForSelector:aSelector];
   }

- (NSArray*)allObjects
   {
	return [objects allObjects];
   }

-(NSMutableSet*)objects
{
    return objects;
}

-(NSInteger)count
{
	return [objects count];
}

@end
