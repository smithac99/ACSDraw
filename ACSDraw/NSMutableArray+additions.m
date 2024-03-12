//
//  NSMutableArray+additions.m
//  ACSDraw
//
//  Created by Alan Smith on 12/03/2024.
//

#import "NSMutableArray+additions.h"

@implementation NSMutableArray (additions)

-(void)addNewObjectsFromArray:(NSArray*)newobjs
{
    for (id obj in newobjs)
    {
        if (![self containsObject:obj])
            [self addObject:obj];
    }
}
@end
