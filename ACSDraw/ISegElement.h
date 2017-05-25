//
//  ISegElement.h
//  Drawtest4
//
//  Created by alan on 18/01/2005.
//  Copyright 2005 Alan C Smith. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "IVertex.h"


@interface ISegElement : NSObject

@property 	(retain) ISegElement *nextElement;
@property 	(assign) ISegElement *prevElement;
@property 	BOOL inside,visited,collinearSection,marked;
@property 	int crossings;
@property 	(retain) IVertex *toVertex;
@property 	(assign) IVertex *fromVertex;


-(id)initWithVertex:(IVertex*)v inside:(bool)ins collinearSection:(bool)collinear marked:(bool)m;
- (BOOL)isGeometricallyTheSameAs:(ISegElement*)seg;
- (BOOL)isGeometricallyTheReverseOf:(ISegElement*)seg;
- (void)incrementCrossings;
- (void)setAllVisited:(bool)b;
- (void)addElement:(ISegElement*)b;
- (NSPoint)point;
- (ISegElement*)fillInToVertices;
- (NSPoint)fromPoint;
- (NSPoint)toPoint;
- (NSPoint)midPoint;
-(NSPoint) prevNonCollinearPointSubPoint:(int)subPoint lpt1:(NSPoint)lpt1 lpt2:(NSPoint)lpt2 stopAt:(ISegElement*)stopSeg;
-(NSPoint) nextNonCollinearPointSubPoint:(int)subPoint lpt1:(NSPoint)lpt1 lpt2:(NSPoint)lpt2 stopAt:(ISegElement*)stopSeg;
-(bool) isCrossingPointForLpt1:(NSPoint)lpt1 lpt2:(NSPoint)lpt2;
-(ISegElement*)computeInsidePoly:(ISegElement*)polyHead;
-(ISegElement*)computeAllInsidePoly:(ISegElement*)polyHead;
-(void)incrementAllCrossings;
-(BOOL)isInsideBezierPath:(NSBezierPath*)p;
-(void)setInsideFromBezierPath:(NSBezierPath*)p;
-(void)setNotInsideFromBezierPath:(NSBezierPath*)p;

@end
