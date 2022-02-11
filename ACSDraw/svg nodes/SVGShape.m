//
//  SVGShape.m
//  Vectorius
//
//  Created by Alan Smith on 06/08/2020.
//  Copyright © 2020 Alan Smith. All rights reserved.
//

#import "SVGShape.h"
#import "SVGPaintServer.h"

@implementation SVGShape

static NSInteger lineCapFromString(NSString* s)
{
    if ([s isEqualToString:@"round"])
        return NSLineCapStyleRound;
    if ([s isEqualToString:@"butt"])
        return NSLineCapStyleButt;
    if ([s isEqualToString:@"square"])
        return NSLineCapStyleSquare;
    return 0;
}

static NSInteger lineJoinFromString(NSString* s)
{
    if ([s isEqualToString:@"round"])
        return NSLineJoinStyleRound;
    if ([s isEqualToString:@"bevel"])
        return NSLineJoinStyleBevel;
    if ([s isEqualToString:@"miter"])
        return NSLineJoinStyleMiter;
    return 0;
}

-(void)strokeAndFillPath:(NSBezierPath*)path context:(NSMutableDictionary*)context
{
    SVGPaint *fill = self.processedAttributes[@"fill"];
    if (fill && fill.paintType != PAINTTYPE_NONE)
    {
        if (fill.paintType == PAINTTYPE_COLOUR)
        {
            NSColor *col = fill.ref;
            NSNumber *alpha = self.processedAttributes[@"fill-opacity"];
            if (alpha)
            {
                float f = [alpha floatValue];
                if (f < 1.0)
                    col = [col colorWithAlphaComponent:f];
            }
            [col set];
            [path fill];
        }
        else if (fill.paintType == PAINTTYPE_SERVER)
        {
            NSString *refstr = fill.ref;
            SVGPaintServer *ps = context[@"objectdict"][refstr];
            if (ps)
            {
                [ps fillPath:path context:context];
            }
        }
    }
    SVGPaint *stroke = self.processedAttributes[@"stroke"];
    if (stroke && stroke.paintType != PAINTTYPE_NONE)
    {
        if (stroke.paintType == PAINTTYPE_COLOUR)
        {
            NSColor *col = stroke.ref;
            NSNumber *alpha = self.processedAttributes[@"stroke-opacity"];
            if (alpha)
            {
                float f = [alpha floatValue];
                if (f < 1.0)
                    col = [col colorWithAlphaComponent:f];
            }

            [col set];
            
            [path setLineWidth:[self.processedAttributes[@"_strokewidth"] floatValue]];
            
            if (self.processedAttributes[@"stroke-linecap"])
            {
                [path setLineCapStyle:lineCapFromString(self.processedAttributes[@"stroke-linecap"])];
            }
            if (self.processedAttributes[@"stroke-linejoin"])
            {
                [path setLineJoinStyle:lineJoinFromString(self.processedAttributes[@"stroke-linejoin"])];
            }
            
            NSNumber *mitrelim = self.processedAttributes[@"stroke-miterlimit"];
            if (mitrelim)
            {
                float f = [mitrelim floatValue];
                [path setMiterLimit:f];
            }

            [path stroke];
        }
    }

}

-(void)applyClip:(NSRect)bbox context:(NSMutableDictionary*)context
{
    [[self path]addClip];
}

-(NSBezierPath*)path
{
    return nil;
}

-(void)drawObject:(NSMutableDictionary*)context
{
    [super drawObject:context];
    NSBezierPath *path = [self path];
    if (path)
        [self strokeAndFillPath:path context:context];
}

-(NSRect)bounds:(NSMutableDictionary*)context
{
    return [[self path]bounds];
}

@end
