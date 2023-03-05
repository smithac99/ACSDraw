//
//  SVG_circle.m
//  Vectorius
//
//  Created by Alan Smith on 07/08/2020.
//  Copyright © 2020 Alan Smith. All rights reserved.
//

#import "SVG_circle.h"

@implementation SVG_circle

-(void)processOtherAttributes:(NSDictionary*)context
{
    NSRect viewbox = [context[@"_viewbox"]rectValue];
    float vbw = viewbox.size.width;
    float vbh = viewbox.size.width;
    float cx = [[self processDimension:@"cx" defaultValue:0 size:vbw]resolveValue:@{}];
    float cy = [[self processDimension:@"cy" defaultValue:0 size:vbh]resolveValue:@{}];
    float r = [[self processDimension:@"r" defaultValue:0 size:vbw]resolveValue:@{}];;
    self.processedAttributes[@"_cx"] = @(cx);
    self.processedAttributes[@"_cy"] = @(cy);
    self.processedAttributes[@"_r"] = @(r);
}

-(NSBezierPath*)path
{
    float r = [self.processedAttributes[@"_r"]floatValue];
    if (r > 0)
    {
        float cx = [self.processedAttributes[@"_cx"]floatValue];
        float cy = [self.processedAttributes[@"_cy"]floatValue];
        CGRect rct = CGRectMake(cx-r, cy-r, r*2, r*2);
        NSBezierPath *path = [NSBezierPath bezierPathWithOvalInRect:rct];
        return path;
    }
    return nil;
}

@end
