//
//  SVGPaintServer.m
//  Vectorius
//
//  Created by Alan Smith on 09/08/2020.
//  Copyright © 2020 Alan Smith. All rights reserved.
//

#import "SVGPaintServer.h"

@implementation SVGPaintServer

-(void)preFill:(NSBezierPath*)path context:(NSMutableDictionary*)context
{
    if (!self.processed)
        [self processAttributes:context];
    [NSGraphicsContext saveGraphicsState];
    [path addClip];
    BOOL isUserSpace = [self.processedAttributes[@"_isUserSpace"]boolValue];
    if (!isUserSpace)
    {
        NSRect bb = [path bounds];
        float x = bb.origin.x;
        float y = bb.origin.y;
        float w = bb.size.width;
        float h = bb.size.height;;
        NSAffineTransform *t = [[NSAffineTransform alloc]init];
        [t translateXBy:x yBy:y];
        [t scaleXBy:w yBy:h];
        [t concat];
    }
}
-(void)doFill:(NSBezierPath*)path context:(NSMutableDictionary*)context
{
    
}
-(void)postFill
{
    [NSGraphicsContext restoreGraphicsState];
}

-(void)fillPath:(NSBezierPath*)path context:(NSMutableDictionary*)context
{
    [self preFill:path context:context];
    [self doFill:path context:context];
    [self postFill];
}

-(void)calculateTransforms
{
    for (SVGTransform *t in self.buildAttributes[@"_transforms"])
        [t calculateTransform];
}

-(void)applyTransforms
{
    NSArray<SVGTransform*> *transforms = self.buildAttributes[@"_transforms"];
    for (SVGTransform *transform in transforms)
    {
        [transform apply];
    }
}

@end
