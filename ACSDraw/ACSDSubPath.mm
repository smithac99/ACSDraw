//
//  ACSDSubPath.mm
//  ACSDraw
//
//  Created by Alan Smith on Tue Mar 05 2002.
//  Copyright (c) 2001 __MyCompanyName__. All rights reserved.
//

#import "ACSDPath.h"
#import "ACSDSubPath.h"
#import "ACSDGraphic.h"
#import "ACSDPathElement.h"
#import "ACSDLineEnding.h"
#import "geometry.h"
#import "gParent.h"
#import "IVertex.h"
#import "ICurveElement.h"
#import "IPolygon.h"
#import "ArrayAdditions.h"
#import "gElement.h"

void addLine(NSMutableArray *lines,NSPoint pt1,NSPoint pt2,NSPoint cp1,NSPoint cp2,BOOL hasCP1,BOOL hasCP2);
NSBezierPath *joinLines(NSMutableArray* leftLines,NSMutableArray* rightLines,bool isClosed);
void setDirs(gElement *gi,gElement*gj);
float angleForVector(NSPoint v);
bool vectorsEquivalent(NSPoint v1,NSPoint v2);
NSBezierPath *lineEndingPath(ACSDLineEnding *lineEnding,NSPoint pt1,NSPoint pt2,float strokeWidth);

@implementation ACSDSubPath

+(ACSDPath*)unionPathFromSubPaths:(NSArray*)subPathArray
   {
	NSInteger ct = [subPathArray count];
	ACSDPath *o0 = [ACSDPath pathWithSubPaths:[NSArray arrayWithObject:[subPathArray objectAtIndex:(ct - 1)]]];
	for (NSInteger i = ct - 2;i >= 0;i--)
	   {
		ACSDPath *o1 = [ACSDPath pathWithSubPaths:[NSArray arrayWithObject:[subPathArray objectAtIndex:i]]];
		NSArray *vertexList = [ACSDSubPath intersectionsBetweenPath:o0 andPath:o1];
		o0 = [ACSDPath pathWithSubPaths:[ACSDSubPath unionSubPathsFromVertexList:vertexList]];
	   }
	return o0;
   }

+(ACSDPath*)unionPathFromPaths:(NSArray*)pathArray
   {
	NSInteger ct = [pathArray count];
	ACSDPath *o0 = [pathArray objectAtIndex:(ct - 1)];
	for (NSInteger i = ct - 2;i >= 0;i--)
	   {
		ACSDPath *o1 = [pathArray objectAtIndex:i];
		NSArray *vertexList = [ACSDSubPath intersectionsBetweenPath:o0 andPath:o1];
		o0 = [ACSDPath pathWithSubPaths:[ACSDSubPath unionSubPathsFromVertexList:vertexList]];
	   }
	return o0;
   }

+(NSArray*)aNotBBetweenPath:(ACSDPath*)p0 andPath:(ACSDPath*)p1
   {
	NSMutableDictionary *vertexDict = [NSMutableDictionary dictionaryWithCapacity:40];
	NSMutableArray *polygonArray0 = [IPolygon polygonsFromSubPaths:[p0 subPaths] vertexDict:vertexDict];
	NSMutableArray *polygonArray1 = [IPolygon polygonsFromSubPaths:[p1 subPaths] vertexDict:vertexDict];
	for (NSInteger i = 0,iCount = [polygonArray0 count];i < iCount;i++)
	   {
	    IPolygon *poli = [polygonArray0 objectAtIndex:i];
		for (NSInteger j = 0,jCount = [polygonArray1 count];j < jCount;j++)
		   {
			IPolygon* polj = [polygonArray1 objectAtIndex:j];
			[poli getIntersectionsWith:polj vertexDict:vertexDict];
		   }
	   }
	for (NSInteger i = 0,iCount = [polygonArray0 count];i < iCount;i++)
	   {
		ISegElement *se = [[[[polygonArray0 objectAtIndex:i]sortChildren]expandSegments]fillInToVertices];
		[se setNotInsideFromBezierPath:[p1 transformedBezierPath]];
	   }
	for (NSInteger i = 0,iCount = [polygonArray1 count];i < iCount;i++)
	   {
		ISegElement *se = [[[[polygonArray1 objectAtIndex:i]sortChildren]expandSegments]fillInToVertices];
		[se setInsideFromBezierPath:[p0 transformedBezierPath]];
	   }
	[IVertex removeDuplicateSegmentsFromVertexDict:vertexDict];
	return [vertexDict allValues];
   }

+(NSArray*)intersectionsBetweenPath:(ACSDPath*)p0 andPath:(ACSDPath*)p1
   {
	NSMutableDictionary *vertexDict = [NSMutableDictionary dictionaryWithCapacity:40];
	NSMutableArray *polygonArray0 = [IPolygon polygonsFromSubPaths:[p0 subPaths] vertexDict:vertexDict];
	NSMutableArray *polygonArray1 = [IPolygon polygonsFromSubPaths:[p1 subPaths] vertexDict:vertexDict];
	for (NSInteger i = 0,iCount = [polygonArray0 count];i < iCount;i++)
	   {
	    IPolygon *poli = [polygonArray0 objectAtIndex:i];
		for (NSInteger j = 0,jCount = [polygonArray1 count];j < jCount;j++)
		   {
			IPolygon* polj = [polygonArray1 objectAtIndex:j];
			[poli getIntersectionsWith:polj vertexDict:vertexDict];
		   }
	   }
	for (NSInteger i = 0,iCount = [polygonArray0 count];i < iCount;i++)
	   {
		ISegElement *se = [[[[polygonArray0 objectAtIndex:i]sortChildren]expandSegments]fillInToVertices];
		[se setInsideFromBezierPath:[p1 transformedBezierPath]];
	   }
	for (NSInteger i = 0,iCount = [polygonArray1 count];i < iCount;i++)
	   {
		ISegElement *se = [[[[polygonArray1 objectAtIndex:i]sortChildren]expandSegments]fillInToVertices];
		[se setInsideFromBezierPath:[p0 transformedBezierPath]];
	   }
	[IVertex removeDuplicateSegmentsFromVertexDict:vertexDict];
	return [vertexDict allValues];
   }

+ (NSMutableArray*)unionSubPathsFromVertexList:(NSArray*)vertexList
   {
	NSMutableArray *resultArray = [NSMutableArray arrayWithCapacity:5];
	bool allVisited = NO;
	NSInteger vCount = [vertexList count];
	while (!allVisited)
	   {
		allVisited = YES;
		int vInd = 0;
		while (vInd < vCount && allVisited)
		   {
			IVertex *v = [vertexList objectAtIndex:vInd];
			NSSet *segSet = [v candidateSegmentsUnion];
			if ([segSet count] > 0)
			   {
				id res = [ACSDSubPath unionSubPathFromVertex:v];
				if (res)
					[resultArray addObject:res];
				allVisited = NO;
			   }
			vInd++;
		   }
	   }
	return resultArray;
   }


+(bool)subPathsAreCounterClockwise:(NSMutableArray*)subPaths
   {
	float area = 0.0;
	NSEnumerator *subPathEnum = [subPaths objectEnumerator];
	ACSDSubPath *subPath;
	while ((subPath = [subPathEnum nextObject]) != nil)
		area += [subPath roughArea];
	return area >= 0.0;
   }

+(void)reverseSubPaths:(NSMutableArray*)subPaths
   {
	NSEnumerator *subPathEnum = [subPaths objectEnumerator];
	ACSDSubPath *subPath;
	while ((subPath = [subPathEnum nextObject]) != nil)
		[subPath reverse];
   }

+(ACSDSubPath*)intersectionSubPathFromVertex:(IVertex*)startV
   {
	NSBezierPath *path = [NSBezierPath bezierPath];
	[path moveToPoint:[startV point]];
	IVertex *currV = startV;
	while (currV)
	   {
		NSSet *segSet = [currV candidateSegmentsIntersect];
		if ([segSet count] > 0)
		   {
			NSEnumerator *segEnum = [segSet objectEnumerator];
			ISegElement *seg = [segEnum nextObject];
			[seg setVisited:YES];
			ISegElement *tseg;
			while ((tseg = [segEnum nextObject]))
				if ([[tseg nextElement]fromVertex] == currV)
					[tseg setVisited:YES];
			if ([seg isMemberOfClass:[ICurveElement class]])
				[path curveToPoint:[[seg toVertex]point] controlPoint1:[(ICurveElement*)seg cp1] controlPoint2:[(ICurveElement*)seg cp2]];
			else
				[path lineToPoint:[[seg toVertex] point]];
			currV = [seg toVertex];
		   }
		else
			currV = nil;
	   }
	[path closePath];
	NSArray *arr = [ACSDSubPath subPathsFromBezierPath:path];
	if ([arr count] > 0)
		return [arr objectAtIndex:0];
	return nil;
   }

+(ACSDSubPath*)unionSubPathFromVertex:(IVertex*)startV
   {
	NSBezierPath *path = [NSBezierPath bezierPath];
	[path moveToPoint:[startV point]];
	IVertex *currV = startV;
	while (currV)
	   {
		NSSet *segSet = [currV candidateSegmentsUnion];
		if ([segSet count] > 0)
		   {
			NSEnumerator *segEnum = [segSet objectEnumerator];
			ISegElement *seg = [segEnum nextObject];
			[seg setVisited:YES];
			ISegElement *tseg;
			while ((tseg = [segEnum nextObject]))
				if ([[tseg nextElement]fromVertex] == currV)
					[tseg setVisited:YES];
			if ([seg isMemberOfClass:[ICurveElement class]])
				[path curveToPoint:[[seg toVertex]point] controlPoint1:[(ICurveElement*)seg cp1] controlPoint2:[(ICurveElement*)seg cp2]];
			else
				[path lineToPoint:[[seg toVertex] point]];
			currV = [seg toVertex];
		   }
		else
			currV = nil;
	   }
	[path closePath];
	NSArray *arr = [ACSDSubPath subPathsFromBezierPath:path];
	if ([arr count] > 0)
		return [arr objectAtIndex:0];
	return nil;
   }

+(ACSDSubPath*)aNotBSubPathFromVertex:(IVertex*)startV
   {
	NSBezierPath *path = [NSBezierPath bezierPath];
	[path moveToPoint:[startV point]];
	IVertex *currV = startV;
	while (currV)
	   {
		NSSet *segSet = [currV candidateSegmentsANotB];
		if ([segSet count] > 0)
		   {
			NSEnumerator *segEnum = [segSet objectEnumerator];
			ISegElement *seg = [segEnum nextObject];
			[seg setVisited:YES];
			ISegElement *tseg;
			while ((tseg = [segEnum nextObject]))
				if ([[tseg nextElement]fromVertex] == currV)
					[tseg setVisited:YES];
			if ([seg isMemberOfClass:[ICurveElement class]])
				[path curveToPoint:[[seg toVertex]point] controlPoint1:[(ICurveElement*)seg cp1] controlPoint2:[(ICurveElement*)seg cp2]];
			else
				[path lineToPoint:[[seg toVertex] point]];
			currV = [seg toVertex];
		   }
		else
			currV = nil;
	   }
	[path closePath];
	NSArray *arr = [ACSDSubPath subPathsFromBezierPath:path];
	if ([arr count] > 0)
		return [arr objectAtIndex:0];
	return nil;
   }

+(ACSDSubPath*)subPath
   {
	return [[[ACSDSubPath alloc]init]autorelease];
   }


+(NSMutableArray*)subPathsFromBezierPath:(NSBezierPath*)path
   {
	NSInteger count = [path elementCount];
	int startInd = 0;
	NSMutableArray *subPathList = [NSMutableArray arrayWithCapacity:count];
	while (startInd < count)
	   {
		ACSDSubPath *sub = [[[ACSDSubPath alloc]init]autorelease];
		BOOL closed;
		startInd = [ACSDPathElement pathElementsFromSubPath:path startFrom:startInd addToArray:[sub pathElements] isClosed:&closed];
		[sub setIsClosed:closed];
		[subPathList addObject:sub];
	   }
	ACSDSubPath *sub = [subPathList objectAtIndex:[subPathList count]-1];
	if ([[sub pathElements] count] == 1)
		[subPathList removeObjectAtIndex:[subPathList count]-1];
	return subPathList; 
   }

-(id)init
   {
    if (self = [super init])
	   {
		pathElements = [[NSMutableArray arrayWithCapacity:12]retain];
		isClosed = NO;
	   }
	return self;
   }

- (void) encodeWithCoder:(NSCoder*)coder
   {
	[coder encodeObject:pathElements forKey:@"ACSDSubPath_pathElements"];
	[coder encodeBool:isClosed forKey:@"ACSDSubPath_isClosed"];
   }

- (id) initWithCoder:(NSCoder*)coder
   {
	self = [super init];
	pathElements = [[coder decodeObjectForKey:@"ACSDSubPath_pathElements"]retain];
	isClosed = [coder decodeBoolForKey:@"ACSDSubPath_isClosed"];
	return self;
   }

-(void)dealloc
   {
	if (pathElements)
		[pathElements release];
	[super dealloc];
   }

-(NSArray*)copyOfPathElements
   {
	return [[pathElements copiedObjects]retain];
   }

-(void)mercatorElementsWithRect:(NSRect)r
{
	NSMutableArray *arr = [NSMutableArray arrayWithCapacity:[pathElements count]];
	for (ACSDPathElement *pe in pathElements)
		[arr addObject:[pe mercatorWithRect:r]];
	[self setPathElements:arr];
}

-(ACSDSubPath*)mercatorSubPathWithRect:(NSRect)r
{
	ACSDSubPath *sp = [[self copy]autorelease];
	[sp mercatorElementsWithRect:r];
	return sp;
}

-(void)demercatorElementsWithRect:(NSRect)r
{
	NSMutableArray *arr = [NSMutableArray arrayWithCapacity:[pathElements count]];
	for (ACSDPathElement *pe in pathElements)
		[arr addObject:[pe demercatorWithRect:r]];
	[self setPathElements:arr];
}

-(ACSDSubPath*)demercatorSubPathWithRect:(NSRect)r
{
	ACSDSubPath *sp = [self copy];
	[sp demercatorElementsWithRect:r];
	return [sp autorelease];
}

- (id)copyWithZone:(NSZone *)zone 
   {
    ACSDSubPath *obj =  [[[self class] allocWithZone:zone] init];
	[obj setPathElements:[[self copyOfPathElements]autorelease] ];
	[obj setIsClosed:isClosed];
	return obj;
   }

- (NSString *)description
   {
	return [NSString stringWithFormat:@"Elements %@ \nisClosed:%d",pathElements,isClosed];
   }

-(NSMutableArray*)pathElements
   {
    return pathElements;
   }

-(void)offsetPointValue:(NSValue*)vp
   {
	[pathElements makeObjectsPerformSelector:@selector(offsetPointValue:)withObject:vp];
   }

-(void)setPathElements:(NSArray*)l
   {
    if (pathElements == l)
		return;
	if (pathElements)
		[pathElements release];
	pathElements = [l mutableCopy];
   }

-(void)addPathElementsFromArray:(NSArray*)l
   {
	[pathElements addObjectsFromArray:l];
   }

-(void)setIsClosedTo:(NSNumber*)b
   { 
    isClosed = [b boolValue];
   }

-(void)setIsClosed:(BOOL)b
   {
    isClosed = b;
   }

-(BOOL)isClosed
   {
    return isClosed;
   }

-(BOOL)isClosedEqualTo:(NSNumber*)val
   {
	BOOL v = [val boolValue];
	return (isClosed == v);
   }

-(BOOL)isSameAs:(id)obj
   {
	if ([self class] != [obj class])
		return NO;
	if (isClosed != [(ACSDSubPath*)obj isClosed])
		return NO;
	NSUInteger ct = [pathElements count];
	if (ct != [[obj pathElements]count])
		return NO;
	for (unsigned i = 0;i < ct;i++)
		if (!([[pathElements objectAtIndex:i]isSameAs:[[obj pathElements]objectAtIndex:i]]))
			return NO;
	return YES;
   }

-(void)splitAndRotateAtIndex:(NSInteger)ind
   {
	[self setIsClosed:NO];
	if (ind == 0)
		return;
	[[pathElements objectAtIndex:0]setIsLineToPoint:YES];
	NSMutableArray *newArray = [NSMutableArray arrayWithArray:
		[pathElements subarrayWithRange:NSMakeRange(ind,[pathElements count] - ind)]];
	[newArray addObjectsFromArray:[pathElements subarrayWithRange:NSMakeRange(0,ind)]];
	[self setPathElements:newArray];
	[[pathElements objectAtIndex:0]setIsLineToPoint:NO];
   }

-(BOOL)deleteMarkedElementsIntoArray:(NSMutableArray**)outputArray
   {
	BOOL thingsDeleted = NO;
	NSMutableArray *newSubPaths = [NSMutableArray arrayWithCapacity:2];
	ACSDSubPath *sp = [[self copy]autorelease];
	[newSubPaths addObject:sp];
	NSInteger ct = [[sp pathElements] count];
	for (NSInteger i = ct - 1;i >= 0;i--)
	   {
		ACSDPathElement *pe = [[sp pathElements] objectAtIndex:i];
		if ([pe deletePoint])
		   {
			thingsDeleted = YES;
			[[[self pathElements] objectAtIndex:i]setDeletePoint:NO];
			[[sp pathElements] removeObjectAtIndex:i];
		   }
	   }
	int spInd = 0;
	for (NSInteger i = [[sp pathElements] count] - 1;i >= 0;i--)
	   {
		ACSDPathElement *pe = [[sp pathElements] objectAtIndex:i];
		if ([pe deleteFollowingLine])
		   {
			[pe setDeleteFollowingLine:NO];
			if ([sp isClosed])
			   {
				NSInteger ind = (i == (int)([[sp pathElements] count] - 1)?0:(i+1));
				[pe setDeleteFollowingLine:NO];
				[sp splitAndRotateAtIndex:ind];
				i = [[sp pathElements] count] - 1;
			   }
			else if (i < (int)([[sp pathElements] count] - 1))
			   {
				ACSDSubPath *newSP = [[[ACSDSubPath alloc]init]autorelease];
				NSRange r = NSMakeRange(i+1,[[sp pathElements] count]-(i+1));
				[newSP addPathElementsFromArray:[[sp pathElements]subarrayWithRange:r]];
				[newSubPaths insertObject:newSP atIndex:++spInd];
				[[sp pathElements] removeObjectsInRange:r];
			   }
			thingsDeleted = YES;
		   }
	   }
	if (thingsDeleted)
		*outputArray = newSubPaths;
	else
		*outputArray = nil;
	return thingsDeleted;
   }

-(void)deleteElement:(const KnobDescriptor&)kd
   {
	[pathElements removeObjectAtIndex:kd.knob];
   }

-(void)insertElement:(ACSDPathElement*)el atIndex:(NSInteger)i
   {
	[pathElements insertObject:el atIndex:i];
   }

-(int)nearestKnobForPoint:(NSPoint)pt squaredDist:(float&)squaredDist
   {
	int minKnob = -1;
	for (unsigned i = 0;i < [pathElements count];i++)
	   {
		float kdist = squaredDistance(pt,[(ACSDPathElement*)[pathElements objectAtIndex:i]point]);
		if (kdist < squaredDist)
		   {
			squaredDist = kdist;
			minKnob = i;
		   }
	   }
	return minKnob;
   }


-(KnobDescriptor)duplicateElement:(const KnobDescriptor&)kd
   {
	ACSDPathElement *el = [[[pathElements objectAtIndex:kd.knob]copy]autorelease];
	KnobDescriptor k = kd;
	k.knob++;
	[pathElements insertObject:el atIndex:k.knob];
	return k;
   }

- (void) applyTransform:(NSAffineTransform*)trans
   {
	[pathElements makeObjectsPerformSelector:@selector(applyTransform:) withObject:trans];
   }

- (float)roughArea												//if the subpath is a polyon, gives the area. is approximate for curves 
   {
	float area = 0.0;
	NSInteger ct = [pathElements count];
	if (ct <= 1)
		return 0.0;
	NSMutableArray *arr = [NSMutableArray arrayWithCapacity:ct + 5];
	ACSDPathElement *element;
	for (int i = 0;i < ct;i++)
	   {
		element = [pathElements objectAtIndex:i];
		if ([element hasPreControlPoint])
			[arr addObject:[NSValue valueWithPoint:[element preControlPoint]]];
		[arr addObject:[NSValue valueWithPoint:[element point]]];
		if ([element hasPostControlPoint])
			[arr addObject:[NSValue valueWithPoint:[element postControlPoint]]];
	   }
	if (!NSEqualPoints([[arr objectAtIndex:0]pointValue],[[arr objectAtIndex:ct - 1]pointValue]))
		[arr addObject:[arr objectAtIndex:0]];
	ct = [arr count];
	NSInteger n = ct - 1;
/*	NSPoint pti = [[arr objectAtIndex:0]pointValue];
	for (int i = 1;i < ct;i++)
	   {
		NSPoint ptip = [[arr objectAtIndex:i]pointValue];
		area += ((pti.x + ptip.x) * (ptip.y - pti.y));
		pti = ptip;
	   }*/
	NSPoint pti = [[arr objectAtIndex:0]pointValue];
	NSPoint ptiminus1 = [[arr objectAtIndex:n - 1]pointValue];
	for (int i = 0;i < n;i++)
	   {
		NSPoint ptinext = [[arr objectAtIndex:i+1]pointValue];
		area += (pti.x * (ptinext.y - ptiminus1.y));
		ptiminus1 = pti;
		pti = ptinext;
	   }
	area = area / 2;
	return area;
   }

- (BOOL)isCounterClockWise
   {
	return [self roughArea] >= 0.0;
   }

- (NSMutableArray*)reversedPathElements
   {
	NSInteger ct = [pathElements count];
	NSMutableArray *newPathElements = [NSMutableArray arrayWithCapacity:ct];
	for (NSInteger i = ct - 1;i >= 0;i--)
		[newPathElements addObject:[(ACSDPathElement*)[pathElements objectAtIndex:i]reverse]];
	[[newPathElements objectAtIndex:0]setIsLineToPoint:NO];
	return newPathElements;
   }

- (void)reverse
   {
	[self setPathElements:[self reversedPathElements]];
   }

- (void)splitEachSegmentAtT:(float)t copy:(BOOL)copy path:(ACSDPath*)path pathInd:(int)pathInd
{
    NSInteger ct = [pathElements count];
    if (ct == 0)
        return;
    NSPoint lastCP,thisPreControlpoint,thisPostControlPoint,lastPoint;
    ACSDPathElement *lastEl,*element = [pathElements objectAtIndex:0];
    lastPoint = [element point];
    BOOL lastHasPostControlPoint = [element hasPostControlPoint];
    if (lastHasPostControlPoint)
        lastCP = [element postControlPoint];
    else
        lastCP = [element point];
    lastEl = element;
    int lastInd = 0;
    for (NSInteger i = ct - 2;i >= 0;i--)
    {
        ACSDPathElement *e1 = [pathElements objectAtIndex:i];
        ACSDPathElement *e2 = [pathElements objectAtIndex:i + 1];
        if ([e2 isLineToPoint])
        {
            if ([e1 hasPostControlPoint] || [e2 hasPreControlPoint])    //it's a curve
            {
                if ([e2 hasPreControlPoint])
                    thisPreControlpoint = [e2 preControlPoint];
                else
                    thisPreControlpoint = [e2 point];
                if ([e1 hasPostControlPoint])
                    thisPostControlPoint = [e1 postControlPoint];
                else
                    thisPostControlPoint = [e1 point];
                NSPoint c1EndPt,c1CP1,c1CP2,c2CP1,c2CP2;
                splitCurveByT([e1 point],[e2 point],thisPostControlPoint,thisPreControlpoint,t,
                              c1EndPt,c1CP1,c1CP2,
                              c2CP1,c2CP2);
                ACSDPathElement *e1c = [e1 copy],*e2c = [e2 copy];
                [e1c setPostControlPoint:c1CP1];
                [path uReplacePathElementWithElement:e1c forKnob:KnobDescriptor(pathInd,i,1)];
                [e2c setPreControlPoint:c2CP2];
                [path uReplacePathElementWithElement:e2c forKnob:KnobDescriptor(pathInd,i+1,1)];
                ACSDPathElement *en = [[ACSDPathElement alloc]initWithPoint:c1EndPt
                                                            preControlPoint:c1CP2 postControlPoint:c2CP1 hasPreControlPoint:YES
                                                        hasPostControlPoint:YES isLineToPoint:YES];
                [en setControlPointsContinuous:YES];
                [path uInsertPathElement:en forKnob:KnobDescriptor(pathInd,i+1,1)];
            }
            else                //it's just a line segment
            {
                NSPoint npt = tPointAlongLine(t,[e1 point],[e2 point]);
                ACSDPathElement *en = [[ACSDPathElement alloc]initWithPoint:npt
                                                                preControlPoint:npt postControlPoint:npt hasPreControlPoint:NO
                                                            hasPostControlPoint:NO isLineToPoint:YES];
                [path uInsertPathElement:en forKnob:KnobDescriptor(pathInd,i+1,1)];
            }
        }
        lastHasPostControlPoint = [element hasPostControlPoint];
        if (lastHasPostControlPoint)
            lastCP = [element postControlPoint];
        else
            lastCP = [element point];
        lastEl = element;
        lastPoint = [element point];
    }
    if (!isClosed)
        return;
    ACSDPathElement *e1 = [pathElements lastObject];
    ACSDPathElement *e2 = [pathElements objectAtIndex:0];
    if ([e1 hasPostControlPoint] || [e2 hasPreControlPoint])    //it's a curve
    {
        if ([e2 hasPreControlPoint])
            thisPreControlpoint = [e2 preControlPoint];
        else
            thisPreControlpoint = [e2 point];
        if ([e1 hasPostControlPoint])
            thisPostControlPoint = [e1 postControlPoint];
        else
            thisPostControlPoint = [e1 point];
        NSPoint c1EndPt,c1CP1,c1CP2,c2CP1,c2CP2;
        splitCurveByT([e1 point],[e2 point],thisPostControlPoint,thisPreControlpoint,t,
                      c1EndPt,c1CP1,c1CP2,
                      c2CP1,c2CP2);
        ACSDPathElement *e1c = [e1 copy],*e2c = [e2 copy];
        [e1c setPostControlPoint:c1CP1];
        [path uReplacePathElementWithElement:e1c forKnob:KnobDescriptor(pathInd,[pathElements count]-1,1)];
        [e2c setPreControlPoint:c2CP2];
        [path uReplacePathElementWithElement:e2c forKnob:KnobDescriptor(pathInd,0,1)];
        ACSDPathElement *en = [[ACSDPathElement alloc]initWithPoint:c1EndPt
                                                    preControlPoint:c1CP2 postControlPoint:c2CP1 hasPreControlPoint:YES
                                                hasPostControlPoint:YES isLineToPoint:YES];
        [en setControlPointsContinuous:YES];
        [path uInsertPathElement:en forKnob:KnobDescriptor(pathInd,[pathElements count],1)];
    }
    else                //it's just a line segment
    {
        NSPoint npt = tPointAlongLine(t,[e1 point],[e2 point]);
        ACSDPathElement *en = [[ACSDPathElement alloc]initWithPoint:npt
                                                    preControlPoint:npt postControlPoint:npt hasPreControlPoint:NO
                                                hasPostControlPoint:NO isLineToPoint:YES];
        [path uInsertPathElement:en forKnob:KnobDescriptor(pathInd,[pathElements count],1)];
    }
}
- (BOOL)splitPathWithPoint:(NSPoint)hitPoint copy:(BOOL)copy path:(ACSDPath*)path pathInd:(int)pathInd
   {
	CGFloat t,dist,threshold = 4.0;
	NSPoint hitPointOnLine;
	NSInteger ct = [pathElements count];
	if (ct == 0)
		return NO;
	NSPoint lastCP,thisPreControlpoint,lastPoint;
	ACSDPathElement *lastEl,*element = [pathElements objectAtIndex:0];
	lastPoint = [element point];
	BOOL lastHasPostControlPoint = [element hasPostControlPoint];
	if (lastHasPostControlPoint)
		lastCP = [element postControlPoint];
	else
		lastCP = [element point];
	lastEl = element;
	int lastInd = 0;
	for (int i = 1;i < ct;lastInd=i,i++)
	   {
		element = [pathElements objectAtIndex:i];
		if ([element isLineToPoint])
		   {
			if (lastHasPostControlPoint || [element hasPreControlPoint])	//it's a curve
			   {
				if ([element hasPreControlPoint])
					thisPreControlpoint = [element preControlPoint];
				else
					thisPreControlpoint = [element point];
				dist = threshold * 2;
				if (nearestPointOnCurve(lastPoint,[element point],lastCP,thisPreControlpoint,hitPoint,
					t,hitPointOnLine,dist,threshold,2.0,0.0,1.0))
				   {
					NSPoint c1EndPt,c1CP1,c1CP2,c2CP1,c2CP2;
					splitCurveByT(lastPoint,[element point],lastCP,thisPreControlpoint,t,
						c1EndPt,c1CP1,c1CP2,
						c2CP1,c2CP2);
					ACSDPathElement *l1 = [lastEl copy],*e1 = [element copy];
					[l1 setPostControlPoint:c1CP1];
					[path uReplacePathElementWithElement:l1 forKnob:KnobDescriptor(pathInd,lastInd,1)];
					[e1 setPreControlPoint:c2CP2];
				    [path uReplacePathElementWithElement:e1 forKnob:KnobDescriptor(pathInd,i,1)];
//					[lastEl setPostControlPoint:c1CP1];
//					[element setPreControlPoint:c2CP2];
					ACSDPathElement *el = [[ACSDPathElement alloc]initWithPoint:c1EndPt
						preControlPoint:c1CP2 postControlPoint:c2CP1 hasPreControlPoint:YES
						hasPostControlPoint:YES isLineToPoint:YES];
					[el setControlPointsContinuous:YES];
//					[pathElements insertObject:el atIndex:i];
					[path uInsertPathElement:el forKnob:KnobDescriptor(pathInd,i,1)];
					return YES;
				   }
			   }
			else				//it's just a line segment
			   {	
				if (testLineSegmentHit(lastPoint,[element point],hitPoint,t,hitPointOnLine,dist,threshold))
				   {
					ACSDPathElement *el = [[ACSDPathElement alloc]initWithPoint:hitPointOnLine
						preControlPoint:hitPointOnLine postControlPoint:hitPointOnLine hasPreControlPoint:NO
						hasPostControlPoint:NO isLineToPoint:YES];
//					[pathElements insertObject:el atIndex:i];
					[path uInsertPathElement:el forKnob:KnobDescriptor(pathInd,i,1)];
					return YES;
				   }
			   }
		   }
		lastHasPostControlPoint = [element hasPostControlPoint];
		if (lastHasPostControlPoint)
			lastCP = [element postControlPoint];
		else
			lastCP = [element point];
		lastEl = element;
		lastPoint = [element point];
	   }
	if (!isClosed)
		return NO;
	element = [pathElements objectAtIndex:0];
	if (lastHasPostControlPoint || [element hasPreControlPoint])	//it's a curve
	   {
		if ([element hasPreControlPoint])
			thisPreControlpoint = [element preControlPoint];
		else
			thisPreControlpoint = [element point];
		dist = threshold * 2;
		if (nearestPointOnCurve(lastPoint,[element point],lastCP,thisPreControlpoint,hitPoint,
								t,hitPointOnLine,dist,threshold,2.0,0.0,1.0))
		   {
			NSPoint c1EndPt,c1CP1,c1CP2,c2CP1,c2CP2;
			splitCurveByT(lastPoint,[element point],lastCP,thisPreControlpoint,t,
						  c1EndPt,c1CP1,c1CP2,
						  c2CP1,c2CP2);
//			[lastEl setPostControlPoint:c1CP1];
//			[element setPreControlPoint:c2CP2];
			ACSDPathElement *l1 = [lastEl copy],*e1 = [element copy];
			[l1 setPostControlPoint:c1CP1];
			[path uReplacePathElementWithElement:l1 forKnob:KnobDescriptor(pathInd,ct - 1,1)];
			[e1 setPreControlPoint:c2CP2];
			[path uReplacePathElementWithElement:e1 forKnob:KnobDescriptor(pathInd,0,1)];
			ACSDPathElement *el = [[ACSDPathElement alloc]initWithPoint:c1EndPt
														preControlPoint:c1CP2 postControlPoint:c2CP1 hasPreControlPoint:YES
													hasPostControlPoint:YES isLineToPoint:YES];
			[el setControlPointsContinuous:YES];
			[path uInsertPathElement:el forKnob:KnobDescriptor(pathInd,ct,1)];
//			[pathElements insertObject:el atIndex:ct];
			return YES;
		   }
	   }
	else				//it's just a line segment
	   {	
		if (testLineSegmentHit(lastPoint,[element point],hitPoint,t,hitPointOnLine,dist,threshold))
		   {
			ACSDPathElement *el = [[ACSDPathElement alloc]initWithPoint:hitPointOnLine
														preControlPoint:hitPointOnLine postControlPoint:hitPointOnLine hasPreControlPoint:NO
													hasPostControlPoint:NO isLineToPoint:YES];
//			[pathElements insertObject:el atIndex:ct];
			[path uInsertPathElement:el forKnob:KnobDescriptor(pathInd,ct,1)];
			return YES;
		   }
	   }
	return NO;
   }

-(ACSDSubPath*)removePathElement:(int)i
   {
	[[pathElements objectAtIndex:i]setIsLineToPoint:NO];
	if (isClosed)
	   {
		[[pathElements objectAtIndex:0]setIsLineToPoint:YES];
		for (int j = 0;j < i;j++)
		   {
			[pathElements addObject:[pathElements objectAtIndex:0]];
			[pathElements removeObjectAtIndex:0];
		   }
		isClosed = NO;
	   }
	else
	   {
		NSMutableArray *arr = [NSMutableArray arrayWithCapacity:[pathElements count] - i + 1];
		[arr addObjectsFromArray:[pathElements objectsAtIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(i,[pathElements count] - i)]]];
		[pathElements removeObjectsInRange:NSMakeRange(i,[pathElements count] - i)];
		if ([arr count] > 1)
		   {
			ACSDSubPath *newSubPath = [ACSDSubPath subPath];
			[newSubPath setPathElements:arr];
			[newSubPath setIsClosed:NO];
			return newSubPath;
		   }
	   }	
	return nil;
   }

- (BOOL)removePathElementWithPoint:(NSPoint)hitPoint newSubPath:(ACSDSubPath**)newSubPath
   {
	CGFloat t,dist,threshold = 4.0;
	NSPoint hitPointOnLine;
	NSInteger ct = [pathElements count];
	if (ct == 0)
		return NO;
	NSPoint lastCP,thisPreControlpoint,lastPoint;
	ACSDPathElement *lastEl,*element = [pathElements objectAtIndex:0];
	lastPoint = [element point];
	BOOL lastHasPostControlPoint = [element hasPostControlPoint];
	if (lastHasPostControlPoint)
		lastCP = [element postControlPoint];
	else
		lastCP = [element point];
	lastEl = element;
	for (int i = 1;i < ct;i++)
	   {
		element = [pathElements objectAtIndex:i];
		if (lastHasPostControlPoint || [element hasPreControlPoint])	//it's a curve
		   {
			if ([element hasPreControlPoint])
				thisPreControlpoint = [element preControlPoint];
			else
				thisPreControlpoint = [element point];
			dist = threshold * 2;
			if (nearestPointOnCurve(lastPoint,[element point],lastCP,thisPreControlpoint,hitPoint,
									t,hitPointOnLine,dist,threshold,2.0,0.0,1.0))
			   {
				*newSubPath = [self removePathElement:i];
				return YES;
			   }
		   }
		else				//it's just a line segment
		   {	
			if (testLineSegmentHit(lastPoint,[element point],hitPoint,t,hitPointOnLine,dist,threshold))
			   {
				*newSubPath = [self removePathElement:i];
				return YES;
			   }
		   }
		lastHasPostControlPoint = [element hasPostControlPoint];
		if (lastHasPostControlPoint)
			lastCP = [element postControlPoint];
		else
			lastCP = [element point];
		lastEl = element;
		lastPoint = [element point];
	   }
	if (!isClosed)
		return NO;
	element = [pathElements objectAtIndex:0];
	if (lastHasPostControlPoint || [element hasPreControlPoint])	//it's a curve
	   {
		if ([element hasPreControlPoint])
			thisPreControlpoint = [element preControlPoint];
		else
			thisPreControlpoint = [element point];
		dist = threshold * 2;
		if (nearestPointOnCurve(lastPoint,[element point],lastCP,thisPreControlpoint,hitPoint,
								t,hitPointOnLine,dist,threshold,2.0,0.0,1.0))
		   {
			isClosed = NO;
			return YES;
		   }
	   }
	else				//it's just a line segment
	   {	
		if (testLineSegmentHit(lastPoint,[element point],hitPoint,t,hitPointOnLine,dist,threshold))
		   {
			isClosed = NO;
			return YES;
		   }
	   }
	return NO;
}

void addLine(NSMutableArray *lines,NSPoint pt1,NSPoint pt2,NSPoint cp1,NSPoint cp2,BOOL hasCP1,BOOL hasCP2)
   {
	NSPoint thisCp2;
	id g;
	if ((hasCP1 && !NSEqualPoints(pt1,cp1))|| (hasCP2 && !NSEqualPoints(pt2,cp2)))	//it's a curve
	   {
		if (hasCP2)
			thisCp2 = cp2;
		else
			thisCp2 = pt2;
		g = [gCurve gCurvePt1:pt1 pt2:pt2 cp1:cp1 cp2:thisCp2];
		[lines addObject:g];
	   }
	else															//it's just a line segment
	   {
		if (NSEqualPoints(pt1,pt2))
			return;
		g = [gLine gLineFrom:pt1 to:pt2];
		[lines addObject:g];
	   }
	[g calculateDirectionVectors];
   }

void setDirs(gElement *gi,gElement *gj)
   {
	NSPoint gilast1,gilast2,gjfirst1,gjfirst2;
	[gi lastPoint:&gilast1 secondLastPoint:&gilast2];
	[gj firstPoint:&gjfirst1 secondPoint:&gjfirst2];
	int dir = SignArea2(gilast2,gilast1,gjfirst2);
//	int dir = SignArea2([gi firstPoint],[gi lastPoint],[gj lastPoint]);
	[gj setDirection:dir];
   }

-(void)fillInDirections:(NSMutableArray*)lines
   {
	NSInteger ct = [lines count];
	for (int i = 0;i < ct - 1;i++)
	   {
		gElement *gi = [lines objectAtIndex:i];
		gElement *gj = [lines objectAtIndex:i + 1];
		setDirs(gi,gj);
	   }
	if (isClosed && ct > 0)
	   {
		gElement *gi = [lines objectAtIndex:ct - 1];
		gElement *gj = [lines objectAtIndex:0];
		setDirs(gi,gj);
	   }
   }

-(NSRect)bounds
   {
	NSInteger ct = [pathElements count];
	if (ct < 2)
		return NSZeroRect;
	NSBezierPath *path = [NSBezierPath bezierPath];
	generateSubPath(path,pathElements,YES);
	return [path bounds];
   }

-(NSMutableArray*)linesFromSubPath
   {
	NSInteger ct = [pathElements count];
	NSMutableArray *lines = [NSMutableArray arrayWithCapacity:ct+1];
	if (ct == 0)
		return lines;
	NSPoint lastCP,lastPoint,firstPoint,firstCP;
	ACSDPathElement *lastEl,*element = [pathElements objectAtIndex:0];
	firstPoint = lastPoint = [element point];
	BOOL lastHasPostControlPoint = [element hasPostControlPoint];
	if (lastHasPostControlPoint)
		lastCP = [element postControlPoint];
	else
		lastCP = [element point];
	firstCP = lastCP;
	lastEl = element;
	BOOL firstHasPreControlPoint = [element hasPreControlPoint];
	if (firstHasPreControlPoint)
		firstCP = [element preControlPoint];
	else
		firstCP = [element point];
	for (NSInteger i = 1;i < ct;i++)
	   {
		element = [pathElements objectAtIndex:i];
		if ([element isLineToPoint])
			addLine(lines,lastPoint,[element point],lastCP,[element preControlPoint],lastHasPostControlPoint,[element hasPreControlPoint]);
		lastHasPostControlPoint = [element hasPostControlPoint];
		if (lastHasPostControlPoint)
			lastCP = [element postControlPoint];
		else
			lastCP = [element point];
		lastEl = element;
		lastPoint = [element point];
	   }
	if (isClosed && !NSEqualPoints(lastPoint,firstPoint))
		addLine(lines,lastPoint,firstPoint,lastCP,firstCP,lastHasPostControlPoint,firstHasPreControlPoint);
	[self fillInDirections:lines];
	return lines;
   }

NSBezierPath *joinLines(NSMutableArray* leftLines,NSMutableArray* rightLines,bool isClosed)
   {
	NSInteger count = [leftLines count] + [rightLines count];
	if (count == 0)
		return nil;
	NSBezierPath *path = [NSBezierPath bezierPath];
	id obj;
	NSEnumerator *objEnum;
	if ([leftLines count] > 0)
	   {
		objEnum = [leftLines objectEnumerator];
		obj = [objEnum nextObject];
		[path moveToPoint:[obj firstPoint]];
		while (obj)
		   {
			if ([obj isKindOfClass:[gCurve class]])
				[path curveToPoint:[obj pt2] controlPoint1:[obj cp1] controlPoint2:[obj cp2]];
			else
				[path lineToPoint:[obj toPt]];
			obj = [objEnum nextObject];
		   }
		if (isClosed)
		   {
			[path closePath];
		   }
	   }
	objEnum = [rightLines objectEnumerator];
	obj = [objEnum nextObject];
	if (obj)
	   {
		if (isClosed)
			[path moveToPoint:[obj firstPoint]];
		else
			[path lineToPoint:[obj firstPoint]];
	   }
	while (obj)
	   {
		if ([obj isKindOfClass:[gCurve class]])
			[path curveToPoint:[obj pt2] controlPoint1:[obj cp1] controlPoint2:[obj cp2]];
		else
			[path lineToPoint:[obj toPt]];
		obj = [objEnum nextObject];
	   }
	[path closePath];
	return path;
   }

float angleForVector(NSPoint v)
   {
	float h = sqrt(v.x * v.x + v.y * v.y);
	if (h == 0.0)
		return 0.0;
	float theta = DEGREES(acos(v.x / h));
	if (v.y > 0)
		theta = 360.0 - theta;
	return theta;
   }


bool vectorsEquivalent(NSPoint v1,NSPoint v2)
   {
	float a1 = angleForVector(v1);
	float a2 = angleForVector(v2);
	if (fabs(a1 - a2) < 0.1)
		return true;
	return (fabs(fabs(a1 - a2) - 180) < 0.001);
/*	if (v1.y == 0.0)
		if (v2.y == 0.0)
			return YES;
		else
			return NO;
	else
	   {
		if (v2.y == 0.0)
			return NO;
		double r1 = v1.x / v1.y;
		double r2 = v2.x / v2.y;
		return fabs(fabs(r1) - fabs(r2)) < 0.001;
	   }*/
   }

NSBezierPath *lineEndingPath(ACSDLineEnding *lineEnding,NSPoint pt1,NSPoint pt2,float strokeWidth)
   {
	if (lineEnding && [lineEnding graphic])
	   {
		float theta = getAngleForPoints(pt1,pt2);
		NSBezierPath *p = [lineEnding lineEndingPathWidth:strokeWidth];
		NSAffineTransform *tf = [NSAffineTransform transform];
		[tf rotateByDegrees:theta];
		NSAffineTransform *tf2 = [NSAffineTransform transform];
		[tf2 translateXBy:pt1.x yBy:pt1.y];
		[tf appendTransform:tf2];
		p = [tf transformBezierPath:p];
		return p;
	   }
	else
		return nil;
   }

-(NSMutableArray*)outlineLines:(NSArray*)lines stroke:(float)strokeWidth lineStart:(ACSDLineEnding*)lineStart lineEnd:(ACSDLineEnding*)lineEnd lineCap:(int)lineCap
{
	NSMutableArray *parents = [NSMutableArray arrayWithCapacity:[lines count]];
    NSEnumerator *objEnum = [lines objectEnumerator];
    id obj = [objEnum nextObject];
    while (obj != nil)
	{
		gParent *parent = [gParent parentWithDirection:[((gElement*)obj) direction] startVector:[obj startDirectionVector] endVector:[obj endDirectionVector]];
		if ([obj isKindOfClass:[gCurve class]])
			outlineCurve(obj,[parent leftLines],[parent rightLines],strokeWidth);
		else
			outlineLine(obj,strokeWidth,[parent leftLines],[parent rightLines]);
		NSPoint lastVector = [obj endDirectionVector];
		while ((obj = [objEnum nextObject])!=nil && vectorsEquivalent([obj startDirectionVector],lastVector))
		{
			if ([obj isKindOfClass:[gCurve class]])
				outlineCurve(obj,[parent leftLines],[parent rightLines],strokeWidth);
			else
				outlineLine(obj,strokeWidth,[parent leftLines],[parent rightLines]);
			lastVector = [obj endDirectionVector];
		}
		[parent setEndDirectionVector:lastVector];
		[parents addObject:parent];
	}
    for (NSInteger i = 0,ct = [parents count];i < ct;i++)
	{
		gParent *pi = [parents objectAtIndex:i];
		NSInteger j = i + 1;
		if (j == ct && isClosed)
			j = 0;
		if (j < ct)
		{
			gParent *pj = [parents objectAtIndex:j];
			if (!(vectorsEquivalent([pi endDirectionVector],[pj startDirectionVector])))
				[pi addBetweenFor:pj];
		}
	}
    objEnum = [parents objectEnumerator];
	NSMutableArray *paths = [NSMutableArray arrayWithCapacity:[parents count]*2];
	gParent *parent;
    while ((parent = [objEnum nextObject]) != nil)
	{
		[parent reverseLeftLines];
		NSBezierPath *p = [NSBezierPath bezierPath];
		BOOL closed = [self isClosed]&&[parents count] == 1;
		int startLineCap,endLineCap;
		if (!closed && parent == [parents objectAtIndex:0])
			startLineCap = lineCap;
		else
			startLineCap = 0;
		if (!closed && parent == [parents lastObject])
			endLineCap = lineCap;
		else
			endLineCap = 0;
		[parent addLinesToPath:p isClosed:closed && [lines count] > 1 startLineCap:startLineCap endLineCap:endLineCap];
		[paths addObject:[ACSDPath pathWithPath:p]];
	}
	if (lineStart && [lineStart graphic])
	{
		NSPoint firstPoint,secondPoint;
		[[lines objectAtIndex:0]firstPoint:&firstPoint secondPoint:&secondPoint];
		ACSDPath *g = [ACSDPath pathWithPath:lineEndingPath(lineStart,firstPoint,secondPoint,strokeWidth)];
		if (![g isCounterClockWise])
			[g reversePathWithStrokeList:nil];
		[paths addObject:g];
	}
	if (lineEnd && [lineEnd graphic])
	{
		NSPoint firstPoint,secondPoint;
		[[lines objectAtIndex:[lines count] - 1]lastPoint:&firstPoint secondLastPoint:&secondPoint];
		ACSDPath *g = [ACSDPath pathWithPath:lineEndingPath(lineEnd,firstPoint,secondPoint,strokeWidth)];
		if (![g isCounterClockWise])
			[g reversePathWithStrokeList:nil];
		[paths addObject:g];
	}
	return paths;
}

-(NSMutableArray*)outlineStroke:(float)strokeWidth lineStart:(ACSDLineEnding*)lineStart lineEnd:(ACSDLineEnding*)lineEnd lineCap:(int)lineCap
   {
	NSMutableArray *lines = [self linesFromSubPath];
	return [[ACSDSubPath unionPathFromPaths:[self outlineLines:lines stroke:strokeWidth lineStart:lineStart lineEnd:lineEnd lineCap:lineCap]]subPaths];
   }

-(NSMutableArray*)outlineDashedStroke:(float)strokeWidth lineStart:(ACSDLineEnding*)lineStart lineEnd:(ACSDLineEnding*)lineEnd lineCap:(int)lineCap
		dashes:(NSArray*)dashes dashPhase:(float)dashPhase
   {
	NSMutableArray *dashArray = [NSMutableArray arrayWithCapacity:[dashes count]];
	[dashArray addObjectsFromArray:dashes];
	if ([dashArray count] & 1)
		[dashArray addObjectsFromArray:dashes];
	float totalDashLength = 0.0;
	for (unsigned i = 0;i < [dashArray count];i++)
		totalDashLength += [[dashArray objectAtIndex:i]floatValue];
	if (totalDashLength < dashPhase)
		dashPhase = 0.0;
	NSMutableArray *lines = [self linesFromSubPath];
	NSMutableArray *paths = [NSMutableArray arrayWithCapacity:[lines count]*2];
	float offset = dashPhase;
	NSInteger dashInd = 0;
	for (NSInteger i = 0,ct = [lines count];i < ct;i++)
	   {
		gElement *obj = [lines objectAtIndex:i];
		float length = [obj length];
		float currentS = 0.0,currentT = 0.0;
		while (currentT < 1.0)
		   {
			float dashLen = [[dashArray objectAtIndex:dashInd]floatValue];
			dashLen -= offset;
			while (dashLen <= 0)
			   {
				dashInd = (dashInd + 1) % [dashArray count];
				dashLen += [[dashArray objectAtIndex:dashInd]floatValue];
			   }
			float sDashLen = dashLen / length;
			float nextS = currentS + sDashLen;
			if (nextS > 1.0)
			   {
				offset = (nextS - 1.0) * length;
				offset = [[dashArray objectAtIndex:dashInd]floatValue] - offset;
				nextS = 1.0;
			   }
			else
			   {
				offset = 0.0;
			   }
			float nextT;
			if ([obj isKindOfClass:[gCurve class]])
			   {
				gCurve *gc = (gCurve*)obj;
				nextT = tForS([gc pt1],[gc cp1],[gc cp2],[gc pt2],64,nextS,length);
			   }
			else
				nextT = nextS;
			if (!(dashInd & 1))
			   {
				gElement *gObj = [obj objectFromMinT:currentT toMaxT:nextT];
				[paths addObjectsFromArray:[self outlineLines:[NSArray arrayWithObject:gObj] stroke: strokeWidth lineStart:nil lineEnd:nil lineCap: lineCap]];
			   }
			if (offset == 0.0)
				dashInd = (dashInd + 1) % [dashArray count];
			currentS = nextS;
			currentT = nextT;
		   }
		obj = [lines objectAtIndex:i];
	   }
	if (lineStart && [lineStart graphic])
	   {
		NSPoint firstPoint,secondPoint;
		[[lines objectAtIndex:0]firstPoint:&firstPoint secondPoint:&secondPoint];
		[paths addObject:[ACSDPath pathWithPath:lineEndingPath(lineStart,firstPoint,secondPoint,strokeWidth)]];
	   }
	if (lineEnd && [lineEnd graphic])
	   {
		NSPoint firstPoint,secondPoint;
		[[lines objectAtIndex:[lines count] - 1]lastPoint:&firstPoint secondLastPoint:&secondPoint];
		[paths addObject:[ACSDPath pathWithPath:lineEndingPath(lineEnd,firstPoint,secondPoint,strokeWidth)]];
	   }
	return [[ACSDSubPath unionPathFromPaths:paths]subPaths];
   }

@end
