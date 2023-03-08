//
//  SVG_linearGradient.m
//  Vectorius
//
//  Created by Alan Smith on 07/08/2020.
//  Copyright © 2020 Alan Smith. All rights reserved.
//

#import "SVG_linearGradient.h"
#import "SVG_stop.h"
#import "SVGPaint.h"

@implementation SVG_linearGradient

-(void)processOtherAttributes:(NSDictionary*)context
{
    SVGDimension *x1,*y1,*x2,*y2;
    x1 = [self processAttributeDimension:@"x1" defaultDimension:[[SVGDimension alloc]initWithFloat:0 unitType:UNIT_PERCENT]];
    y1 = [self processAttributeDimension:@"y1" defaultDimension:[[SVGDimension alloc]initWithFloat:0 unitType:UNIT_PERCENT]];
    x2 = [self processAttributeDimension:@"x2" defaultDimension:[[SVGDimension alloc]initWithFloat:100 unitType:UNIT_PERCENT]];
    y2 = [self processAttributeDimension:@"y2" defaultDimension:[[SVGDimension alloc]initWithFloat:0 unitType:UNIT_PERCENT]];
    NSString *gradientUnits = self.resolvedAttributes[@"gradientUnits"];
    BOOL isUserSpace = [gradientUnits isEqualToString:@"userSpaceOnUse"];
    self.processedAttributes[@"_isUserSpace"] = [NSNumber numberWithBool:isUserSpace];
    self.processedAttributes[@"spreadMethod"] = self.resolvedAttributes[@"spreadMethod"];
}

-(void)doFill:(NSBezierPath*)path context:(NSMutableDictionary*)context
{
    NSUInteger ct = [self.children count];
    if (ct > 0)
    {
        BOOL isUserSpace = [self.processedAttributes[@"_isUserSpace"]boolValue];
        NSRect bb;
        if (isUserSpace)
            bb = [context[@"_viewbox"]rectValue];
        else
            bb = [path bounds];
        float x = bb.origin.x;
        float y = bb.origin.y;
        float w = bb.size.width;
        float h = bb.size.height;
        float x1,y1,x2,y2;
        if (isUserSpace)
        {
            x1 = [((SVGDimension*)self.processedAttributes[@"x1"])resolveValue:@{@"_offset":@(x),@"_size":@(w)}];
            y1 = [((SVGDimension*)self.processedAttributes[@"y1"])resolveValue:@{@"_offset":@(y),@"_size":@(h)}];
            x2 = [((SVGDimension*)self.processedAttributes[@"x2"])resolveValue:@{@"_offset":@(x),@"_size":@(w)}];
            y2 = [((SVGDimension*)self.processedAttributes[@"y2"])resolveValue:@{@"_offset":@(y),@"_size":@(h)}];
        }
        else
        {
            x1 = [((SVGDimension*)self.processedAttributes[@"x1"])resolveValue:@{@"_size":@(1.0)}];
            y1 = [((SVGDimension*)self.processedAttributes[@"y1"])resolveValue:@{@"_size":@(1.0)}];
            x2 = [((SVGDimension*)self.processedAttributes[@"x2"])resolveValue:@{@"_size":@(1.0)}];
            y2 = [((SVGDimension*)self.processedAttributes[@"y2"])resolveValue:@{@"_size":@(1.0)}];
        }
        NSMutableArray *colours = [NSMutableArray arrayWithCapacity:ct];
        CGFloat positions[ct];
        for (int i = 0;i < ct;i++)
        {
            SVG_stop *stop = (SVG_stop*)[self.children objectAtIndex:i];
            SVGPaint *paint = stop.processedAttributes[@"stop-color"];
            float alpha = [stop.processedAttributes[@"stop-opacity"]floatValue];
            NSColor *col = paint.ref;
            [colours addObject:[col colorWithAlphaComponent:alpha]];
            positions[i] = [stop.processedAttributes[@"offset"]resolveValue:@{@"_size":@(1.0)}];
        }
        NSGradient *grad = [[NSGradient alloc]initWithColors:colours atLocations:positions colorSpace:[NSColorSpace genericRGBColorSpace]];
        [grad drawFromPoint:NSMakePoint(x1,y1) toPoint:NSMakePoint(x2,y2) options:NSGradientDrawsBeforeStartingLocation|NSGradientDrawsAfterEndingLocation];
    }
}

@end
