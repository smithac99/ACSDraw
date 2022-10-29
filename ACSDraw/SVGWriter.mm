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
	[[col colorUsingColorSpace:[NSColorSpace deviceRGBColorSpace]]getRed:&r green:&g blue:&b alpha:&a];
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
	[[col colorUsingColorSpace:[NSColorSpace deviceRGBColorSpace]]getRed:&r green:&g blue:&b alpha:&a];
	r *= 100;
	g *= 100;
	b *= 100;
	return [NSString stringWithFormat:@"rgb(%0.03g%%,%0.03g%%,%0.03g%%)",r,g,b];
   }

id fillFromNodeAttributes(NSDictionary* attrs)
{
    if (([attrs objectForKey:@"fill"]==nil) && ([attrs objectForKey:@"fill-opacity"]==nil) && ([attrs objectForKey:@"fillopacity"]==nil))
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
    if (n == nil)
        n = [attrs objectForKey:@"fillopacity"];
    if (n)
        opacity = [n floatValue];
    return [[ACSDFill alloc]initWithColour:[col colorWithAlphaComponent:opacity]];
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
    if (n == nil)
        n = [attrs objectForKey:@"strokewidth"];
    if (n)
        width = [n floatValue];
    ACSDStroke *stroke = [[ACSDStroke alloc]initWithColour:col width:width];
    float mitrelimit = 1.0;
    n = [attrs objectForKey:@"mitre-limit"];
    if (n)
        mitrelimit = [n floatValue];
    NSString *lc = [attrs objectForKey:@"stroke-linecap"];
    if (lc == nil)
        lc = [attrs objectForKey:@"linecap"];
    if (lc)
    {
        if ([lc isEqualToString:@"butt"])
            [stroke setLineCap:NSLineCapStyleButt];
        else if ([lc isEqualToString:@"round"])
            [stroke setLineCap:NSLineCapStyleRound];
        else if ([lc isEqualToString:@"square"])
            [stroke setLineCap:NSLineCapStyleSquare];
    }
    NSString *lj = [attrs objectForKey:@"stroke-linejoin"];
    if (lj)
    {
        if ([lj isEqualToString:@"miter"])
            [stroke setLineJoin:NSLineJoinStyleMiter];
        else if ([lj isEqualToString:@"round"])
            [stroke setLineJoin:NSLineJoinStyleRound];
        else if ([lj isEqualToString:@"bevel"])
            [stroke setLineJoin:NSLineJoinStyleBevel];
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
            [darray addObjectsFromArray:[darray copy]];
        if ([darray count] > 0)
            [stroke setDashes:darray];
    }
    return stroke;
}

NSColor *colorFromRGBString(NSString* str)
{
    static NSMutableDictionary *colourLiteralDictionary = nil;
    if ([str isEqualToString:@"none"])
        return nil;
    if ([str hasPrefix:@"#"])
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
    else if ([str hasPrefix:@"rgb("] && [str hasSuffix:@")"])
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
    else
    {
        NSArray *comps = [str componentsSeparatedByString:@","];
        if ([comps count] > 2)
        {
            float rgb[3];
            for (int i = 0;i < 3;i++)
            {
                NSString *comp = comps[i];
                rgb[i] = [comp floatValue] / 255.0;
            }
            return [NSColor colorWithCalibratedRed:rgb[0] green:rgb[1] blue:rgb[2] alpha:1.0];
        }
        else
        {
            if (colourLiteralDictionary == nil)
            {
                NSArray *colourLiterals = @[
                @[@"aliceblue",@(240),@(248),@(255)],
                @[@"antiquewhite",@(250),@(235),@(215)],
                @[@"aqua",@(0),@(255),@(255)],
                @[@"aquamarine",@(127),@(255),@(212)],
                @[@"azure",@(240),@(255),@(255)],
                @[@"beige",@(245),@(245),@(220)],
                @[@"bisque",@(255),@(228),@(196)],
                @[@"black",@(0),@(0),@(0)],
                @[@"blanchedalmond",@(255),@(235),@(205)],
                @[@"blue",@(0),@(0),@(255)],
                @[@"blueviolet",@(138),@(43),@(226)],
                @[@"brown",@(165),@(42),@(42)],
                @[@"burlywood",@(222),@(184),@(135)],
                @[@"cadetblue",@(95),@(158),@(160)],
                @[@"chartreuse",@(127),@(255),@(0)],
                @[@"chocolate",@(210),@(105),@(30)],
                @[@"coral",@(255),@(127),@(80)],
                @[@"cornflowerblue",@(100),@(149),@(237)],
                @[@"cornsilk",@(255),@(248),@(220)],
                @[@"crimson",@(220),@(20),@(60)],
                @[@"cyan",@(0),@(255),@(255)],
                @[@"darkblue",@(0),@(0),@(139)],
                @[@"darkcyan",@(0),@(139),@(139)],
                @[@"darkgoldenrod",@(184),@(134),@(11)],
                @[@"darkgray",@(169),@(169),@(169)],
                @[@"darkgreen",@(0),@(100),@(0)],
                @[@"darkgrey",@(169),@(169),@(169)],
                @[@"darkkhaki",@(189),@(183),@(107)],
                @[@"darkmagenta",@(139),@(0),@(139)],
                @[@"darkolivegreen",@(85),@(107),@(47)],
                @[@"darkorange",@(255),@(140),@(0)],
                @[@"darkorchid",@(153),@(50),@(204)],
                @[@"darkred",@(139),@(0),@(0)],
                @[@"darksalmon",@(233),@(150),@(122)],
                @[@"darkseagreen",@(143),@(188),@(143)],
                @[@"darkslateblue",@(72),@(61),@(139)],
                @[@"darkslategray",@(47),@(79),@(79)],
                @[@"darkslategrey",@(47),@(79),@(79)],
                @[@"darkturquoise",@(0),@(206),@(209)],
                @[@"darkviolet",@(148),@(0),@(211)],
                @[@"deeppink",@(255),@(20),@(147)],
                @[@"deepskyblue",@(0),@(191),@(255)],
                @[@"dimgray",@(105),@(105),@(105)],
                @[@"dimgrey",@(105),@(105),@(105)],
                @[@"dodgerblue",@(30),@(144),@(255)],
                @[@"firebrick",@(178),@(34),@(34)],
                @[@"floralwhite",@(255),@(250),@(240)],
                @[@"forestgreen",@(34),@(139),@(34)],
                @[@"fuchsia",@(255),@(0),@(255)],
                @[@"gainsboro",@(220),@(220),@(220)],
                @[@"ghostwhite",@(248),@(248),@(255)],
                @[@"gold",@(255),@(215),@(0)],
                @[@"goldenrod",@(218),@(165),@(32)],
                @[@"gray",@(128),@(128),@(128)],
                @[@"grey",@(128),@(128),@(128)],
                @[@"green",@(0),@(128),@(0)],
                @[@"greenyellow",@(173),@(255),@(47)],
                @[@"honeydew",@(240),@(255),@(240)],
                @[@"hotpink",@(255),@(105),@(180)],
                @[@"indianred",@(205),@(92),@(92)],
                @[@"indigo",@(75),@(0),@(130)],
                @[@"ivory",@(255),@(255),@(240)],
                @[@"khaki",@(240),@(230),@(140)],
                @[@"lavender",@(230),@(230),@(250)],
                @[@"lavenderblush",@(255),@(240),@(245)],
                @[@"lawngreen",@(124),@(252),@(0)],
                @[@"lemonchiffon",@(255),@(250),@(205)],
                @[@"lightblue",@(173),@(216),@(230)],
                @[@"lightcoral",@(240),@(128),@(128)],
                @[@"lightcyan",@(224),@(255),@(255)],
                @[@"lightgoldenrodyellow",@(250),@(250),@(210)],
                @[@"lightgray",@(211),@(211),@(211)],
                @[@"lightgreen",@(144),@(238),@(144)],
                @[@"lightgrey",@(211),@(211),@(211)],
                @[@"lightpink",@(255),@(182),@(193)],
                @[@"lightsalmon",@(255),@(160),@(122)],
                @[@"lightseagreen",@(32),@(178),@(170)],
                @[@"lightskyblue",@(135),@(206),@(250)],
                @[@"lightslategray",@(119),@(136),@(153)],
                @[@"lightslategrey",@(119),@(136),@(153)],
                @[@"lightsteelblue",@(176),@(196),@(222)],
                @[@"lightyellow",@(255),@(255),@(224)],
                @[@"lime",@(0),@(255),@(0)],
                @[@"limegreen",@(50),@(205),@(50)],
                @[@"linen",@(250),@(240),@(230)],
                @[@"magenta",@(255),@(0),@(255)],
                @[@"maroon",@(128),@(0),@(0)],
                @[@"mediumaquamarine",@(102),@(205),@(170)],
                @[@"mediumblue",@(0),@(0),@(205)],
                @[@"mediumorchid",@(186),@(85),@(211)],
                @[@"mediumpurple",@(147),@(112),@(219)],
                @[@"mediumseagreen",@(60),@(179),@(113)],
                @[@"mediumslateblue",@(123),@(104),@(238)],
                @[@"mediumspringgreen",@(0),@(250),@(154)],
                @[@"mediumturquoise",@(72),@(209),@(204)],
                @[@"mediumvioletred",@(199),@(21),@(133)],
                @[@"midnightblue",@(25),@(25),@(112)],
                @[@"mintcream",@(245),@(255),@(250)],
                @[@"mistyrose",@(255),@(228),@(225)],
                @[@"moccasin",@(255),@(228),@(181)],
                @[@"navajowhite",@(255),@(222),@(173)],
                @[@"navy",@(0),@(0),@(128)],
                @[@"oldlace",@(253),@(245),@(230)],
                @[@"olive",@(128),@(128),@(0)],
                @[@"olivedrab",@(107),@(142),@(35)],
                @[@"orange",@(255),@(165),@(0)],
                @[@"orangered",@(255),@(69),@(0)],
                @[@"orchid",@(218),@(112),@(214)],
                @[@"palegoldenrod",@(238),@(232),@(170)],
                @[@"palegreen",@(152),@(251),@(152)],
                @[@"paleturquoise",@(175),@(238),@(238)],
                @[@"palevioletred",@(219),@(112),@(147)],
                @[@"papayawhip",@(255),@(239),@(213)],
                @[@"peachpuff",@(255),@(218),@(185)],
                @[@"peru",@(205),@(133),@(63)],
                @[@"pink",@(255),@(192),@(203)],
                @[@"plum",@(221),@(160),@(221)],
                @[@"powderblue",@(176),@(224),@(230)],
                @[@"purple",@(128),@(0),@(128)],
                @[@"red",@(255),@(0),@(0)],
                @[@"rosybrown",@(188),@(143),@(143)],
                @[@"royalblue",@(65),@(105),@(225)],
                @[@"saddlebrown",@(139),@(69),@(19)],
                @[@"salmon",@(250),@(128),@(114)],
                @[@"sandybrown",@(244),@(164),@(96)],
                @[@"seagreen",@(46),@(139),@(87)],
                @[@"seashell",@(255),@(245),@(238)],
                @[@"sienna",@(160),@(82),@(45)],
                @[@"silver",@(192),@(192),@(192)],
                @[@"skyblue",@(135),@(206),@(235)],
                @[@"slateblue",@(106),@(90),@(205)],
                @[@"slategray",@(112),@(128),@(144)],
                @[@"slategrey",@(112),@(128),@(144)],
                @[@"snow",@(255),@(250),@(250)],
                @[@"springgreen",@(0),@(255),@(127)],
                @[@"steelblue",@(70),@(130),@(180)],
                @[@"tan",@(210),@(180),@(140)],
                @[@"teal",@(0),@(128),@(128)],
                @[@"thistle",@(216),@(191),@(216)],
                @[@"tomato",@(255),@(99),@(71)],
                @[@"turquoise",@(64),@(224),@(208)],
                @[@"violet",@(238),@(130),@(238)],
                @[@"wheat",@(245),@(222),@(179)],
                @[@"white",@(255),@(255),@(255)],
                @[@"whitesmoke",@(245),@(245),@(245)],
                @[@"yellow",@(255),@(255),@(0)],
                @[@"yellowgreen",@(154),@(205),@(50)]
                ];
                colourLiteralDictionary = [NSMutableDictionary dictionaryWithCapacity:[colourLiterals count]];
                for (NSArray *collist in colourLiterals)
                {
                    float rgb[3];
                    for (int i = 0;i < 3;i++)
                        rgb[i] = [collist[i+1] floatValue] / 255.0;
                    colourLiteralDictionary[collist[0]] = [NSColor colorWithRed:rgb[0] green:rgb[1] blue:rgb[2] alpha:1.0];
                }
            }
            return colourLiteralDictionary[str];
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
               case NSBezierPathElementMoveTo:
                   point[0] = adjust_point(point[0]);
                   if (i != ct - 1)
                       [str appendFormat:@"M%0.04g %0.04g",point[0].x,point[0].y];
                   currPoint = point[0];
                   break;
               case NSBezierPathElementLineTo:
                   point[0] = adjust_point(point[0]);
                   [str appendFormat:@"L%0.04g %0.04g",point[0].x,point[0].y];
                   currPoint = point[0];
                   break;
               case NSBezierPathElementCurveTo:
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
               case NSBezierPathElementClosePath:
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
               case NSBezierPathElementMoveTo:
				[str appendFormat:@"ctx.moveTo(%g,%g);",point[0].x,point[0].y];
				break;
               case NSBezierPathElementLineTo:
				[str appendFormat:@"ctx.lineTo(%g,%g);",point[0].x,point[0].y];
				break;
               case NSBezierPathElementCurveTo:
				[str appendFormat:@"ctx.bezierCurveTo(%g,%g,%g,%g,%g,%g);",point[0].x,point[0].y,point[1].x,point[1].y,point[2].x,point[2].y];
				break;
               case NSBezierPathElementClosePath:
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
           _documentSize = sz;
           prefix = [[NSMutableString alloc]initWithCapacity:100];
           defs = [[NSMutableString alloc]initWithCapacity:512];
           contents = [[NSMutableString alloc]initWithCapacity:512];
           [prefix appendString:xmlHead];
           [prefix appendString:docHead];
           document = doc;
           page = p;
           self.gradients = [NSMutableArray array];
           lineEndings = [NSMutableSet setWithCapacity:5];
           shadows = [NSMutableSet setWithCapacity:5];
           self.patterns = [[NSMutableArray alloc]init];
           contentsStack = [NSMutableArray array];
           otherDefStrings = [NSMutableArray array];
           self.sources = [NSMutableDictionary dictionary];
           self.shouldInvertSVGCoords = YES;
           if (self.shouldInvertSVGCoords)
           {
               self.inversionTransform = [[NSAffineTransform alloc]init];
               [self.inversionTransform translateXBy:0 yBy:_documentSize.height];
               [self.inversionTransform scaleXBy:1 yBy:-1];
           }
       }
    return self;
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

-(void)addPattern:(id)g
{
    [self.patterns addObject:g];
}

-(void)addLineEnding:(ACSDLineEnding*)le
{
 [lineEndings addObject:le];
}

-(void)addOtherDefString:(NSString*)defstr
{
 [otherDefStrings addObject:defstr];
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
    if (self.shouldInvertSVGCoords)
        [prefix appendString:@"<g>\n"];
    else
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
    contents = [[NSMutableString alloc]init];
}

-(NSString*)restoreContents
{
    NSString *curr = contents;
    contents = [contentsStack lastObject];
    [contentsStack removeLastObject];
    return curr;
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
    
    if ([self.patterns count] > 0)
	{
		for (id pat in self.patterns)
            if ([pat isKindOfClass:[ACSDPattern class]])
                [pat writeSVGPatternDef:self allPatterns:self.patterns];
            else
            {
                NSDictionary *d = pat;
                ACSDPattern *p = d[@"pattern"];
                NSRect r = [d[@"bounds"]rectValue];
                NSString *name = d[@"name"];
                [p writeSVGPatternDef:self allPatterns:self.patterns bounds:r name:name];
            }
	}
    if ([defs length] > 0 || [otherDefStrings count] > 0)
	   {
           [prefix appendString:@"<defs>\n"];
           [prefix appendString:defs];
           for (NSString *s in otherDefStrings)
               [prefix appendFormat:@"\t%@\n",s];
           [prefix appendString:@"</defs>\n"];
       }
    if (self.shouldInvertSVGCoords)
        [prefix appendString:@"<g>\n"];
    else
        [prefix appendFormat:@"<g transform=\"translate(0,%d) scale(1,-1)\">\n",(int)docSize.height];
}

-(NSRect)invertRect:(NSRect)r
{
    NSPoint origin = r.origin;
    origin = NSMakePoint(origin.x,  NSMaxY(r));
    origin = [self.inversionTransform transformPoint:origin];
    r.origin = origin;
    return r;
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
