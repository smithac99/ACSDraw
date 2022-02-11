//
//  SVG_svg.m
//  Vectorius
//
//  Created by Alan Smith on 06/08/2020.
//  Copyright © 2020 Alan Smith. All rights reserved.
//

#import "SVG_svg.h"

@implementation SVG_svg

-(instancetype)initWithXMLNode:(XMLNode*)xmlNode context:(NSMutableDictionary*)context
{
    if (self = [self init])
    {
        [self.buildAttributes addEntriesFromDictionary:context[@"defaultattrs"]];
        [self buildTree:xmlNode context:context];
        [self extractViewBox:context];
    }
    return self;
}

-(void)extractViewBox:(NSMutableDictionary*)context
{
    id vb = self.buildAttributes[@"viewBox"];
    if (vb == nil)
    {
        float iw = [context[@"_vwidth"]floatValue];
        float ih = [context[@"_vheight"]floatValue];
        float x = [[self processDimension:@"x" defaultValue:0 size:iw]resolveValue:@{}];
        float y = [[self processDimension:@"y" defaultValue:0 size:ih]resolveValue:@{}];
        float w = [[self processDimension:@"width" defaultValue:iw size:iw]resolveValue:@{}];;
        float h = [[self processDimension:@"height" defaultValue:ih size:ih]resolveValue:@{}];
        self.viewBox = NSMakeRect(x, y, w, h);
    }
    else
    {
        if ([vb isKindOfClass:[NSString class]])
        {
            self.viewBox = [self getViewBoxFromString:vb];
        }
    }
    self.buildAttributes[@"_viewbox"] = [NSValue valueWithRect:self.viewBox];
}

-(void)resolveChildren:(NSDictionary*)context
{
    NSMutableDictionary *contextCopy = [context mutableCopy];
    contextCopy[@"_viewbox"] = self.resolvedAttributes[@"viewBox"];
    for (SVGNode *child in self.children)
    {
        [child resolveAttributes:contextCopy];
    }
    
}

@end
