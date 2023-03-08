//
//  SVGShape.h
//  Vectorius
//
//  Created by Alan Smith on 06/08/2020.
//  Copyright © 2020 Alan Smith. All rights reserved.
//

#import "SVGGraphicalObject.h"


@interface SVGShape : SVGGraphicalObject


-(void)strokeAndFillPath:(NSBezierPath*)path context:(NSMutableDictionary*)context;
-(NSBezierPath*)path;
-(void)drawObject:(NSMutableDictionary*)context;

@end

