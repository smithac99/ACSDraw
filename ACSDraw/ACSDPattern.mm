//
//  ACSDPattern.mm
//  ACSDraw
//
//  Created by alan on 22/02/2005.
//  Copyright 2005 Alan C Smith. All rights reserved.
//

#import "ACSDPattern.h"
#import "GraphicView.h"
#import "ACSDPath.h"
#import "ACSDRect.h"
#import "ACSDGroup.h"
#import "ACSDGraphic.h"
#import "ACSDFill.h"
#import "SVGWriter.h"
#import "ACSDGraphic.h"
#import "ObjectPDFData.h"
#import "AffineTransformAdditions.h"

CGSize cgSizeFromNSSize(NSSize sz);
CGPoint cgPointFromNSPoint(NSPoint pt);

CGSize cgSizeFromNSSize(NSSize sz)
{
	return CGSizeMake(sz.width,sz.height);
}

CGPoint cgPointFromNSPoint(NSPoint pt)
{
	return CGPointMake(pt.x,pt.y);
}

@implementation ACSDPattern


+(ACSDPattern*)defaultPattern
{
	NSBezierPath *path;
	path = [NSBezierPath bezierPath];
	[path moveToPoint:NSMakePoint(10,5)];
	[path lineToPoint:NSMakePoint(10,20)];
	[path lineToPoint:NSMakePoint(17,15)];
	[path lineToPoint:NSMakePoint(12,15)];
	[path lineToPoint:NSMakePoint(10,5)];
	[path closePath];
	ACSDPath *ap = [[ACSDPath alloc]initWithName:@"DefaultPattern" fill:[[ACSDFill alloc]initWithColour:[NSColor blackColor]]
										  stroke:nil rect:NSZeroRect layer:nil
									  bezierPath:path];
	return [[ACSDPattern alloc] initWithGraphic:ap scale:1.0 spacing:0.2 offset:0.0 offsetMode:OFFSET_MODE_NONE alpha:1.0 mode:ACSD_PATTERN_SINGLE
								   patternBounds:[ap bounds]];
}

+(ACSDPattern*)patternWithGraphic:(ACSDGraphic*)g scale:(float)sc spacing:(float)sp offset:(float)o offsetMode:(int)om alpha:(float)al mode:(int)m patternBounds:(NSRect)r
{
	return [[ACSDPattern alloc] initWithGraphic:g scale:sc spacing:sp offset:o offsetMode:om alpha:al mode:m
								   patternBounds:r];
}

+(ACSDPattern*)patternWithGraphic:(ACSDGraphic*)g
{
    NSRect bnds;
    ACSDRect *foundrect = nil;
    int rectcount = 0;
    if ([g isKindOfClass:[ACSDGroup class]])
    {
        ACSDGroup *gp = (ACSDGroup*)g;
        for (ACSDGraphic *gr in [gp graphics])
        {
            if ([gr isKindOfClass:[ACSDRect class]])
            {
                rectcount++;
                foundrect = (ACSDRect*)gr;
            }
            if (rectcount > 1)
                break;
        }
    }
    if (foundrect)
        bnds = [foundrect bounds];
    else
        bnds = [g bounds];
	ACSDPattern *pat = [[ACSDPattern alloc] initWithGraphic:g scale:1.0 spacing:0.0 offset:0.0 offsetMode:OFFSET_MODE_NONE alpha:1.0 mode:ACSD_PATTERN_SINGLE
								   patternBounds:bnds];
    return pat;
}

-(id)initWithGraphic:(ACSDGraphic*)g scale:(float)sc spacing:(float)sp offset:(float)o offsetMode:(int)om alpha:(float)al mode:(int)m patternBounds:(NSRect)r
{
	if (self = [super initWithColour:[[NSColor whiteColor]colorWithAlphaComponent:al]])
	{
		self.graphic = g;
		[self.graphic buildPDFData];
		pdfImageRep = [NSPDFImageRep imageRepWithData:[[self.graphic objectPdfData]pdfData]];
		pdfOffset = [[self.graphic objectPdfData]offset];
		self.scale = sc;
		self.offset = o;
		self.offsetMode = om;
		self.spacing = sp;
		self.alpha = al;
		self.mode = m;
		self.patternBounds = r;
        self.patternOrigin = NSMakePoint(0.5, 0.5);
		graphicCache = nil;
		self.backgroundColour = [NSColor clearColor];
		self.clip = YES;
	}
	return self;
}

- (id)copyWithZone:(NSZone *)zone 
{
    ACSDPattern *o = [[[self class] allocWithZone:zone] initWithGraphic:[self.graphic copy] scale:self.scale spacing:self.spacing offset:self.offset offsetMode:self.offsetMode alpha:self.alpha
														 mode:self.mode patternBounds:[self patternBounds]];
	[o setBackgroundColour:self.backgroundColour];
	[o setClip:self.clip];
    [o setRotation:self.rotation];
    o.patternOrigin = self.patternOrigin;
	return o;
}

- (void) encodeWithCoder:(NSCoder*)coder
{
	[coder encodeObject:self.graphic forKey:@"ACSDPattern_graphic"];
	[coder encodeObject:[NSNumber numberWithFloat:self.scale]forKey:@"ACSDPattern_scale"];
	[coder encodeObject:[NSNumber numberWithFloat:self.spacing]forKey:@"ACSDPattern_spacing"];
	[coder encodeObject:[NSNumber numberWithFloat:self.offset]forKey:@"ACSDPattern_offset"];
	[coder encodeObject:[NSNumber numberWithInt:self.offsetMode]forKey:@"ACSDPattern_offsetMode"];
	[coder encodeObject:[NSNumber numberWithFloat:self.alpha]forKey:@"ACSDPattern_alpha"];
	[coder encodeObject:[NSNumber numberWithInt:self.mode]forKey:@"ACSDPattern_mode"];
	[coder encodeObject:self.backgroundColour forKey:@"ACSDPattern_backgroundColour"];
	[ACSDGraphic encodeRect:self.patternBounds coder:coder forKey:@"ACSDPattern_patternBounds"];
	[coder encodeBool:self.clip forKey:@"ACSDPattern_clip"];
	[coder encodeFloat:self.rotation forKey:@"ACSDPattern_rotation"];
    [coder encodePoint:self.patternOrigin forKey:@"ACSDPattern_patternOrigin"];
}

- (id) initWithCoder:(NSCoder*)coder
{
	self = [super init];
	self.graphic = [coder decodeObjectForKey:@"ACSDPattern_graphic"];
	self.scale = [[coder decodeObjectForKey:@"ACSDPattern_scale"]floatValue];
	self.spacing = [[coder decodeObjectForKey:@"ACSDPattern_spacing"]floatValue];
	self.offset = [[coder decodeObjectForKey:@"ACSDPattern_offset"]floatValue];
	self.offsetMode = [[coder decodeObjectForKey:@"ACSDPattern_offsetMode"]intValue];
	self.alpha = [[coder decodeObjectForKey:@"ACSDPattern_alpha"]floatValue];
	self.mode = [[coder decodeObjectForKey:@"ACSDPattern_mode"]intValue];
	self.patternBounds = [ACSDGraphic decodeRectForKey:@"ACSDPattern_patternBounds" coder:coder];
	self.backgroundColour = [coder decodeObjectForKey:@"ACSDPattern_backgroundColour"];
	self.clip = [coder decodeBoolForKey:@"ACSDPattern_clip"];
	self.rotation = [coder decodeFloatForKey:@"ACSDPattern_rotation"];
    if ([coder decodeObjectForKey:@"ACSDPattern_patternOrigin"])
        self.patternOrigin = [coder decodePointForKey:@"ACSDPattern_patternOrigin"];
	[self.graphic buildPDFData];
	pdfImageRep = [NSPDFImageRep imageRepWithData:[[self.graphic objectPdfData]pdfData]];
	pdfOffset = [[self.graphic objectPdfData]offset];
	graphicCache = nil;
	return self;
}

-(void)dealloc
{
	self.graphic = nil;
	//[graphicCache release];
	//[pdfImageRep release];
	self.backgroundColour = nil;
	//[super dealloc];
}

-(BOOL)canFill
{
	return YES;
}


-(void)changeCache
{
	NSRect b = [self.graphic bounds];
	//float lpad,rpad,tpad,bpad;
	//NSRect dr = [graphic displayBounds];
/*	lpad = b.origin.x - dr.origin.x;
	bpad = b.origin.y - dr.origin.y;
	rpad = (dr.origin.x + dr.size.width) - (b.origin.x + b.size.width);
	tpad = (dr.origin.y + dr.size.height) - (b.origin.y + b.size.height);*/
	b.size.width *= (1.0 + self.spacing);
	b.size.height *= (1.0 + self.spacing);
	if (self.mode > ACSD_PATTERN_SINGLE)
		b.size.width *= 2;
	if (self.mode > ACSD_PATTERN_DOUBLE_MIRROR)
		b.size.height *= 2;
	if (graphicCache)
		[graphicCache resizeToWidth:b.size.width height:b.size.height];
	else
		graphicCache = [[GraphicCache alloc]initWithWidth:b.size.width height:b.size.height];
}

-(void)changeScale:(float)sc view:(GraphicView*)gView
{
	[self invalidateGraphicsRefreshCache:NO];
	[self setScale:sc];
	[self.graphic setMagnification:self.scale];
	if (gView)
	{
		[graphicCache setMagnification:self.scale*[gView magnification]];
		[self changeCache];
	}
	[self invalidateGraphicsRefreshCache:YES];
}

-(void)changeMode:(int)m view:(GraphicView*)gView
{
	[self invalidateGraphicsRefreshCache:NO];
	[self setMode:m];
	[self invalidateGraphicsRefreshCache:YES];
}

-(void)changeSpacing:(float)sp view:(GraphicView*)gView
{
	[self invalidateGraphicsRefreshCache:NO];
	[self setSpacing:sp];
	[self changeCache];
	[self invalidateGraphicsRefreshCache:YES];
}

-(void)changeOffset:(float)f view:(GraphicView*)gView
{
	[self invalidateGraphicsRefreshCache:NO];
	[self setOffset:f];
	[self changeCache];
	[self invalidateGraphicsRefreshCache:YES];
}

-(void)changeOffsetMode:(int)om view:(GraphicView*)gView
{
	[self invalidateGraphicsRefreshCache:NO];
	[self setOffsetMode:om];
	[self changeCache];
	[self invalidateGraphicsRefreshCache:YES];
}

-(void)changeAlpha:(float)f view:(GraphicView*)gView
{
	[self invalidateGraphicsRefreshCache:NO];
	[self setAlpha:f];
	[self changeCache];
	[self invalidateGraphicsRefreshCache:YES];
}

-(void)changeGraphic:(ACSDGraphic*)g view:(GraphicView*)gView
{
	[self setGraphic:g];
	[self invalidateGraphicsRefreshCache:YES];
}

-(void)changeClip:(BOOL)clip view:(GraphicView*)gView
{
	[self invalidateGraphicsRefreshCache:NO];
	[self setClip:clip];
	[self changeCache];
	[self invalidateGraphicsRefreshCache:YES];
}

-(void)changeRotation:(float)rot view:(GraphicView*)gView
{
	[self invalidateGraphicsRefreshCache:NO];
	[self setRotation:rot];
	[self changeCache];
	[self invalidateGraphicsRefreshCache:YES];
}

-(void)refreshGraphicCache
{
	[[graphicCache image]lockFocus];
	[[NSColor clearColor]set];
	NSRectFill([graphicCache allocatedBounds]);
	NSAffineTransform *tf = [NSAffineTransform transform];
	[tf scaleBy:[graphicCache magnification]];
	[tf concat];
	[self.graphic draw:[graphicCache allocatedBounds] inView:nil selected:NO isGuide:NO cacheDrawing:NO options:nil];
	[graphicCache setValid:YES];
	[[graphicCache image]unlockFocus];
}

#define ODD(a) ((a) & 1)?YES:NO
#define EVEN(a) ((a) & 1)?NO:YES

-(NSAffineTransform*)transformForI:(int)i j:(int)j destRect:(NSRect)destRect
{
	if (self.mode == ACSD_PATTERN_SINGLE || (EVEN(i) && EVEN(j)))
		return [NSAffineTransform transform];
	if (self.mode == ACSD_PATTERN_MIRROR)
	{
		if (ODD(j))
		{
			NSAffineTransform *aff = [NSAffineTransform transformWithTranslateXBy:destRect.size.width yBy:0];
			[aff prependTransform:[NSAffineTransform transformWithScaleXBy:-1 yBy:1]];
			return aff;
		}
	}
	else if (self.mode == ACSD_PATTERN_MIRROR_UPDOWN)
	{
		if (ODD(j))
		{
			NSAffineTransform *aff = [NSAffineTransform transformWithTranslateXBy:destRect.size.width yBy:destRect.size.height];
			[aff prependTransform:[NSAffineTransform transformWithScaleXBy:-1 yBy:-1]];
			return aff;
		}
	}
	else if (self.mode == ACSD_PATTERN_MIRROR_UPSIDE)
	{
		if (ODD(i))
		{
			NSAffineTransform *aff = [NSAffineTransform transformWithTranslateXBy:0 yBy:destRect.size.height];
			[aff prependTransform:[NSAffineTransform transformWithScaleXBy:1 yBy:-1]];
			return aff;
		}
	}
	else if (self.mode == ACSD_PATTERN_MIRROR_UPSIDE_LEFTRIGHT)
	{
		if (ODD(i))
		{
			NSAffineTransform *aff = [NSAffineTransform transformWithTranslateXBy:destRect.size.width yBy:destRect.size.height];
			[aff prependTransform:[NSAffineTransform transformWithScaleXBy:-1 yBy:-1]];
			return aff;
		}
	}
	else if (self.mode == ACSD_PATTERN_DOUBLE_MIRROR)
	{
		if (EVEN(i))	//ODD(j)
		{
			NSAffineTransform *aff = [NSAffineTransform transformWithTranslateXBy:destRect.size.width yBy:0];
			[aff prependTransform:[NSAffineTransform transformWithScaleXBy:-1 yBy:1]];
			return aff;
		}
		else			//(ODD(i)
		{
			if (ODD(j))
			{
				NSAffineTransform *aff = [NSAffineTransform transformWithTranslateXBy:destRect.size.width yBy:destRect.size.height];
				[aff prependTransform:[NSAffineTransform transformWithScaleXBy:-1 yBy:-1]];
				return aff;
			}
			else
			{
				NSAffineTransform *aff = [NSAffineTransform transformWithTranslateXBy:0 yBy:destRect.size.height];
				[aff prependTransform:[NSAffineTransform transformWithScaleXBy:1 yBy:-1]];
				return aff;
			}
		}
	}
	else if (self.mode == ACSD_PATTERN_ROTATE)
	{
		float angle = 0;
		if (EVEN(i))	//ODD(j)
			angle = -90;
		else if (EVEN(j))
			angle = 180;
		else
			angle = 90;
		NSAffineTransform *aff = [NSAffineTransform transformWithTranslateXBy:destRect.size.width/2 yBy:destRect.size.height/2];
		[aff prependTransform:[NSAffineTransform transformWithRotationByDegrees:angle]];
		[aff prependTransform:[NSAffineTransform transformWithTranslateXBy:-destRect.size.width/2 yBy:-destRect.size.height/2]];
		return aff;
	}
	return [NSAffineTransform transform];
}

-(NSAffineTransform*)transformWithOffsetForI:(int)i j:(int)j destRect:(NSRect)destRect
{
	NSAffineTransform *aff = [self transformForI:i j:j destRect:destRect];
	if (self.offsetMode == OFFSET_MODE_X)
	{
		if (self.offset != 0.0 && ODD(i))
			[aff appendTransform:[NSAffineTransform transformWithTranslateXBy:destRect.size.width * (1.0 + self.spacing) * self.offset yBy:0]];
	}
	else if (self.offsetMode == OFFSET_MODE_Y)
	{
		if (self.offset != 0.0 && ODD(j))
			[aff appendTransform:[NSAffineTransform transformWithTranslateXBy:0 yBy:destRect.size.height * (1.0 + self.spacing) * self.offset]];
	}
	return aff;
}

-(void)fillPath:(NSBezierPath*)path
{
	[NSGraphicsContext saveGraphicsState];
	[path addClip];
	NSRect pathBounds = [path bounds];
	if (self.rotation != 0)
	{
		NSAffineTransform *afff = [NSAffineTransform transformWithRotationByDegrees:self.rotation];
		[afff concat];
		afff = [NSAffineTransform transformWithRotationByDegrees:-self.rotation];
		path = [afff transformBezierPath:path];
		pathBounds = [path bounds];
	}
	if (self.backgroundColour)
	{
		[self.backgroundColour set];
		[NSBezierPath fillRect:pathBounds];
	}
	NSRect graphicBounds = [self patternBounds];
	float patternWidth = graphicBounds.size.width;
	float patternHeight = graphicBounds.size.height;
	float scaledPatternWidth = patternWidth * self.scale;
	float scaledPatternHeight = patternHeight * self.scale;
	float xIncrement = scaledPatternWidth * (1.0 + self.spacing);
	float yIncrement = scaledPatternHeight * (1.0 + self.spacing);
	NSRect destRect = NSZeroRect;
	destRect.size.width = scaledPatternWidth;
	destRect.size.height = scaledPatternHeight;
	if (self.alpha < 1.0)
	{
		CGContextRef currentContext = (CGContextRef)[[NSGraphicsContext currentContext] graphicsPort];
		CGContextSetAlpha(currentContext,self.alpha);
	}
    float ox = pathBounds.origin.x + _patternOrigin.x * pathBounds.size.width;
    float oy = pathBounds.origin.y + (1.0 - _patternOrigin.y) * pathBounds.size.height;
    while (ox > pathBounds.origin.x)
        ox -= xIncrement;
    while (oy > pathBounds.origin.y)
        oy -= yIncrement;
    for (destRect.origin.y = oy;destRect.origin.y < NSMaxY(pathBounds);destRect.origin.y += yIncrement)
	{
        for (destRect.origin.x = ox;destRect.origin.x < NSMaxX(pathBounds);destRect.origin.x += xIncrement)
		{
			[NSGraphicsContext saveGraphicsState];
			[[NSAffineTransform transformWithTranslateXBy:destRect.origin.x 
													  yBy:destRect.origin.y]concat];
			//[[self transformWithOffsetForI:i j:j destRect:destRect]concat];
			if (self.clip)
				[[NSBezierPath bezierPathWithRect:NSMakeRect(0.0,0.0,destRect.size.width,destRect.size.height)]addClip];
			[[NSAffineTransform transformWithScaleBy:self.scale]concat];
			[[NSAffineTransform transformWithTranslateXBy:pdfOffset.x - graphicBounds.origin.x 
													  yBy:pdfOffset.y - graphicBounds.origin.y]concat];
			[pdfImageRep draw];
			[NSGraphicsContext restoreGraphicsState];
		}
	}
	[NSGraphicsContext restoreGraphicsState];
}

-(void)fillPath:(NSBezierPath*)path attributes:(NSDictionary*)attributes
{
	[self fillPath:path];
}

-(void)buildPDFData
{
	if (self.graphic)
		[self.graphic buildPDFData];
}

-(void)freePDFData
{
	if (self.graphic)
		[self.graphic freePDFData];
}

-(NSString*)svgName:(ACSDrawDocument*)doc
{
    NSUInteger i = [[doc fills]indexOfObjectIdenticalTo:self];
    return [NSString stringWithFormat:@"Pattern%ld",i];
}

-(NSString*)graphicXMLForEvent:(NSMutableDictionary*)options
{
    NSMutableString *graphicString = [NSMutableString stringWithCapacity:100];
    NSArray *allPatterns = options[@"allpatterns"];
    NSString *xlink = nil;
    NSInteger idx = [allPatterns indexOfObjectIdenticalTo:self];
    for (NSInteger i = 0;i < idx;i++)
    {
        ACSDPattern *other = allPatterns[i];
        if ([other.graphic isSameAs:self.graphic] && other.tempName)
        {
            xlink = other.tempName;
            break;
        }
    }
    
    NSString *name = [self svgName:options[@"document"]];
    self.tempName = name;
    NSRect graphicBounds = [self patternBounds];
    float patternWidth = graphicBounds.size.width;
    float patternHeight = graphicBounds.size.height;
    float scaledPatternWidth = patternWidth * self.scale;
    float scaledPatternHeight = patternHeight * self.scale;
    float xIncrement = scaledPatternWidth * (1.0 + self.spacing);
    float yIncrement = scaledPatternHeight * (1.0 + self.spacing);

    [graphicString appendString:@"<pattern"];
    if (xlink)
        [graphicString appendFormat:@" xlink:href=\"#%@\"",xlink];
    [graphicString appendFormat:@" id=\"%@\" patternUnits=\"userSpaceOnUse\" x=\"0\" y=\"0\" width=\"%0.03g\" height=\"%0.03g\"",name,xIncrement,yIncrement];
    if (!self.clip)
        [graphicString appendString:@" overflow=\"visible\""];
    if (self.rotation == 0)
    {
        if (xlink)
            [graphicString appendString:@" patternTransform=\"\""];
    }
    else
        [graphicString appendFormat:@" patternTransform=\"rotate(%g)\"",self.rotation];
    [graphicString appendString:@">\n"];
    if (xlink == nil)
    {
        if (self.backgroundColour && [self.backgroundColour alphaComponent] > 0.0)
        {
            [graphicString appendFormat:@"\t<rect x=\"-1\" y=\"-1\" width=\"%0.03g\" height=\"%0.03g\" fill=\"%@\"/>\n",xIncrement+2,yIncrement+2,string_from_nscolor([self backgroundColour])];
        }
        //[graphicString appendFormat:@"\t<group transform=\"translate(%g,%g)\">\n",-graphicBounds.origin.x,-graphicBounds.origin.y];
        [graphicString appendFormat:@"\t<group scalex=\"%g\" scaley=\"%g\">\n",self.scale,self.scale];
        [graphicString appendString:[self.graphic graphicXMLForEvent:options]];
        [graphicString appendString:@"\t</group>\n"];
    }
    [graphicString appendString:@"</pattern>\n"];
    return graphicString;
}

#define svgShouldUseBBUnits YES

-(void)writeSVGPatternDef:(SVGWriter*)svgWriter allPatterns:(NSArray*)allPatterns bounds:(NSRect)objectBounds name:(NSString*)pname
{
    NSString *xlink = nil;
    for (NSDictionary *d in allPatterns)
    {
        ACSDPattern *other = d[@"pattern"];
        if (other == self)
        {
            NSString *othername = d[@"name"];
            if (othername != pname)
                xlink = othername;
            break;
        }
    }
    
    NSString *name = pname;
    self.tempName = name;
    NSRect patBounds = [self patternBounds];
    if (svgWriter.shouldInvertSVGCoords)
        patBounds = [svgWriter invertRect:patBounds];
    float patternWidth = patBounds.size.width;
    float patternHeight = patBounds.size.height;
    float xIncrement = patternWidth * (1.0 + self.spacing);
    float yIncrement = patternHeight * (1.0 + self.spacing);

    [[svgWriter defs]appendFormat:@"\t<pattern id=\"%@\" ",name];
    
    float cx,cy;
    if (svgShouldUseBBUnits)
    {
        cx = _patternOrigin.x;
        cy = _patternOrigin.y;
        xIncrement = xIncrement  * _scale / objectBounds.size.width;
        yIncrement = yIncrement * _scale / objectBounds.size.height;
    }
    else
    {
        cx = NSMidX(objectBounds) / self.scale;
        cy = NSMidY(objectBounds) / self.scale;

    }
    if (xlink)
    {
        [[svgWriter defs]appendFormat:@" xlink:href=\"#%@\" ",xlink];
        [[svgWriter defs]appendFormat:@"x=\"%g\" y=\"%g\"",cx,cy];
    }
    else
    {
        NSString *coordType=@"userSpaceOnUse";
        if (svgShouldUseBBUnits)
            coordType = @"objectBoundingBox";
        [[svgWriter defs]appendFormat:@"patternUnits=\"%@\" x=\"%g\" y=\"%g\" width=\"%0.03g\" height=\"%0.03g\"",coordType, cx,cy,xIncrement,yIncrement];
        [[svgWriter defs]appendFormat:@" viewBox=\"%g %g %g %g\"",patBounds.origin.x,patBounds.origin.y,patBounds.size.width,patBounds.size.height];
        if (!self.clip)
            [[svgWriter defs]appendString:@" overflow=\"visible\""];
        NSMutableString *transString = [NSMutableString string];
        if (self.rotation != 0.0)
            [transString appendFormat:@"rotate(%g)",self.rotation];
        //if (self.scale != 1.0)
            //[transString appendFormat:@" scale(%g)",self.scale];
        if ([transString length] > 0)
            [[svgWriter defs]appendFormat:@" patternTransform=\"%@\"",transString];
    }
    [[svgWriter defs]appendString:@">\n"];
    if (xlink == nil)
    {
        [svgWriter saveContents];
        [svgWriter indentDef];
        [self.graphic writeSVGData:svgWriter];
        [svgWriter outdentDef];
        [[svgWriter defs]appendString:[svgWriter contents]];
        [svgWriter restoreContents];
    }
    [[svgWriter defs]appendString:@"\t</pattern>\n"];
}

-(void)writeSVGPatternDef:(SVGWriter*)svgWriter allPatterns:(NSArray<ACSDPattern*>*)allPatterns
{
	NSString *xlink = nil;
	NSInteger idx = [allPatterns indexOfObjectIdenticalTo:self];
	for (NSInteger i = 0;i < idx;i++)
	{
		ACSDPattern *other = allPatterns[i];
		if ([other.graphic isSameAs:self.graphic] && other.tempName)
		{
			xlink = other.tempName;
			break;
		}
	}
	
    NSString *name = [self svgName:[svgWriter document]];
	self.tempName = name;
    NSRect graphicBounds = [self patternBounds];
    float patternWidth = graphicBounds.size.width;
    float patternHeight = graphicBounds.size.height;
    //float scaledPatternWidth = patternWidth * self.scale;
    //float scaledPatternHeight = patternHeight * self.scale;
    //float xIncrement = scaledPatternWidth * (1.0 + self.spacing);
    //float yIncrement = scaledPatternHeight * (1.0 + self.spacing);
    float xIncrement = patternWidth * (1.0 + self.spacing);
    float yIncrement = patternHeight * (1.0 + self.spacing);

	[[svgWriter defs]appendString:@"<pattern"];
	if (xlink)
		[[svgWriter defs]appendFormat:@" xlink:href=\"#%@\"",xlink];
    [[svgWriter defs]appendFormat:@" id=\"%@\" patternUnits=\"userSpaceOnUse\" x=\"0\" y=\"0\" width=\"%0.03g\" height=\"%0.03g\"",name,xIncrement,yIncrement];
    [[svgWriter defs]appendFormat:@" viewBox=\"%g %g %g %g\"",graphicBounds.origin.x,graphicBounds.origin.y,graphicBounds.size.width,graphicBounds.size.height];

	if (!self.clip)
		[[svgWriter defs]appendString:@" overflow=\"visible\""];
    NSMutableString *transString = [NSMutableString string];
    if (self.rotation != 0.0)
        [transString appendFormat:@"rotate(%g)",self.rotation];
    if (self.scale != 1.0)
        [transString appendFormat:@" scale(%g)",self.scale];
    if ([transString length] > 0)
        [[svgWriter defs]appendFormat:@" patternTransform=\"%@\"",transString];
	else if (xlink)
        [[svgWriter defs]appendString:@" patternTransform=\"\""];
	[[svgWriter defs]appendString:@">\n"];
	if (xlink == nil)
	{
		if (self.backgroundColour && [self.backgroundColour alphaComponent] > 0.0)
		{
			[[svgWriter defs] appendFormat:@"\t<rect x=\"%0.03g\" y=\"%0.03g\" width=\"%0.03g\" height=\"%0.03g\" fill=\"%@\"/>\n",graphicBounds.origin.x,graphicBounds.origin.y,xIncrement,yIncrement,string_from_nscolor([self backgroundColour])];
		}
		//[[svgWriter defs] appendFormat:@"\t<g transform=\"translate(%g,%g)\">\n",-graphicBounds.origin.x,-graphicBounds.origin.y];
		[svgWriter saveContents];
		[svgWriter indentDef];
		[self.graphic writeSVGData:svgWriter];
		[svgWriter outdentDef];
		[[svgWriter defs]appendString:[svgWriter contents]];
		[svgWriter restoreContents];
		//[[svgWriter defs]appendString:@"\t</g>"];
	}
    [[svgWriter defs]appendString:@"\t</pattern>\n"];
}

-(void)writeSVGData:(SVGWriter*)svgWriter
{
    //NSString *name = [self svgName:[svgWriter document]];
    //[[svgWriter contents]appendFormat:@"fill=\"url(#%@)\" ",name];
    [[svgWriter contents]appendFormat:@"fill=\"url(#%@)\" ",self.tempName];
}


-(BOOL)isSameAs:(id)obj
{
	if (![obj isMemberOfClass:[self class]])
		return NO;
	ACSDPattern *pat = obj;
	if (![super isSameAs:pat])
		return NO;
	if (![[pat graphic] isSameAs:self.graphic])
		return NO;
	if ([pat scale] != self.scale)
		return NO;
	if ([pat spacing] != self.spacing)
		return NO;
	if ([pat offset] != self.offset)
		return NO;
	if ([pat offsetMode] != self.offsetMode)
		return NO;
	if ([pat alpha] != self.alpha)
		return NO;
	if ([pat clip] != self.clip)
		return NO;
	if ([pat rotation] != self.rotation)
		return NO;
	if (NSEqualRects([pat patternBounds],self.patternBounds))
		return NO;
	return YES;
}

-(NSSet*)usedShadows
{
	if (self.graphic)
		return [self.graphic usedShadows];
	return [NSSet set];
}

-(NSSet*)usedStrokes
{
	if (self.graphic)
		return [self.graphic usedStrokes];
	return [NSSet set];
}

-(NSSet*)usedFills
{
	if (self.graphic)
		return [self.graphic usedFills];
	return [NSSet set];
}

-(FlippableView*)setCurrentDrawingDestination:(FlippableView*)dest
{
	if (self.graphic)
	{
		return [self.graphic setCurrentDrawingDestination:dest];
	}
	return nil;
}

-(void)setPdfImageRep:(NSPDFImageRep*)pir
{
	if (pdfImageRep == pir)
		return;
	//if (pdfImageRep)
		//[pdfImageRep release];
	pdfImageRep = pir;
	//if (pdfImageRep)
		//[pdfImageRep retain];
}

-(void)setPdfOffset:(NSPoint)p
{
	pdfOffset = p;
}

-(NSPDFImageRep*)pdfImageRep
{
	return pdfImageRep;
}

-(NSPoint)pdfOffset
{
	return pdfOffset;
}

@end
