//
//  gSubPath.mm
//  ACSDraw
//
//  Created by alan on 08/01/06.
//  Copyright 2006 Alan C Smith. All rights reserved.
//

#import "gSubPath.h"
#import "gElement.h"
#import "ACSDSubPath.h"
#import "gCurve.h"
#import "gLine.h"

@implementation gSubPath

+(gSubPath*)gSubPathFromACSDSubPath:(ACSDSubPath*)sp
   {
	gSubPath *gSP = [[gSubPath alloc]init];
	[gSP generateElementsFromSubPath:sp];
	[gSP calcLength];
	return gSP;
   }

+(NSMutableArray*)gSubPathsFromACSDSubPaths:(NSMutableArray*)sps
{
	NSMutableArray *gsps = [NSMutableArray arrayWithCapacity:[sps count]];
    float totalLength = 0.0;
    for (ACSDSubPath *sp in sps)
    {
        gSubPath *gsp = [gSubPath gSubPathFromACSDSubPath:sp];
        totalLength += [gsp length];
		[gsps addObject:gsp];
    }
    for (gSubPath *gsp in gsps)
        gsp.fractionalLength = [gsp length] / totalLength;
	return gsps;
}


+(NSArray*)s:(float)s alongGSubPaths:(NSArray*)gsps
{
	NSMutableArray *ngsps = [NSMutableArray arrayWithCapacity:[gsps count]];
    float currS = 0.0;
    int idx = 0;
    for (gSubPath *gsp in gsps)
        if (currS + gsp.fractionalLength >= s)
            break;
        else
        {
            currS += gsp.fractionalLength;
            [ngsps addObject:gsp];
            idx++;
        }
    gSubPath *gsp = gsps[idx];
    float sdiff = s - currS;
    float sfrac = sdiff / gsp.fractionalLength;
    [ngsps addObject:[gsp subPathUpToS:sfrac]];
    return ngsps;
}

+(NSAffineTransform*)transformForLength:(float)l fromGSubPaths:(NSMutableArray*)gSubPaths
   {
	NSEnumerator *objEnum = [gSubPaths objectEnumerator];
    gSubPath *gSP;
    while ((gSP = [objEnum nextObject]) != nil)
		if ([gSP length] + [gSP lengthFrom] >= l)
			return [gSP transformForLength:l];
	return nil;
   }


-(id)init
   {
	if (self = [super init])
	   {
		_elements = nil;
		self.length = -1.0;
		self.lengthFrom = -1.0;
	   }
	return self;
   }

- (id)copyWithZone:(NSZone *)zone
{
    gSubPath *obj =  [[[self class] allocWithZone:zone] init];
	NSMutableArray *arr = [NSMutableArray arrayWithCapacity:[_elements count]];
	for (gElement *el in _elements)
	{
		gElement *g = [el copy];
		[arr addObject:g];
	}
	[obj setLength:self.length];
	[obj setLengthFrom:self.lengthFrom];
	[obj setElements:arr];
	return obj;
}

-(void)calcLength
{
    NSEnumerator *objEnum = [_elements objectEnumerator];
    gElement *el;
	self.length = 0;
    while ((el = [objEnum nextObject]) != nil)
    {
		[el calculateLength];
		[el setLengthFrom:self.length];
		self.length += [el length];
    }
    for (gElement *el in _elements)
        [el setFractionalLength:[el length] / self.length];
}

-(void)generateElementsFromSubPath:(ACSDSubPath*)subPath
   {
	[self setElements:[subPath linesFromSubPath]];
   }

-(NSAffineTransform*)transformForLength:(float)l
   {
    if (l > self.length + self.lengthFrom)
		return nil;
	NSEnumerator *objEnum = [_elements objectEnumerator];
    gElement *el;
    while ((el = [objEnum nextObject]) != nil)
		if ([el length] + [el lengthFrom] >= l)
			return [el transformForLength:l];
	return nil;
   }

-(gSubPath*)subPathUpToS:(float)s
{
	NSMutableArray *els = [NSMutableArray arrayWithCapacity:[_elements count]];
    float currS = 0.0;
    int idx = 0;
    while (idx < [_elements count])
    {
        if (currS + [_elements[idx] fractionalLength] >= s)
            break;
        else
        {
            currS += [_elements[idx] fractionalLength];
            [els addObject:[_elements[idx]copy]];
            idx++;
        }
    }
    float sdiff = s - currS;
    gElement *el = _elements[idx];
    float sfrac = sdiff / [el fractionalLength];
    float t = [el tForS:sfrac];
    [els addObject:[el elementUpToT:t]];
	gSubPath *gSP = [[gSubPath alloc]init];
	[gSP setElements:els];
	[gSP calcLength];
	return gSP;
}

-(NSBezierPath*)bezierPath
{
	NSBezierPath *bp = [NSBezierPath bezierPath];
	if ([_elements count] > 0)
	{
		NSPoint lastPoint = NSZeroPoint,firstPoint={0.0,0.0};
		NSEnumerator *objEnum = [_elements objectEnumerator];
		id el = [objEnum nextObject];
		firstPoint = [el firstPoint];
		[bp moveToPoint:[el firstPoint]];
		while (el)
		{
			if ([el isKindOfClass:[gCurve class]])
			{
				[bp curveToPoint:[el pt2] controlPoint1:[el cp1] controlPoint2:[el cp2]];
				lastPoint = [el pt2];
			}
			else
			{
				[bp lineToPoint:[el toPt]];
				lastPoint = [el toPt];
			}
			el = [objEnum nextObject];
		}
	}
	return bp;
}
@end
