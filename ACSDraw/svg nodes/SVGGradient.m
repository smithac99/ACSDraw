//
//  SVGGradient.m
//  Vectorius
//
//  Created by Alan Smith on 09/08/2020.
//  Copyright © 2020 Alan Smith. All rights reserved.
//

#import "SVGGradient.h"

@implementation SVGGradient

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

@end
