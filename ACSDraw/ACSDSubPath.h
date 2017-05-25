//
//  ACSDSubPath.h
//  ACSDraw
//
//  Created by Alan Smith on Tue Mar 05 2002.
//  Copyright (c) 2001 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "ACSDGraphic.h"

@class ACSDLineEnding;
@class IVertex;
@class ACSDPathElement;

@interface ACSDSubPath : NSObject
   {
	NSMutableArray *pathElements;
	BOOL isClosed;
   }

+(ACSDPath*)unionPathFromSubPaths:(NSArray*)subPathArray;
+(ACSDPath*)unionPathFromPaths:(NSArray*)pathArray;
+(bool)subPathsAreCounterClockwise:(NSMutableArray*)subPaths;
+(void)reverseSubPaths:(NSMutableArray*)subPaths;
+(ACSDSubPath*)subPath;
+(ACSDSubPath*)intersectionSubPathFromVertex:(IVertex*)startVertex;
+(NSArray*)intersectionsBetweenPath:(ACSDPath*)p0 andPath:(ACSDPath*)p1;
+(NSArray*)aNotBBetweenPath:(ACSDPath*)p0 andPath:(ACSDPath*)p1;
+(ACSDSubPath*)unionSubPathFromVertex:(IVertex*)startV;
+(ACSDSubPath*)aNotBSubPathFromVertex:(IVertex*)startV;
+(NSMutableArray*)subPathsFromBezierPath:(NSBezierPath*)path;
+ (NSMutableArray*)unionSubPathsFromVertexList:(NSArray*)vertexList;
-(NSMutableArray*)pathElements;
-(NSArray*)copyOfPathElements;
-(void)setIsClosed:(BOOL)b;
-(void)setIsClosedTo:(NSNumber*)b;
-(BOOL)isClosed;
-(void)setPathElements:(NSArray*)l;
-(void)splitAndRotateAtIndex:(NSInteger)ind;
- (void) applyTransform:(NSAffineTransform*)trans;
- (BOOL)removePathElementWithPoint:(NSPoint)hitPoint newSubPath:(ACSDSubPath**)newSubPath;
- (BOOL)splitPathWithPoint:(NSPoint)hitPoint copy:(BOOL)copy path:(ACSDPath*)path pathInd:(int)pathInd;
- (float)roughArea;
- (BOOL)isCounterClockWise;
-(NSMutableArray*)outlineStroke:(float)strokeWidth lineStart:(ACSDLineEnding*)lineStart lineEnd:(ACSDLineEnding*)lineEnd lineCap:(int)lineCap;
-(NSMutableArray*)outlineDashedStroke:(float)strokeWidth lineStart:(ACSDLineEnding*)lineStart lineEnd:(ACSDLineEnding*)lineEnd lineCap:(int)lineCap
		dashes:(NSArray*)dashes dashPhase:(float)dashPhase;
-(NSMutableArray*)linesFromSubPath;
- (void)reverse;
-(BOOL)deleteMarkedElementsIntoArray:(NSMutableArray**)outputArray;
-(void)deleteElement:(const KnobDescriptor&)kd;
-(KnobDescriptor)duplicateElement:(const KnobDescriptor&)kd;
-(void)insertElement:(ACSDPathElement*)el atIndex:(NSInteger)i;
-(BOOL)isClosedEqualTo:(NSNumber*)val;
-(void)offsetPointValue:(NSValue*)vp;
-(int)nearestKnobForPoint:(NSPoint)pt squaredDist:(float&)squaredDist;
-(NSRect)bounds;
-(ACSDSubPath*)mercatorSubPathWithRect:(NSRect)r;
-(ACSDSubPath*)demercatorSubPathWithRect:(NSRect)r;


@end
