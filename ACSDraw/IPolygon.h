//
//  IPolygon.h
//  Drawtest4
//
//  Created by alan on 16/01/2005.
//  Copyright 2005 Alan C Smith. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "ISegment.h"

NSInteger sortChildren(id seg1,id seg2,void *contextInfo);

@class ACSDPath;
@class ACSDSubPath;

@interface IPolygon : NSObject 


@property (strong) NSMutableArray *componentList;
@property bool isClosed;

+(IPolygon*) polygon;
+(IPolygon*) polygonFromSubPath:(ACSDSubPath*)subPath vertexDict:(NSMutableDictionary*)vertexDict;
+(NSMutableArray*)polygonsFromSubPaths:(NSArray*)subPaths vertexDict:(NSMutableDictionary*)vertexDict;
+(NSMutableArray*)polygonsFromPath:(ACSDPath*)path vertexDict:(NSMutableDictionary*)vertexDict;
- (void)addSegmentfromX:(float)x y:(float)y vertexDict:(NSMutableDictionary*)vDict;
- (void)addSegmentPt:(NSPoint)pt vertexDict:(NSMutableDictionary*)vDict;
- (void)addCurvePt0:(NSPoint)pt0 cp1:(NSPoint)cp1 cp2:(NSPoint)cp2 vertexDict:(NSMutableDictionary*)vDict;
- (IComponent*)component:(NSInteger)i;
- (NSUInteger)noComponents;
- (IVertex*)vertex:(NSInteger)i;
- (NSPoint)point:(NSInteger)i;
- (IPolygon*) sortChildren;
- (ISegElement*)expandSegments;
- (void)fillInToVertices;
- (NSPoint)GetPointMajor:(NSInteger*)major minor:(NSInteger*)minor;
- (NSPoint)GetNextPointMajor:(NSInteger*)major minor:(NSInteger*)minor;
- (NSPoint)GetPreviousPointMajor:(NSInteger*)major minor:(NSInteger*)minor;
- (bool)isCrossingPoint:(NSInteger)i pointA:(NSPoint)a pointB:(NSPoint)b; 
-(void)getIntersectionsWith:(IPolygon*)polygon vertexDict:(NSMutableDictionary*)vertexDict;
- (void)markChildren:(bool)b;
- (IPolygon*)resolveCoincidentPoints:(NSMutableArray*)polygonList;

@end
