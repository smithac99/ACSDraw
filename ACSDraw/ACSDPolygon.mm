//
//  ACSDPolygon.mm
//  ACSDraw
//
//  Created by alan on 14/05/06.
//  Copyright 2006 Alan C Smith. All rights reserved.
//

#import "ACSDPolygon.h"
#import "geometry.h"
#import "AffineTransformAdditions.h"
#import "GraphicView.h"


@implementation ACSDPolygon

+ (NSString*)graphicTypeName
{
	return @"Polygon";
}

-(id)initWithName:(NSString*)n fill:(ACSDFill*)f stroke:(ACSDStroke*)str rect:(NSRect)r layer:(ACSDLayer*)l
		  noSides:(int)ns pt0:(NSPoint)p0 pt1:(NSPoint)p1
{
    if (self = [super initWithName:n fill:f stroke:str rect:r layer:l])
	{
		pt0 = p0;
		pt1 = p1;
		[self setNoSides:ns];
		[self computeHandlePoints];
	}
	return self;
}

- (id)copyWithZone:(NSZone *)zone 
{
	id obj = [super copyWithZone:zone];
	[obj setNoSides:noSides];
	[obj setPt0:pt0];
	[obj setPt1:pt1];
	[obj computeHandlePoints];
	[obj invalidateGraphicSizeChanged:YES shapeChanged:NO redraw:YES notify:NO];
	return obj;
}

- (void) encodeWithCoder:(NSCoder*)coder
   {
	[super encodeWithCoder:coder];
	[coder encodeInt:noSides forKey:@"ACSDPolygon_noSides"];
	[ACSDGraphic encodePoint:pt0 coder:coder forKey:@"ACSDPolygon_pt0"];
	[ACSDGraphic encodePoint:pt1 coder:coder forKey:@"ACSDPolygon_pt1"];
	[ACSDGraphic encodePoint:centrePoint coder:coder forKey:@"ACSDPolygon_centrePoint"];
   }

- (id) initWithCoder:(NSCoder*)coder
   {
	self = [super initWithCoder:coder];
	[self setNoSides:[coder decodeIntForKey:@"ACSDPolygon_noSides"]];
	pt0 = [ACSDGraphic decodePointForKey:@"ACSDPolygon_pt0" coder:coder];
	pt1 = [ACSDGraphic decodePointForKey:@"ACSDPolygon_pt1" coder:coder];
	centrePoint = [ACSDGraphic decodePointForKey:@"ACSDPolygon_centrePoint" coder:coder];
	[self computeHandlePoints];
	return self;
   }

-(void)allocHandlePoints
   {
	if (handlePoints)
		delete[] handlePoints;
	handlePoints = new NSPoint[noSides];
	noHandlePoints = noSides;
   }

-(int)noSides
   {
	return noSides;
   }

-(void)setNoSides:(int)ns
   {
	noSides = ns;
	if (noSides != noHandlePoints)
		[self allocHandlePoints];
   }

-(NSPoint)pt0
   {
	return pt0;
   }

-(NSPoint)pt1
   {
	return pt1;
   }

-(void)setPt0:(NSPoint)p
   { 
	pt0 = p;
   }

-(void)setPt1:(NSPoint)p
   { 
	pt1 = p;
   }

-(NSPoint)centrePoint
   {
	return centrePoint;
   }

-(void)computeHandlePoints
   {
	handlePoints[0] = pt0;
	handlePoints[1] = pt1;
	if (NSEqualPoints(pt0,pt1))
	   {
		centrePoint = pt0;
		bounds = rectFromPoints(pt0,pt1);
		for (int i = 2;i < noSides;i++)
			handlePoints[i] = pt0;
		return;
	   }
	NSPoint mPoint = midPoint(pt0,pt1);
	float adj = pointDistance(mPoint,pt0);
	float theta = 0.5 * (180.0 - (360.0 / noSides));
	float tanTheta = tan(RADIANS(theta));
	float opp = tanTheta * adj;
	NSPoint differenceVector = diff_points(pt1,pt0);
	NSPoint perpendicularVector = lperp(differenceVector);
	float vectorLength = dlen(perpendicularVector);
	float ratio = opp / vectorLength;
	centrePoint = NSMakePoint(mPoint.x + perpendicularVector.x * ratio,mPoint.y + perpendicularVector.y * ratio);
	NSAffineTransform *tf = [NSAffineTransform transformWithTranslateXBy:-centrePoint.x yBy:-centrePoint.y];
	[tf appendTransform:[NSAffineTransform transformWithRotationByDegrees:(360.0/noSides)]];
	[tf appendTransform:[NSAffineTransform transformWithTranslateXBy:centrePoint.x yBy:centrePoint.y]];
	for (int i = 2;i < noSides;i++)
		handlePoints[i] = [tf transformPoint:handlePoints[i-1]];
	bounds = [[self bezierPath]bounds];
   }

-(void)computePt0FromCentrePoint:(NSPoint)cp
   {
	centrePoint = cp;
	NSAffineTransform *tf = [NSAffineTransform transformWithTranslateXBy:-centrePoint.x yBy:-centrePoint.y];
	[tf appendTransform:[NSAffineTransform transformWithRotationByDegrees:(-360.0/noSides)]];
	[tf appendTransform:[NSAffineTransform transformWithTranslateXBy:centrePoint.x yBy:centrePoint.y]];
	pt0 = [tf transformPoint:pt1];
   }	

- (NSBezierPath *)bezierPath
   {
    NSBezierPath *path = [NSBezierPath bezierPath];
	[path moveToPoint:handlePoints[0]];
	if (!NSEqualPoints(pt0,pt1))
	   {
		for (int i = 1;i < noSides;i++)
			[path lineToPoint:handlePoints[i]];
		[path closePath];
	   }
	return path;
   }

-(BOOL)uSetPt0:(NSPoint)p0 pt1:(NSPoint)p1
   {
	[[[self undoManager] prepareWithInvocationTarget:self] uSetPt0:pt0 pt1:pt1];
	[self invalidateInView];
	pt0 = p0;
	pt1 = p1;
	[self computeHandlePoints];
	[self invalidateGraphicSizeChanged:YES shapeChanged:YES redraw:YES notify:NO];
	return YES;
   }

- (void)startBoundsManipulation
   {
    manipulatingBounds = YES;
    oPt0 = pt0;
    oPt1 = pt1;
   }

- (void)stopBoundsManipulation
   {
    if (manipulatingBounds)
	   {
		manipulatingBounds = NO;
        if (!(NSEqualPoints(oPt0,pt0) && NSEqualPoints(oPt1,pt1)))
		   {
			[[[self undoManager] prepareWithInvocationTarget:self] uSetPt0:oPt0 pt1:oPt1];
           }
       }
   }

-(void)createInit:(NSPoint)anchorPoint event:(NSEvent*)theEvent
{
	pt1 = anchorPoint;
}

-(void)createMid:(NSPoint)anchorPoint currentPoint:(NSPoint*)currPoint event:(NSEvent*)theEvent
{
	pt1 = *currPoint;
    if (([theEvent modifierFlags] & NSEventModifierFlagOption)==0)
		pt0 = anchorPoint;
	else
		[self computePt0FromCentrePoint:anchorPoint];
	[self computeHandlePoints];
}

-(BOOL)needsRestrictTo45
{
    return YES;
}

- (KnobDescriptor)resizeByMovingKnob:(KnobDescriptor)kd toPoint:(NSPoint)point event:(NSEvent *)theEvent constrain:(BOOL)constrain aroundCentre:(BOOL)aroundCentre
{
    NSInteger knob = kd.knob;
    NSInteger prevKnob = (kd.knob + noSides - 1) % noSides;
    CGPoint anchorPoint = handlePoints[prevKnob];
    if (constrain)
        restrictTo45(anchorPoint,&point);
    [self invalidateGraphicSizeChanged:NO shapeChanged:NO redraw:NO notify:NO];
    NSAffineTransform *tf = [NSAffineTransform transformWithTranslateXBy:-centrePoint.x yBy:-centrePoint.y];
    [tf appendTransform:[NSAffineTransform transformWithRotationByDegrees:(360.0/noSides)]];
    [tf appendTransform:[NSAffineTransform transformWithTranslateXBy:centrePoint.x yBy:centrePoint.y]];
    handlePoints[knob] = point;
    for (int i = 1;i < noSides;i++)
	   {
           NSInteger handleNo = (i + knob) % noSides;
           NSInteger prevHandleNo = (i - 1 + knob) % noSides;
           handlePoints[handleNo] = [tf transformPoint:handlePoints[prevHandleNo]];
       }
    pt0 = handlePoints[0];
    pt1 = handlePoints[1];
    bounds = [[self bezierPath]bounds];
    [self invalidateGraphicSizeChanged:YES shapeChanged:YES redraw:YES notify:NO];
    [self invalidateConnectors];
    return kd;
}

- (void)moveBy:(NSPoint)vector
{
    if (vector.x == 0.0 && vector.y == 0.0)
        return;
    if (self.layer)
        [self invalidateGraphicPositionChanged:NO sizeChanged:NO shapeChanged:NO redraw:NO notify:NO];
    self.rotationPoint = offset_point(self.rotationPoint, vector);
    centrePoint.x += vector.x;
    centrePoint.y += vector.y;
    for (int i = 0;i < noSides;i++)
    handlePoints[i] = offset_point(handlePoints[i],vector);
    pt0 = handlePoints[0];
    pt1 = handlePoints[1];
    bounds = [[self bezierPath]bounds];
    [self computeTransform];
    if (self.layer)
    {
        [self invalidateGraphicPositionChanged:YES sizeChanged:NO shapeChanged:NO redraw:NO notify:NO];
        [self invalidateConnectors];
        [self postChangeOfBounds];
    }
}

-(KnobDescriptor)nearestKnobForPoint:(NSPoint)pt
   {
	float squaredDist = 10000*10000;
	int minKnob = NoKnob;
	for (int i = 0;i < noSides;i++)
	   {
		float kdist = squaredDistance(pt,handlePoints[i]);
		if (kdist < squaredDist)
		   {
			squaredDist = kdist;
			minKnob = i;
		   }
	   }
	return KnobDescriptor(minKnob);
   }

-(NSPoint)pointForKnob:(const KnobDescriptor&)kd
   {
    return handlePoints[kd.knob];
   }

@end
