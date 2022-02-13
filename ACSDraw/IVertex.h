//
//  IVertex.h
//  Drawtest4
//
//  Created by alan on 16/01/2005.
//  Copyright 2005 Alan C Smith. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class ISegElement;

@interface IVertex : NSObject 
   
@property float x,y;
@property (retain)NSMutableArray *segmentList;
   

+(void)removeDuplicateSegmentsFromVertexDict:(NSDictionary*)vertexDict;
+(IVertex*)vertexForPoint:(NSPoint) pt vertexDict:(NSMutableDictionary*)vertexDict;
-(id)initWithX:(float)xVal y:(float)yVal;
-(id)initWithPoint:(NSPoint)pt;
- (float)x;
- (float)y;
- (NSPoint)point;
- (NSMutableArray *)segmentList;
- (ISegElement*)segment:(int)i;
- (void)addSegment:(ISegElement*)is;
- (NSInteger)noSegments;
- (NSMutableSet*)candidateSegmentsIntersect;
- (NSMutableSet*)candidateSegmentsUnion;
- (NSMutableSet*)candidateSegmentsANotB;
- (void)removeDuplicateSegments;
- (void)removeReverseSegmentsForVertices:(NSArray*)vList startingAtIndex:(NSInteger)ind;

@end
