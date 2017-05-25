//
//  ACSDPathElement.h
//  ACSDraw
//
//  Created by Alan Smith on Mon Feb 04 2002.
//  Copyright (c) 2001 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface ACSDPathElement : NSObject

@property NSPoint point,preControlPoint,postControlPoint;
@property BOOL isLineToPoint,hasPreControlPoint,hasPostControlPoint,controlPointsContinuous;
@property BOOL deletePoint;
@property BOOL deleteFollowingLine;

+(ACSDPathElement*)mergePathElement1:(ACSDPathElement*)pe1 andPathElement2:(ACSDPathElement*)pe2;
+(int)pathElementsFromSubPath:(NSBezierPath*)path startFrom:(int)startInd addToArray:(NSMutableArray*)elements isClosed:(BOOL*)closed;
-(id)initWithPoint:(NSPoint)pt preControlPoint:(NSPoint)preCP postControlPoint:(NSPoint)postCP 
	hasPreControlPoint:(BOOL) hasPreCP hasPostControlPoint:(BOOL)hasPostCP isLineToPoint:(BOOL)iltp;


-(void)setPreCPFromPostCP;
-(void)setPostCPFromPreCP;
-(void)setPreCPFromPostCPAngle;
-(void)setPostCPFromPreCPAngle;
-(NSRect)controlPointBounds;
-(void)moveToPoint:(NSPoint)pt;
-(void)offsetPoint:(NSPoint)pt;
-(void)offsetPointValue:(NSValue*)vp;
- (void) applyTransform:(NSAffineTransform*)trans;
-(void)setFromElement:(ACSDPathElement*)pe;
-(void)setWithPoint:(NSPoint)pt preControlPoint:(NSPoint)preCP postControlPoint:(NSPoint)postCP 
	hasPreControlPoint:(BOOL) hasPreCP hasPostControlPoint:(BOOL)hasPostCP isLineToPoint:(BOOL)iltp 
	controlPointsContinuous:(BOOL) cpc;
-(ACSDPathElement*)reverse;
-(void)resetDeleteMarkers;
-(ACSDPathElement*)mercatorWithRect:(NSRect)r;
-(ACSDPathElement*)demercatorWithRect:(NSRect)r;

@end
