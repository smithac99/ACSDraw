//
//  ACSDCircle.mm
//  ACSDraw
//
//  Created by Alan Smith on Sun Jan 20 2002.
//  Copyright (c) 2001 __MyCompanyName__. All rights reserved.
//

#import "ACSDCircle.h"
#import "ShadowType.h"
#import "AffineTransformAdditions.h"
#import "ACSDSubPath.h"
#import "ACSDPath.h"
#import "XMLNode.h"
#import "geometry.h"
#import "SVGWriter.h"


@implementation ACSDCircle

+ (NSString*)graphicTypeName
{
	return @"Circle";
}

+(id)circleWithSVGNode:(XMLNode*)xmlnode settingsStack:(NSMutableArray*)settingsStack
{
	float cx = [xmlnode attributeFloatValue:@"cx"];
	float cy = [xmlnode attributeFloatValue:@"cy"];
	float rad = [xmlnode attributeFloatValue:@"r"];
	CGPoint pt = NSMakePoint(cx, cy);
	NSAffineTransform *t = [[settingsStack lastObject]objectForKey:@"transform"];
	if (t)
		pt = [t transformPoint:pt];
	NSRect frame;
	frame.origin.x = pt.x - rad;
	frame.origin.y = pt.y - rad;
	frame.size.width = rad * 2.0;
	frame.size.height = frame.size.width;
	return [[ACSDCircle alloc]initWithName:@"" fill:nil stroke:nil rect:frame layer:nil];
}

+(id)circleWithXMLNode:(XMLNode*)xmlnode settingsStack:(NSMutableArray*)settingsStack
{
    NSDictionary *settings = [settingsStack lastObject];
    NSRect parentRect = [settings[@"parentrect"]rectValue];

    
    float x = [xmlnode attributeFloatValue:@"x"];
    float y = [xmlnode attributeFloatValue:@"y"];
    float width = [xmlnode attributeFloatValue:@"width"];
    float height = [xmlnode attributeFloatValue:@"height"];
    
    //parentRect = InvertedRect(parentRect, docHeight);
    width = width * parentRect.size.width;
    height = height * parentRect.size.height;
    NSPoint pos = LocationForRect(x, 1 - y, parentRect);
    ACSDGraphic *r = [[ACSDCircle alloc]initWithName:@"" fill:nil stroke:nil rect:NSMakeRect(pos.x, pos.y - height, width, height) layer:nil];
    //[r setPosition:pos];
    return r;
}

- (NSBezierPath *)bezierPath
{
	return [NSBezierPath bezierPathWithOvalInRect:bounds];
}

-(NSRect)displayBoundsSansShadow
{
	float inset = -[self paddingRequired];
	NSRect r;
	if (transform)
		r = [[transform transformBezierPath:[NSBezierPath bezierPathWithRect:bounds]]controlPointBounds];
	else
		r = [[NSBezierPath bezierPathWithRect:bounds]controlPointBounds];
	if (graphicMode == GRAPHIC_MODE_OUTLINE)
	{
		NSRect r2 = [[self transformedOutlinePath]controlPointBounds];
		r = NSUnionRect(r,r2);
	}
	if (r.size.width <= 0.0)
		r.size.width = 1.0;
	if (r.size.height <= 0.0)
		r.size.height = 1.0;
	return NSInsetRect(r, inset, inset);
}

- (void)drawHandlesGuide:(BOOL)forGuide  magnification:(float)mag options:(NSUInteger)options
{
	[self setHandleColour:forGuide];
	[NSBezierPath setDefaultLineWidth:0.0];
	NSBezierPath *path = [self transformedBezierPath];
	[NSGraphicsContext saveGraphicsState];
	if (self.moving)
		[[NSAffineTransform transformWithTranslateXBy:moveOffset.x yBy:moveOffset.y] concat];
	[path moveToPoint:handlePoints[0]];
	for (int i = 1;i < noHandlePoints;i++)
		[path lineToPoint:handlePoints[i]];
	if ([self hasClosedPath])
		[path closePath];
	[path stroke];
	if (!forGuide)
	{
		for (int i = 0;i < noHandlePoints;i++)
			[self drawHandleAtPoint:handlePoints[i]magnification:mag];
		[self drawCentrePointMagnification:mag];
	}
	[NSGraphicsContext restoreGraphicsState];
}

-(ACSDPath*)wholeFilledOutline
{
	float pad = 0.0;
	if (stroke && [stroke colour])
		pad = [stroke lineWidth] / 2.0;
	NSRect r = NSInsetRect([self bounds],-pad,-pad);
	NSBezierPath *p = [NSBezierPath bezierPathWithOvalInRect:r];
	if (transform)
		p = [transform transformBezierPath:p];
	return [ACSDPath pathWithPath:p];
}

-(ACSDPath*)wholeOutline
{
	if (fill && [fill colour])
		return [self wholeFilledOutline];
	return [super wholeOutline];
}

-(NSString*)graphicAttributesXML:(NSMutableDictionary*)options
{
	int docHeight = [[options objectForKey:xmlDocHeight]intValue];
	NSMutableString *attrString = [NSMutableString stringWithCapacity:100];
	[attrString appendString:[super graphicAttributesXML:options]];
	NSRect parR = [self parentRect:options];
	NSRect invrect = InvertedRect(parR, docHeight);
	NSRect b = [self bounds];
	NSPoint p0 = b.origin;
	NSPoint p1 = NSMakePoint(NSMaxX(b), NSMaxY(b));
	p0 = InvertedPoint(p0, docHeight);
	p1 = InvertedPoint(p1, docHeight);
	p0 = RelativePointInRect(p0.x,p0.y, invrect);
	p1 = RelativePointInRect(p1.x,p1.y, invrect);
	NSRect r = rectFromPoints(p0, p1);
	[attrString appendFormat:@" x=\"%g\" y=\"%g\" width=\"%g\" height=\"%g\"",r.origin.x,r.origin.y,r.size.width,r.size.height];
	for (NSArray *arr in self.attributes)
		if ([arr[0]isEqualToString:@"widthtracksheight"] || [arr[0]isEqualToString:@"heighttrackswidth"])
			[attrString appendFormat:@" pxwidth=\"%g\" pxheight=\"%g\"",b.size.width,b.size.height];
	return attrString;
}

-(NSString*)svgType
{
    if (bounds.size.width == bounds.size.height)
        return @"circle";
    return @"ellipse";
}

-(NSString*)svgTypeSpecifics:(SVGWriter*)svgWriter boundingBox:(NSRect)bb
{
    NSPoint cpt = NSMakePoint(NSMidX(bounds),NSMidY(bounds));
    if (svgWriter.shouldInvertSVGCoords)
        cpt = [svgWriter.inversionTransform transformPoint:cpt];
    if (bounds.size.width == bounds.size.height)
        return [NSString stringWithFormat:@"cx=\"%g\" cy=\"%g\" r=\"%g\" ",cpt.x,cpt.y,bounds.size.width/2];
    return [NSString stringWithFormat:@"cx=\"%g\" cy=\"%g\" rx=\"%g\" ry=\"%g\" ", cpt.x,cpt.y,bounds.size.width/2,bounds.size.height/2];
}


@end
