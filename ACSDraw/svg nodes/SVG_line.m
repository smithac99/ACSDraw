//
//  SVG_line.m
//  Vectorius
//
//  Created by Alan Smith on 07/08/2020.
//  Copyright © 2020 Alan Smith. All rights reserved.
//

#import "SVG_line.h"

@implementation SVG_line

-(void)processOtherAttributes:(NSDictionary*)context
{
    NSRect viewbox = [context[@"_viewbox"]rectValue];
    float vbw = viewbox.size.width;
    float vbh = viewbox.size.width;
    float x1 = [[self processDimension:@"x1" defaultValue:0 size:vbw]resolveValue:@{}];
    float y1 = [[self processDimension:@"y1" defaultValue:0 size:vbh]resolveValue:@{}];
    float x2 = [[self processDimension:@"x2" defaultValue:0 size:vbw]resolveValue:@{}];
    float y2 = [[self processDimension:@"y2" defaultValue:0 size:vbh]resolveValue:@{}];
    self.processedAttributes[@"_x1"] = @(x1);
    self.processedAttributes[@"_y1"] = @(y1);
    self.processedAttributes[@"_x2"] = @(x2);
    self.processedAttributes[@"_y2"] = @(y2);
}


-(NSBezierPath*)path
{
    float x1 = [self.processedAttributes[@"_x1"]floatValue];
    float x2 = [self.processedAttributes[@"_x2"]floatValue];
    float y1 = [self.processedAttributes[@"_y1"]floatValue];
    float y2 = [self.processedAttributes[@"_y2"]floatValue];
    NSBezierPath *path = [NSBezierPath bezierPath];
    [path moveToPoint:NSMakePoint(x1, y1)];
    [path lineToPoint:NSMakePoint(x2, y2)];
    return path;
}


@end
