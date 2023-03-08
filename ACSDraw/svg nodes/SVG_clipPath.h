//
//  SVG_clipPath.h
//  Vectorius
//
//  Created by Alan Smith on 12/08/2020.
//  Copyright © 2020 Alan Smith. All rights reserved.
//

#import "SVGNode.h"

NS_ASSUME_NONNULL_BEGIN

@interface SVG_clipPath : SVGNode

-(void)applyClip:(NSRect)objectBounds context:(NSMutableDictionary*)context;

@end

NS_ASSUME_NONNULL_END
