//
//  gParent.mm
//  ACSDraw
//
//  Created by alan on 15/02/2005.
//  Copyright 2005 Alan C Smith. All rights reserved.
//

#import "geometry.h"
#import "gParent.h"
#import "gElement.h"
#import "gCurve.h"
#import "gLine.h"
#import "ACSDGraphic.h"

NSMutableArray *reverseLines(NSMutableArray* lines);

NSMutableArray *reverseLines(NSMutableArray* lines)
   {
	NSMutableArray *rLines = [NSMutableArray arrayWithCapacity:[lines count]];
    NSEnumerator *objEnum = [lines reverseObjectEnumerator];
    id obj;
    while ((obj = [objEnum nextObject]) != nil) 
		if ([obj isKindOfClass:[gCurve class]])
			[rLines addObject:[gCurve gCurvePt1:[obj pt2] pt2:[obj pt1] cp1:[obj cp2] cp2:[obj cp1]]];
		else
			[rLines addObject:[gLine gLineFrom:[obj toPt] to:[obj fromPt]]];
	return rLines;
   }

@implementation gParent

+ (void)extendFirstElementOf:(NSMutableArray*)lines toPoint:(NSPoint)pt
   {
	id obj = [lines objectAtIndex:0];
	if ([obj isKindOfClass:[gCurve class]])
		[lines insertObject:[gLine gLineFrom:pt to:[obj firstPoint]]atIndex:0];
	else
		[obj setFromPt:pt];
   }

+ (void)extendLastElementOf:(NSMutableArray*)lines toPoint:(NSPoint)pt
   {
	id obj = [lines objectAtIndex:[lines count]-1];
	if ([obj isKindOfClass:[gCurve class]])
		[lines insertObject:[gLine gLineFrom:[obj lastPoint] to:pt]atIndex:[lines count]];
	else
		[obj setToPt:pt];
   }

+ (gParent*)parentWithDirection:(int)dir startVector:(NSPoint)sv endVector:(NSPoint)ev
   {
	return [[[gParent alloc]initWithDirection:dir startVector:sv endVector:ev]autorelease];
   }
   
- (id)initWithDirection:(int)dir startVector:(NSPoint)sv endVector:(NSPoint)ev
   {
	if (self = [super init])
	   {
		leftLines = [NSMutableArray arrayWithCapacity:2];
		rightLines = [NSMutableArray arrayWithCapacity:2];
		direction = dir;
		startDirectionVector = sv;
		endDirectionVector = ev;
	   }
	return self;
   }
/*
-(void)dealloc
   {
	if (leftLines)
		[leftLines release];
	if (rightLines)
		[rightLines release];
	[super dealloc];
   }
*/

- (NSString *)description
   {
	return [NSString stringWithFormat:@"gParent \n direction:%d startVector:%g %g endvector:%g %g\nleft:%@\nright:%@",
		direction,startDirectionVector.x,startDirectionVector.y,endDirectionVector.x,endDirectionVector.y,leftLines,rightLines];
   }


-(NSMutableArray*)leftLines
   {
	return leftLines;
   }

-(NSMutableArray*)rightLines
   {
	return rightLines;
   }

-(int)direction
   {
	return direction;
   }

-(NSPoint)startDirectionVector
   {
	return startDirectionVector;
   }

-(NSPoint)endDirectionVector
   {
	return endDirectionVector;
   }

-(void)setEndDirectionVector:(NSPoint)edv
   {
	endDirectionVector = edv;
   }

-(NSPoint)firstRightPoint
   {
	return [[rightLines objectAtIndex:0]firstPoint];
   }

-(NSPoint)lastRightPoint
   {
	return [[rightLines objectAtIndex:[rightLines count]-1]lastPoint];
   }

-(NSPoint)firstLeftPoint
   {
	return [[leftLines objectAtIndex:0]firstPoint];
   }

-(NSPoint)lastLeftPoint
   {
	return [[leftLines objectAtIndex:[leftLines count]-1]lastPoint];
   }

-(void)reverseLeftLines
   {
	leftLines = reverseLines(leftLines);
   }

-(void)addBetweenFor:(gParent*)nextParent
   {
	int nextDir = [nextParent direction];
	if (nextDir == 0)
		return;
	//NSPoint nextEndDirectionVector = [nextParent endDirectionVector];
	NSPoint intersectPoints[5];
	double os[5],ot[5];
	if (nextDir > 0)						//turning left
	   {
		NSPoint nextLineA = [nextParent firstRightPoint];
		NSPoint nextEndVector = [nextParent startDirectionVector];
		NSPoint nextLineB;
		nextLineB.x = nextLineA.x + nextEndVector.x;
		nextLineB.y = nextLineA.y + nextEndVector.y;
		NSPoint thisLineA = [self lastRightPoint];
		NSPoint thisLineB;
		thisLineB.x = thisLineA.x + endDirectionVector.x;
		thisLineB.y = thisLineA.y + endDirectionVector.y;
		int ct = linesIntersect(nextLineA,nextLineB,thisLineA,thisLineB,intersectPoints,os,ot);
		if (ct == 1 && ot[0] > 0.0)
		   {
		    [gParent extendFirstElementOf:[nextParent rightLines] toPoint:intersectPoints[0]];
		    [gParent extendLastElementOf:[self rightLines] toPoint:intersectPoints[0]];
		   }
		else if (ct == 0)
		   {
		    [gParent extendFirstElementOf:[nextParent rightLines] toPoint:[nextParent firstLeftPoint]];
		    [gParent extendLastElementOf:[self rightLines] toPoint:[self lastLeftPoint]];
		   }
	   }
	else						//turning right
	   {
		NSPoint nextLineA = [nextParent firstLeftPoint];
		NSPoint nextEndVector = [nextParent startDirectionVector];
		NSPoint nextLineB;
		nextLineB.x = nextLineA.x + nextEndVector.x;
		nextLineB.y = nextLineA.y + nextEndVector.y;
		NSPoint thisLineA = [self lastLeftPoint];
		NSPoint thisLineB;
		thisLineB.x = thisLineA.x + endDirectionVector.x;
		thisLineB.y = thisLineA.y + endDirectionVector.y;
		int ct = linesIntersect(nextLineA,nextLineB,thisLineA,thisLineB,intersectPoints,os,ot);
		if (ct == 1 && ot[0] > 0.0)
		   {
		    [gParent extendFirstElementOf:[nextParent leftLines] toPoint:intersectPoints[0]];
		    [gParent extendLastElementOf:[self leftLines] toPoint:intersectPoints[0]];
		   }
		else if (ct == 0)
		   {
		    [gParent extendFirstElementOf:[nextParent leftLines] toPoint:[nextParent firstRightPoint]];
		    [gParent extendLastElementOf:[self leftLines] toPoint:[self lastRightPoint]];
		   }
		
	   }
   }

-(void) addLinesToPath:(NSBezierPath*)path isClosed:(BOOL)isClosed startLineCap:(int)startLineCap endLineCap:(int)endLineCap
   {
	NSInteger count = [leftLines count] + [rightLines count];
	if (count == 0)
		return ;
	id obj;
	NSPoint lastPoint=NSZeroPoint,firstPoint={0.0,0.0};
	NSEnumerator *objEnum;
	if ([leftLines count] > 0)
	   {
		objEnum = [leftLines objectEnumerator];
		obj = [objEnum nextObject];
		firstPoint = [obj firstPoint];
		[path moveToPoint:[obj firstPoint]];
		while (obj)
		   {
			if ([obj isKindOfClass:[gCurve class]])
			   {
				[path curveToPoint:[obj pt2] controlPoint1:[obj cp1] controlPoint2:[obj cp2]];
				lastPoint = [obj pt2];
			   }
			else
			   {
				[path lineToPoint:[obj toPt]];
				lastPoint = [obj toPt];
			   }
			obj = [objEnum nextObject];
		   }
		if (isClosed)
			[path closePath];
	   }
	objEnum = [rightLines objectEnumerator];
	obj = [objEnum nextObject];
	if (obj)
		if (isClosed)
			[path moveToPoint:[obj firstPoint]];
		else
		   {
			if (startLineCap == NSRoundLineCapStyle)
			   {
			    float angle = getAngleForPoints(lastPoint,[obj firstPoint]);
				float xx = (lastPoint.x-[obj firstPoint].x);
				float yy = (lastPoint.y-[obj firstPoint].y);
				xx = xx * xx;
				yy = yy * yy;
				[path appendBezierPathWithArcWithCenter:NSMakePoint((lastPoint.x+[obj firstPoint].x)/2.0,(lastPoint.y+[obj firstPoint].y)/2.0)
					radius:(sqrt(xx + yy) / 2.0) startAngle:angle endAngle:(angle + 180)];
			   }
			else
				[path lineToPoint:[obj firstPoint]];
		   }
	while (obj)
	   {
		if ([obj isKindOfClass:[gCurve class]])
		   {
			[path curveToPoint:[obj pt2] controlPoint1:[obj cp1] controlPoint2:[obj cp2]];
			lastPoint = [obj pt2];
		   }
		else
		   {
			[path lineToPoint:[obj toPt]];
			lastPoint = [obj toPt];
		   }
		obj = [objEnum nextObject];
	   }
	if (endLineCap == NSRoundLineCapStyle)
	   {
		float angle = getAngleForPoints(lastPoint,firstPoint);
		float xx = (lastPoint.x-firstPoint.x);
		float yy = (lastPoint.y-firstPoint.y);
		xx = xx * xx;
		yy = yy * yy;
		[path appendBezierPathWithArcWithCenter:NSMakePoint((lastPoint.x+firstPoint.x)/2.0,(lastPoint.y+firstPoint.y)/2.0)
			radius:(sqrt(xx + yy) / 2.0) startAngle:angle endAngle:(angle + 180)];
	   }
	[path closePath];
   }


@end
