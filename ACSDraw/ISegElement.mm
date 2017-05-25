//
//  ISegElement.mm
//  Drawtest4
//
//  Created by alan on 18/01/2005.
//  Copyright 2005 Alan C Smith. All rights reserved.
//

#import "ISegElement.h"
#import "geometry.h"
#import "math.h"


@implementation ISegElement

-(id)initWithVertex:(IVertex*)v inside:(bool)ins collinearSection:(bool)collinear marked:(bool)m
{
	if (self = [super init])
	{
		self.fromVertex = v;
		self.inside = ins;
		self.visited = NO;
		self.marked = m;
		self.nextElement = nil;
		self.prevElement = nil;
		self.collinearSection = collinear;
	}
	return self;
}

- (NSString *)description
{
	return [NSString stringWithFormat:@"From Vertex - %@; To Vertex - %@;\n inside - %@; visited - %@; collinearSection - %@ ",
			self.fromVertex,self.toVertex,@(self.inside),@(self.visited),@(self.collinearSection)];
}

- (BOOL)isGeometricallyTheSameAs:(ISegElement*)seg
{
	if ([self class] != [seg class])
		return NO;
	if (self.fromVertex != [seg fromVertex] || self.toVertex != [seg toVertex])
		return NO;
	return YES;
}

- (BOOL)isGeometricallyTheReverseOf:(ISegElement*)seg
{
	if ([self class] != [seg class])
		return NO;
	if (self.fromVertex != [seg toVertex] || self.toVertex != [seg fromVertex])
		return NO;
	return YES;
}

- (NSPoint)point
{
	return [self.fromVertex point];
}

- (NSPoint)fromPoint
{
	return [self.fromVertex point];
}

- (NSPoint)toPoint
{
	return [self.toVertex point];
}

- (NSPoint)midPoint
{
	NSPoint pt = [self fromPoint];
	NSPoint t = [self toPoint];
	pt.x = (pt.x + t.x) / 2.0;
	pt.y = (pt.y + t.y) / 2.0;
	return pt;
}

-(BOOL)isInsideBezierPath:(NSBezierPath*)p
{
	return [p containsPoint:[self midPoint]];
}

-(void)setInsideFromBezierPath:(NSBezierPath*)p
{
	ISegElement *elPtr = self;
	do
	{
		[elPtr setInside:[elPtr isInsideBezierPath:p]];
		elPtr = [elPtr nextElement];
	} while (elPtr != self);
}

-(void)setNotInsideFromBezierPath:(NSBezierPath*)p
{
	ISegElement *elPtr = self;
	do
	{
		[elPtr setInside:![elPtr isInsideBezierPath:p]];
		elPtr = [elPtr nextElement];
	} while (elPtr != self);
}

- (void)incrementCrossings
{
	self.crossings++;
}

- (void)setAllVisited:(bool)b
{
	self.visited = b;
	if (self.nextElement)
		[self.nextElement setAllVisited:b];
}

- (void)addElement:(ISegElement*)b
{
	if (self.nextElement == nil)
	{
		[self setNextElement:b];
		if (b != nil)
			[b setPrevElement:self];
	}
	else
		[self.nextElement addElement:b];
}

- (ISegElement*)fillInToVertices
{
	ISegElement *elPtr = self;
	do
	{
		[elPtr setToVertex:[[elPtr nextElement]fromVertex]];
		[elPtr setCrossings:0];
		elPtr = [elPtr nextElement];
	} while (elPtr != self);
	return self;
}

-(NSPoint) prevNonCollinearPointSubPoint:(int)subPoint lpt1:(NSPoint)lpt1 lpt2:(NSPoint)lpt2 stopAt:(ISegElement*)stopSeg	//assume line is horizontal
{
	NSPoint fromPoint = [self fromPoint];
	if (fromPoint.y == lpt1.y)	//is collinear
	{
		if (fromPoint.x > lpt1.x)					//point is to right
			return lpt1;
		if (self.prevElement == stopSeg)
			return lpt1;
		return [self.prevElement prevNonCollinearPointSubPoint:2 lpt1:lpt1 lpt2:lpt2 stopAt:stopSeg];
	}
	return fromPoint;
}

-(NSPoint) nextNonCollinearPointSubPoint:(int)subPoint lpt1:(NSPoint)lpt1 lpt2:(NSPoint)lpt2 stopAt:(ISegElement*)stopSeg	//assume line is horizontal
{
	NSPoint fromPoint = [self fromPoint];
	if (fromPoint.y == lpt1.y)	//is collinear
	{
		if (fromPoint.x > lpt1.x)					//point is to right
			return lpt1;
		if (self.nextElement == stopSeg)
			return lpt1;
		return [self.nextElement nextNonCollinearPointSubPoint:0 lpt1:lpt1 lpt2:lpt2 stopAt:stopSeg];
	}
	return fromPoint;
}

-(bool) isCrossingPointForLpt1:(NSPoint)lpt1 lpt2:(NSPoint)lpt2			//assume line is horizontal
{
	NSPoint pPt = [self prevNonCollinearPointSubPoint:0 lpt1:lpt1 lpt2:lpt2 stopAt:self];
	if (pPt.y == lpt1.y)
		return NO;
	NSPoint nPt = [self nextNonCollinearPointSubPoint:0 lpt1:lpt1 lpt2:lpt2 stopAt:self];
	if (nPt.y == lpt1.y)
		return NO;
	return ((pPt.y - lpt1.y) < 0) != ((nPt.y - lpt1.y) < 0);
}

-(bool)properIntersectionWithLinePt0:(NSPoint)lpt0 pt1:(NSPoint)lpt1
{
	NSPoint intersectPoints[5];
	double os[5],ot[5];
	int noIntersections = linesIntersect(lpt0,lpt1,[self fromPoint],[self toPoint],intersectPoints,os,ot);
	if (noIntersections != 1)
		return NO;
	if (os[0] >= 0.0)
		return NO;
	if (ot[0] == 0.0)								//possible crossing point
		if ([self isCrossingPointForLpt1:lpt0 lpt2:lpt1])
			return YES;
	return ot[0] < 1.0 && ot[0] > 0.0;
}

-(ISegElement*)computeInsidePoly:(ISegElement*)polyHead
{
	NSPoint lpt0 = [self midPoint],lpt1;
	lpt1.x = lpt0.x + 100.0;
	lpt1.y = lpt0.y;
	ISegElement *elPtr = polyHead;
	do
	{
		if ([elPtr properIntersectionWithLinePt0:lpt0 pt1:lpt1])
			self.crossings++;
		elPtr = [elPtr nextElement];
	} while (elPtr != polyHead);
	return self;
}

-(ISegElement*)computeAllInsidePoly:(ISegElement*)polyHead
{
	ISegElement *elPtr = self;
	do
	{
		[elPtr computeInsidePoly:polyHead];
		elPtr = [elPtr nextElement];
	} while (elPtr != self);
	return self;
}

-(void)incrementAllCrossings
{
	ISegElement *elPtr = self;
	do
	{
		[elPtr incrementCrossings];
		elPtr = [elPtr nextElement];
	} while (elPtr != self);
}

@end
