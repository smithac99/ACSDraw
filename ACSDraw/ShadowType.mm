//
//  ShadowType.mm
//  ACSDraw
//
//  Created by Alan Smith on Fri Feb 15 2002.
//  Copyright (c) 2001 __MyCompanyName__. All rights reserved.
//

#import "ShadowType.h"
#import "ACSDrawDocument.h"
#import "SVGWriter.h"
#import "GraphicView.h"


@implementation ShadowType


+ (NSMutableArray*)initialShadows
   {
	NSMutableArray* arr = [NSMutableArray arrayWithCapacity:10];
	NSColor *col5 = [NSColor colorWithCalibratedWhite:0.0 alpha:0.5];
	NSColor *col7 = [NSColor colorWithCalibratedWhite:0.0 alpha:0.7];
	NSColor *col8 = [NSColor colorWithCalibratedWhite:0.0 alpha:0.8];
	[arr addObject:[[[ShadowType alloc]init]autorelease]];
	[arr addObject:[[[ShadowType alloc]initWithBlurRadius:3 xOffset:5 yOffset:-5 colour:[NSColor blackColor]]autorelease]];
	[arr addObject:[[[ShadowType alloc]initWithBlurRadius:3 xOffset:10 yOffset:-10 colour:col8]autorelease]];
	[arr addObject:[[[ShadowType alloc]initWithBlurRadius:3 xOffset:15 yOffset:-15 colour:col8]autorelease]];
	[arr addObject:[[[ShadowType alloc]initWithBlurRadius:3 xOffset:15 yOffset:15 colour:col8]autorelease]];
	[arr addObject:[[[ShadowType alloc]initWithBlurRadius:5 xOffset:7 yOffset:-7 colour:col8]autorelease]];
	[arr addObject:[[[ShadowType alloc]initWithBlurRadius:5 xOffset:25 yOffset:-25 colour:col5]autorelease]];
	[arr addObject:[[[ShadowType alloc]initWithBlurRadius:7 xOffset:17 yOffset:17 colour:col5]autorelease]];
	[arr addObject:[[[ShadowType alloc]initWithBlurRadius:9 xOffset:15 yOffset:15 colour:col7]autorelease]];
	[arr addObject:[[[ShadowType alloc]initWithBlurRadius:7 xOffset:-10 yOffset:-10 colour:[NSColor redColor]]autorelease]];
    return arr;
   }

-(id)initWithBlurRadius:(float)bR xOffset:(float)x yOffset:(float)y colour:(NSColor*)col
   {
	if (self = [super init])
	   {
		itsShadow = [[NSShadow alloc]init];
		[itsShadow setShadowOffset:NSMakeSize(x,y)];
		[itsShadow setShadowBlurRadius:bR];
		[itsShadow setShadowColor:col];
	   }
	return self;
   }

-(id)init
   {
	if (self = [super init])
	   {
		itsShadow = nil;
	   }
	return self;
   }

- (id)copyWithZone:(NSZone *)zone 
   {
    id obj;
	if (itsShadow)
		obj =  [[[self class] allocWithZone:zone] initWithBlurRadius:[self blurRadius] xOffset:[self xOffset] yOffset:[self yOffset] colour:[self colour]];
	else
		obj =  [[[self class] allocWithZone:zone]init];
	return obj;
   }

-(void)dealloc
   {
	if (itsShadow)
		[itsShadow release];
	if (scaledShadow)
		[scaledShadow release];
	[super dealloc];
   }

- (void) encodeWithCoder:(NSCoder*)coder
   {
	BOOL shadowExists = (itsShadow != nil);
	[super encodeWithCoder:coder];
	[coder encodeBool:shadowExists forKey:@"ShadowType_shadowExists"];
	if (shadowExists)
	   {
		[coder encodeFloat:[self xOffset] forKey:@"ShadowType_xOffset"];
		[coder encodeFloat:[self yOffset] forKey:@"ShadowType_yOffset"];
		[coder encodeFloat:[self blurRadius] forKey:@"ShadowType_blurRadius"];
		[coder encodeObject:[self colour] forKey:@"ShadowType_colour"];
	   }
   }

- (id) initWithCoder:(NSCoder*)coder
   {
	self = [super initWithCoder:coder];
//	self = [super init];
	BOOL shadowExists = [coder decodeBoolForKey:@"ShadowType_shadowExists"];
	if (shadowExists)
	   {
		itsShadow = [[NSShadow alloc]init];
		[itsShadow setShadowOffset:NSMakeSize([coder decodeFloatForKey:@"ShadowType_xOffset"],
			[coder decodeFloatForKey:@"ShadowType_yOffset"])];
		[itsShadow setShadowBlurRadius:[coder decodeFloatForKey:@"ShadowType_blurRadius"]];
		[itsShadow setShadowColor:[coder decodeObjectForKey:@"ShadowType_colour"]];
	   }
//	itsShadow = [[coder decodeObjectForKey:@"ShadowType_itsShadow"]retain];
	return self;
   }

-(float)blurRadius
   {
	if (itsShadow)
		return [itsShadow shadowBlurRadius];
	return 0.0;
   }

-(float)xOffset
   {
	if (itsShadow)
		return [itsShadow shadowOffset].width;
	return 0.0;
   }

-(float)yOffset
   {
	if (itsShadow)
		return [itsShadow shadowOffset].height;
	return 0.0;
   }

-(NSColor*)colour
   {
	return [itsShadow shadowColor];
   }

-(NSShadow*)itsShadow
   {
	return itsShadow;
   }

-(NSShadow*)shadowWithScale:(float) scale
   {
	if (itsShadow == nil || scale == 1.0)
		return itsShadow;
	if (!scaledShadow)
		scaledShadow = [[NSShadow alloc]init];
	NSSize sz = [itsShadow shadowOffset];
	sz.width = sz.width * scale;
	sz.height = sz.height * scale;
	[scaledShadow setShadowOffset:sz];
	[scaledShadow setShadowBlurRadius:[itsShadow shadowBlurRadius] * scale];
	[scaledShadow setShadowColor:[itsShadow shadowColor]];
	return scaledShadow;
   }

-(void)setBlurRadius:(float)br
{
    if (br == [itsShadow shadowBlurRadius])
        return;
    [self invalidateGraphicsRefreshCache:NO];
    [itsShadow setShadowBlurRadius:br];
    [self invalidateGraphicsRefreshCache:NO];
}

-(void)setOffset:(NSSize)sz
{
    if (NSEqualSizes(sz,[itsShadow shadowOffset]))
        return;
    [self invalidateGraphicsRefreshCache:NO];
    [itsShadow setShadowOffset:sz];
    [self invalidateGraphicsRefreshCache:NO];
}

-(void)setColour:(NSColor*)col
{
    if ([itsShadow shadowColor] == col)
        return;
    [self invalidateGraphicsRefreshCache:NO];
    [itsShadow setShadowColor:col];
    [self invalidateGraphicsRefreshCache:NO];
}

-(NSString*)svgName:(ACSDrawDocument*)doc
{
    NSUInteger i = [[doc shadows]indexOfObjectIdenticalTo:self];
    return [NSString stringWithFormat:@"Shadow%ld",i];
}

-(void)notifyOnADDOrRemove
{
    [self postNotify:ACSDRefreshShadowsNotification object:self];
}

-(void)writeSVGShadowDef:(SVGWriter*)svgWriter
   {
	NSString *name = [self svgName:[svgWriter document]];
	NSSize sz = [[svgWriter document]documentSize];
	[[svgWriter defs]appendFormat:@"<filter id=\"%@\" filterUnits=\"userSpaceOnUse\" x=\"0\" y=\"0\" width=\"%g\" height=\"%g\">\n",
		name,sz.width,sz.height];
	[[svgWriter defs]appendString:@"\t<feComponentTransfer in=\"SourceAlpha\" result=\"faded\">\n"];
	[[svgWriter defs]appendFormat:@"\t<feFuncA type=\"linear\" slope=\"%g\" intercept=\"0.0\"/>\n",[[self colour]alphaComponent]];
	[[svgWriter defs]appendString:@"\t</feComponentTransfer>\n"];
	[[svgWriter defs]appendFormat:@"\t<feGaussianBlur in=\"faded\" stdDeviation=\"%g\" result=\"blur\"/>\n",[self blurRadius]];
	[[svgWriter defs]appendFormat:@"\t<feOffset in=\"blur\" dx=\"%g\" dy=\"%g\" result=\"offsetBlur\"/>\n",[self xOffset],[self yOffset]];
	[[svgWriter defs]appendString:@"\t<feMerge>\n"];
	[[svgWriter defs]appendString:@"\t\t<feMergeNode in=\"offsetBlur\"/>\n"];
	[[svgWriter defs]appendString:@"\t\t<feMergeNode in=\"SourceGraphic\"/>\n"];
	[[svgWriter defs]appendString:@"\t</feMerge>\n"];
	[[svgWriter defs]appendString:@"</filter>\n"];
   }

-(void)writeSVGData:(SVGWriter*)svgWriter
   {
	if (itsShadow == nil)
		return;
	NSString *name = [self svgName:[svgWriter document]];
//	[self writeSVGShadowDef:svgWriter];
	[[svgWriter contents]appendFormat:@"filter=\"url(#%@)\" ",name];
   }

-(NSString*)canvasData:(CanvasWriter*)canvasWriter
{
	if (itsShadow == nil)
		return @"";
	return [NSString stringWithFormat:@"ctx.shadowOffsetX=\"%g\";ctx.shadowOffsetY=\"%g\";ctx.shadowBlur=\"%g\";ctx.shadowColor=\"%@\";\n",
		[self xOffset],-[self yOffset],[self blurRadius],rgba_from_nscolor([self colour])];
}

-(BOOL)isSameAs:(id)obj
   {
	if (![super isSameAs:obj])
		return NO;
	if (![itsShadow isEqual:[obj itsShadow]])
		return NO;
	return YES;
   }

@end
