//
//  SVG_polygon.m
//  Vectorius
//
//  Created by Alan Smith on 07/08/2020.
//  Copyright © 2020 Alan Smith. All rights reserved.
//

#import "SVG_polygon.h"

@implementation SVG_polygon

-(void)processOtherAttributes:(NSDictionary*)context
{
    NSString *pathString = self.resolvedAttributes[@"points"];
    NSBezierPath *p = BezierPathFromSVGPath(pathString);
    [p closePath];
    self.processedAttributes[@"_path"] = p;
}

@end
