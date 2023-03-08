//
//  SVG_polyline.m
//  Vectorius
//
//  Created by Alan Smith on 07/08/2020.
//  Copyright © 2020 Alan Smith. All rights reserved.
//

#import "SVG_polyline.h"

@implementation SVG_polyline

-(void)processOtherAttributes:(NSDictionary*)context
{
    NSString *pathString = self.resolvedAttributes[@"points"];
    NSBezierPath *p = BezierPathFromSVGPath(pathString);
    self.processedAttributes[@"_path"] = p;
}

@end
