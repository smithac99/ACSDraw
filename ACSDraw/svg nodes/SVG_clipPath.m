//
//  SVG_clipPath.m
//  Vectorius
//
//  Created by Alan Smith on 12/08/2020.
//  Copyright © 2020 Alan Smith. All rights reserved.
//

#import "SVG_clipPath.h"

@implementation SVG_clipPath

-(void)buildTree:(XMLNode*)xmlNode context:(NSMutableDictionary*)context
{
    [super buildTree:xmlNode context:context];
    [self buildChildren:xmlNode context:context];
}

-(void)processOtherAttributes:(NSDictionary*)context
{
   NSString *clipPathUnits = self.resolvedAttributes[@"clipPathUnits"];
    BOOL isBoundingBoxSpace = [clipPathUnits isEqualToString:@"objectBoundingBox"];
    self.processedAttributes[@"_clipPathIsBoundingBoxSpace"] = [NSNumber numberWithBool:isBoundingBoxSpace];
}

-(void)applyClip:(NSRect)objectBounds context:(NSMutableDictionary*)context
{
    for (SVGNode *n in self.children)
    {
        if (![n processed])
            [n processAttributes:context];
        [n applyClip:objectBounds context:context];
    }
}

@end
