//
//  ACSDFreeHand.mm
//  ACSDraw
//
//  Created by Alan Smith on 07/03/2007.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import "ACSDFreeHand.h"
#import "geometry.h"
#import "GraphicView.h"
#import "FreeHandPoint.h"
#import "ACSDGroup.h"


@implementation ACSDFreeHand

+ (NSString*)graphicTypeName
{
	return @"FreeHand";
}


-(id)initWithName:(NSString*)n fill:(ACSDFill*)f stroke:(ACSDStroke*)str rect:(NSRect)r layer:(ACSDLayer*)l
{
    if (self = [super initWithName:n fill:f stroke:str rect:r layer:l])
	{
		points = [NSMutableArray arrayWithCapacity:50];
		bezierPath = [NSBezierPath bezierPath];
		level = 5;
	}
	return self;
}

-(void)buildBezierPath
{
	if ([points count] == 0)
		return;
	bezierPath = [NSBezierPath bezierPath];
	[bezierPath moveToPoint:[[points objectAtIndex:0]point]];
	for (FreeHandPoint *fhp in points)
		[bezierPath lineToPoint:[fhp point]];
}

-(void)buildBezierPathFromLines:(NSArray*)lines
{
	if ([lines count] == 0)
		return;
	bezierPath = [NSBezierPath bezierPath];
	[bezierPath moveToPoint:[[lines objectAtIndex:0]fromPt]];
	for (id obj in lines)
		if ([obj isKindOfClass:[gCurve class]])
			[bezierPath curveToPoint:[obj pt2] controlPoint1:[obj cp1] controlPoint2:[obj cp2]];
		else
			[bezierPath lineToPoint:[obj toPt]];
}

- (void)moveBy:(NSPoint)vector
{
	if (vector.x == 0.0 && vector.y == 0.0)
		return;
	if ([points count] == 0)
		return;
	if (self.layer)
		[self invalidateGraphicSizeChanged:NO shapeChanged:NO redraw:NO notify:NO];
	rotationPoint.x += vector.x;
	rotationPoint.y += vector.y;
	for (FreeHandPoint *fhp in points)
		[fhp moveBy:vector];
	[self buildBezierPath];
	[self computeTransform];
	[self computeTransformedHandlePoints];
	bounds = NSOffsetRect([self bounds], vector.x, vector.y);
	
	if (self.layer)
	{
		[self invalidateGraphicSizeChanged:YES shapeChanged:YES redraw:YES notify:NO];
		[self invalidateConnectors];
		[self postChangeOfBounds];
	}
}

-(void)calculateLengths
{
	[(FreeHandPoint*)[points objectAtIndex:0]setLength:0];
	NSPoint lastPoint = [[points objectAtIndex:0]point];
	float lastLength = 0.0;
	for (FreeHandPoint *fhp in points)
	{
		[fhp setLength:(lastLength + pointDistance([fhp point],lastPoint))];
		lastLength = [fhp length];
		lastPoint = [fhp point];
	}
}

-(void)calcCurveFromInd:(int)startInd toInd:(int)endInd currLevel:(int)currLevel maxLevel:(int)maxLevel curves:(NSMutableArray*)curves
{
	if (endInd - startInd <= 1)
	{
		[curves addObject:[gLine gLineFrom:[[points objectAtIndex:startInd]point] to:[[points objectAtIndex:endInd]point]]];
		return;
	}
	if (currLevel < maxLevel)
	{
		[self calcCurveFromInd:startInd toInd:(startInd + endInd)/2 currLevel:currLevel + 1 maxLevel:maxLevel curves:curves];
		[self calcCurveFromInd:(startInd + endInd)/2 toInd:endInd currLevel:currLevel + 1 maxLevel:maxLevel curves:curves];
		return;
	}
	NSPoint pt0 = [[points objectAtIndex:startInd]point];
	NSPoint pt1 = [[points objectAtIndex:endInd]point];
	double sumcp1x=0.0,sumcp2x=0.0,sumcp1y=0.0,sumcp2y=0.0;
	float midway = (endInd - startInd)/2.0;
	int ct = 0;
	for (int i = 1;((float)i) < midway;i++)
	{
		float t = ((float)i) / (endInd-startInd);
		NSPoint pti = [[points objectAtIndex:i + startInd]point];
		NSPoint ptj = [[points objectAtIndex:endInd - i]point];
		NSPoint cp1,cp2;
		getXorYC(pt0.x,pt1.x,pti.x,ptj.x,t,cp1.x,cp2.x);
		getXorYC(pt0.y,pt1.y,pti.y,ptj.y,t,cp1.y,cp2.y);
		sumcp1x += cp1.x;
		sumcp1y += cp1.y;
		sumcp2x += cp2.x;
		sumcp2y += cp2.y;
		ct++;
	}
	if (ct == 0)
		[curves addObject:[gLine gLineFrom:pt0 to:pt1]];
	else
	{
		sumcp1x /= ct;
		sumcp1y /= ct;
		sumcp2x /= ct;
		sumcp2y /= ct;
		[curves addObject:[gCurve gCurvePt1:pt0 pt2:pt1 cp1:NSMakePoint(sumcp1x,sumcp1y) cp2:NSMakePoint(sumcp2x,sumcp2y)]];
	}
}

-(int)level
{
	return level;
}

-(float)pressureLevel
{
	return pressureLevel;
}

-(void)invalidateGraphicSizeChanged:(BOOL)sizeChanged shapeChanged:(BOOL)shapeChanged redraw:(BOOL)redraw notify:(BOOL)notify
{
	if (sizeChanged)
		[self setDisplayBoundsValid:NO];
	if (shapeChanged)
	{
		[self setOutlinePathValid:NO];
	}
	if (graphicCache && self.usesCache && sizeChanged)
		[self readjustCache];
	if (graphicCache && redraw)
		[graphicCache setValid:NO];
	[self invalidateInView];
	if (parent)
		[parent invalidateGraphicSizeChanged:sizeChanged shapeChanged:shapeChanged redraw:redraw notify:notify];
	if (notify)
		[[NSNotificationCenter defaultCenter] postNotificationName:ACSDGraphicDidChangeNotification object:self];
}

- (void)uSetPressureLevel:(float)l
{
	if (pressureLevel == l)
		return;
	[[[self undoManager] prepareWithInvocationTarget:self] uSetPressureLevel:pressureLevel];
	pressureLevel = l;
	[self invalidateGraphicSizeChanged:NO shapeChanged:NO redraw:NO notify:NO];
	[self setBezierPathValid:NO];
	[self bezierPath];
	[self invalidateGraphicSizeChanged:YES shapeChanged:YES redraw:YES notify:NO];
}

- (void)uSetLevel:(float)l
{
	if (level == l)
		return;
	[[[self undoManager] prepareWithInvocationTarget:self] uSetLevel:level];
	level = l;
	[self invalidateGraphicSizeChanged:NO shapeChanged:NO redraw:NO notify:NO];
	[self setBezierPathValid:NO];
	[self bezierPath];
	[self invalidateGraphicSizeChanged:YES shapeChanged:YES redraw:YES notify:NO];
}

- (NSBezierPath *)bezierPath
{
	if (!addingPoints && !self.bezierPathValid && points && ([points count] > 1))
	{
		NSMutableArray *curves = [NSMutableArray arrayWithCapacity:100];
		[self calcCurveFromInd:0 toInd:(int)[points count]-1 currLevel:0 maxLevel:level curves:curves];
		[self buildBezierPathFromLines:curves];
		[self setBounds:[bezierPath bounds]];
		[self setBezierPathValid:YES];
	}
    return bezierPath;
}

-(void)createInit:(NSPoint)anchorPoint event:(NSEvent*)theEvent
{
	[points addObject:[FreeHandPoint freeHandPoint:anchorPoint pressure:[theEvent pressure]]];
	[bezierPath moveToPoint:anchorPoint];
    [self setBounds:NSMakeRect(anchorPoint.x, anchorPoint.y, 0.0, 0.0)];
	[self setBezierPathValid:YES];
	addingPoints = YES;
}

-(void)createMid:(NSPoint)anchorPoint currentPoint:(NSPoint*)currPoint event:(NSEvent*)theEvent
{
	[points addObject:[FreeHandPoint freeHandPoint:*currPoint pressure:[theEvent pressure]]];
	[bezierPath lineToPoint:*currPoint];
	[self setBounds:[bezierPath bounds]];
}

-(BOOL)createCleanUp:(BOOL)cancelled
{
	[self setBezierPathValid:NO];
	return [super createCleanUp:cancelled];
}
@end
