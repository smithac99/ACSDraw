//
//  ISegment.mm
//  Drawtest4
//
//  Created by alan on 16/01/2005.
//  Copyright 2005 Alan C Smith. All rights reserved.
//

#import "geometry.h"
#import "ISegment.h"
#import "ISegElement.h"
#import "SubSegment.h"
#import "ICurve.h"

int getCollinearIntersectPoints(NSPoint a,NSPoint b,NSPoint c,NSPoint d,NSMutableArray* intersectPoints,NSMutableArray* os,NSMutableArray* ot);
int checkEndPointsIntersect(NSPoint a,NSPoint b,NSPoint c,NSPoint d,NSMutableArray* intersectPoints,NSMutableArray* os,NSMutableArray* ot);
int linesIntersect(NSPoint a,NSPoint b,NSPoint c,NSPoint d,NSMutableArray* intersectPoints,NSMutableArray* os,NSMutableArray* ot);



@implementation ISegment

+(ISegment*)segmentFrom:(NSPoint)fromPoint to:(NSPoint)toPoint vertexDict:(NSMutableDictionary*)vDict
{
	return [[ISegment alloc]initWithFromPoint:fromPoint toPoint:toPoint vertexDict:vDict];
}

-(id)initWithVertex:(IVertex*)v
{
	self = [super initWithVertex:v];
	return self;
}

-(id)initWithVertex:(IVertex*)v inside:(bool) ins
{
	self = [super initWithVertex:v inside:ins];
	return self;
}

-(id)initWithX:(float)xVal y:(float)yVal vertexDict:(NSMutableDictionary*)vDict
{
	self = [super initWithX:xVal y:yVal vertexDict:vDict];
	return self;
}

-(id)initWithPoint:(NSPoint)pt vertexDict:(NSMutableDictionary*)vDict
{
	self = [super initWithPoint:pt vertexDict:vDict];
	return self;
}

- (void)expandChildrenHeadElement:(ISegElement**)head currentElement:(ISegElement**)curr;
{
	ISegElement *newSeg;
	newSeg = [[ISegElement alloc]initWithVertex:[self fromVertex] inside:[self inside]
							   collinearSection:[self collinearSection]marked:[self marked]];
	if (*curr)
		[(*curr) addElement:newSeg];
	else
		(*head) = newSeg ;
	(*curr) = newSeg;
	[[self fromVertex] addSegment:newSeg];
	for (NSInteger j = 0,c = [[self children]count];j < c;j++)
	{
		SubSegment *subseg = [[self children]objectAtIndex:j];
		IVertex *iv = [subseg fromVertex];
		newSeg = [[ISegElement alloc]initWithVertex:iv inside:[subseg inside] collinearSection:[subseg collinearSection]marked:[self marked]];
		if (*curr)
			[(*curr) addElement:newSeg];
		else
			(*head) = newSeg;
		(*curr) = newSeg;
		[iv addSegment:newSeg];
	}
}

int getCollinearIntersectPoints(NSPoint a,NSPoint b,NSPoint c,NSPoint d,NSMutableArray* intersectPoints,NSMutableArray* os,NSMutableArray* ot)
{
	[intersectPoints addObject:[NSValue valueWithPoint:a]];
	[os addObject:[NSNumber numberWithDouble:0.0]];
	[ot addObject:[NSNumber numberWithDouble:collinearS(c,d,a)]];
	
	[intersectPoints addObject:[NSValue valueWithPoint:b]];
	[os addObject:[NSNumber numberWithDouble:1.0]];
	[ot addObject:[NSNumber numberWithDouble:collinearS(c,d,b)]];
	
	if (!NSEqualPoints(a,c) && !NSEqualPoints(b,c))
	{
		[intersectPoints addObject:[NSValue valueWithPoint:c]];
		[os addObject:[NSNumber numberWithDouble:collinearS(a,b,c)]];
		[ot addObject:[NSNumber numberWithDouble:0.0]];
	}
	
	if (!NSEqualPoints(a,d) && !NSEqualPoints(b,d))
	{
		[intersectPoints addObject:[NSValue valueWithPoint:d]];
		[os addObject:[NSNumber numberWithDouble:collinearS(a,b,d)]];
		[ot addObject:[NSNumber numberWithDouble:1.0]];
	}
	return (int)[os count];
}

int checkEndPointsIntersect(NSPoint a,NSPoint b,NSPoint c,NSPoint d,NSMutableArray* intersectPoints,NSMutableArray* os,NSMutableArray* ot)
{
	if (NSEqualPoints(a,c))
	{
		[intersectPoints addObject:[NSValue valueWithPoint:a]];
		[os addObject:[NSNumber numberWithDouble:0.0]];
		[ot addObject:[NSNumber numberWithDouble:0.0]];
		return 1;
	}
	if (NSEqualPoints(b,c))
	{
		[intersectPoints addObject:[NSValue valueWithPoint:b]];
		[os addObject:[NSNumber numberWithDouble:1.0]];
		[ot addObject:[NSNumber numberWithDouble:0.0]];
		return 1;
	}
	if (NSEqualPoints(a,d))
	{
		[intersectPoints addObject:[NSValue valueWithPoint:a]];
		[os addObject:[NSNumber numberWithDouble:0.0]];
		[ot addObject:[NSNumber numberWithDouble:1.0]];
		return 1;
	}
	if (NSEqualPoints(b,d))
	{
		[intersectPoints addObject:[NSValue valueWithPoint:b]];
		[os addObject:[NSNumber numberWithDouble:1.0]];
		[ot addObject:[NSNumber numberWithDouble:1.0]];
		return 1;
	}
	return 0;
}

int linesIntersect(NSPoint a,NSPoint b,NSPoint c,NSPoint d,NSMutableArray* intersectPoints,NSMutableArray* os,NSMutableArray* ot)
											//returns no of intersections of line ab with line cd
											//if actual segment intersection, s will be >=0 and <=1
{
	double num,denom,s,t;
	denom = a.x * (d.y - c.y) +
	b.x * (c.y - d.y) +
	d.x * (b.y - a.y) +
	c.x * (a.y - b.y);
	if (denom == 0.0)							// lines are parallel
		if (collinear(a,b,c))
		{
			int ct = getCollinearIntersectPoints(a,b,c,d,intersectPoints,os,ot);
			return ct;
		}
		else
			return 0;
	if (checkEndPointsIntersect(a,b,c,d,intersectPoints,os,ot))		//required because of rounding errors
		return 1;
	num =   a.x * (d.y - c.y) +
	c.x * (a.y - d.y) +
	d.x * (c.y - a.y);
	s = num/denom;
	num =   -(a.x * (c.y - b.y) +
			  b.x * (a.y - c.y) +
			  c.x * (b.y - a.y));
	t = num/denom;
	[intersectPoints addObject:[NSValue valueWithPoint:NSMakePoint(a.x + s * (b.x - a.x),a.y + s * (b.y - a.y))]];
	[os addObject:[NSNumber numberWithDouble:s]];
	[ot addObject:[NSNumber numberWithDouble:t]];
	return 1;
}

- (int)componentIntersection:(IComponent*)c2 intersectPoints:(NSMutableArray*)intersectPoints
						  os:(NSMutableArray*)os ot:(NSMutableArray*)ot collinear:(bool*)collinear
{
	if (NSEqualPoints([fromVertex point],[toVertex point]))
		return 0;
	if ([c2 isMemberOfClass:[ISegment class]])
	{
		int ct = linesIntersect([fromVertex point],[toVertex point],[[c2 fromVertex]point],[[c2 toVertex]point],intersectPoints,os,ot);
		*collinear = (ct > 1);
		return ct;
	}
	else
	{
		ICurve *ic2 = (ICurve*)c2;
		lineCurveIntersection([fromVertex point],[toVertex point],[[ic2 fromVertex]point],[[ic2 toVertex]point],[ic2 cp1],[ic2 cp2],
							  intersectPoints,os,ot,*collinear,0.0,1.0,true);
		[ic2 getNegIntersectionsPtA:[[self fromVertex] point] ptB:[[self toVertex] point] intersectPoints:intersectPoints os:ot ot:os];
		return (int)[os count];
	}
	return 0;
}

- (void)outlineComponentLeftLines:(NSMutableArray*)leftLines rightLines:(NSMutableArray*)rightLines strokeWidth:(float)strokeWidth vertexDict:(NSMutableDictionary*)vDict
{
	float w2 = strokeWidth / 2;
	NSPoint fromPt = [fromVertex point];
	NSPoint toPt = [toVertex point];
	NSPoint d = diff_points(toPt,fromPt);		//difference vector
	NSPoint perpD = lperp(d);					//perpendicular to difference vector
	float t = w2 / dlen(perpD);					//relates t to the length of the difference vector
	float dx = perpD.x * t;
	float dy = perpD.y * t;
	NSPoint lFromPt,lToPt,rFromPt,rToPt;
	lFromPt.x = fromPt.x + dx;
	lFromPt.y = fromPt.y + dy;
	lToPt.x = toPt.x + dx;
	lToPt.y = toPt.y + dy;
	dx = -dx;
	dy = -dy;
	rFromPt.x = fromPt.x + dx;
	rFromPt.y = fromPt.y + dy;
	rToPt.x = toPt.x + dx;
	rToPt.y = toPt.y + dy;
	[leftLines addObject:[ISegment segmentFrom:lFromPt to:lToPt vertexDict:vDict]];
	[rightLines addObject:[ISegment segmentFrom:rFromPt to:rToPt vertexDict:vDict]];
}




@end
