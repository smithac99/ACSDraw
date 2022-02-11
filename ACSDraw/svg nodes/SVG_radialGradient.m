//
//  SVG_radialGradient.m
//  Vectorius
//
//  Created by Alan Smith on 09/08/2020.
//  Copyright © 2020 Alan Smith. All rights reserved.
//

#import "SVG_radialGradient.h"
#import "SVG_stop.h"

@implementation SVG_radialGradient

-(void)processOtherAttributes:(NSDictionary*)context
{
    SVGDimension *cx,*cy,*fx,*fy,*r;
    cx = [self processAttributeDimension:@"cx" defaultDimension:[[SVGDimension alloc]initWithFloat:50 unitType:UNIT_PERCENT]];
    cy = [self processAttributeDimension:@"cy" defaultDimension:[[SVGDimension alloc]initWithFloat:50 unitType:UNIT_PERCENT]];
    fx = [self processAttributeDimension:@"fx" defaultDimension:[cx copy]];
    fy = [self processAttributeDimension:@"fy" defaultDimension:[cy copy]];
    r = [self processAttributeDimension:@"r" defaultDimension:[[SVGDimension alloc]initWithFloat:50 unitType:UNIT_PERCENT]];
    NSString *gradientUnits = self.resolvedAttributes[@"gradientUnits"];
    BOOL isUserSpace = [gradientUnits isEqualToString:@"userSpaceOnUse"];
    /*if (!isUserSpace)
    {
        if (cx.unitType != UNIT_PERCENT)
            cx.unitType = UNIT_RATIO;
        if (cy.unitType != UNIT_PERCENT)
            cy.unitType = UNIT_RATIO;
        if (fx.unitType != UNIT_PERCENT)
            fx.unitType = UNIT_RATIO;
        if (fy.unitType != UNIT_PERCENT)
            fy.unitType = UNIT_RATIO;
        if (r.unitType != UNIT_PERCENT)
            r.unitType = UNIT_RATIO;
    }*/
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
        float cx,cy,fx,fy,r;
        if (isUserSpace)
        {
            cx = [((SVGDimension*)self.processedAttributes[@"cx"])resolveValue:@{@"_offset":@(x),@"_size":@(w)}];
            cy = [((SVGDimension*)self.processedAttributes[@"cy"])resolveValue:@{@"_offset":@(y),@"_size":@(h)}];
            fx = [((SVGDimension*)self.processedAttributes[@"fx"])resolveValue:@{@"_offset":@(x),@"_size":@(w)}];
            fy = [((SVGDimension*)self.processedAttributes[@"fy"])resolveValue:@{@"_offset":@(y),@"_size":@(h)}];
            float diag = sqrtf(w*w+h*h);
            r = [((SVGDimension*)self.processedAttributes[@"r"])resolveValue:@{@"_size":@(diag)}];
        }
        else
        {
            cx = [((SVGDimension*)self.processedAttributes[@"cx"])resolveValue:@{@"_size":@1.0}];
            cy = [((SVGDimension*)self.processedAttributes[@"cy"])resolveValue:@{@"_size":@1.0}];
            fx = [((SVGDimension*)self.processedAttributes[@"fx"])resolveValue:@{@"_size":@1.0}];
            fy = [((SVGDimension*)self.processedAttributes[@"fy"])resolveValue:@{@"_size":@1.0}];
            r = [((SVGDimension*)self.processedAttributes[@"r"])resolveValue:@{@"_size":@1.0}];
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
        [grad drawFromCenter:NSMakePoint(fx,fy) radius:0 toCenter:NSMakePoint(cx,cy) radius:r  options:NSGradientDrawsBeforeStartingLocation|NSGradientDrawsAfterEndingLocation];
    }
}


@end
