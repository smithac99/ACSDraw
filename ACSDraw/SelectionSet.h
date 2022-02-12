//
//  SelectionSet.h
//  ACSDraw
//
//  Created by Alan Smith on Sun Feb 03 2002.
//  Copyright (c) 2001 __MyCompanyName__. All rights reserved.
//

#import <Foundation/NSSet.h>


@interface SelectionSet : NSObject 
{
	NSMutableSet *objects;
}

- (id)initWithCapacity:(unsigned)numItems;
- (NSArray*)allObjects;
- (void)addObjectsFromArray:(NSArray*)array;
- (void)removeAllObjects;
-(NSMutableSet*)objects;
-(NSInteger)count;

@end
