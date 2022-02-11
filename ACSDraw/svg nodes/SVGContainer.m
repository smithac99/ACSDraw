//
//  SVGContainer.m
//  Vectorius
//
//  Created by Alan Smith on 07/08/2020.
//  Copyright © 2020 Alan Smith. All rights reserved.
//

#import "SVGContainer.h"

@implementation SVGContainer

-(void)drawObject:(NSMutableDictionary*)context
{
    [super drawObject:context];
    for (SVGGraphicalObject *child in self.children)
        if ([child isKindOfClass:[SVGGraphicalObject class]])
            [child draw:context];
}

-(void)buildTree:(XMLNode*)xmlNode context:(NSMutableDictionary*)context
{
    [super buildTree:xmlNode context:context];
    [self buildChildren:xmlNode context:context];
}

-(void)applyClip:(NSRect)bbox context:(NSMutableDictionary*)context
{
    for (SVGNode *n in self.children)
    {
        if (![n processed])
            [n processAttributes:context];
        [n applyClip:bbox context:context];
    }
}

-(NSRect)bounds:(NSMutableDictionary*)context
{
    NSRect bnds = NSZeroRect;
    for (SVGNode *n in self.children)
    {
        if (![n processed])
            [n processAttributes:context];
        if ([n isKindOfClass:[SVGGraphicalObject class]])
            bnds = NSUnionRect(bnds, [((SVGGraphicalObject*)n) bounds:context]);
    }
    return bnds;
}

@end
