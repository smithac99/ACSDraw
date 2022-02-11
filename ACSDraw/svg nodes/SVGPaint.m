//
//  SVGPaint.m
//  Vectorius
//
//  Created by Alan Smith on 06/08/2020.
//  Copyright © 2020 Alan Smith. All rights reserved.
//

#import "SVGPaint.h"

@implementation SVGPaint

-(instancetype)initWithObj:(id)obj
{
    if (self = [super init])
    {
        if (obj == nil)
            _paintType = PAINTTYPE_NONE;
        else
        {
            _ref = obj;
            if ([_ref isKindOfClass:[NSColor class]])
                _paintType = PAINTTYPE_COLOUR;
            else
                _paintType = PAINTTYPE_SERVER;
        }
    }
    return self;
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
                {
                    if (isdigit(ch))
                        val = ch - '0';
                    else
                        val = ch - 'a' + 10;
                }
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
                {
                    if (isdigit(ch))
                        val = ch - '0';
                    else
                        val = ch - 'a' + 10;
                }
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
-(instancetype)initWithString:(NSString*)attrstr
{
    if (self = [super init])
    {
        if ([attrstr isEqualToString:@"none"])
            _paintType = PAINTTYPE_NONE;
        else if ([attrstr hasPrefix:@"url"])
        {
            _ref = [attrstr substringWithRange:NSMakeRange(5,[attrstr length]-1-5)];
            _paintType = PAINTTYPE_SERVER;
        }
        else
        {
            NSColor *col = colorFromRGBString(attrstr);
            if (col)
            {
                _paintType = PAINTTYPE_COLOUR;
                _ref = col;
            }
            else
                _paintType = PAINTTYPE_NONE;
        }
    }
    return self;
}

@end
