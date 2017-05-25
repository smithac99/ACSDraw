//
//  ACSDLine.mm
//  ACSDraw
//
//  Created by Alan Smith on Sat Mar 02 2002.
//  Copyright (c) 2001 __MyCompanyName__. All rights reserved.
//

#import "ACSDLine.h"
#import "GraphicView.h"
#import "ACSDPath.h"
#import "ACSDShadow.h"
#import "geometry.h"
#import "AffineTransformAdditions.h"
#import "SVGWriter.h"


@implementation ACSDLine

+ (NSString*)graphicTypeName
{
	return @"Line";
}

+ (ACSDLine*)lineFrom:(NSPoint)f to:(NSPoint)t stroke:(ACSDStroke*)str layer:(ACSDLayer*)l
{
	ACSDLine *ln = [[ACSDLine alloc]initWithName:@"" fill:nil stroke:str rect:rectFromPoints(f,t) layer:l];
	[ln setFromPt:f];
	[ln setToPt:t];
	return ln;
}

- (id)copyWithZone:(NSZone *)zone
{
	id obj = [super copyWithZone:zone];
	[obj setFromPt:_fromPt];
	[obj setToPt:_toPt];
	[obj invalidateGraphicSizeChanged:YES shapeChanged:YES redraw:YES notify:NO];
	return obj;
}

- (void) encodeWithCoder:(NSCoder*)coder
{
	[super encodeWithCoder:coder];
	[ACSDGraphic encodePoint:_fromPt coder:coder forKey:@"ACSDLine_fromPt"];
	[ACSDGraphic encodePoint:_toPt coder:coder forKey:@"ACSDLine_toPt"];
}

- (id) initWithCoder:(NSCoder*)coder
{
	self = [super initWithCoder:coder];
	self.fromPt = [ACSDGraphic decodePointForKey:@"ACSDLine_fromPt" coder:coder];
	self.toPt = [ACSDGraphic decodePointForKey:@"ACSDLine_toPt" coder:coder];
	handlePoints = new NSPoint[2];
	noHandlePoints = 2;
	return self;
}

-(void)allocHandlePoints
{
	handlePoints = new NSPoint[2];
	noHandlePoints = 2;
}

-(void)uSetFromPt:(NSPoint)p
{
	[self invalidateGraphicSizeChanged:NO shapeChanged:NO redraw:NO notify:NO];
	[[[self undoManager] prepareWithInvocationTarget:self] uSetFromPt:self.fromPt];
	self.fromPt = p;
	[self setBounds:rectFromPoints(self.fromPt,self.toPt)];
	[self invalidateGraphicSizeChanged:YES shapeChanged:YES redraw:YES notify:NO];
}

- (void)uSetToPt:(NSPoint)p
{
	[self invalidateGraphicSizeChanged:NO shapeChanged:NO redraw:NO notify:NO];
	[[[self undoManager] prepareWithInvocationTarget:self] uSetToPt:self.toPt];
	self.toPt = p;
	[self setBounds:rectFromPoints(self.fromPt,self.toPt)];
	[self invalidateGraphicSizeChanged:YES shapeChanged:YES redraw:YES notify:NO];
}

-(void)permanentScale:(float)sc transform:(NSAffineTransform*)t
{
	NSPoint p = [t transformPoint:self.fromPt];
	[self uSetFromPt:p];
	p = [t transformPoint:self.toPt];
	[self uSetToPt:p];
}

- (BOOL)intersectsWithRect:(NSRect)selectionRect	//used for selecting with rubberband
   {
	if (transform == nil)
		return lineInRect(selectionRect,self.fromPt,self.toPt);
	return [super intersectsWithRect:selectionRect];
   }

- (BOOL)shapeUnderPoint:(NSPoint)point includeKnobs:(BOOL)includeKnobs view:(GraphicView*)vw
   {
	if (transform == nil)
		return NSPointInRect(point,bounds);
	return [super shapeUnderPoint:point includeKnobs:includeKnobs view:vw];
   }


- (NSBezierPath *)bezierPath
   {
    NSBezierPath *path = [NSBezierPath bezierPath];
	[path moveToPoint:self.fromPt];
	[path lineToPoint:self.toPt];
	return path;
   }

- (void)moveBy:(NSPoint)vector
   {
	if (vector.x == 0.0 && vector.y == 0.0)
		return;
	_fromPt.x += vector.x;
	_fromPt.y += vector.y;
	_toPt.x += vector.x;
	_toPt.y += vector.y;
    [self setBoundsTo:NSOffsetRect([self bounds], vector.x, vector.y) from:bounds];
	rotationPoint.x += vector.x;
	rotationPoint.y += vector.y;
	[self computeTransform];
	[self invalidateGraphicSizeChanged:YES shapeChanged:YES redraw:YES notify:NO];
	[self invalidateConnectors];
	[self postChangeOfBounds];
   }

- (void)flipV
{
	NSPoint cpt = [self centrePoint];
	[self invalidateGraphicSizeChanged:NO shapeChanged:NO redraw:NO notify:NO];
	_fromPt.y = cpt.y - (_fromPt.y - cpt.y);
	_toPt.y = cpt.y - (_toPt.y - cpt.y);
	[self invalidateGraphicSizeChanged:YES shapeChanged:YES redraw:YES notify:NO];
}

- (void)flipH
{
	NSPoint cpt = [self centrePoint];
	[self invalidateGraphicSizeChanged:NO shapeChanged:NO redraw:NO notify:NO];
	_fromPt.x = cpt.x - (_fromPt.x - cpt.x);
	_toPt.x = cpt.x - (_toPt.x - cpt.x);
	[self invalidateGraphicSizeChanged:YES shapeChanged:YES redraw:YES notify:NO];
}

-(void)createInit:(NSPoint)anchorPoint event:(NSEvent*)theEvent
{
	self.fromPt = anchorPoint;
	self.toPt = anchorPoint;
    [self setBounds:rectFromPoints(self.fromPt,self.toPt)];
}

-(void)createMid:(NSPoint)anchorPoint currentPoint:(NSPoint*)currPoint event:(NSEvent*)theEvent
{
	self.toPt = *currPoint;
	[self setBounds:[self rectFromAnchorPoint:self.fromPt movingPoint:self.toPt constrainedPoint:currPoint dragFromCentre:NO	constrain:NO]];
}

-(BOOL)needsRestrictTo45
{
	return YES;
}
- (KnobDescriptor)resizeByMovingKnob:(KnobDescriptor)kd toPoint:(NSPoint)point event:(NSEvent *)theEvent constrain:(BOOL)constrain aroundCentre:(BOOL)aroundCentre
   {
	if (transform)
		point = [self invertPoint:point];
	if (kd.knob == 0)
	   {
		if (([theEvent modifierFlags] & NSShiftKeyMask)!=0)
			restrictTo45(self.toPt,&point);
		[self uSetFromPt:point];
	   }
	else
	   {
		if (([theEvent modifierFlags] & NSShiftKeyMask)!=0)
			restrictTo45(self.fromPt,&point);
		[self uSetToPt:point];
	   }
	[self setBounds:rectFromPoints(self.fromPt,self.toPt)];
	return kd;
   }

-(void)computeHandlePoints
   {
	handlePoints[0] = self.fromPt;
	handlePoints[1] = self.toPt;
   }

-(BOOL)isSameAs:(id)obj
   {
	if (![super isSameAs:obj])
		return NO;
	if (!NSEqualPoints(self.fromPt,[obj fromPt]))
		return NO;
	if (!NSEqualPoints(self.toPt,[obj toPt]))
		return NO;
	return YES;
   }

-(NSString*)xmlEventTypeName
{
    return @"path";
}

-(NSString*)graphicAttributesXML:(NSMutableDictionary*)options
{
    NSMutableString *attrString = [NSMutableString stringWithCapacity:100];
    [attrString appendString:[super graphicAttributesXML:options]];
    NSBezierPath *p = [self transformedBezierPath];
    NSRect parR = [self parentRect:options];
    NSAffineTransform *t = [NSAffineTransform transformWithTranslateXBy:-parR.origin.x yBy:-parR.origin.y];
    [t appendTransform:[NSAffineTransform transformWithScaleXBy:1.0 / parR.size.width yBy:1.0 / parR.size.height]];
    [t appendTransform:[NSAffineTransform transformWithTranslateXBy:0 yBy:-1]];
    [t appendTransform:[NSAffineTransform transformWithScaleXBy:1.0 yBy:-1.0]];
    p = [t transformBezierPath:p];
    NSString *pstr = string_from_path(p);
    [attrString appendFormat:@" d=\"%@\"",pstr];
    return attrString;
}

@end
