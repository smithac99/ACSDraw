//
//  ICurve.mm
//  Drawtest4
//
//  Created by alan on 27/01/2005.
//  Copyright 2005 Alan C Smith. All rights reserved.
//

#import "geometry.h"
#import "ICurve.h"
#import "SubSegment.h"
#import "ICurveElement.h"
#import "ISegment.h"



@implementation ICurve

+(ICurve*)curveFrom:(NSPoint)fromPoint to:(NSPoint)toPoint cp1:(NSPoint)cpt1 cp2:(NSPoint)cpt2 vertexDict:(NSMutableDictionary*)vDict
{
	return [[ICurve alloc]initWithFromPoint:fromPoint toPoint:toPoint controlPoint1:cpt1 controlPoint2:cpt2 vertexDict:vDict];
}

-(id)initWithVertex:(IVertex*)v controlPoint1:(NSPoint)cpt1 controlPoint2:(NSPoint)cpt2
{
	if (self = [super initWithVertex:v])
	{
		self.cp1 = cpt1;
		self.cp2 = cpt2;
	}
	return self;
}

-(id)initWithVertex:(IVertex*)v inside:(bool)ins controlPoint1:(NSPoint)cpt1 controlPoint2:(NSPoint)cpt2
{
	if (self = [super initWithVertex:v inside:ins])
	{
		self.cp1 = cpt1;
		self.cp2 = cpt2;
	}
	return self;
}

-(id)initWithPoint:(NSPoint)pt controlPoint1:(NSPoint)cpt1 controlPoint2:(NSPoint)cpt2 vertexDict:(NSMutableDictionary*)vDict
{
	if (self = [super initWithX:pt.x y:pt.y vertexDict:vDict])
	{
		self.cp1 = cpt1;
		self.cp2 = cpt2;
	}
	return self;
}

-(id)initWithFromPoint:(NSPoint)fpt toPoint:(NSPoint)tpt controlPoint1:(NSPoint)cpt1 controlPoint2:(NSPoint)cpt2 vertexDict:(NSMutableDictionary*)vDict
{
	if (self = [super initWithFromPoint:fpt toPoint:tpt vertexDict:vDict])
	{
		self.cp1 = cpt1;
		self.cp2 = cpt2;
	}
	return self;
}

- (NSString *)description
{
	return [NSString stringWithFormat:@"%@ \n cp1 - %g  %g; cp2 - %g  %g",
			[super description],self.cp1.x,self.cp1.y,self.cp2.x,self.cp2.y];
}

- (void)expandChildrenHeadElement:(ISegElement**)head currentElement:(ISegElement**)curr;
{
	double lastS = 0.0;
	NSPoint cpt0,cpt3,ccp1,ccp2;
	cpt0 = [fromVertex point];
	cpt3 = [toVertex point];
	ccp1 = self.cp1;
	ccp2 = self.cp2;
	id obj = self;
	for (NSInteger i = 0,ct = [children count];i < ct;i++)
	{
		NSPoint leftpt3,leftcp1,leftcp2,rightcp1,rightcp2;
		SubSegment *child = [children objectAtIndex:i];
		double thisS = ([child s] - lastS) * (1.0 / (1.0 - lastS));
		splitCurveByT(cpt0,cpt3,ccp1,ccp2,thisS,leftpt3,leftcp1,leftcp2,rightcp1,rightcp2);
		ICurveElement *newCurve = [[ICurveElement alloc]initWithVertex:[obj fromVertex]
																inside:[obj inside] collinearSection:[obj collinearSection]
																   cp1:leftcp1 cp2:leftcp2 marked:[self marked]];
		[[obj fromVertex] addSegment:newCurve];
		if ((*curr))
			[(*curr) addElement:newCurve];
		else
			(*head) = newCurve;
		(*curr) = newCurve;
		cpt0 = leftpt3;
		ccp1 = rightcp1;
		ccp2 = rightcp2;
		lastS = [child s];
		obj = child;
	}
	ICurveElement *newCurve = [[ICurveElement alloc]initWithVertex:[obj fromVertex]
															inside:[obj inside] collinearSection:[obj collinearSection]
															   cp1:ccp1 cp2:ccp2 marked:[self marked]];
	[[obj fromVertex] addSegment:newCurve];
	if ((*curr))
		[(*curr) addElement:newCurve];
	else
		(*head) = newCurve;
	(*curr) = newCurve;
}


- (int)componentIntersection:(IComponent*)c2 intersectPoints:(NSMutableArray*)intersectPoints
						  os:(NSMutableArray*)os ot:(NSMutableArray*)ot collinear:(bool*)collinear
{
	if ([c2 isMemberOfClass:[ISegment class]])
	{
		if (NSEqualPoints([[c2 fromVertex] point],[[c2 toVertex] point]))
			return 0;
		lineCurveIntersection([[c2 fromVertex] point],[[c2 toVertex] point],[[self fromVertex]point],[[self toVertex]point],
							  [self cp1],[self cp2],intersectPoints,ot,os,*collinear,0.0,1.0,true);
		[self getNegIntersectionsPtA:[[c2 fromVertex] point] ptB:[[c2 toVertex] point] intersectPoints:intersectPoints os:os ot:ot];
		return (int)[intersectPoints count];
	}
	else
	{
		ICurve *ic2 = (ICurve*)c2;
		curveCurveIntersection([fromVertex point],[toVertex point],self.cp1,self.cp2,[[ic2 fromVertex]point],[[ic2 toVertex]point],[ic2 cp1],[ic2 cp2],
							   intersectPoints,os,ot,*collinear,0.0,1.0,0.0,1.0);
		NSMutableArray *tempIntersectPoints = [NSMutableArray arrayWithCapacity:8],
		*tempOs = [NSMutableArray arrayWithCapacity:8],
		*tempOt = [NSMutableArray arrayWithCapacity:8];
		bool dummy;
		lineCurveIntersection([[self fromVertex] point],[self cp1],[[ic2 fromVertex]point],[[ic2 toVertex]point],
							  [ic2 cp1],[ic2 cp2],tempIntersectPoints,tempOs,tempOt,dummy,0.0,1.0,true);
		for (NSInteger i = 0,ct = [tempOs count];i < ct;i++)
		{
			if ([[tempOs objectAtIndex:i]doubleValue] < 0.0)
			{
				[intersectPoints addObject:[tempIntersectPoints objectAtIndex:i]];
				[os addObject:[tempOs objectAtIndex:i]];
				[ot addObject:[tempOt objectAtIndex:i]];
			}
		}
		[tempIntersectPoints removeAllObjects];
		[tempOs removeAllObjects];
		[tempOt removeAllObjects];
		lineCurveIntersection([[ic2 fromVertex] point],[ic2 cp1],[[self fromVertex]point],[[self toVertex]point],
							  [self cp1],[self cp2],tempIntersectPoints,tempOs,tempOt,dummy,0.0,1.0,true);
		for (NSInteger i = 0,ct = [tempOs count];i < ct;i++)
		{
			if ([[tempOs objectAtIndex:i]doubleValue] < 0.0)
			{
				[intersectPoints addObject:[tempIntersectPoints objectAtIndex:i]];
				[os addObject:[tempOt objectAtIndex:i]];
				[ot addObject:[tempOs objectAtIndex:i]];
			}
		}
		return (int)[intersectPoints count];
	}
	return 0;
}

- (void)getNegIntersectionsPtA:(NSPoint)a ptB:(NSPoint)b intersectPoints:(NSMutableArray*)intersectPoints
							os:(NSMutableArray*)os ot:(NSMutableArray*)ot
{
	NSPoint ip[5];
	double s[5],t[5];
	int ct = linesIntersect([fromVertex point],self.cp1,a,b,ip,s,t);
	for (int i = 0;i < ct;i++)
		if (s[i] < 0.0 && t[i] >=0 && t[i] < 1.0)
		{
			[intersectPoints addObject:[NSValue valueWithPoint:ip[i]]];
			[os addObject:[NSNumber numberWithDouble:s[i]]];
			[ot addObject:[NSNumber numberWithDouble:t[i]]];
		}
}

- (void)outlineComponentLeftLines:(NSMutableArray*)leftLines rightLines:(NSMutableArray*)rightLines strokeWidth:(float)strokeWidth vertexDict:(NSMutableDictionary*)vDict
{
	NSMutableArray *tempLeftLines = [NSMutableArray arrayWithCapacity:10];
	NSMutableArray *tempRightLines = [NSMutableArray arrayWithCapacity:10];
	gCurve *gc = [gCurve gCurvePt1:[self fromPoint] pt2:[self toPoint] cp1:[self cp1] cp2:[self cp2]];
	outlineCurve(gc,tempLeftLines,tempRightLines,strokeWidth);
	NSEnumerator *curveEnum = [tempLeftLines objectEnumerator];
	gCurve *curve;
	while ((curve = [curveEnum nextObject]) != nil)
		[leftLines addObject:[ICurve curveFrom:[curve pt1] to:[curve pt2] cp1:[curve cp1] cp2:[curve cp2] vertexDict:vDict]];
	curveEnum = [tempRightLines objectEnumerator];
	while ((curve = [curveEnum nextObject]) != nil)
		[rightLines addObject:[ICurve curveFrom:[curve pt1] to:[curve pt2] cp1:[curve cp1] cp2:[curve cp2] vertexDict:vDict]];
}


@end
