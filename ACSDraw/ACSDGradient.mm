//
//  ACSDGradient.mm
//  ACSDraw
//
//  Created by Alan Smith on Sun Feb 10 2002.
//  Copyright (c) 2001 __MyCompanyName__. All rights reserved.
//

#import "ACSDGradient.h"
#import "ACSDrawDocument.h"
#import "GradientElement.h"
#import "SVGWriter.h"
#import "AffineTransformAdditions.h"
#import "ACSDGraphic.h"
#import "CanvasWriter.h"


@implementation ACSDGradient

@synthesize gradientType,radialCentre;

-(id)init
{
	if (self = [super initWithColour:nil])
	{
		self.gradientElements = [NSMutableArray arrayWithCapacity:2];
		shadingInfo.gradient = self;
		radialCentre = NSMakePoint(0.0,0.0);
	}
	return self;
}

-(id)initWithColour1:(NSColor*)col1 colour2:(NSColor*)col2
{
	if (self = [self init])
	{
		[self.gradientElements addObject:[[GradientElement alloc]initWithPosition:0.0 colour:col1]];
		[self.gradientElements addObject:[[GradientElement alloc]initWithPosition:1.0 colour:col2]];
		self.preOffset = self.postOffset = self.angle = 0.0;
	}
	return self;
}

- (id)copyWithZone:(NSZone *)zone 
{
    ACSDGradient *g =  [[[self class] allocWithZone:zone]init];
	NSMutableArray *arr = [NSMutableArray arrayWithCapacity:[[self gradientElements]count]];
	for (int i = 0;i < (signed)[[self gradientElements]count];i++)
		[arr addObject:[[self.gradientElements objectAtIndex:i]copy]];
	[g setGradientElements:arr];
	[g setPreOffset:self.preOffset];
	[g setPostOffset:self.postOffset];
	[g setAngle:self.angle];
	[g setGradientType:gradientType];
	[g setRadialCentre:radialCentre];
	return g;
}

- (void) encodeWithCoder:(NSCoder*)coder
{
	[super encodeWithCoder:coder];
	[coder encodeObject:self.gradientElements forKey:@"ACSDGradient_gradientElements"];
	[coder encodeFloat:self.preOffset forKey:@"ACSDGradient_preOffset"];
	[coder encodeFloat:self.postOffset forKey:@"ACSDGradient_postOffset"];
	[coder encodeFloat:self.angle forKey:@"ACSDGradient_angle"];
	[coder encodeInt:gradientType forKey:@"ACSDGradient_gradientType"];
	[ACSDGraphic encodePoint:radialCentre coder:coder forKey:@"ACSDGradient_radialCentre"];
}

- (id) initWithCoder:(NSCoder*)coder
{
	self = [super initWithCoder:coder];
	self.gradientElements = [coder decodeObjectForKey:@"ACSDGradient_gradientElements"];
    self.preOffset = [coder decodeFloatForKey:@"ACSDGradient_preOffset"];
    self.postOffset = [coder decodeFloatForKey:@"ACSDGradient_postOffset"];
    self.angle = [coder decodeFloatForKey:@"ACSDGradient_angle"];
	gradientType = [coder decodeIntForKey:@"ACSDGradient_gradientType"];
	[ACSDGraphic decodePointForKey:@"ACSDGradient_radialCentre" coder:coder];
	shadingInfo.gradient = self;
	return self;
}

-(void)addGradientElementAndOrder:(GradientElement*)ge
   {
	[self.gradientElements addObject:ge];
	[self.gradientElements sortUsingSelector:@selector(comparePositionWith:)];
	[self invalidateGraphicsRefreshCache:YES];
   }

-(BOOL)canFill
   {
	return (self.gradientElements && ([self.gradientElements count] > 1));
   }

-(NSColor*)leftColour
   {
	return [[self.gradientElements objectAtIndex:0]colour];
   }

-(NSColor*)rightColour
   {
	return [[self.gradientElements objectAtIndex:1]colour];
   }

-(void)setLeftColour:(NSColor*)c
   {
	[[self.gradientElements objectAtIndex:0]setColour:c];
   }

-(void)setRightColour:(NSColor*)c
   {
	[[self.gradientElements objectAtIndex:1]setColour:c];
   }

-(void)setLeftColour:(NSColor*)c inView:(GraphicView*)gView
   {
	[self setLeftColour:c];
	[self invalidateGraphicsRefreshCache:YES];
   }

-(void)setRightColour:(NSColor*)c inView:(GraphicView*)gView
   {
	[self setRightColour:c];
	[self invalidateGraphicsRefreshCache:YES];
   }


-(NSColor*)shadingColourForPosition:(float)pos
   {
	if ([self.gradientElements count] == 0)
		return [NSColor clearColor];
	int ind = 0, nextInd = 0;
	float currVal = [(GradientElement*)[self.gradientElements objectAtIndex:0]position];
	float nextVal = currVal;
	if (pos < currVal)
		return [[self.gradientElements objectAtIndex:ind]colour];
	while (nextInd < (int)[self.gradientElements count] && nextVal < pos)
	   {
		currVal = nextVal;
		ind = nextInd;
		nextInd++;
		if (nextInd < (int)[self.gradientElements count])
			nextVal = [(GradientElement*)[self.gradientElements objectAtIndex:nextInd]position];
	   }
	if (pos >= nextVal)
		return [[self.gradientElements objectAtIndex:ind]colour];
	float frac;
	if (nextVal > currVal)
		frac = (pos - currVal) / (nextVal - currVal);
	else 
		frac = 0.0;
	NSColor *currColour = [[[self.gradientElements objectAtIndex:ind]colour]colorUsingColorSpaceName:NSCalibratedRGBColorSpace];
	NSColor *nextColour = [[[self.gradientElements objectAtIndex:nextInd]colour]colorUsingColorSpaceName:NSCalibratedRGBColorSpace];
	float r,g,b,a;
	r = [currColour redComponent] + frac * ([nextColour redComponent] - [currColour redComponent]);
	g = [currColour greenComponent] + frac * ([nextColour greenComponent] - [currColour greenComponent]);
	b = [currColour blueComponent] + frac * ([nextColour blueComponent] - [currColour blueComponent]);
	a = [currColour alphaComponent] + frac * ([nextColour alphaComponent] - [currColour alphaComponent]);
	return [NSColor colorWithCalibratedRed:r green:g blue:b alpha:a];
   }

-(void)fillPath:(NSBezierPath*)path angle:(float)ang
{
	[NSGraphicsContext saveGraphicsState];
    [path addClip];
	NSUInteger ct = [self.gradientElements count];
	NSMutableArray *colours = [NSMutableArray arrayWithCapacity:ct];
	CGFloat *positions = new CGFloat[ct];
	for (int i = 0;i < ct;i++)
	{
		GradientElement *ge = [self.gradientElements objectAtIndex:i];
		[colours addObject:[ge colour]];
		positions[i] = [ge position];
	}
	NSGradient *grad = [[NSGradient alloc]initWithColors:colours atLocations:positions colorSpace:[NSColorSpace genericRGBColorSpace]];
	if (gradientType == GRADIENT_RADIAL)
		[grad drawInBezierPath:path relativeCenterPosition:radialCentre];
	else
		[grad drawInBezierPath:path angle:ang];
	[NSGraphicsContext restoreGraphicsState];
	delete[] positions;
}

-(void)fillPath:(NSBezierPath*)path
{
	[self fillPath:path angle:self.angle];
}


-(void)setAngle:(float)f
   {
    _angle = f;
	[self invalidateGraphicsRefreshCache:YES];
   }

-(void)setPreOffset:(float)pre postOffset:(float)post angle:(float)ang view:(GraphicView*)gView
   {
	self.preOffset = pre;
	self.postOffset = post;
	self.angle = ang;
	[self invalidateGraphicsRefreshCache:YES];
   }

-(void)changeGradientType:(int)gt
{
	self.gradientType = gt;
	[self invalidateGraphicsRefreshCache:YES];
}

-(void)changeRadialCentre:(NSPoint)pt
{
	self.radialCentre = pt;
	[self invalidateGraphicsRefreshCache:YES];
}

-(NSString*)svgName:(ACSDrawDocument*)doc
   {
	NSUInteger i = [[doc fills]indexOfObjectIdenticalTo:self];
	return [NSString stringWithFormat:@"Gradient%ld",i];
   }

-(NSString*)graphicXMLForEvent:(NSMutableDictionary*)options
{
	NSMutableString *graphicString = [NSMutableString stringWithCapacity:100];
	NSString *indent = [options objectForKey:xmlIndent];
	if (gradientType == GRADIENT_LINEAR)
	{
		[graphicString appendFormat:@"%@<linearGradient id=\"%@\" ",indent,[self svgName:options[@"document"]]];
		if (self.angle != 0.0)
		{
			NSBezierPath *p = [NSBezierPath bezierPathWithRect:NSMakeRect(-0.5, -0.5, 1, 1)];
			NSAffineTransform *t = [NSAffineTransform transformWithRotationByDegrees:-self.angle];
			[p transformUsingAffineTransform:t];
			NSPoint pt1 = NSMakePoint([p bounds].origin.x,0);
			NSPoint pt2 = NSMakePoint(NSMaxX([p bounds]),0);
			t = [NSAffineTransform transformWithRotationByDegrees:self.angle];
			pt1 = [t transformPoint:pt1];
			pt2 = [t transformPoint:pt2];
			pt1.x += 0.5;
			pt1.y += 0.5;
			pt2.x += 0.5;
			pt2.y += 0.5;
			[graphicString appendFormat:@"x1=\"%g\" y1=\"%g\" x2=\"%g\" y2=\"%g\" ",pt1.x,1-pt1.y,pt2.x,1-pt2.y];
		}
		[graphicString appendString:@">\n"];
		for (GradientElement *ge in [self.gradientElements sortedArrayUsingSelector:@selector(comparePositionWith:)])
		{
			NSColor *col = [ge colour];
			[graphicString appendFormat:@"%@\t<stop offset=\"%g%%\" stop-color=\"%@\" stop-opacity=\"%g\"/>\n",indent,ge.position * 100,
			 string_from_nscolor(col),[col alphaComponent]];
		}
		[graphicString appendFormat:@"%@</linearGradient>\n",indent];
	}
    else
    {
        [graphicString appendFormat:@"%@<radialGradient id=\"%@\" ",indent,[self svgName:options[@"document"]]];
        CGFloat cx = (radialCentre.x + 1.0) / 2.0;
        CGFloat cy = (-radialCentre.y + 1.0) / 2.0;
        [graphicString appendFormat:@"cx=\"%g\" cy=\"%g\" r=\"%g\" ",cx,cy,1.0];
        [graphicString appendString:@">\n"];
        for (GradientElement *ge in [self.gradientElements sortedArrayUsingSelector:@selector(comparePositionWith:)])
        {
            NSColor *col = [ge colour];
            [graphicString appendFormat:@"%@\t<stop offset=\"%g%%\" stop-color=\"%@\" stop-opacity=\"%g\"/>\n",indent,ge.position * 100,
             string_from_nscolor(col),[col alphaComponent]];
        }
        [graphicString appendFormat:@"%@</radialGradient>\n",indent];
    }
	return graphicString;
}

-(void)writeSVGGradientDef:(SVGWriter*)svgWriter options:(NSDictionary*)options
{
	NSString *name = [NSString stringWithFormat:@"%@_%d",[self svgName:[svgWriter document]],[options[@"index"]intValue]];
    if (gradientType == GRADIENT_LINEAR)
    {
        [[svgWriter defs]appendFormat:@"<linearGradient id=\"%@\" ",name];
        if (self.angle != 0.0)
        {
            NSBezierPath *p = [NSBezierPath bezierPathWithRect:NSMakeRect(-0.5, -0.5, 1, 1)];
            NSAffineTransform *t = [NSAffineTransform transformWithRotationByDegrees:-self.angle];
            [p transformUsingAffineTransform:t];
            NSPoint pt1 = NSMakePoint([p bounds].origin.x,0);
            NSPoint pt2 = NSMakePoint(NSMaxX([p bounds]),0);
            if (svgWriter.shouldInvertSVGCoords)
                t = [NSAffineTransform transformWithRotationByDegrees:-self.angle];
            else
                t = [NSAffineTransform transformWithRotationByDegrees:self.angle];
            pt1 = [t transformPoint:pt1];
            pt2 = [t transformPoint:pt2];
            pt1.x += 0.5;
            pt1.y += 0.5;
            pt2.x += 0.5;
            pt2.y += 0.5;
            [[svgWriter defs]appendFormat:@"x1=\"%g\" y1=\"%g\" x2=\"%g\" y2=\"%g\" ",pt1.x,pt1.y,pt2.x,pt2.y];
            //[[svgWriter defs]appendFormat:@"gradientTransform=\"rotate(%g)\" ",angle];
        }
        [[svgWriter defs]appendString:@">\n"];
        for (GradientElement *ge in [self.gradientElements sortedArrayUsingSelector:@selector(comparePositionWith:)])
        {
            NSColor *col = [ge colour];
            [[svgWriter defs]appendFormat:@"\t<stop offset=\"%g%%\" stop-color=\"%@\" stop-opacity=\"%g\"/>\n",ge.position * 100,
             string_from_nscolor(col),[col alphaComponent]];
        }
        [[svgWriter defs]appendString:@"</linearGradient>\n"];
    }
    else
    {
        [[svgWriter defs]appendFormat:@"<radialGradient id=\"%@\" ",name];
        CGFloat cx = (radialCentre.x + 1.0) / 2.0;
        CGFloat cy = (-radialCentre.y + 1.0) / 2.0;
        [[svgWriter defs]appendFormat:@" cx=\"%g\" cy=\"%g\" ",cx,cy];
        [[svgWriter defs]appendString:@">\n"];
        for (GradientElement *ge in [self.gradientElements sortedArrayUsingSelector:@selector(comparePositionWith:)])
        {
            NSColor *col = [ge colour];
            [[svgWriter defs]appendFormat:@"\t<stop offset=\"%g%%\" stop-color=\"%@\" stop-opacity=\"%g\"/>\n",ge.position * 100,
             string_from_nscolor(col),[col alphaComponent]];
        }
        [[svgWriter defs]appendString:@"</radialGradient>\n"];
    }
}

-(void)writeSVGData:(SVGWriter*)svgWriter
{
	NSString *name = [self svgName:[svgWriter document]];
	int idx = (int)[svgWriter.gradients count] - 1;
	[[svgWriter contents]appendFormat:@"fill=\"url(#%@_%d)\" ",name,idx];
}

-(NSString*)canvasData:(CanvasWriter*)canvasWriter
{
	NSMutableString *str = [NSMutableString stringWithCapacity:40];
	NSAffineTransform *trans = [NSAffineTransform transformWithRotationByDegrees:(-self.angle)];
	NSBezierPath *p = [trans transformBezierPath:[canvasWriter objectForKey:@"path"]];
	NSRect b = [p bounds];
	NSPoint p1 = NSMakePoint(b.origin.x,0.0);
	NSPoint p2 = NSMakePoint(NSMaxX(b),0.0);
	[trans invert];
	p1 = [trans transformPoint:p1];
	p2 = [trans transformPoint:p2];
	[str appendFormat:@"var grad = ctx.createLinearGradient(%g,%g,%g,%g);\n",p1.x,p1.y,p2.x,p2.y];
	NSMutableArray *ges = [self.gradientElements copy];
	[ges sortUsingSelector:@selector(comparePositionWith:)];
	NSUInteger ct = [ges count];
	for (int i = 0;i < ct;i++)
	{
		GradientElement *ge = [ges objectAtIndex:i];
		[str appendFormat:@"grad.addColorStop(%g,'%@');\n",ge.position,rgba_from_nscolor([ge colour])];
	}
	[str appendFormat:@"ctx.fillStyle = %@;\n",@"grad"];
	return str;
}

-(BOOL)isSameAs:(id)obj
   {
	if (![super isSameAs:obj])
		return NO;
	NSUInteger count = [self.gradientElements count];
	if (count != [[obj gradientElements]count])
		return NO;
	for (unsigned int i=0;i < count;i++)
		if (![[self.gradientElements objectAtIndex:i]isSameAs:[[obj gradientElements] objectAtIndex:i]])
			return NO;
	return YES;
   }


@end
