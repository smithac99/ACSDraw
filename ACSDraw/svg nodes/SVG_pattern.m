//
//  SVG_pattern.m
//  Vectorius
//
//  Created by Alan Smith on 10/08/2020.
//  Copyright © 2020 Alan Smith. All rights reserved.
//

#import "SVG_pattern.h"
#import "SVGGraphicalObject.h"

@implementation SVG_pattern

-(void)processOtherAttributes:(NSDictionary*)context
{
    SVGDimension *x,*y,*w,*h;
    x = [self processAttributeDimension:@"x" defaultDimension:[[SVGDimension alloc]initWithFloat:0 unitType:UNIT_USER]];
    y = [self processAttributeDimension:@"y" defaultDimension:[[SVGDimension alloc]initWithFloat:0 unitType:UNIT_USER]];
    w = [self processAttributeDimension:@"width" defaultDimension:[[SVGDimension alloc]initWithFloat:0 unitType:UNIT_USER]];
    h = [self processAttributeDimension:@"height" defaultDimension:[[SVGDimension alloc]initWithFloat:0 unitType:UNIT_USER]];
    self.processedAttributes[@"patternUnits"] = self.resolvedAttributes[@"patternUnits"];
    self.processedAttributes[@"patternContentUnits"] = self.resolvedAttributes[@"patternContentUnits"];
    self.patternUnitsUser = [self.processedAttributes[@"patternUnits"] isEqualToString:@"userSpaceOnUse"];
    self.processedAttributes[@"_isUserSpace"] = [NSNumber numberWithBool:self.patternUnitsUser];
    self.patternContentUnitsUser = [self.processedAttributes[@"patternContentUnits"] isEqualToString:@"userSpaceOnUse"];
    NSString *vb = self.resolvedAttributes[@"viewBox"];
    if (vb)
        self.processedAttributes[@"viewBox"] = [NSValue valueWithRect:[self getViewBoxFromString:vb]];
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

-(void)drawCell:(NSMutableDictionary*)context
{
    for (SVGNode *n in self.children)
    {
        if ([n isKindOfClass:[SVGGraphicalObject class]])
        {
            if (![n processed])
                [n processAttributes:context];
            [((SVGGraphicalObject*)n) draw:context];
        }
    }
}
-(void)preFilln:(NSBezierPath*)path context:(NSMutableDictionary*)context
{
    if (!self.processed)
        [self processAttributes:context];
    [NSGraphicsContext saveGraphicsState];
    [path addClip];

    //[self applyTransforms];
}

-(void)doFill:(NSBezierPath*)path context:(NSMutableDictionary*)context
{
    float x,y,w,h;
    x = [((SVGDimension*)self.processedAttributes[@"x"])resolveValue:@{}];
    y = [((SVGDimension*)self.processedAttributes[@"y"])resolveValue:@{}];
    w = [((SVGDimension*)self.processedAttributes[@"width"])resolveValue:@{}];
    h = [((SVGDimension*)self.processedAttributes[@"height"])resolveValue:@{}];
    NSRect bb = [path bounds];

    NSValue *vbref = self.processedAttributes[@"viewBox"];
    NSAffineTransform *transformViewBox = nil;
    if (vbref)
    {
        NSRect viewBox = [vbref rectValue];
        transformViewBox = [[NSAffineTransform alloc]init];
        [transformViewBox scaleXBy:w/viewBox.size.width yBy:h/viewBox.size.height];
        [transformViewBox translateXBy:-viewBox.origin.x yBy:-viewBox.origin.y];
    }

    CGContextRef cgref = [[NSGraphicsContext currentContext]CGContext];
    CGRect clipBounds = CGContextGetClipBoundingBox(cgref);
    while (x > clipBounds.origin.x)
        x -= w;
    while (y > clipBounds.origin.y)
        y -= h;
    float startx = x;
    while (y < clipBounds.origin.y + clipBounds.size.height)
    {
        [[NSGraphicsContext currentContext]saveGraphicsState];
        x = startx;
        while (x < clipBounds.origin.x + clipBounds.size.width)
        {
            [[NSGraphicsContext currentContext]saveGraphicsState];
            NSAffineTransform *tx = [[NSAffineTransform alloc]init];
            [tx translateXBy:x yBy:y];
            [tx concat];
            
            if (transformViewBox)
            {
                [transformViewBox concat];
            }
            else if (self.patternContentUnitsUser)
            {
                if (!self.patternUnitsUser)
                {                               // convert to user space
                    NSAffineTransform *tp = [[NSAffineTransform alloc]init];
                    [tp scaleXBy:bb.size.width/w yBy:bb.size.height/h];
                }
            }
            else
            {
                if (self.patternUnitsUser)
                {                              // convert to bounding box
                    NSAffineTransform *tp = [[NSAffineTransform alloc]init];
                    [tp scaleXBy:w/bb.size.width yBy:h/bb.size.height];
                }
            }
            [self drawCell:context];
            [[NSGraphicsContext currentContext]restoreGraphicsState];
            x += w;
        }
        [[NSGraphicsContext currentContext]restoreGraphicsState];
        y += h;
    }
}

-(void)buildTree:(XMLNode*)xmlNode context:(NSMutableDictionary*)context
{
    [super buildTree:xmlNode context:context];
    [self buildChildren:xmlNode context:context];
    [self getAttributeTransform:@"patternTransform" fromXmlNode:xmlNode];
}

@end
