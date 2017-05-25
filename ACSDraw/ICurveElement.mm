//
//  ICurveElement.mm
//  Drawtest4
//
//  Created by alan on 29/01/2005.
//  Copyright 2005 Alan C Smith. All rights reserved.
//

#import "ICurveElement.h"
#import "geometry.h"


@implementation ICurveElement

-(id)initWithVertex:(IVertex*)v inside:(bool)ins collinearSection:(bool)collinear cp1:(NSPoint)cPoint1 cp2:(NSPoint) cPoint2 marked:(bool)m
{
	if (self = [super initWithVertex:v inside:ins collinearSection:collinear marked:m])
	{
		_cp1 = cPoint1;
		_cp2 = cPoint2;
	}
	return self;
}

- (NSString *)description
{
	return [NSString stringWithFormat:@"%@ \n cp1 - %@; cp2 - %@",
			[super description],[NSValue valueWithPoint:_cp1],[NSValue valueWithPoint:_cp2]];
}

- (BOOL)isGeometricallyTheSameAs:(ISegElement*)seg
{
	if (![super isGeometricallyTheSameAs:seg])
		return NO;
	return NSEqualPoints(_cp1,[(ICurveElement*)seg cp1]) && NSEqualPoints(_cp2,[(ICurveElement*)seg cp2]);
}

- (BOOL)isGeometricallyTheReverseOf:(ISegElement*)seg
{
	if (![super isGeometricallyTheReverseOf:seg])
		return NO;
	return NSEqualPoints(_cp1,[(ICurveElement*)seg cp2]) && NSEqualPoints(_cp2,[(ICurveElement*)seg cp1]);
}

- (NSPoint)midPoint
{
	NSPoint fromPt = [self fromPoint];
	NSPoint toPt = [self toPoint];
	NSPoint c1EndPt,c1CP1,c1CP2,c2CP1,c2CP2;
	splitCurveByT(fromPt,toPt,_cp1,_cp2,0.5,c1EndPt,c1CP1,c1CP2,c2CP1,c2CP2);
	return c1EndPt;
}

-(NSPoint) prevNonCollinearPointSubPoint:(int)subPoint lpt1:(NSPoint)lpt1 lpt2:(NSPoint)lpt2 stopAt:(ISegElement*)stopSeg	//assume line is horizontal
{
	if (subPoint == 0)
		return [super prevNonCollinearPointSubPoint:0 lpt1:lpt1 lpt2:lpt2 stopAt:stopSeg];
	NSPoint fromPoint;
	if (subPoint == 1)
		fromPoint = _cp1;
	else
		fromPoint = _cp2;
	if (fromPoint.y == lpt1.y)	//is collinear
	{
		if (fromPoint.x > lpt1.x)					//point is to right
			return lpt1;
		return [self prevNonCollinearPointSubPoint:subPoint - 1 lpt1:lpt1 lpt2:lpt2 stopAt:stopSeg];
	}
	return fromPoint;
}

-(NSPoint) nextNonCollinearPointSubPoint:(int)subPoint lpt1:(NSPoint)lpt1 lpt2:(NSPoint)lpt2 stopAt:(ISegElement*)stopSeg	//assume line is horizontal
{
	NSPoint fromPoint;
	if (subPoint == 0)
		fromPoint = [self fromPoint];
	else if (subPoint == 1)
		fromPoint = _cp1;
	else
		fromPoint = _cp2;
	if (fromPoint.y == lpt1.y)	//is collinear
	{
		if (fromPoint.x > lpt1.x)					//point is to right
			return lpt1;
		if (subPoint == 2)
		{
			if (stopSeg == self.nextElement)
				return lpt1;
			return [self.nextElement nextNonCollinearPointSubPoint:0 lpt1:lpt1 lpt2:lpt2 stopAt:stopSeg];
		}
		else
			return [self nextNonCollinearPointSubPoint:subPoint + 1 lpt1:lpt1 lpt2:lpt2 stopAt:stopSeg];
	}
	return fromPoint;
}

-(bool)properIntersectionWithLinePt0:(NSPoint)lpt0 pt1:(NSPoint)lpt1
{
	NSMutableArray *intersectPoints = [NSMutableArray arrayWithCapacity:5];
	NSMutableArray *os = [NSMutableArray arrayWithCapacity:5];
	NSMutableArray *ot = [NSMutableArray arrayWithCapacity:5];
	float minX = [self fromPoint].x;
	if (minX > _cp1.x)
		minX = _cp1.x;
	if (minX > _cp2.x)
		minX = _cp2.x;
	if (minX > lpt0.x - 100)
		minX = lpt0.x - 100;
	lpt1.x = minX - 10.0;
	bool collinear;
	int noIntersections = lineCurveIntersection(lpt0,lpt1,[self fromPoint],[self toPoint],_cp1,_cp2,intersectPoints,os,ot,collinear,0.0,1.0,true);
	if (noIntersections != 1)
		return NO;
	if ([[os objectAtIndex:0]floatValue] < 0.0)
		return NO;
	float otval = [[ot objectAtIndex:0]floatValue];
	if (otval == 0.0)								//possible crossing point
		if ([self isCrossingPointForLpt1:lpt0 lpt2:lpt1])
			return YES;
	return otval < 1.0 && otval > 0.0;
}



@end
