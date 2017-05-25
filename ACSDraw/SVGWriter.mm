//
//  SVGWriter.mm
//  ACSDraw
//
//  Created by Alan Smith on Thu Mar 07 2002.
//  Copyright (c) 2001 __MyCompanyName__. All rights reserved.
//

#import "SVGWriter.h"
#import "ACSDAttribute.h"
#import "ACSDLayer.h"
#import "ACSDPage.h"
#import "ACSDGradient.h"
#import "ACSDStroke.h"
#import "ShadowType.h"
#import "ACSDLineEnding.h"
#import "ACSDGraphic.h"
#import "ACSDPattern.h"
#import "geometry.h"

NSString* headerString(int width,int height);

NSString *xmlHead = @"<?xml version=\"1.0\" standalone=\"no\"?>\n";
NSString *docHead = @"<!DOCTYPE svg PUBLIC \"-//W3C//DTD SVG 1.0//EN\" \"http://www.w3.org/TR/2001/REC-SVG-20010904/DTD/svg10.dtd\">\n";

NSString* rgba_from_nscolor(NSColor *col)
   {
    if (!col)
		col = [NSColor blackColor];
	CGFloat r,g,b,a;
	[[col colorUsingColorSpaceName:NSCalibratedRGBColorSpace device:nil]getRed:&r green:&g blue:&b alpha:&a];
	r *= 255;
	g *= 255;
	b *= 255;
	return [NSString stringWithFormat:@"rgba(%d,%d,%d,%g)",(int)r,(int)g,(int)b,a];
   }

NSString* string_from_nscolor(NSColor *col)
   {
    if (!col)
		col = [NSColor blackColor];
	CGFloat r,g,b,a;
	[[col colorUsingColorSpaceName:NSCalibratedRGBColorSpace device:nil]getRed:&r green:&g blue:&b alpha:&a];
	r *= 100;
	g *= 100;
	b *= 100;
	return [NSString stringWithFormat:@"rgb(%0.03g%%,%0.03g%%,%0.03g%%)",r,g,b];
   }

id fillFromNodeAttributes(NSDictionary* attrs)
{
    if (([attrs objectForKey:@"fill"]==nil) && ([attrs objectForKey:@"fill-opacity"]==nil))
        return nil;
    NSColor *col = nil;
    NSString *str = [attrs objectForKey:@"fill"];
	if ([str hasPrefix:@"url"])
		return str;
    if (str)
        col = colorFromRGBString(str);
    else
        col = [NSColor blackColor];
    float opacity = 1.0;
    id n = [attrs objectForKey:@"fill-opacity"];
    if (n)
        opacity = [n floatValue];
    return [[[ACSDFill alloc]initWithColour:[col colorWithAlphaComponent:opacity]]autorelease];
}

ACSDStroke* strokeFromNodeAttributes(NSDictionary* attrs)
{
    if (([attrs objectForKey:@"stroke"]==nil) && ([attrs objectForKey:@"stroke-opacity"]==nil) && ([attrs objectForKey:@"stroke-linecap"]==nil) && ([attrs objectForKey:@"stroke-linejoin"]==nil) && ([attrs objectForKey:@"stroke-width"]==nil) && ([attrs objectForKey:@"stroke-miterlimit"]==nil) && ([attrs objectForKey:@"stroke-dasharray"]==nil) && ([attrs objectForKey:@"stroke-dashoffset"]==nil))
        return nil;
    NSColor *col = nil;
    NSString *str = [attrs objectForKey:@"stroke"];
    if (str)
        col = colorFromRGBString(str);
    else
        col = [NSColor blackColor];
    float opacity = 1.0;
    id n = [attrs objectForKey:@"stroke-opacity"];
    if (n)
        opacity = [n floatValue];
    col = [col colorWithAlphaComponent:opacity];
    float width = 1.0;
    n = [attrs objectForKey:@"stroke-width"];
    if (n)
        width = [n floatValue];
    ACSDStroke *stroke = [[[ACSDStroke alloc]initWithColour:col width:width]autorelease];
    float mitrelimit = 1.0;
    n = [attrs objectForKey:@"stroke-width"];
    if (n)
        mitrelimit = [n floatValue];
    NSString *lc = [attrs objectForKey:@"stroke-linecap"];
    if (lc)
    {
        if ([lc isEqualToString:@"butt"])
            [stroke setLineCap:NSButtLineCapStyle];
        else if ([lc isEqualToString:@"round"])
            [stroke setLineCap:NSRoundLineCapStyle];
        else if ([lc isEqualToString:@"square"])
            [stroke setLineCap:NSSquareLineCapStyle];
    }
    NSString *lj = [attrs objectForKey:@"stroke-linejoin"];
    if (lj)
    {
        if ([lj isEqualToString:@"miter"])
            [stroke setLineJoin:NSMiterLineJoinStyle];
        else if ([lj isEqualToString:@"round"])
            [stroke setLineJoin:NSRoundLineJoinStyle];
        else if ([lj isEqualToString:@"bevel"])
            [stroke setLineJoin:NSBevelLineJoinStyle];
    }
    float dashoffset = 1.0;
    n = [attrs objectForKey:@"stroke-dashoffset"];
    if (n)
    {
        dashoffset = [n floatValue];
        [stroke setDashPhase:dashoffset];
    }
    NSString *dashes = [attrs objectForKey:@"stroke-dasharray"];
    if (dashes)
    {
        NSMutableArray *darray = [NSMutableArray arrayWithCapacity:5];
        NSArray *comps = [dashes componentsSeparatedByCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@", "]];
        for (NSString *s in comps)
            [darray addObject:[NSNumber numberWithFloat:[s floatValue]]];
        if (([darray count] & 1) != 0)
            [darray addObjectsFromArray:[[darray copy]autorelease]];
        if ([darray count] > 0)
            [stroke setDashes:darray];
    }
    return stroke;
}

NSColor *colorFromRGBString(NSString* str)
{
    if ([str isEqualToString:@"none"])
        return nil;
    if ([str length] < 4)
        return nil;
    if ([[str substringToIndex:1]isEqualToString:@"#"])
    {
        str = [[str substringFromIndex:1]lowercaseString];
        if ([str length] == 3)
        {
            int rgb[3];
            for (int i = 0;i < 3;i++)
            {
                unichar ch = [str characterAtIndex:i];
                int val = 0;
                if (ishexnumber(ch))
                    if (isdigit(ch))
                        val = ch - '0';
                    else
                        val = ch - 'a' + 10;
                rgb[i] = val;
            }
            return [NSColor colorWithCalibratedRed:rgb[0]/15.0 green:rgb[1]/15.0 blue:rgb[2]/15.0 alpha:1.0];
        }
        else if ([str length] == 6)
        {
            int rrggbb[6];
            for (int i = 0;i < 6;i++)
            {
                unichar ch = [str characterAtIndex:i];
                int val = 0;
                if (ishexnumber(ch))
                    if (isdigit(ch))
                        val = ch - '0';
                    else
                        val = ch - 'a' + 10;
                rrggbb[i] = val;
            }
            return [NSColor colorWithCalibratedRed:(rrggbb[0] * 16 + rrggbb[1])/255.0 green:(rrggbb[2] * 16 + rrggbb[3])/255.0 blue:(rrggbb[4] * 16 + rrggbb[5])/255.00 alpha:1.0];
        }
    }
    else if ([str length] > 4 && [[str substringToIndex:4]isEqualToString:@"rgb("]&& [[str substringFromIndex:[str length]-1]isEqualToString:@")"])
    {
        str = [str substringWithRange:NSMakeRange(4, [str length] - 4 - 1)];
        NSArray *components = [str componentsSeparatedByString:@","];
        if ([components count] == 3)
        {
            float rgb[3];
            for (int i = 0;i < 3;i++)
            {
                NSString *comp = components[i];
                if ([comp length] > 0 && [[comp substringFromIndex:[comp length] - 1]isEqualToString:@"%"])
                    rgb[i] = [[comp substringToIndex:[comp length]-1]floatValue] / 100.0;
                else
                    rgb[i] = [comp floatValue] / 255.0;
            }
            return [NSColor colorWithCalibratedRed:rgb[0] green:rgb[1] blue:rgb[2] alpha:1.0];
        }
    }
    return nil;
}

NSString* string_from_transform(NSAffineTransform *trans)
   {
    if (!trans)
		return @"";
	NSAffineTransformStruct ats = [trans transformStruct];
	return [NSString stringWithFormat:@"matrix(%f,%f,%f,%f,%f,%f) ",ats.m11,ats.m12,ats.m21,ats.m22,ats.tX,ats.tY];
   }

static NSPoint adjust_point(NSPoint pt)
{
    if (fabs(pt.x) < 0.0001)
        pt.x = 0;
    if (fabs(pt.y) < 0.0001)
        pt.y = 0;
    return pt;
}
NSString* string_from_path(NSBezierPath* path)
{
    NSInteger ct = [path elementCount];
    if (ct < 2)
        return @"";
    NSMutableString *str = [NSMutableString stringWithCapacity:50];
    NSPoint point[3];
    NSPoint currPoint = NSZeroPoint;
    for (NSInteger i = 0;i < ct;i++)
	   {
           NSBezierPathElement elementType = [path elementAtIndex:i associatedPoints:point];
           switch (elementType)
           {
               case NSMoveToBezierPathElement:
                   point[0] = adjust_point(point[0]);
                   if (i != ct - 1)
                       [str appendFormat:@"M%0.04g %0.04g",point[0].x,point[0].y];
                   currPoint = point[0];
                   break;
               case NSLineToBezierPathElement:
                   point[0] = adjust_point(point[0]);
                   [str appendFormat:@"L%0.04g %0.04g",point[0].x,point[0].y];
                   currPoint = point[0];
                   break;
               case NSCurveToBezierPathElement:
                   //[str appendFormat:@"C%g %g %g %g %g %g",point[0].x,point[0].y,point[1].x,point[1].y,point[2].x,point[2].y];
                   [str appendString:@"c"];
                   for (int i = 0;i < 3;i++)
                   {
                       NSPoint dp = adjust_point(diff_points(point[i], currPoint));
                       if (i > 0 && dp.x >= 0)
                           [str appendString:@" "];
                       [str appendFormat:@"%0.03g",dp.x];
                       if (dp.y >= 0)
                           [str appendString:@" "];
                       [str appendFormat:@"%0.03g",dp.y];
                   }
                   currPoint = point[2];
                   break;
               case NSClosePathBezierPathElement:
                   [str appendString:@"Z"];
                   break;
           }
       }
    return str;
}

NSString* canvas_string_from_path(NSBezierPath* path)
   {
	NSInteger ct = [path elementCount];
	if (ct < 2)
		return @"";
	NSMutableString *str = [NSMutableString stringWithCapacity:50];
	NSPoint point[3];
	for (NSInteger i = 0;i < ct;i++)
	   {
		NSBezierPathElement elementType = [path elementAtIndex:i associatedPoints:point];
		switch (elementType)
		   {
			case NSMoveToBezierPathElement:
				[str appendFormat:@"ctx.moveTo(%g,%g);",point[0].x,point[0].y];
				break;
			case NSLineToBezierPathElement:
				[str appendFormat:@"ctx.lineTo(%g,%g);",point[0].x,point[0].y];
				break;
			case NSCurveToBezierPathElement:
				[str appendFormat:@"ctx.bezierCurveTo(%g,%g,%g,%g,%g,%g);",point[0].x,point[0].y,point[1].x,point[1].y,point[2].x,point[2].y];
				break;
			case NSClosePathBezierPathElement:
				[str appendString:@"ctx.closePath();"];
				break;
		   }
	   }
	return str;
   }

#pragma mark -

@implementation SVGWriter

-(id)initWithSize:(NSSize)sz document:(ACSDrawDocument*)doc page:(NSInteger)p
{
    if (self = [super init])
	   {
           prefix = [[NSMutableString alloc]initWithCapacity:100];
           defs = [[NSMutableString alloc]initWithCapacity:512];
           contents = [[NSMutableString alloc]initWithCapacity:512];
           [prefix appendString:xmlHead];
           [prefix appendString:docHead];
           document = doc;
           page = p;
           self.gradients = [NSMutableArray array];
           lineEndings = [[NSMutableSet setWithCapacity:5]retain];
           shadows = [[NSMutableSet setWithCapacity:5]retain];
           patterns = [[NSMutableSet setWithCapacity:5]retain];
           contentsStack = [[NSMutableArray array]retain];
       }
    return self;
}

-(void)dealloc
{
	[contents release];
	[defs release];
	[prefix release];
	self.gradients = nil;
	[lineEndings release];
    [shadows release];
    [patterns release];
	[super dealloc];
}

NSString* headerString(int width,int height)
   {
	return [NSString stringWithFormat:@"<svg xmlns=\"http://www.w3.org/2000/svg\" xmlns:xlink=\"http://www.w3.org/1999/xlink\" width=\"%dpx\" height=\"%dpx\" viewBox = \"0 0 %d %d\">\n",
		width,height,width,height];
   }

-(void)addShadow:(ShadowType*)shad
   {
	[shadows addObject:shad];
   }

-(void)addGradient:(NSDictionary*)d
{
    [self.gradients addObject:d];
}

-(void)addPattern:(ACSDPattern*)g
{
    [patterns addObject:g];
}

-(void)addLineEnding:(ACSDLineEnding*)le
   {
	[lineEndings addObject:le];
   }

-(void)createDataForGraphic:(ACSDGraphic*)g
{
	NSRect displayBounds = [g displayBounds];
	[prefix appendString:headerString((int)displayBounds.size.width,(int)displayBounds.size.height)];
	[contents appendFormat:@"<g transform=\"translate(%d,%d)\">\n",(int)-displayBounds.origin.x,(int)-displayBounds.origin.y];
	[g writeSVGData:self];
//	if ([self.gradients count] > 0)
//		[self.gradients makeObjectsPerformSelector:@selector(writeSVGGradientDef:) withObject:self];
	if ([shadows count] > 0)
		[shadows makeObjectsPerformSelector:@selector(writeSVGShadowDef:) withObject:self];
	if ([lineEndings count] > 0)
		[lineEndings makeObjectsPerformSelector:@selector(writeSVGData:) withObject:self];
	if ([defs length] > 0)
	{
		[prefix appendString:@"<defs>\n"];
		[prefix appendString:defs];
		[prefix appendString:@"</defs>\n"];
	}
	[prefix appendFormat:@"<g transform=\"translate(0,%d) scale(1,-1)\">\n",(int)displayBounds.size.height];
	[contents appendString:@"</g>\n"];
}

-(NSString*)indentString
   {
	if (indentString)
		return indentString;
	return @"";
   }

-(void)indentDef
   {
	if (indentString)
		indentString = [indentString stringByAppendingString:@"\t"];
	else
		indentString = @"\t";
   }

-(void)outdentDef
   {
	if (indentString == nil)
		return;
	if ([indentString length] <= 1)
		indentString = nil;
	else
		indentString = [indentString substringToIndex:[indentString length]-1];
   }

-(void)saveContents
{
    [contentsStack addObject:contents];
    [contents release];
    contents = [[NSMutableString alloc]init];
}

-(void)restoreContents
{
    [contents release];
    contents = [[contentsStack lastObject]retain];
    [contentsStack removeLastObject];
}

-(void)createData
{
    indentString = nil;
    NSInteger i;
    NSMutableArray *arr;
    NSSize docSize = [document documentSize];
    [prefix appendString:headerString((int)docSize.width,(int)docSize.height)];
    [self indentDef];
    arr=[[[document pages]objectAtIndex:page]layers];
    for (i = [arr count] - 1;i >= 0;i--)
	   {
           ACSDLayer *layer = [arr objectAtIndex:i];
           if ([layer exportable] && [[layer graphics]count] > 0)
               [layer writeSVGData:self];
       }
    [self outdentDef];
	{
		int j = 0;
		for (NSDictionary *d in self.gradients)
		{
			ACSDGradient *grad = d[@"gradient"];
			[grad writeSVGGradientDef:self options:self.gradients[j]];
			j++;
		}
	}
    if ([shadows count] > 0)
        [shadows makeObjectsPerformSelector:@selector(writeSVGShadowDef:) withObject:self];
    if ([lineEndings count] > 0)
        [lineEndings makeObjectsPerformSelector:@selector(writeSVGData:) withObject:self];
    
    if ([patterns count] > 0)
	{
		NSArray *allp = [patterns allObjects];
		for (ACSDPattern *pat in allp)
			[pat writeSVGPatternDef:self allPatterns:allp];
	}
    if ([defs length] > 0)
	   {
           [prefix appendString:@"<defs>\n"];
           [prefix appendString:defs];
           [prefix appendString:@"</defs>\n"];
       }
    [prefix appendFormat:@"<g transform=\"translate(0,%d) scale(1,-1)\">\n",(int)docSize.height];
}

-(NSString*)clipPathName
   {
    return clipPathName;
   }

-(void)setClipPathName:(NSString*)s
   {
    clipPathName = s;
   }

-(ACSDrawDocument*)document
   {
    return document;
   }
   
-(NSMutableString*)contents
   {
    return contents;
   }

-(NSMutableString*)prefix
   {
    return prefix;
   }

-(NSMutableString*)defs
{
	return defs;
}

-(NSString*)fullString
{
	return [NSString stringWithFormat:@"%@%@</g>\n</svg>\n",prefix,contents];
}
@end
