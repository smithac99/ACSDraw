//
//  SVG_defs.m
//  Vectorius
//
//  Created by Alan Smith on 08/08/2020.
//  Copyright © 2020 Alan Smith. All rights reserved.
//

#import "SVG_defs.h"

@implementation SVG_defs

-(void)processAttributes:(NSMutableDictionary*)context
{
    [self processChildrenAttributes:context];
}

-(void)buildTree:(XMLNode*)xmlNode context:(NSMutableDictionary*)context
{
    [self buildChildren:xmlNode context:context];
}

-(void)resolveAttributes:(NSMutableDictionary*)context
{
    self.resolved = YES;
    [self resolveChildren:context];
}

@end
