//
//  IVertex.mm
//  Drawtest4
//
//  Created by alan on 16/01/2005.
//  Copyright 2005 Alan C Smith. All rights reserved.
//

#import "IVertex.h"
#import "ISegment.h"
#import "ISegElement.h"
#import "ICurveElement.h"


@implementation IVertex

+(void)removeDuplicateSegmentsFromVertexDict:(NSDictionary*)vertexDict
   {
	NSArray *vertexArray = [vertexDict allValues];
	[vertexArray makeObjectsPerformSelector:@selector(removeDuplicateSegments)];
	for (NSInteger i = 0,ct = [vertexArray count] - 1;i < ct;i++)
		[[vertexArray objectAtIndex:i]removeReverseSegmentsForVertices:vertexArray startingAtIndex:i+1];
   }


+(IVertex*)vertexForPoint:(NSPoint) pt vertexDict:(NSMutableDictionary*)vertexDict
   {
//	pt.x = ((int)(pt.x * 1000.0))/1000.0;
//	pt.y = ((int)(pt.y * 1000.0))/1000.0;
	NSValue *val = [NSValue valueWithPoint:pt];
	IVertex *v = [vertexDict objectForKey:val];
	if (!v)
	   {
		v = [[IVertex alloc]initWithX:pt.x y:pt.y];
		[vertexDict setObject:v forKey:val];
		[v release];
	   }
	return v;
   }

-(id)initWithX:(float)xVal y:(float)yVal
   {
    if (self = [super init])
	   {
		x = xVal;
		y = yVal;
		segmentList = [[NSMutableArray alloc]initWithCapacity:2];
	   }
	return self;
   }

-(id)initWithPoint:(NSPoint)pt
   {
    if (self = [super init])
	   {
		x = pt.x;
		y = pt.y;
		segmentList = [[NSMutableArray alloc]initWithCapacity:2];
	   }
	return self;
   }

-(void)dealloc
   {
	if (segmentList)
		[segmentList release];
	[super dealloc];
   }

- (NSString *)description
   {
	NSMutableString *ms = [NSMutableString stringWithCapacity:40];
	[ms appendFormat:@"xy = [%g %g], number of segs - %ld\n",x,y,[segmentList count]];
	for (unsigned i = 0;i < [segmentList count];i++)
	   {
		id s = [segmentList objectAtIndex:i];
		[ms appendFormat:@"[%g %g] ",[[s toVertex]x],[[s toVertex]y]];
		if ([s isKindOfClass:[ICurveElement class]])
		   {
			[ms appendFormat:@"[%g %g] ",[s cp1].x,[s cp1].y];
			[ms appendFormat:@"[%g %g] ",[s cp2].x,[s cp2].y];
		   }
		[ms appendFormat:@" inside - %d visited - %d\n",[s inside],[s visited]];
	   }
	return ms;
   }

- (NSMutableArray*)segmentList
   {
	return segmentList;
   }

- (void)setSegmentList:(NSMutableArray*)arr
   {
	if (arr == segmentList)
		return;
	if (segmentList)
		[segmentList release];
	segmentList = [arr retain];
   }

- (void)addSegment:(ISegElement*)is
   {
	[segmentList addObject:is];
   }

- (float)x
   {
	return x;
   }

- (float)y
   {
	return y;
   }

- (NSPoint)point
   {
	return NSMakePoint(x,y);
   }

- (NSInteger)noSegments
   {
	return [segmentList count];
   }

- (ISegElement*)segment:(int)i
   {
	return [segmentList objectAtIndex:i];
   }

- (NSMutableSet*)candidateSegmentsIntersect
   {
	NSInteger ct = [segmentList count];
	NSMutableSet *candidates = [NSMutableSet setWithCapacity:ct];
	for (int i = 0;i < ct;i++)
	   {
		ISegElement *seg = [segmentList objectAtIndex:i];
		if ((![seg visited]) && ([seg inside] == YES))
			[candidates addObject:seg];
	   }
	return candidates;
   }

- (NSMutableSet*)candidateSegmentsUnion
   {
	NSInteger ct = [segmentList count];
	NSMutableSet *candidates = [NSMutableSet setWithCapacity:ct];
	for (int i = 0;i < ct;i++)
	   {
		ISegElement *seg = [segmentList objectAtIndex:i];
//		if (![seg visited] && ([seg inside] == NO || ![seg collinearSection]))
		if (![seg visited] && [seg inside] == NO)
			[candidates addObject:seg];
	   }
	return candidates;
   }

- (NSMutableSet*)candidateSegmentsANotB
   {
	NSInteger ct = [segmentList count];
	NSMutableSet *candidates = [NSMutableSet setWithCapacity:ct];
	for (int i = 0;i < ct;i++)
	   {
		ISegElement *seg = [segmentList objectAtIndex:i];
		if (![seg visited] && (([seg inside] && [seg marked]) || (![seg inside] && ![seg marked])))
			[candidates addObject:seg];
	   }
	return candidates;
   }

- (void)removeDuplicateSegments
   {
	for (unsigned i = 0;i < [segmentList count];i++)
	   {
	    ISegElement *iSeg = [segmentList objectAtIndex:i];
		for (NSUInteger j = [segmentList count] - 1;j > i;j--)
		   {
			ISegElement *jSeg = [segmentList objectAtIndex:j];
			if ([jSeg isGeometricallyTheSameAs:iSeg])
				[segmentList removeObjectAtIndex:j];
		   }
	   }
   }

- (void)removeReverseSegmentsForVertex:(IVertex*)v
   {
	unsigned i = 0;
	while (i < [segmentList count])
	   {
	    ISegElement *iSeg = [segmentList objectAtIndex:i];
		unsigned j = 0;
		while (j < [[v segmentList]count])
		   {
			ISegElement *jSeg = [[v segmentList] objectAtIndex:j];
			if ([jSeg isGeometricallyTheReverseOf:iSeg])
			   {
				[[v segmentList] removeObjectAtIndex:j];
				[segmentList removeObjectAtIndex:i];
				i--;
			   }
			else
				j++;
		   }
		i++;
	   } 
   }

- (void)removeReverseSegmentsForVertices:(NSArray*)vList startingAtIndex:(NSInteger)ind
   {
	for (NSUInteger i = ind,ct = [vList count];i < ct;i++)
		[self removeReverseSegmentsForVertex:[vList objectAtIndex:i]];
   }

@end
