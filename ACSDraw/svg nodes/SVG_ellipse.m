//
//  SVG_ellipse.m
//  Vectorius
//
//  Created by Alan Smith on 06/08/2020.
//  Copyright © 2020 Alan Smith. All rights reserved.
//

#import "SVG_ellipse.h"

@implementation SVG_ellipse

-(void)processOtherAttributes:(NSDictionary*)context
{
    NSRect viewbox = [context[@"_viewbox"]rectValue];
    float vbw = viewbox.size.width;
    float vbh = viewbox.size.width;
    float cx = [[self processDimension:@"cx" defaultValue:0 size:vbw]resolveValue:@{}];
    float cy = [[self processDimension:@"cy" defaultValue:0 size:vbh]resolveValue:@{}];
    float rx = [[self processDimension:@"rx" defaultValue:0 size:vbw]resolveValue:@{}];;
    float ry = [[self processDimension:@"ry" defaultValue:0 size:vbh]resolveValue:@{}];
    self.processedAttributes[@"_cx"] = @(cx);
    self.processedAttributes[@"_cy"] = @(cy);
    self.processedAttributes[@"_rx"] = @(rx);
    self.processedAttributes[@"_ry"] = @(ry);
}

-(NSBezierPath*)path
{
    float rx = [self.processedAttributes[@"_rx"]floatValue];
    float ry = [self.processedAttributes[@"_ry"]floatValue];
    if (rx > 0 && ry > 0)
    {
        float cx = [self.processedAttributes[@"_cx"]floatValue];
        float cy = [self.processedAttributes[@"_cy"]floatValue];
        CGRect r = CGRectMake(cx-rx, cy-ry, rx*2, ry*2);
        NSBezierPath *path = [NSBezierPath bezierPathWithOvalInRect:r];
        return path;
    }
    return nil;
}

@end
