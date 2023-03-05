//
//  SVG_use.m
//  Vectorius
//
//  Created by Alan Smith on 08/08/2020.
//  Copyright © 2020 Alan Smith. All rights reserved.
//

#import "SVG_use.h"
#import "SVG_symbol.h"
#import "SVG_svg.h"
#import "SVGTransform.h"

@implementation SVG_use

-(void)resolveAttributes:(NSMutableDictionary*)context
{
    [super resolveAttributes:context];
    NSString *ref = self.resolvedAttributes[@"xlink:href"];
    if (ref && [ref hasPrefix:@"#"])
    {
        NSString *targetid = [ref substringFromIndex:1];
        SVGNode *target = context[@"objectdict"][targetid];
        if (target && target != self)
        {
            [self objectForTargetReference:target context:context];
        }
    }
}

-(SVGNode*)objectForTargetReference:(SVGNode*)target context:(NSMutableDictionary*)context
{
    if ([target isMemberOfClass:[SVG_symbol class]])
        return [self symbolNodeForTargetReference:target context:context];
    if ([target isMemberOfClass:[SVG_svg class]])
        return [self SVGNodeForTargetReference:target context:context];
    return [self otherNodeForTargetReference:target context:context];
}

-(SVGNode*)SVGNodeForTargetReference:(SVGNode*)target context:(NSMutableDictionary*)context
{
    SVGNode *tc = [target copyToClass:[SVG_svg class]];
    [self.children addObject:tc];
    tc.parent = self;
    
    NSString *dx = self.resolvedAttributes[@"x"];
    NSString *dy = self.resolvedAttributes[@"y"];
    NSString *dwidth = self.resolvedAttributes[@"width"];
    NSString *dheight = self.resolvedAttributes[@"height"];
    NSMutableArray *transforms = self.buildAttributes[@"_transforms"];
    [transforms addObjectsFromArray:[SVGTransform transformsForInputString:[NSString stringWithFormat:@"translate(%@ %@)",dx,dy]]];
    for (NSString *k in @[@"x",@"y",@"width",@"height",@"xlink:href"])
        [self.resolvedAttributes removeObjectForKey:k];
    
    if (dwidth)
        tc.resolvedAttributes[@"width"] = dwidth;
    if (dheight)
        tc.resolvedAttributes[@"height"] = dheight;
    [tc.resolvedAttributes removeObjectForKey:@"id"];
    return tc;
}

-(SVGNode*)symbolNodeForTargetReference:(SVGNode*)target context:(NSMutableDictionary*)context
{
    SVGNode *tc = [target copyToClass:[SVG_svg class]];
    [self.children addObject:tc];
    tc.parent = self;
    
    NSString *dx = self.resolvedAttributes[@"x"];
    NSString *dy = self.resolvedAttributes[@"y"];
    NSString *dwidth = self.resolvedAttributes[@"width"];
    NSString *dheight = self.resolvedAttributes[@"height"];
    NSMutableArray *transforms = self.buildAttributes[@"_transforms"];
    [transforms addObjectsFromArray:[SVGTransform transformsForInputString:[NSString stringWithFormat:@"translate(%@ %@)",dx,dy]]];
    for (NSString *k in @[@"x",@"y",@"width",@"height",@"xlink:href"])
        [self.resolvedAttributes removeObjectForKey:k];
    
    if (dwidth)
        tc.resolvedAttributes[@"width"] = dwidth;
    if (dheight)
        tc.resolvedAttributes[@"height"] = dheight;
    [tc.resolvedAttributes removeObjectForKey:@"id"];
    return tc;
}

-(SVGNode*)otherNodeForTargetReference:(SVGNode*)target context:(NSMutableDictionary*)context
{
    SVGNode *tc = [target copy];
    [self.children addObject:tc];
    tc.parent = self;
    
    NSString *dx = self.resolvedAttributes[@"x"];
    NSString *dy = self.resolvedAttributes[@"y"];
    NSMutableArray *transforms = self.buildAttributes[@"_transforms"];
    [transforms addObjectsFromArray:[SVGTransform transformsForInputString:[NSString stringWithFormat:@"translate(%@ %@)",dx,dy]]];
    for (NSString *k in @[@"x",@"y",@"width",@"height",@"xlink:href"])
        [self.resolvedAttributes removeObjectForKey:k];

    [tc.resolvedAttributes removeObjectForKey:@"id"];
    return tc;
}

-(void)drawObject:(NSMutableDictionary*)context
{
    [super drawObject:context];
    for (SVGGraphicalObject *child in self.children)
        if ([child isKindOfClass:[SVGGraphicalObject class]])
            [child draw:context];
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

@end
