//
//  SVGGradient.m
//  Vectorius
//
//  Created by Alan Smith on 09/08/2020.
//  Copyright © 2020 Alan Smith. All rights reserved.
//

#import "SVGGradient.h"

@implementation SVGGradient


//temp
-(instancetype)initWithCoder:(NSCoder*)code
{
    return nil;
}
-(void) processAttributes:(NSMutableDictionary *)context
{
    [self calculateTransforms];
    [super processAttributes:context];
    for (SVGNode *stop in self.children)
        if (!stop.processed)
            [stop processAttributes:context];
}

-(void)buildTree:(XMLNode*)xmlNode context:(NSMutableDictionary*)context
{
    [super buildTree:xmlNode context:context];
    [self buildChildren:xmlNode context:context];
    [self getAttributeTransform:@"gradientTransform" fromXmlNode:xmlNode];
}

-(void)preFill:(NSBezierPath*)path context:(NSMutableDictionary*)context
{
    [super preFill:path context:context];
    [self applyTransforms];
}

-(void)resolveAttributes:(NSMutableDictionary*)context
{
    [super resolveAttributes:context];
    NSString *ref = self.resolvedAttributes[@"xlink:href"];
    if (ref && [ref hasPrefix:@"#"])
    {
        NSString *targetid = [ref substringFromIndex:1];
        SVGNode *target = context[@"objectdict"][targetid];
        if (target && [target isKindOfClass:[self class]])
        {
            if (!target.resolved)
                [target resolveAttributes:context];
            for (NSString *k in [target.resolvedAttributes allKeys])
            {
                if (self.resolvedAttributes[k] == nil)
                    self.resolvedAttributes[k] = target.resolvedAttributes[k];
            }
            if ([self.children count] == 0)
                for (SVGNode *n in target.children)
                    [self.children addObject:[n copy]];
        }
    }
    [self resolveChildren:context];
}

@end
