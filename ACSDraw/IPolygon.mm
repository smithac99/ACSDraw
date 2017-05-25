//
//  IPolygon.mm
//  Drawtest4
//
//  Created by alan on 16/01/2005.
//  Copyright 2005 Alan C Smith. All rights reserved.
//

#import "geometry.h"
#import "IPolygon.h"
#import "SubSegment.h"
#import "ISegElement.h"
#import "ICurve.h"
#import "ACSDSubPath.h"
#import "ACSDPath.h"
#import "gCurve.h"
#import "gLine.h"

void GetIntersectionsWithPolygon(IPolygon *pol1,NSInteger i,IPolygon *pol2,NSMutableDictionary *vertexDict);
void GetIntersections(IPolygon *pol1,int i,IPolygon *pol2,NSMutableDictionary *vertexDict);


@implementation IPolygon

+(IPolygon*) polygon
{
	return [[IPolygon alloc]init];
}

+(IPolygon*) polygonFromSubPath:(ACSDSubPath*)subPath vertexDict:(NSMutableDictionary*)vertexDict
{
	IPolygon *pol = [IPolygon polygon];
	NSArray *elements = [subPath linesFromSubPath];
	for (id g in elements)
	{
		if ([g isMemberOfClass:[gCurve class]])
			[pol addCurvePt0:[g pt1] cp1:[g cp1] cp2:[g cp2] vertexDict:vertexDict];
		else
			[pol addSegmentPt:[g fromPt] vertexDict:vertexDict];
	}
	[pol setIsClosed:[subPath isClosed]];
	return pol;
}

+(NSMutableArray*)polygonsFromPath:(ACSDPath*)path vertexDict:(NSMutableDictionary*)vertexDict
{
	NSArray *subPaths = [path subPaths];
	NSMutableArray *polygons = [NSMutableArray arrayWithCapacity:[subPaths count]];
	for (id sp in subPaths)
	{
		IPolygon *pol = [IPolygon polygonFromSubPath:sp vertexDict:vertexDict];
		[pol fillInToVertices];
		[polygons addObject:pol];
	}
	return polygons;
}

+(NSMutableArray*)polygonsFromSubPaths:(NSArray*)subPaths vertexDict:(NSMutableDictionary*)vertexDict
{
	NSMutableArray *polygons = [NSMutableArray arrayWithCapacity:[subPaths count]];
	for (id sp in subPaths)
	{
		IPolygon *pol = [IPolygon polygonFromSubPath:sp vertexDict:vertexDict];
		[pol fillInToVertices];
		[polygons addObject:pol];
	}
	return polygons;
}

-(id)init
{
	if (self = [super init])
	{
		self.componentList = [[NSMutableArray alloc]initWithCapacity:8];
		self.isClosed = YES;
	}
	return self;
}

- (NSString *)description
{
	return [NSString stringWithFormat:@"Component List - %@ \n ",self.componentList];
}

- (NSUInteger)noComponents
{
	return [self.componentList count];
}

- (IComponent*)component:(NSInteger)i
{
	NSInteger ct = [self noComponents];
	i = (i + ct) % ct;
	return [self.componentList objectAtIndex:i];
}

- (IVertex*)vertex:(NSInteger)i
{
	return [[self component:i]fromVertex];
}

- (NSPoint)point:(NSInteger)i
{
	IVertex *v = [self vertex:i];
	return NSMakePoint([v x],[v y]);
}

- (void)addSegmentfromX:(float)x y:(float)y vertexDict:(NSMutableDictionary*)vDict
{
	[self.componentList addObject:[[ISegment alloc]initWithX:x y:y vertexDict:vDict]];
}

- (void)addSegmentPt:(NSPoint)pt vertexDict:(NSMutableDictionary*)vDict
{
	[self.componentList addObject:[[ISegment alloc]initWithPoint:pt vertexDict:vDict]];
}

- (void)addCurvePt0:(NSPoint)pt0 cp1:(NSPoint)cp1 cp2:(NSPoint)cp2 vertexDict:(NSMutableDictionary*)vDict
{
	[self.componentList addObject:[[ICurve alloc]initWithPoint:pt0 controlPoint1:cp1 controlPoint2:cp2 vertexDict:vDict]];
}

- (void)fillInToVertices
{
	NSInteger ct = [self noComponents];
	if (ct == 0)
		return;
	IComponent *lastComp = [self component:0];
	for (NSInteger i = 1;i < ct;i++)
	{
		IComponent *comp = [self component:i];
		[lastComp setToVertex:[comp fromVertex]];
		lastComp = comp;
	}
	[lastComp setToVertex:[[self component:0] fromVertex]];
}

NSInteger sortChildren(id seg1,id seg2,void *contextInfo)
{
	double s1 = [(SubSegment*)seg1 s];
	double s2 = [(SubSegment*)seg2 s];
	if (s1 == s2)
		return NSOrderedSame;
	else if (s1 < s2)
		return NSOrderedAscending;
	else
		return NSOrderedDescending;
}

- (void)markChildren:(bool)b
{
	NSInteger ct = [self noComponents];
	for (NSInteger i = 0;i < ct;i++)
		[[self component:i]setMarked:b];
}

- (int)pt:(NSPoint)pt isInside:(IPolygon*)poly success:(bool*)success useY:(bool)useY
{
	int intersectionCount = 0;
	NSMutableDictionary *tempDict = [NSMutableDictionary dictionaryWithCapacity:2];
	NSPoint toPt;
	if (useY)
		toPt = NSMakePoint(pt.x,pt.y - 10.0);
	else
		toPt = NSMakePoint(pt.x - 10.0,pt.y);
	NSMutableArray *intersectPoints = [NSMutableArray arrayWithCapacity:8],
	*os = [NSMutableArray arrayWithCapacity:8],
	*ot = [NSMutableArray arrayWithCapacity:8];
	ISegment *iSeg = [ISegment segmentFrom:pt to:toPt vertexDict:tempDict];
	for (NSInteger i = 0,ct = [poly noComponents];i < ct;i++)
	{
		ISegment *iSeg2 = (ISegment*)[poly component:i];
		int noIntersections;
		bool isCollinear=NO;
		[intersectPoints removeAllObjects];
		[os removeAllObjects];
		[ot removeAllObjects];
		if ((noIntersections = [iSeg componentIntersection:iSeg2 intersectPoints:intersectPoints os:os ot:ot collinear:&isCollinear]) > 0)
		{
			if (isCollinear)
			{
				*success = NO;
				return false;
			}
			for (int k = 0;k < noIntersections;k++)
			{
				double sk = [[os objectAtIndex:k]doubleValue];
				double tk = [[ot objectAtIndex:k]doubleValue];
				if (tk == 0.0 || tk == 1.0)
				{
					*success = NO;
					return false;
				}
				if (tk > 0.0 && tk < 1.0 && sk > 0.0)
					intersectionCount++;
			}
		}
	}
	*success = YES;
	return intersectionCount;
}

- (int)segPtA:(NSPoint)ptA ptB:(NSPoint)ptB intersectionsWith:(IPolygon*)poly
{
	if (NSEqualPoints(ptA,ptB))
		return 0;
	bool successful = NO,useY = NO;
	int result=0;
	if (ptA.y == ptB.y)
		useY = YES;
	while (!successful)
	{
		double s = rand() / (RAND_MAX + 1.0);
		NSPoint midPoint;
		midPoint.x = ptA.x + (ptB.x - ptA.x) * s;
		midPoint.y = ptA.y + (ptB.y - ptA.y) * s;
		result = [self pt:midPoint isInside:poly success:&successful useY:useY];
	}
	return result;
}

- (bool)segPtA:(NSPoint)ptA ptB:(NSPoint)ptB isInside:(NSMutableArray*)polygonList
{
	int totalIntersections = 0;
	for (id pl in polygonList)
	{
		totalIntersections += [self segPtA:ptA ptB:ptB intersectionsWith:pl];
	}
	
	return (totalIntersections % 2) != 0;
}

- (IPolygon*) sortChildren
{
	NSUInteger ct = [self noComponents];
	for (NSUInteger i = 0;i < ct;i++)
	{
		IComponent *comp = [self component:i];
		[[comp children]sortUsingFunction: sortChildren context:NULL];
		bool inside = ([comp noNegs] % 2) != 0;
		[comp setInside:inside];
		for (SubSegment *subSeg in [comp children])
		{
			if ([subSeg flipInside])
				inside = !inside;
			if ([subSeg collinearSection])
				[subSeg setInside:YES];
			else
				[subSeg setInside:inside];
		}
	}
	return self;
}

- (IPolygon*)resolveCoincidentPoints:(NSMutableArray*)polygonList
{
	NSUInteger ct = [self noComponents];
	for (int i = 0;i < ct;i++)
	{
		IComponent *comp = [self component:i];
		if ([comp isCoincidentPoint])
		{
			bool inside = [self segPtA:[comp fromPoint] ptB:[comp toPoint] isInside:polygonList];
			[comp setInside:inside];
			for (SubSegment *subSeg in [comp children])
			{
				if ([subSeg flipInside])
					inside = !inside;
				if ([subSeg collinearSection])
					[subSeg setInside:YES];
				else
					[subSeg setInside:inside];
			}
		}
	}
	return self;
}

- (ISegElement*)expandSegments
{
	NSUInteger ct = [self noComponents];
	ISegElement *head = nil,*curr = nil;
	for (int i = 0;i < ct;i++)
	{
		IComponent *component = [self component:i];
		[component expandChildrenHeadElement:&head currentElement:&curr];
	}
	[curr setNextElement:head];
	[head setPrevElement:curr];
	return head;
}

- (NSPoint)GetPointMajor:(NSInteger*)major minor:(NSInteger*)minor
{
	IComponent *ic = [self component:(*major)];
	if ([ic isMemberOfClass:[ISegment class]] || (*minor) == 0)
		return [[ic fromVertex]point];
	ICurve *icu = (ICurve*)ic;
	if ((*minor) == 1)
		return [icu cp1];
	return [icu cp2];
}

- (NSPoint)GetNextPointMajor:(NSInteger*)major minor:(NSInteger*)minor
{
	IComponent *ic = [self component:(*major)];
	bool isCurve = [ic isMemberOfClass:[ICurve class]];
	(*minor)++;
	if ((*minor) > 2 || (!isCurve && (*minor) > 0))
	{
		(*major) = ((*major) + 1) % [self noComponents];
		(*minor) = 0;
	}
	return [self GetPointMajor:major minor:minor];
}

- (NSPoint)GetPreviousPointMajor:(NSInteger*)major minor:(NSInteger*)minor
{
	(*minor)--;
	if ((*minor) < 0)
	{
		NSInteger no = [self noComponents];
		(*major) = ((*major) - 1 + no) % no;
		if ([[self component:(*major)] isMemberOfClass:[ICurve class]])
			(*minor) = 2;
		else
			(*minor) = 0;
	}
	return [self GetPointMajor:major minor:minor];
}

- (bool)isCrossingPoint:(NSInteger)i pointA:(NSPoint)a pointB:(NSPoint)b
{
	//NSPoint intersectPoint = [self point:i];	//must be collinear with a and b
	int sj = 0, sk = 0;
	double s = collinearS(a,b,[self point:i]);
	NSInteger major = i, minor = 0;
	NSPoint nextPoint = [self GetNextPointMajor:&major minor:&minor];
	while (!(major == i && minor == 0)  && (sj = SignArea2(a,b,nextPoint)) == 0 && (s = collinearS(a,b,nextPoint)) >= 0.0 && s <= 1.0 )
		nextPoint = [self GetNextPointMajor:&major minor:&minor];
	if (major == i && minor == 0)
		return NO;
	major = i;
	minor = 0;
	NSPoint prevPoint = [self GetPreviousPointMajor:&major minor:&minor];
	while (!(major == i && minor == 0)  && (sk = SignArea2(a,b,prevPoint)) == 0 && (s = collinearS(a,b,prevPoint)) >= 0.0 && s <= 1.0)
		prevPoint = [self GetPreviousPointMajor:&major minor:&minor];
	if (major == i && minor == 0)
		return NO;
	return sj != sk;
}

void GetIntersectionsWithPolygon(IPolygon *pol1,NSInteger i,IPolygon *pol2,NSMutableDictionary *vertexDict)
{
	NSInteger noIntersections;
	NSInteger pol2Count = [pol2 noComponents];
	NSMutableArray *intersectPoints = [NSMutableArray arrayWithCapacity:8],
	*os = [NSMutableArray arrayWithCapacity:8],
	*ot = [NSMutableArray arrayWithCapacity:8];
	ISegment *iSeg = (ISegment*)[pol1 component:i];
	for (NSInteger j = 0;j < pol2Count;j++)
	{
		ISegment *iSeg2 = (ISegment*)[pol2 component:j];
		bool isCollinear=NO;
		[intersectPoints removeAllObjects];
		[os removeAllObjects];
		[ot removeAllObjects];
		if ((noIntersections = [iSeg componentIntersection:iSeg2 intersectPoints:intersectPoints os:os ot:ot collinear:&isCollinear]) > 0)
		{
			for (NSInteger k = 0;k < noIntersections;k++)
			{
				double tk = [[ot objectAtIndex:k]doubleValue];
				double sk = [[os objectAtIndex:k]doubleValue];
				NSPoint iPointk = [[intersectPoints objectAtIndex:k]pointValue];
				if (sk >= 0.0 && sk <= 1.0 && tk >= 0.0 && tk <= 1.0)
				{
					IVertex *iv = [IVertex vertexForPoint:iPointk vertexDict:vertexDict];
					if (sk > 0.0 && sk < 1.0 && tk <= 1.0)
					{
						SubSegment *subSeg = [[SubSegment alloc]initWithVertex:iv s:sk];
						[[iSeg children] addObject:subSeg];
						if (isCollinear)
							[subSeg setCollinearSection:YES];
					}
					if (tk > 0.0 && tk < 1.0 && sk <= 1.0)
					{
						SubSegment *subSeg = [[SubSegment alloc]initWithVertex:iv s:tk];
						[[iSeg2 children] addObject:subSeg];
						if (isCollinear)
							[subSeg setCollinearSection:YES];
					}
					if (sk == 0.0 && isCollinear)
						[iSeg setCollinearSection:YES];
					if (tk == 0.0 && isCollinear)
						[iSeg2 setCollinearSection:YES];
				}
			}
		}
	}
}

void GetIntersections(IPolygon *pol1,int i,IPolygon *pol2,NSMutableDictionary *vertexDict)
{
	NSInteger noIntersections;
	NSInteger pol2Count = [pol2 noComponents];
	NSMutableArray *intersectPoints = [NSMutableArray arrayWithCapacity:8],
	*os = [NSMutableArray arrayWithCapacity:8],
	*ot = [NSMutableArray arrayWithCapacity:8];
	ISegment *iSeg = (ISegment*)[pol1 component:i];
	for (NSInteger j = 0;j < pol2Count;j++)
	{
		ISegment *iSeg2 = (ISegment*)[pol2 component:j];
		bool isCollinear=NO;
		[intersectPoints removeAllObjects];
		[os removeAllObjects];
		[ot removeAllObjects];
		if ((noIntersections = [iSeg componentIntersection:iSeg2 intersectPoints:intersectPoints os:os ot:ot collinear:&isCollinear]) > 0)
		{
			for (NSInteger k = 0;k < noIntersections;k++)
			{
				bool sCrossingPoint = NO,tCrossingPoint = NO;
				double tk = [[ot objectAtIndex:k]doubleValue];
				double sk = [[os objectAtIndex:k]doubleValue];
				NSPoint iPointk = [[intersectPoints objectAtIndex:k]pointValue];
				NSInteger major = i,minor = 0;
				[pol1 GetPointMajor:&major minor:&minor];
				[pol1 GetNextPointMajor:&major minor:&minor];
				if (sk == 0.0 && (tk == 0.0 || tk == 1.0))
				{
					[iSeg setIsCoincidentPoint:YES];
					if (tk == 0.0)
						[iSeg2 setIsCoincidentPoint:YES];
				}
				if (tk == 0.0)
				{
					NSInteger major = i,minor = 0;
					NSPoint pta = [pol1 GetPointMajor:&major minor:&minor];
					NSPoint ptb = [pol1 GetNextPointMajor:&major minor:&minor];
					if ([pol2 isCrossingPoint:j pointA:pta pointB:ptb])
						sCrossingPoint = YES;
				}
				if (sk == 0.0)
				{
					NSInteger major = j,minor = 0;
					NSPoint pta = [pol2 GetPointMajor:&major minor:&minor];
					NSPoint ptb = [pol2 GetNextPointMajor:&major minor:&minor];
					if ([pol1 isCrossingPoint:i pointA:pta pointB:ptb])
						tCrossingPoint = YES;
				}
				if (sk >= 0.0 && sk <= 1.0 && tk >= 0.0 && tk <= 1.0)
				{
					IVertex *iv = [IVertex vertexForPoint:iPointk vertexDict:vertexDict];
					if (sk > 0.0 && sk < 1.0 && tk <= 1.0)
					{
						SubSegment *subSeg = [[SubSegment alloc]initWithVertex:iv s:sk];
						[[iSeg children] addObject:subSeg];
						if (tk == 0.0)
						{
							if (!sCrossingPoint)
								[subSeg setFlipInside:NO];
						}
						if (isCollinear)
						{
							[subSeg setCollinearSection:YES];
							[subSeg setFlipInside:NO];
						}
					}
					if (tk > 0.0 && tk < 1.0 && sk <= 1.0)
					{
						SubSegment *subSeg = [[SubSegment alloc]initWithVertex:iv s:tk];
						[[iSeg2 children] addObject:subSeg];
						if (sk == 0.0)
						{
							if (!tCrossingPoint)
								[subSeg setFlipInside:NO];
						}
						if (isCollinear)
						{
							[subSeg setCollinearSection:YES];
							[subSeg setFlipInside:NO];
						}
					}
				}
				if (sk <= 0.0)
				{
					if (sk == 0.0 && isCollinear)							//changed
						[iSeg setCollinearSection:YES];						//changed
					if (tk == 0.0)
					{
						if (sCrossingPoint)
							[iSeg setNoNegs:[iSeg noNegs]+1];
					}
					else if (tk > 0.0 && tk < 1.0)
						[iSeg setNoNegs:[iSeg noNegs]+1];
				}
				if (tk <= 0.0)
				{
					if (tk == 0.0 && isCollinear)							//changed
						[iSeg2 setCollinearSection:YES];					//changed
					if (sk == 0.0)
					{
						if (tCrossingPoint)
							[iSeg2 setNoNegs:[iSeg2 noNegs]+1];
					}
					else if (sk > 0.0 && sk < 1.0)
						[iSeg2 setNoNegs:[iSeg2 noNegs]+1];
				}
			}
		}
	}
}

-(void)getIntersectionsWith:(IPolygon*)polygon vertexDict:(NSMutableDictionary*)vertexDict
{
	NSInteger noSegs = [self noComponents];
	for (NSInteger i = 0;i < noSegs;i++)
		GetIntersectionsWithPolygon(self,i,polygon,vertexDict);
}

-(NSBezierPath*)outlineStroke:(float)strokeWidth lineStart:(ACSDLineEnding*)lineStart lineEnd:(ACSDLineEnding*)lineEnd vertexDict:(NSMutableDictionary*)vDict
{
	NSMutableArray *leftLines = [NSMutableArray arrayWithCapacity:[self noComponents]];
	NSMutableArray *rightLines = [NSMutableArray arrayWithCapacity:[self noComponents]];
	NSEnumerator *objEnum = [self.componentList objectEnumerator];
	IComponent *obj;
	while ((obj = [objEnum nextObject]) != nil)
		[obj outlineComponentLeftLines:leftLines rightLines:rightLines strokeWidth:strokeWidth vertexDict:vDict];
	
	return nil;
}

@end
