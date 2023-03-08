//
//  SVG_stop.m
//  Vectorius
//
//  Created by Alan Smith on 09/08/2020.
//  Copyright © 2020 Alan Smith. All rights reserved.
//

#import "SVG_stop.h"

@implementation SVG_stop

-(void)processOtherAttributes:(NSDictionary*)context
{
    if ([self processAttributeFloat:@"stop-opacity"] == nil)
        self.processedAttributes[@"stop-opacity"] = @(1.0);
    if ([self processAttributePaint:@"stop-color"] == nil)
        self.processedAttributes[@"stop-color"] = [NSColor blackColor];
    [self processDimension:@"offset" defaultValue:0 size:1.0];
}

@end
