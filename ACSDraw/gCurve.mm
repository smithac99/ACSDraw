//
//  gCurve.mm
//  ACSDraw
//
//  Created by alan on Mon Mar 29 2004.
//  Copyright (c) 2004 __MyCompanyName__. All rights reserved.
//

#import "gCurve.h"
#import "geometry.h"
#import "ACSDGraphic.h"


@implementation gCurve

+ (gCurve*)gCurvePt1:(NSPoint)p1 pt2:(NSPoint)p2 cp1:(NSPoint)cc1 cp2:(NSPoint)cc2
{
	return [[gCurve alloc]initWithPt1:p1 pt2:p2 cp1:cc1 cp2:cc2];
}

+ (gCurve*)gCurvePt1:(NSPoint)p1 pt2:(NSPoint)p2 cp1:(NSPoint)cc1 cp2:(NSPoint)cc2 direction:(int)dir
{
	return [[gCurve alloc]initWithPt1:p1 pt2:p2 cp1:cc1 cp2:cc2 direction:dir];
}

- (id)initWithPt1:(NSPoint)p1 pt2:(NSPoint)p2 cp1:(NSPoint)cc1 cp2:(NSPoint)cc2
{
	if (self = [super init])
	{
		self.pt1 = p1;
		self.pt2 = p2;
		self.cp1 = cc1;
		self.cp2 = cc2;
		self.direction = 0;
		self.length = -1.0;
	}
	return self;
}

- (id)initWithPt1:(NSPoint)p1 pt2:(NSPoint)p2 cp1:(NSPoint)cc1 cp2:(NSPoint)cc2 direction:(int)dir
{
	if (self = [super init])
	{
		self.pt1 = p1;
		self.pt2 = p2;
		self.cp1 = cc1;
		self.cp2 = cc2;
		self.direction = dir;
		self.length = -1.0;
	}
	return self;
}

- (id)copyWithZone:(NSZone *)zone
{
	gCurve *obj =  [[[self class] allocWithZone:zone] initWithPt1:self.pt1 pt2:self.pt2 cp1:self.cp1 cp2:self.cp2 direction:self.direction];
	[obj setLength:self.length];
	[obj setLengthFrom:self.lengthFrom];
	[obj setStartDirectionVector:self.startDirectionVector];
	[obj setEndDirectionVector:self.endDirectionVector];
	return obj;
}

- (NSString *)description
{
	return [NSString stringWithFormat:@"gCurve \n direction:%d startVector:%g %g endvector:%g %g\nfrom:%g %g\nto:%g %g cp1:%g %g cp2:%g %g",
			self.direction,self.startDirectionVector.x,self.startDirectionVector.y,self.endDirectionVector.x,self.endDirectionVector.y,self.pt1.x,self.pt1.y,self.pt2.x,self.pt2.y,
			self.cp1.x,self.cp1.y,self.cp2.x,self.cp2.y];
}

-(NSPoint)firstPoint
{
	return self.pt1;
}

-(NSPoint)lastPoint
{
	return self.pt2;
}

-(void)firstPoint:(NSPoint*)fp secondPoint:(NSPoint*)sp
{
	*fp = self.pt1;
	if (NSEqualPoints(self.pt1,self.cp1))
		if (NSEqualPoints(self.pt1,self.cp2))
			*sp = self.pt2;
		else
			*sp = self.cp2;
		else
			*sp = self.cp1;
}

-(void)lastPoint:(NSPoint*)fp secondLastPoint:(NSPoint*)sp
{
	*fp = self.pt2;
	if (NSEqualPoints(self.pt2,self.cp2))
		if (NSEqualPoints(self.pt2,self.cp1))
			*sp = self.pt1;
		else
			*sp = self.cp1;
		else
			*sp = self.cp2;
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
	NSPoint c1EndPt,c1CP1,c1CP2,c2CP1,c2CP2,endPt;
	splitCurveByT(self.pt1,self.pt2,self.cp1,self.cp2,minT,c1EndPt,c1CP1,c1CP2,c2CP1,c2CP2);
	if (maxT == 1.0)
		return [gCurve gCurvePt1:c1EndPt pt2:self.pt2 cp1:c2CP1 cp2:c2CP2];
	CGFloat tempT = (maxT - minT) / (1.0 - minT);
	splitCurveByT(c1EndPt,self.pt2,c2CP1,c2CP2,tempT,endPt,c1CP1,c1CP2,c2CP1,c2CP2);
	return [gCurve gCurvePt1:c1EndPt pt2:endPt cp1:c1CP1 cp2:c1CP2];
}

-(float)tForS:(float)s
{
	return tForS(self.pt1,self.cp1,self.cp2,self.pt2,64,s,self.length);
}

-(gElement*)elementUpToT:(float)t
{
	NSArray *arr = splitCurveByT(self, t);
	return arr[0];
}

-(NSAffineTransform*)transformForLength:(CGFloat)l
{
	NSAffineTransform *transform = [NSAffineTransform transform];
	if (l > self.length + self.lengthFrom)
		return transform;
	CGFloat s = (l - self.lengthFrom) / self.length;
    //CGFloat t = tForS(pt1,cp1,cp2,pt2,64,s,length);
    CGFloat t = [self tForS:s];
	NSPoint loc,normal;
	bzNormal(self,t,loc,normal);					//Get the location and normal vector for t
	normal.x += loc.x;
	normal.y += loc.y;
	float angle = getAngleForPoints(loc,normal) + 90.0;
	[transform translateXBy:loc.x yBy:loc.y];
	[transform rotateByDegrees:angle];
	return transform;
}

-(void)calculateLength
{
    self.length = arcLength(self.pt1,self.cp1,self.cp2,self.pt2,64,0.0,1.0);
}
@end
