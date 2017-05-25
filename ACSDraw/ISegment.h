//
//  ISegment.h
//  Drawtest4
//
//  Created by alan on 16/01/2005.
//  Copyright 2005 Alan C Smith. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "IComponent.h"


@interface ISegment : IComponent 

+(ISegment*)segmentFrom:(NSPoint)fromPoint to:(NSPoint)toPoint vertexDict:(NSMutableDictionary*)vDict;
-(id)initWithVertex:(IVertex*)v;
-(id)initWithVertex:(IVertex*)v inside:(bool) ins;
-(id)initWithX:(float)xVal y:(float)yVal vertexDict:(NSMutableDictionary*)vDict;
-(id)initWithPoint:(NSPoint)pt vertexDict:(NSMutableDictionary*)vDict;

@end
