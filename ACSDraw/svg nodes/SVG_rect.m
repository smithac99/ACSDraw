//
//  SVG_rect.m
//  Vectorius
//
//  Created by Alan Smith on 06/08/2020.
//  Copyright © 2020 Alan Smith. All rights reserved.
//

#import "SVG_rect.h"
#import "SVGDimension.h"

@implementation SVG_rect

-(void)processOtherAttributes:(NSDictionary*)context
{
    NSRect viewbox = [context[@"_viewbox"]rectValue];
    float vbw = viewbox.size.width;
    float vbh = viewbox.size.width;
    float x = [[self processDimension:@"x" defaultValue:0 size:vbw]resolveValue:@{}];
    float y = [[self processDimension:@"y" defaultValue:0 size:vbh]resolveValue:@{}];
    float w = [[self processDimension:@"width" defaultValue:0 size:vbw]resolveValue:@{}];;
    float h = [[self processDimension:@"height" defaultValue:0 size:vbh]resolveValue:@{}];
    self.processedAttributes[@"_frame"] = [NSValue valueWithRect:NSMakeRect(x, y, w, h)];
    float rx = [[self processDimension:@"rx" defaultValue:0 size:vbw]resolveValue:@{}];;
    float ry = [[self processDimension:@"ry" defaultValue:0 size:vbh]resolveValue:@{}];
    self.processedAttributes[@"_rx"] = @(rx);
    self.processedAttributes[@"_ry"] = @(ry);
}

-(NSBezierPath*)path
{
    NSValue *vr = self.processedAttributes[@"_frame"];
    if (vr)
    {
        NSBezierPath *path;
        float rx = [self.processedAttributes[@"_rx"]floatValue];
        float ry = [self.processedAttributes[@"_ry"]floatValue];
        NSRect r = [vr rectValue];
        if (rx == 0 && ry == 0)
            path = [NSBezierPath bezierPathWithRect:r];
        else
            path = [NSBezierPath bezierPathWithRoundedRect:r xRadius:rx yRadius:ry];
        return path;
    }
    return nil;
}

-(void)drawObject:(NSMutableDictionary*)context
{
    [super drawObject:context];
    NSBezierPath *path = [self path];
    if (path)
        [self strokeAndFillPath:path context:context];
}


@end
