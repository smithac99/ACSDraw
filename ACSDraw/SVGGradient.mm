//
//  SVGGradient.m
//  ACSDraw
//
//  Created by Alan on 12/03/2015.
//
//

#import "SVGGradient.h"
#import "SVGWriter.h"
#import "GradientElement.h"
#import "geometry.h"
#import "ACSDGraphic.h"

@implementation SVGGradient

-(id)init
{
	if (self = [super init])
	{
		self.attrs = [NSMutableDictionary dictionary];
	}
	return self;
}

- (id)copyWithZone:(NSZone *)zone
{
	SVGGradient *g =  [super copyWithZone:zone];
	[g.attrs addEntriesFromDictionary:self.attrs];
    return g;
}

- (void) encodeWithCoder:(NSCoder*)coder
{
    [super encodeWithCoder:coder];
    [coder encodeObject:self.attrs forKey:@"SVGGradient_attrs"];
}

- (id) initWithCoder:(NSCoder*)coder
{
    self = [super initWithCoder:coder];
    self.attrs = [coder decodeObjectForKey:@"SVGGradient_attrs"];
    return self;
}

-(void)writeSVGGradientDef:(SVGWriter*)svgWriter
{
    NSString *name = [self svgName:[svgWriter document]];
    [[svgWriter defs]appendFormat:@"<linearGradient id=\"%@\" ",name];
    if (self.attrs[@"transform"])
        [[svgWriter defs]appendFormat:@"gradientTransform=\"%@\" ",string_from_transform(self.attrs[@"transform"])];
	for (NSString *k in @[@"x1",@"y1",@"x2",@"y2"])
		if (self.attrs[k])
			[[svgWriter defs]appendFormat:@"%@=\"%@\" ",k,self.attrs[k]];
    [[svgWriter defs]appendString:@">\n"];
    for (GradientElement *ge in self.gradientElements)
    {
        NSColor *col = [ge colour];
        [[svgWriter defs]appendFormat:@"\t<stop offset=\"%g%%\" stop-color=\"%@\" stop-opacity=\"%g\"/>\n",ge.position * 100,
         string_from_nscolor(col),[col alphaComponent]];
    }
    [[svgWriter defs]appendString:@"</linearGradient>\n"];
}

-(BOOL)isSameAs:(id)obj
{
    if (![super isSameAs:obj])
        return NO;
    for (NSString *k in [[self attrs]allKeys])
	{
		if (![self.attrs[k] isEqual:[obj attrs][k]])
			  return NO;
	}
    return YES;
}

-(void)resolveSettingsForOriginalBoundingBox:(NSRect)bb frame:(NSRect)fr
{
	BOOL unitsBB = ![[self.attrs[@"gradientUnits"]lowercaseString]isEqual:@"userspaceonuse"];
	NSAffineTransform *trans = self.attrs[@"transform"];
	if (self.gradientType == GRADIENT_LINEAR)
	{
		CGFloat x1=0,y1=0,x2=1,y2=0;
		CGPoint pt1 = LocationForRect(x1, y1, bb);
		CGPoint pt2 = LocationForRect(x2, y2, bb);
		NSString *s = self.attrs[@"x1"];
		if (s)
		{
			CGFloat f = FloatOrPercentage(s);
			if (unitsBB)
			{
				CGPoint p = LocationForRect(f, 0, bb);
				pt1.x = p.x;
			}
			else
				pt1.x = f;
		}
		s = self.attrs[@"y1"];
		if (s)
		{
			CGFloat f = FloatOrPercentage(s);
			if (unitsBB)
			{
				CGPoint p = LocationForRect(0,f, bb);
				pt1.y = p.y;
			}
			else
				pt1.y = f;
		}
		s = self.attrs[@"x2"];
		if (s)
		{
			CGFloat f = FloatOrPercentage(s);
			if (unitsBB)
			{
				CGPoint p = LocationForRect(f, 0, bb);
				pt2.x = p.x;
			}
			else
				pt2.x = f;
		}
		s = self.attrs[@"y2"];
		if (s)
		{
			CGFloat f = FloatOrPercentage(s);
			if (unitsBB)
			{
				CGPoint p = LocationForRect(0,f, bb);
				pt2.y = p.y;
			}
			else
				pt2.y = f;
		}
		if (trans)
		{
			pt1 = [trans transformPoint:pt1];
			pt2 = [trans transformPoint:pt2];
		}
		pt1.y = fr.size.height - pt1.y;
		pt2.y = fr.size.height - pt2.y;
		self.angle = 360 - DEGREES(atan2(pt2.y-pt1.y, pt2.x - pt1.x));
	}
	else
	{
		CGFloat cx = 0.5,cy = 0.5;
		CGPoint pt1 = LocationForRect(cx, cy, bb);
		NSString *s = self.attrs[@"cx"];
		if (s)
		{
			CGFloat f = FloatOrPercentage(s);
			if (unitsBB)
			{
				CGPoint p = LocationForRect(f, 0, bb);
				pt1.x = p.x;
			}
			else
				pt1.x = f;
		}
		s = self.attrs[@"cy"];
		if (s)
		{
			CGFloat f = FloatOrPercentage(s);
			if (unitsBB)
			{
				CGPoint p = LocationForRect(0,f, bb);
				pt1.y = p.y;
			}
			else
				pt1.y = f;
		}
		if (trans)
			pt1 = [trans transformPoint:pt1];
		pt1.y = fr.size.height - pt1.y;
		self.radialCentre = RelativePointInRect(pt1.x, pt1.y, bb);
	}
}
@end
