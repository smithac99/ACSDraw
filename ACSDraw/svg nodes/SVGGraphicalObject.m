//
//  SVGGraphicalObject.m
//  Vectorius
//
//  Created by Alan Smith on 06/08/2020.
//  Copyright © 2020 Alan Smith. All rights reserved.
//

#import "SVGGraphicalObject.h"
#import "SVG_clipPath.h"

@implementation SVGGraphicalObject

-(instancetype)init
{
    if (self = [super init])
    {
    }
    return self;
}

-(void)drawObject:(NSMutableDictionary*)context
{
}

-(void)draw:(NSMutableDictionary*)context
{
    if ([self preDraw:context])
    {
        if (![self.processedAttributes[@"visibility"]isEqualToString:@"hidden"])
            [self drawObject:context];
        [self postDraw:context];
    }
}

-(void)applyTransforms
{
    NSArray<SVGTransform*> *transforms = self.buildAttributes[@"_transforms"];
    for (SVGTransform *transform in transforms)
    {
        [transform apply];
    }
}

-(void)processAttributes:(NSMutableDictionary*)context
{
    [self calculateTransforms];
    [super processAttributes:context];
    if (self.resolvedAttributes[@"clip-path"])
        self.processedAttributes[@"clip-path"] = self.resolvedAttributes[@"clip-path"];
}

-(void)calculateTransforms
{
    for (SVGTransform *t in self.buildAttributes[@"_transforms"])
        [t calculateTransform];
}

-(BOOL)preDraw:(NSMutableDictionary*)context
{
    if (!self.processed)
        [self processAttributes:context];
    NSString *display = self.processedAttributes[@"display"];
    if ([display isEqualToString:@"none"])
        return NO;
    [[NSGraphicsContext currentContext]saveGraphicsState];
    [self applyTransforms];
    NSString *ref = self.resolvedAttributes[@"clip-path"];
    if (ref && [ref hasPrefix:@"url"])
    {
        {
            NSString *targetid = [ref substringWithRange:NSMakeRange(5,[ref length]-1-5)];
            SVGNode *target = context[@"objectdict"][targetid];
            if (target && [target isKindOfClass:[SVG_clipPath class]])
            {
                if (!target.resolved)
                    [target resolveAttributes:context];
                NSRect bnds = NSZeroRect;
                if ([target.resolvedAttributes[@"_clipPathIsBoundingBoxSpace"]boolValue])
                    bnds = [self bounds:context];
                [((SVG_clipPath*)target) applyClip:bnds context:context];
            }
        }
    }
    NSNumber *opacityAttr = self.resolvedAttributes[@"opacity"];
    if (opacityAttr)
    {
        float alpha = [opacityAttr floatValue];
        if (alpha < 1.0)
        {
            CGContextRef currentContext = (CGContextRef)[[NSGraphicsContext currentContext] graphicsPort];
            CGContextBeginTransparencyLayer (currentContext, NULL);
            CGContextSetAlpha(currentContext,alpha);
            self.mustEndTransparencyLayer = YES;
        }
    }
    return YES;
}

-(void)postDraw:(NSMutableDictionary*)context
{
    if ([self mustEndTransparencyLayer])
    {
        CGContextRef currentContext = (CGContextRef)[[NSGraphicsContext currentContext] graphicsPort];
        CGContextEndTransparencyLayer(currentContext);
    }
    [[NSGraphicsContext currentContext]restoreGraphicsState];
}

-(void)resolveAttributes:(NSMutableDictionary*)context
{
    [super resolveAttributes:context];
    if (self.buildAttributes[@"_transforms"])
        self.resolvedAttributes[@"_transforms"] = self.buildAttributes[@"_transforms"];
}

-(NSRect)bounds:(NSMutableDictionary*)context
{
    return NSZeroRect;
}
@end
