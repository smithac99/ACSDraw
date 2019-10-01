//
//  ACSDRect.mm
//  ACSDraw
//
//  Created by Alan Smith on Mon Jan 14 2002.
//  Copyright (c) 2001 __MyCompanyName__. All rights reserved.
//

#import "ACSDRect.h"
#import "ACSDPath.h"
#import "ACSDShadow.h"
#import "GraphicView.h"
#import "SelectionSet.h"
#import "geometry.h"
#import "XMLNode.h"

@implementation ACSDRect

+ (NSString*)graphicTypeName
{
	return @"Rectangle";
}

+(id)rectWithRect:(NSRect)r
{
	return [[ACSDRect alloc]initWithName:@"" fill:nil stroke:nil rect:r layer:nil];
}

- (void)postChangeOfBounds
{
	if (!layer)
		return;
	if ([[layer selectedGraphics]count] == 1)
	{
		NSRect r = bounds;
		if (moving)
			r = NSOffsetRect(r,moveOffset.x,moveOffset.y);
		NSDictionary *dict1 = @{@"bounds":[NSValue valueWithRect:r],
								@"cornerRadius":[NSNumber numberWithFloat:self.cornerRadius],
								@"maxCornerRadius":[NSNumber numberWithFloat:[self maxCornerRadius]]};
		[[NSNotificationCenter defaultCenter] postNotificationName:ACSDDimensionChangeNotification object:self userInfo:dict1];
	}
}

+(id)rectangleWithXMLNode:(XMLNode*)xmlnode settingsStack:(NSMutableArray*)settingsStack
{
    NSDictionary *settings = [settingsStack lastObject];
    NSRect parentRect = [settings[@"parentrect"]rectValue];

    float x = [xmlnode attributeFloatValue:@"x"];
    float y = [xmlnode attributeFloatValue:@"y"];
    float width = [xmlnode attributeFloatValue:@"width"];
    float height = [xmlnode attributeFloatValue:@"height"];
    float cornerrad = [xmlnode attributeFloatValue:@"cornerradius"];

    //parentRect = InvertedRect(parentRect, docHeight);
    width = width * parentRect.size.width;
    height = height * parentRect.size.height;
    NSPoint pos = LocationForRect(x, 1 - y, parentRect);
    ACSDGraphic *r = [[ACSDRect alloc]initWithName:@"" fill:nil stroke:nil rect:NSMakeRect(pos.x, pos.y - height, width, height) layer:nil];
    if (cornerrad != 0)
        [((ACSDRect*)r) setCornerRadius:cornerrad * height];
    //[r setPosition:pos];
    return r;
}

-(id)initWithName:(NSString*)n fill:(ACSDFill*)f stroke:(ACSDStroke*)str rect:(NSRect)r layer:(ACSDLayer*)l
   {
    self = [super initWithName:n fill:f stroke:str rect:r layer:l];
	self.cornerRadius = 0.0;
	return self;
   }

- (id) initWithCoder:(NSCoder*)coder
   {
	self = [super initWithCoder:coder];
	self.cornerRadius = [coder decodeFloatForKey:@"ACSDRect_cornerRadius"];
	return self;
   }

- (void) encodeWithCoder:(NSCoder*)coder
{
	[super encodeWithCoder:coder];
	[coder encodeFloat:self.cornerRadius forKey:@"ACSDRect_cornerRadius"];
}

- (id)copyWithZone:(NSZone *)zone 
   {
	id obj = [super copyWithZone:zone];
	[(ACSDRect*)obj setCornerRadius:self.cornerRadius];
	return obj;
   }

- (BOOL)intersectsWithRect:(NSRect)selectionRect	//used for selecting with rubberband
   {
	if (transform == nil)
		return NSIntersectsRect(selectionRect,[self bounds]);
	else
		return [super intersectsWithRect:selectionRect];
   }

-(ACSDPath*)wholeOutline
   {
	if (fill && [fill colour])
		return [self wholeFilledRect];
	return [super wholeOutline];
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

- (void)startBoundsManipulation
{
    [super startBoundsManipulation];
    self.originalCornerRadius = self.cornerRadius;
	self.originalCornerRatio = 0.0;
	if (self.cornerRadius != 0.0)
	{
		float smallSide = fmin(bounds.size.width,bounds.size.height);
		if (smallSide != 0.0)
			self.originalCornerRatio = self.cornerRadius/smallSide;
	}
}

-(void)setGraphicCornerRadius:(float)rad from:(float)oldRad notify:(BOOL)notify
{
	if (rad == oldRad)
		return;
	if (!manipulatingBounds)
		[[[self undoManager] prepareWithInvocationTarget:self] setGraphicCornerRadius:oldRad from:rad notify:YES];
	[self invalidateGraphicSizeChanged:NO shapeChanged:NO redraw:NO notify:NO];
	[self setCornerRadius:rad];
	[self invalidateGraphicSizeChanged:YES shapeChanged:NO redraw:YES notify:notify];
}

- (void)stopBoundsManipulation
{
    if (manipulatingBounds)
	   {
        if (!NSEqualRects(originalBounds,bounds))
		{
            manipulatingBounds = NO;
			self.cornerRadius = self.originalCornerRadius;
            [self setGraphicBoundsTo:bounds from:originalBounds];
//            [self setGraphicCornerRadius:cornerRadius from:originalCornerRadius notify:YES];
		}
		else
			manipulatingBounds = NO;
       }
}

-(BOOL)setGraphicCornerRadius:(float)r notify:(BOOL)notify
{
	if (r == self.cornerRadius)
		return NO;
	if (!manipulatingBounds)
		[[[self undoManager] prepareWithInvocationTarget:self] setGraphicCornerRadius:self.cornerRadius notify:YES];
	[self invalidateGraphicSizeChanged:NO shapeChanged:NO redraw:NO notify:NO];
	[self setCornerRadius:r];
	[self invalidateGraphicSizeChanged:YES shapeChanged:NO redraw:YES notify:notify];
	return YES;
}

-(float)maxCornerRadius
{
	return fmin(bounds.size.width,bounds.size.height)/2.0;
}

- (NSBezierPath *)bezierPath
{
	if (self.cornerRadius == 0.0)
		return [super bezierPath];
	NSBezierPath *path = [NSBezierPath bezierPath];
	NSRect iBounds = NSInsetRect(bounds,self.cornerRadius,self.cornerRadius);
	[path moveToPoint:NSMakePoint(bounds.origin.x,iBounds.origin.y)];
	[path appendBezierPathWithArcWithCenter:iBounds.origin radius:self.cornerRadius startAngle:180.0 endAngle:270.0 clockwise:NO];
	[path lineToPoint:NSMakePoint(NSMaxX(iBounds),bounds.origin.y)];
	[path appendBezierPathWithArcWithCenter:NSMakePoint(NSMaxX(iBounds),NSMinY(iBounds)) radius:self.cornerRadius startAngle:270.0 endAngle:0.0 clockwise:NO];
	[path lineToPoint:NSMakePoint(NSMaxX(bounds),NSMaxY(iBounds))];
	[path appendBezierPathWithArcWithCenter:NSMakePoint(NSMaxX(iBounds),NSMaxY(iBounds)) radius:self.cornerRadius startAngle:0.0 endAngle:90.0 clockwise:NO];
	[path lineToPoint:NSMakePoint(NSMinX(iBounds),NSMaxY(bounds))];
	[path appendBezierPathWithArcWithCenter:NSMakePoint(NSMinX(iBounds),NSMaxY(iBounds)) radius:self.cornerRadius startAngle:90.0 endAngle:180.0 clockwise:NO];
	[path closePath];
    return path;
}

-(BOOL)setGraphicBoundsTo:(NSRect)newBounds from:(NSRect)oldBounds 
{
    if (NSEqualRects(newBounds, oldBounds))
		return NO;
	else
	{
		[super setGraphicBoundsTo:newBounds from:oldBounds];
		if (self.cornerRadius != 0.0 || (manipulatingBounds && self.originalCornerRadius != 0.0))
		{
			float ratio=0.0,smallSide;
			if (manipulatingBounds)
			{
				ratio = self.originalCornerRatio;
			}
			else
			{
				smallSide = fmin(oldBounds.size.width,oldBounds.size.height);
				if (smallSide != 0.0)
				{
					ratio = self.cornerRadius/smallSide;
				}
			}
			smallSide = fmin(newBounds.size.width,newBounds.size.height);
			float newCornerRadius = ratio * smallSide;
			[self setCornerRadius:newCornerRadius];
		}
		[self postChangeOfBounds];
		return YES;
	}
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
    if (self.cornerRadius != 0.0)
        [attrString appendFormat:@" cornerradius=\"%g\"",self.cornerRadius / b.size.height];
    return attrString;
}
@end
