//
//  SVG_path.h
//  Vectorius
//
//  Created by Alan Smith on 07/08/2020.
//  Copyright © 2020 Alan Smith. All rights reserved.
//

#import "SVGShape.h"


@interface SVG_path : SVGShape

@end

NSBezierPath* BezierPathFromSVGPath(NSString *str);
