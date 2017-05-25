//
//  gLine.mm
//  ACSDraw
//
//  Created by alan on Mon Mar 29 2004.
//  Copyright (c) 2004 __MyCompanyName__. All rights reserved.
//

#import "gLine.h"
#import "geometry.h"
#import "ACSDGraphic.h"


@implementation gLine


+ (gLine*)gLineFrom:(NSPoint)p1 to:(NSPoint)p2
{
	return [[gLine alloc]initWithFromPt:p1 toPt:p2];
}

+ (gLine*)gLineFrom:(NSPoint)p1 to:(NSPoint)p2 direction:(int)dir
{
	return [[gLine alloc]initWithFromPt:p1 toPt:p2 direction:dir];
}

- (id)initWithFromPt:(NSPoint)p1 toPt:(NSPoint)p2
{
	if (self = [super init])
	{
		self.fromPt = p1;
		self.toPt = p2;
		self.direction = 0;
		self.length = -1.0;
	}
	return self;
}

- (id)initWithFromPt:(NSPoint)p1 toPt:(NSPoint)p2 direction:(int)dir
{
	if (self = [super init])
	{
		self.fromPt = p1;
		self.toPt = p2;
		self.direction = dir;
		self.length = -1.0;
	}
	return self;
}

- (id)copyWithZone:(NSZone *)zone
{
	gLine *obj =  [[[self class] allocWithZone:zone] initWithFromPt:self.fromPt toPt:self.toPt direction:self.direction];
	[obj setLength:self.length];
	[obj setLengthFrom:self.lengthFrom];
	[obj setStartDirectionVector:self.startDirectionVector];
	[obj setEndDirectionVector:self.endDirectionVector];
	return obj;
}

- (NSString *)description
{
	return [NSString stringWithFormat:@"gLine \n direction:%d startVector:%g %g  endvector:%g %g\nfrom:%g %g\nto:%g %g",
			self.direction,self.startDirectionVector.x,self.startDirectionVector.y,self.endDirectionVector.x,self.endDirectionVector.y,self.fromPt.x,self.fromPt.y,self.toPt.x,self.toPt.y];
}

-(NSPoint)firstPoint
{
	return self.fromPt;
}

-(NSPoint)lastPoint
{
	return self.toPt;
}

-(void)firstPoint:(NSPoint*)fp secondPoint:(NSPoint*)sp
{
	*fp = self.fromPt;
	*sp = self.toPt;
}

-(void)lastPoint:(NSPoint*)fp secondLastPoint:(NSPoint*)sp
   {
	*fp = self.toPt;
	*sp = self.fromPt;
   }

-(void)setStartVector:(NSPoint)v1 endVector:(NSPoint)v2
{
	self.startDirectionVector = v1;
	self.endDirectionVector = v2;
}

-(void)calculateDirectionVectors
{
	NSPoint point1,point2;
	[self firstPoint:&point1 secondPoint:&point2];
	self.startDirectionVector = NSMakePoint(point1.x - point2.x,point1.y - point2.y);
	[self lastPoint:&point1 secondLastPoint:&point2];
	self.endDirectionVector = NSMakePoint(point1.x - point2.x,point1.y - point2.y);
}

- (gElement*)objectFromMinT:(double)minT toMaxT:(double)maxT
{
	NSPoint d = diff_points(self.toPt,self.fromPt);
	NSPoint newFrom,newTo;
	newFrom.x = self.fromPt.x + minT * d.x;
	newFrom.y = self.fromPt.y + minT * d.y;
	newTo.x = self.fromPt.x + maxT * d.x;
	newTo.y = self.fromPt.y + maxT * d.y;
	return [gLine gLineFrom:newFrom to:newTo];
}

-(NSAffineTransform*)transformForLength:(CGFloat)l
{
	NSAffineTransform *transform = [NSAffineTransform transform];
	if (l > self.length + self.lengthFrom)
		return transform;
	CGFloat s = (l - self.lengthFrom) / self.length;
	NSPoint d = diff_points(self.toPt,self.fromPt);			//difference vector
	NSPoint loc;
	loc.x = self.fromPt.x + s * d.x;
	loc.y = self.fromPt.y + s * d.y;
	CGFloat angle = getAngleForPoints(self.fromPt,self.toPt) - 180.0;
	[transform translateXBy:loc.x yBy:loc.y];
	[transform rotateByDegrees:angle];
	return transform;
}

-(void)calculateLength
{
	self.length = pointDistance(self.fromPt, self.toPt);
}

-(float)tForS:(float)s
{
	return s;
}

-(gElement*)elementUpToT:(float)t
{
	NSPoint to = tPointAlongLine(t, self.fromPt, self.toPt);
	return [gLine gLineFrom:self.fromPt to:to];
}

@end
