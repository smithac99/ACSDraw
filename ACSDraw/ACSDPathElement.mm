//
//  ACSDPathElement.mm
//  ACSDraw
//
//  Created by Alan Smith on Mon Feb 04 2002.
//  Copyright (c) 2001 __MyCompanyName__. All rights reserved.
//

#import "ACSDPathElement.h"
#import "ACSDPath.h"
#import "geometry.h"

float gradient(NSPoint pt1,NSPoint pt2);
bool gradientsEqualish(NSPoint pt1,NSPoint pt2,NSPoint pt3,NSPoint pt4);
NSPoint mercatorPoint(NSPoint p,NSRect r);
NSPoint demercatorPoint(NSPoint p,NSRect r);

float gradient(NSPoint pt1,NSPoint pt2)
{
	float x = pt2.x - pt1.x;
	float y = pt2.y - pt1.y;
	return (y / x); 
}

bool gradientsEqualish(NSPoint pt1,NSPoint pt2,NSPoint pt3,NSPoint pt4)
{
	NSPoint v1,v2;
	v1.x = pt2.x - pt1.x;
	v1.y = pt2.y - pt1.y;
	v2.x = pt4.x - pt3.x;
	v2.y = pt4.y - pt3.y;
	if (v1.y == 0.0)
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
			return fabs(r1 - r2) < 0.001;
		}
}

@implementation ACSDPathElement

+(ACSDPathElement*)mergePathElement1:(ACSDPathElement*)pe1 andPathElement2:(ACSDPathElement*)pe2
{
	NSPoint p;
	p.x = ([pe1 point].x + [pe2 point].x) / 2.0;
	p.y = ([pe1 point].y + [pe2 point].y) / 2.0;
	ACSDPathElement *newPE = [[ACSDPathElement alloc]initWithPoint:p preControlPoint:[pe1 preControlPoint] postControlPoint:[pe2 postControlPoint]
												hasPreControlPoint:[pe1 hasPreControlPoint] hasPostControlPoint:[pe2 hasPostControlPoint] isLineToPoint:[pe1 isLineToPoint]];
	return newPE;
}

+(int)pathElementsFromSubPath:(NSBezierPath*)path startFrom:(int)startInd addToArray:(NSMutableArray*)elements isClosed:(BOOL*)closed
{
	int i = startInd;
	NSUInteger noElements = [path elementCount];
	NSPoint points[3],lastPoint={0.0,0.0};
	NSBezierPathElement elementType = [path elementAtIndex:i associatedPoints:points];
	*closed = NO;
	do
	{
		ACSDPathElement *el = nil;
		switch (elementType)
		{
			case NSMoveToBezierPathElement:
				el = [[ACSDPathElement alloc]initWithPoint:points[0] preControlPoint:points[0] postControlPoint:points[0] 
										hasPreControlPoint:NO hasPostControlPoint:NO isLineToPoint:NO];
				lastPoint = points[0];
				break;
			case NSLineToBezierPathElement:
				//				if (!NSEqualPoints(lastPoint,points[0]))
				//				   {
				el = [[ACSDPathElement alloc]initWithPoint:points[0] preControlPoint:points[0] postControlPoint:points[0] 
										hasPreControlPoint:NO hasPostControlPoint:NO isLineToPoint:YES];
				lastPoint = points[0];
				//				   }
				break;
			case NSCurveToBezierPathElement:
				el = [[ACSDPathElement alloc]initWithPoint:points[2] preControlPoint:points[1] postControlPoint:points[2] 
										hasPreControlPoint:YES hasPostControlPoint:NO isLineToPoint:YES];
				lastPoint = points[2];
				break;
			case NSClosePathBezierPathElement:
				*closed = YES;
				break;
		}
		if (el)
			[elements addObject:el];
		i++;
		if (i < noElements)
			elementType = [path elementAtIndex:i associatedPoints:points];
	}while (i < noElements && elementType != NSMoveToBezierPathElement);
	NSUInteger count = [elements count];
	for (int j = 0;j < count;j++)
	{
		NSBezierPathElement elementType = [path elementAtIndex:j + startInd associatedPoints:points];
		ACSDPathElement *prevEl = [elements objectAtIndex:((j==0)?(count - 1):(j-1))];
		if (elementType == NSCurveToBezierPathElement)
		{
			[prevEl setPostControlPoint:points[0]];
			[prevEl setHasPostControlPoint:YES];
		}
	}
	for (int j = 0;j < count;j++)
	{
		NSBezierPathElement elementType = [path elementAtIndex:j + startInd associatedPoints:points];
		ACSDPathElement *el = [elements objectAtIndex:j];
		if (elementType == NSCurveToBezierPathElement)
		{
			if (gradientsEqualish([el preControlPoint],[el point],[el point],[el postControlPoint]))
				//			if (fabs(gradient([el preControlPoint],[el point]) - gradient([el point],[el postControlPoint])) < 0.001)
				[el setControlPointsContinuous:YES];
		}
	}
	if (count > 2)
	{
		ACSDPathElement *firstEl = [elements objectAtIndex:0];
		ACSDPathElement *lastEl = [elements objectAtIndex:(count - 1)];
		if (NSEqualPoints([firstEl point],[lastEl point]))
		{
			*closed = YES;
			[firstEl setPreControlPoint:[lastEl preControlPoint]];
			[firstEl setHasPreControlPoint:[lastEl hasPreControlPoint]];
			if ( [firstEl hasPreControlPoint] && [firstEl hasPostControlPoint] &&
				gradientsEqualish([firstEl preControlPoint],[firstEl point],[firstEl point],[firstEl postControlPoint]))
				[firstEl setControlPointsContinuous:YES];
			[elements removeObjectAtIndex:count - 1];
		}
	}
	return i;
}

-(id)initWithPoint:(NSPoint)pt preControlPoint:(NSPoint)preCP postControlPoint:(NSPoint)postCP 
hasPreControlPoint:(BOOL) hasPreCP hasPostControlPoint:(BOOL)hasPostCP isLineToPoint:(BOOL)iltp
{
	if (self = [super init])
	{
		self.point = pt;
		self.preControlPoint = preCP;
		self.postControlPoint = postCP;
		self.hasPreControlPoint = hasPreCP;
		self.hasPostControlPoint = hasPostCP;
		self.controlPointsContinuous = NO;
		self.isLineToPoint = iltp;
		self.deletePoint = NO;
		self.deleteFollowingLine = NO;
	}
	return self;
}

- (id)copyWithZone:(NSZone *)zone 
{
    id obj = [[ACSDPathElement alloc]initWithPoint:self.point preControlPoint:self.preControlPoint postControlPoint:self.postControlPoint
								hasPreControlPoint:self.hasPreControlPoint hasPostControlPoint:self.hasPostControlPoint isLineToPoint:self.isLineToPoint];
	[obj setControlPointsContinuous:self.controlPointsContinuous];
	[obj setDeletePoint:self.deletePoint];
	[obj setDeleteFollowingLine:self.deleteFollowingLine];
	return obj;
}

- (NSString *)description
{
	return [NSString stringWithFormat:@"point:%g %g preControlPoint:%g %g ,postControlPoint:%g %g isLineToPoint:%d hasPreControlPoint:%d hasPostControlPoint:%d controlPointsContinuous:%d\n",
			self.point.x,self.point.y,self.preControlPoint.x,self.preControlPoint.y,self.postControlPoint.x,self.postControlPoint.y,self.isLineToPoint,self.hasPreControlPoint,self.hasPostControlPoint,self.controlPointsContinuous];
}

-(void)setWithPoint:(NSPoint)pt preControlPoint:(NSPoint)preCP postControlPoint:(NSPoint)postCP 
 hasPreControlPoint:(BOOL) hasPreCP hasPostControlPoint:(BOOL)hasPostCP isLineToPoint:(BOOL)iltp 
controlPointsContinuous:(BOOL) cpc
{
	self.point = pt;
	self.preControlPoint = preCP;
	self.postControlPoint = postCP;
	self.hasPreControlPoint = hasPreCP;
	self.hasPostControlPoint = hasPostCP;
	self.controlPointsContinuous = cpc;
	self.isLineToPoint = iltp;
}

-(void)setFromElement:(ACSDPathElement*)pe
{
	self.point = [pe point];
	self.preControlPoint = [pe preControlPoint];
	self.postControlPoint = [pe postControlPoint];
	self.hasPreControlPoint = [pe hasPreControlPoint];
	self.hasPostControlPoint = [pe hasPostControlPoint];
	self.controlPointsContinuous = [pe controlPointsContinuous];
	self.isLineToPoint = [pe isLineToPoint];
}

- (void) applyTransform:(NSAffineTransform*)trans
{
	self.point = [trans transformPoint:self.point];
	self.preControlPoint = [trans transformPoint:self.preControlPoint];
	self.postControlPoint = [trans transformPoint:self.postControlPoint];
}

- (void) encodeWithCoder:(NSCoder*)coder
{
	[ACSDGraphic encodePoint:self.point coder:coder forKey:@"ACSDPathElement_point"];
	[ACSDGraphic encodePoint:self.preControlPoint coder:coder forKey:@"ACSDPathElement_preControlPoint"];
	[ACSDGraphic encodePoint:self.postControlPoint coder:coder forKey:@"ACSDPathElement_postControlPoint"];
	unsigned int bools = 0;
	if (self.hasPreControlPoint)
		bools = bools | 1;
	if (self.hasPostControlPoint)
		bools = bools | 2;
	if (self.controlPointsContinuous)
		bools = bools | 4;
	if (self.isLineToPoint)
		bools = bools | 8;
	[coder encodeObject:[NSNumber numberWithUnsignedInt:bools] forKey:@"PE_BOOLS"];
//	[coder encodeBool:hasPreControlPoint forKey:@"ACSDPathElement_hasPreControlPoint"];
//	[coder encodeBool:hasPostControlPoint forKey:@"ACSDPathElement_hasPostControlPoint"];
//	[coder encodeBool:controlPointsContinuous forKey:@"ACSDPathElement_controlPointsContinuous"];
//	[coder encodeBool:isLineToPoint forKey:@"ACSDPathElement_isLineToPoint"];
}

- (id) initWithCoder:(NSCoder*)coder
{
	self = [super init];
	self.point = [ACSDGraphic decodePointForKey:@"ACSDPathElement_point" coder:coder];
	self.preControlPoint = [ACSDGraphic decodePointForKey:@"ACSDPathElement_preControlPoint" coder:coder];
	self.postControlPoint = [ACSDGraphic decodePointForKey:@"ACSDPathElement_postControlPoint" coder:coder];
//	hasPreControlPoint = [coder decodeBoolForKey:@"ACSDPathElement_hasPreControlPoint"];
//	hasPostControlPoint = [coder decodeBoolForKey:@"ACSDPathElement_hasPostControlPoint"];
//	controlPointsContinuous = [coder decodeBoolForKey:@"ACSDPathElement_controlPointsContinuous"];
//	isLineToPoint = [coder decodeBoolForKey:@"ACSDPathElement_isLineToPoint"];
	id o = [coder decodeObjectForKey:@"PE_BOOLS"];
	if (o)
	{
		unsigned int num = [o unsignedIntValue];
		self.hasPreControlPoint = ((num & 1)!= 0);
		self.hasPostControlPoint = ((num & 2)!= 0);
		self.controlPointsContinuous = ((num & 4)!= 0);
		self.isLineToPoint = ((num & 8)!= 0);
	}
	else
	{
		self.hasPreControlPoint = [coder decodeBoolForKey:@"ACSDPathElement_hasPreControlPoint"];
		self.hasPostControlPoint = [coder decodeBoolForKey:@"ACSDPathElement_hasPostControlPoint"];
		self.controlPointsContinuous = [coder decodeBoolForKey:@"ACSDPathElement_controlPointsContinuous"];
		self.isLineToPoint = [coder decodeBoolForKey:@"ACSDPathElement_isLineToPoint"];
	}
	return self;
}

-(ACSDPathElement*)reverse
{
	ACSDPathElement *el = [[ACSDPathElement alloc]initWithPoint:self.point preControlPoint:self.postControlPoint postControlPoint:self.preControlPoint
											 hasPreControlPoint:self.hasPostControlPoint hasPostControlPoint:self.hasPreControlPoint isLineToPoint:YES];
	return el;
}

-(void)setPreCPFromPostCPAngle
{
	float postDeltaX = self.postControlPoint.x - self.point.x;
	float postDeltaY = self.postControlPoint.y - self.point.y;
	float postHypotenuse = sqrt(postDeltaX * postDeltaX + postDeltaY * postDeltaY);
	float preDeltaX = self.preControlPoint.x - self.point.x;
	float preDeltaY = self.preControlPoint.y - self.point.y;
	float preHypotenuse = sqrt(preDeltaX * preDeltaX + preDeltaY * preDeltaY);
	if (postHypotenuse < 0.0)
		return;
	float ratio = preHypotenuse / postHypotenuse;
	_preControlPoint.x = self.point.x - postDeltaX * ratio;
	_preControlPoint.y = self.point.y - postDeltaY * ratio;
}

-(void)setPreCPFromPostCP
{
	float deltaX = self.postControlPoint.x - self.point.x;
	float deltaY = self.postControlPoint.y - self.point.y;
	_preControlPoint.x = self.point.x - deltaX;
	_preControlPoint.y = self.point.y - deltaY;
}

-(void)setPostCPFromPreCPAngle
{
	float postDeltaX = self.postControlPoint.x - self.point.x;
	float postDeltaY = self.postControlPoint.y - self.point.y;
	float postHypotenuse = sqrt(postDeltaX * postDeltaX + postDeltaY * postDeltaY);
	float preDeltaX = self.preControlPoint.x - self.point.x;
	float preDeltaY = self.preControlPoint.y - self.point.y;
	float preHypotenuse = sqrt(preDeltaX * preDeltaX + preDeltaY * preDeltaY);
	if (preHypotenuse < 0.0)
		return;
	float ratio = postHypotenuse / preHypotenuse;
	_postControlPoint.x = self.point.x - preDeltaX * ratio;
	_postControlPoint.y = self.point.y - preDeltaY * ratio;
}

-(void)setPostCPFromPreCP
{
	float deltaX = self.preControlPoint.x - self.point.x;
	float deltaY = self.preControlPoint.y - self.point.y;
	_postControlPoint.x = self.point.x - deltaX;
	_postControlPoint.y = self.point.y - deltaY;
}

-(NSRect)controlPointBounds
{
	NSPoint pt1,pt2;
	if (self.hasPreControlPoint)
		pt1 = self.preControlPoint;
	else
		pt1 = self.point;
	if (self.hasPostControlPoint)
		pt2 = self.postControlPoint;
	else
		pt2 = self.point;
	return rectFromPoints(pt1,pt2);
} 

-(void)moveToPoint:(NSPoint)pt
{
	float dX = pt.x - self.point.x;
	float dY = pt.y - self.point.y;
	self.point = pt;
	if (self.hasPreControlPoint)
	{
		_preControlPoint.x += dX;
		_preControlPoint.y += dY;
	}
	if (self.hasPostControlPoint)
	{
		_postControlPoint.x += dX;
		_postControlPoint.y += dY;
	}
}

-(void)offsetPoint:(NSPoint)pt
{
	float dX = pt.x;
	float dY = pt.y;
	_point.x += dX;
	_point.y += dY;
	if (_hasPreControlPoint)
	{
		_preControlPoint.x += dX;
		_preControlPoint.y += dY;
	}
	if (_hasPostControlPoint)
	{
		_postControlPoint.x += dX;
		_postControlPoint.y += dY;
	}
}

-(void)offsetPointValue:(NSValue*)vp
{
	[self offsetPoint:[vp pointValue]];
}

-(BOOL)isSameAs:(id)obj
{
	if ([self class] != [obj class])
		return NO;
	return (_isLineToPoint == [obj isLineToPoint]
			&& _hasPreControlPoint == [obj hasPreControlPoint]
			&& _hasPostControlPoint == [obj hasPostControlPoint]
			&& _controlPointsContinuous == [obj controlPointsContinuous]
			&& NSEqualPoints(_point,[obj point])
			&& NSEqualPoints(_preControlPoint,[obj preControlPoint])
			&& NSEqualPoints(_postControlPoint,[obj postControlPoint])
			);
}


-(void)resetDeleteMarkers
{
	_deletePoint = NO;
	_deleteFollowingLine = NO;
}

NSPoint mercatorPoint(NSPoint p,NSRect r)
{
	float xRatio = 2.0 * M_PI /r.size.width;
	float y = (p.y - (r.size.height / 2.0))* xRatio;
	y = asinh(tan(y));
	p.y = (y / xRatio) + (r.size.height / 2.0);
	return p;
}

NSPoint demercatorPoint(NSPoint p,NSRect r)
{
	float xRatio = 2.0 * M_PI /r.size.width;
	float y = (p.y - (r.size.height / 2.0))* xRatio;
	y = atan(sinh(y));
	p.y = (y / xRatio) + (r.size.height / 2.0);
	return p;
}

-(ACSDPathElement*)mercatorWithRect:(NSRect)r
{
	ACSDPathElement *pe = [self copy];
	[pe setPoint:mercatorPoint(_point,r)];
	[pe setPostControlPoint:mercatorPoint(_postControlPoint,r)];
	[pe setPreControlPoint:mercatorPoint(_preControlPoint,r)];
	return pe;
}

-(ACSDPathElement*)demercatorWithRect:(NSRect)r
{
	ACSDPathElement *pe = [self copy];
	[pe setPoint:demercatorPoint(_point,r)];
	[pe setPostControlPoint:demercatorPoint(_postControlPoint,r)];
	[pe setPreControlPoint:demercatorPoint(_preControlPoint,r)];
	return pe;
}

@end
