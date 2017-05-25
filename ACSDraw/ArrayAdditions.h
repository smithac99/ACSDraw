//
//  ArrayAdditions.h
//  ACSDraw
//
//  Created by alan on 01/05/06.
//  Copyright 2006 Alan C Smith. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface NSArray(ArrayAdditions)

- (void)makeObjectsPerformSelector:(SEL)theSelector withObject:(id)arg1 andObject:(id)arg2;
- (BOOL)andMakeObjectsPerformSelector:(SEL)theSelector;
- (BOOL)andMakeObjectsPerformSelector:(SEL)theSelector withObject:(id)arg;
- (BOOL)orMakeObjectsPerformSelector:(SEL)aSelector;
- (BOOL)orMakeAllObjectsPerformSelector:(SEL)aSelector;
- (BOOL)orMakeObjectsPerformSelector:(SEL)theSelector withObject:(id)arg;
- (BOOL)orMakeAllObjectsPerformSelector:(SEL)theSelector withObject:(id)arg;
-(NSArray*)objectsWhichRespond:(BOOL)response toSelector:(SEL)theSelector;
-(NSIndexSet*)indexesOfObjectsWhichRespond:(BOOL)response toSelector:(SEL)theSelector;
- (id)firstObjectWhichRespondsYesToSelector:(SEL)theSelector withObject:(id)o;
- (id)lastObjectWhichRespondsYesToSelector:(SEL)theSelector withObject:(id)arg;
-(BOOL)allObjectsAreKindOfClass:(Class)aClass;
-(NSArray*)copiedObjects;
- (void)reverseMakeObjectsPerformSelector:(SEL)theSelector;
- (void)reverseMakeObjectsPerformSelector:(SEL)theSelector withObject:(id)arg;
-(id)objectAtReversedIndex:(NSUInteger)index;


@end
