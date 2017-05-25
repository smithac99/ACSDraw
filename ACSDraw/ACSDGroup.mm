//
//  ACSDGroup.mm
//  ACSDraw
//
//  Created by alan on Mon Feb 23 2004.
//  Copyright (c) 2004 __MyCompanyName__. All rights reserved.
//

#import "ACSDGroup.h"
#import "ShadowType.h"
#import "SVGWriter.h"
#import "ObjectPDFData.h"
#import "ArrayAdditions.h"
#import "ACSDText.h"
#import "ACSDGroup.h"
#import "CanvasWriter.h"

@implementation ACSDGroup

+ (NSString*)graphicTypeName
   {
	return @"Group";
   }

+(NSRect)rectForObjects:(NSArray*)gArray
   {
    NSRect r = NSZeroRect;
	NSEnumerator *objEnum = [gArray objectEnumerator];
	ACSDGraphic *curGraphic;
    while ((curGraphic = [objEnum nextObject]) != nil)
		r = NSUnionRect(r,[curGraphic transformedBounds]);
	return r;
   }
   
+(void)adjustGraphicsBoundsForArray:(NSArray*)graphics offset:(NSPoint)offset
   {
	offset.x = -offset.x;
	offset.y = -offset.y;
	NSEnumerator *objEnum = [graphics objectEnumerator];
	ACSDGraphic *curGraphic;
    while ((curGraphic = [objEnum nextObject]) != nil)
		[curGraphic uMoveBy:offset];
   }

-(id)initWithName:(NSString*)n fill:(ACSDFill*)f stroke:(ACSDStroke*)str rect:(NSRect)b layer:(ACSDLayer*)l
   {
	self = [super initWithName:n fill:f stroke:str rect:b layer:l];
	return self;
   }
   
-(id)initWithName:(NSString*)n graphics:(NSArray*)gArray layer:(ACSDLayer*)l
   {
    NSRect r = [ACSDGroup rectForObjects:gArray];
	if (self = [self initWithName:n fill:nil stroke:nil rect:r layer:l])
	   {
		[self setGraphics:gArray];
		[graphics makeObjectsPerformSelector:@selector(setLayer:) withObject:l];
		[graphics makeObjectsPerformSelector:@selector(postUndelete)];
		[graphics makeObjectsPerformSelector:@selector(freeCache)];
	   }
	return self;
   }

- (id)copyWithZone:(NSZone *)zone
{
    ACSDGroup *obj = [super copyWithZone:zone];
    [obj setGraphics:[[graphics copiedObjects]mutableCopy]];
    [obj setDisplayBoundsValid:NO];
    obj.colourMode = self.colourMode;
    return obj;
}

-(void)setLayer:(ACSDLayer *)l
{
    [super setLayer:l];
    [graphics makeObjectsPerformSelector:@selector(setLayer:) withObject:l];
}

- (void) encodeWithCoder:(NSCoder*)coder
{
    [super encodeWithCoder:coder];
    [coder encodeObject:graphics forKey:@"ACSDGroup_graphics"];
    [coder encodeInt:self.colourMode forKey:@"ACSDGroup_colourmode"];
}

- (id) initWithCoder:(NSCoder*)coder
{
    self = [super initWithCoder:coder];
    graphics = [coder decodeObjectForKey:@"ACSDGroup_graphics"];
    self.colourMode = [coder decodeIntForKey:@"ACSDGroup_colourmode"];
    [graphics makeObjectsPerformSelector:@selector(setParent:) withObject:self];
    return self;
}

-(void)setGraphics:(NSArray*)g
   {
	if (g == graphics)
		return;
	graphics = [g mutableCopy];
	[graphics makeObjectsPerformSelector:@selector(setParent:) withObject:self];
	[graphics makeObjectsPerformSelector:@selector(setLayer:) withObject:layer];
	[graphics makeObjectsPerformSelector:@selector(postUndelete)];
	[graphics makeObjectsPerformSelector:@selector(freeCache)];
    bounds = [ACSDGroup rectForObjects:graphics];
	[self computeHandlePoints];
   }

-(NSArray*)removeGraphics
   {
	[graphics makeObjectsPerformSelector:@selector(setParent:) withObject:nil];
	NSArray *arr = graphics;
	[self setGraphics:[NSArray array]];
	return arr;
   }

-(void)fixTextBoxLinks
   {
	for (ACSDGraphic *g in graphics)
	   {
		if ([g isKindOfClass:[ACSDText class]])
		{
			if ([(ACSDText*)g previousText] == nil && [(ACSDText*)g nextText] != nil)
				[ACSDText sortOutLinkedTextGraphics:(ACSDText*)g];
		}
		else if ([g isKindOfClass:[ACSDGroup class]])
			[(ACSDGroup*)g fixTextBoxLinks];
	   }
   }

-(void)preDelete
{
	[super preDelete];
	[graphics makeObjectsPerformSelector:@selector(preDelete)];
}

-(void)permanentScale:(float)sc transform:(NSAffineTransform*)t
{
	for (ACSDGraphic *g in graphics)
		[g permanentScale:sc transform:t];
	[self setGraphicBoundsTo:[ACSDGroup rectForObjects:graphics] from:[self bounds]];
}

-(void)deRegisterWithDocument:(ACSDrawDocument*)doc
   {
	[doc deRegisterObject:self];
	[graphics makeObjectsPerformSelector:@selector(deRegisterWithDocument:)withObject:doc];
   }

-(void)registerWithDocument:(ACSDrawDocument*)doc
   {
	[doc registerObject:self];
	[graphics makeObjectsPerformSelector:@selector(registerWithDocument:)withObject:doc];
   }

-(void)setAllFills:(ACSDFill*)f
   {
	[graphics makeObjectsPerformSelector:@selector(setAllFills:) withObject:f];
   }

-(void)drawHighlightRect:(NSRect)r colour:(NSColor*)col hotPoint:(NSPoint)hotPoint modifiers:(NSUInteger)modifiers
   {
	NSEnumerator *objEnum = [graphics objectEnumerator];
	ACSDGraphic *curGraphic;
    while ((curGraphic = [objEnum nextObject]) != nil)
		[curGraphic drawHighlightRect:r colour:col hotPoint:hotPoint modifiers:modifiers];
   }

- (void)moveBy:(NSPoint)vector
   {
	if (vector.x == 0.0 && vector.y == 0.0)
		return;
	NSEnumerator *objEnum = [graphics objectEnumerator];
	ACSDGraphic *curGraphic;
    while ((curGraphic = [objEnum nextObject]) != nil)
		[curGraphic moveBy:vector];
	[super moveBy:vector];
   }

-(void)setDeleted:(BOOL)d
  {
	if (d == deleted)
		return;
	NSEnumerator *objEnum = [graphics objectEnumerator];
	ACSDGraphic *curGraphic;
    while ((curGraphic = [objEnum nextObject]) != nil)
		[curGraphic setDeleted:d];
	[super setDeleted:d];
   }

- (BOOL)intersectsWithRect:(NSRect)selectionRect	//used for selecting with rubberband
   {
	NSEnumerator *objEnum = [graphics objectEnumerator];
	ACSDGraphic *curGraphic;
    while ((curGraphic = [objEnum nextObject]) != nil)
		if ([curGraphic intersectsWithRect:selectionRect])
			return YES;
	return NO;
   }

-(BOOL)graphicUsesStroke:(ACSDStroke*)str
   {
	if (str == stroke)
		return YES;
	NSEnumerator *objEnum = [graphics objectEnumerator];
	ACSDGraphic *curGraphic;
    while ((curGraphic = [objEnum nextObject]) != nil)
		if ([curGraphic graphicUsesStroke:str])
			return YES;
	return NO;
   }

- (void)clearReferences
   {
	[super clearReferences];
	[graphics makeObjectsPerformSelector:@selector(clearReferences)];
   }

-(float)paddingRequired
   {
	float padding = 0.0;
	NSEnumerator *objEnum = [graphics objectEnumerator];
	ACSDGraphic *curGraphic;
    while ((curGraphic = [objEnum nextObject]) != nil)
	   {
	    float tp = [curGraphic paddingRequired];
		if (tp > padding)
			padding = tp;
	   }	
	return padding;
   }


-(NSRect)displayBoundsSansShadow
   {
	NSRect r = NSZeroRect;
	NSEnumerator *objEnum = [graphics objectEnumerator];
	ACSDGraphic *curGraphic;
    while ((curGraphic = [objEnum nextObject]) != nil)
		r = NSUnionRect(r,[curGraphic displayBounds]);
	if (transform)
		r = [[transform transformBezierPath:[NSBezierPath bezierPathWithRect:r]]bounds];
	return r;
   }

-(NSRect)viewableBounds
   {
	if (![self isMask])
		return [self displayBounds];
    ACSDGraphic *g = [graphics objectAtIndex:[graphics count]-1];
	NSRect r = [g controlPointBounds];
	if (r.size.width <= 0.0)
		r.size.width = 1.0;
	if (r.size.height <= 0.0)
		r.size.height = 1.0;
	if (shadowType)
	   {
		NSRect s = NSOffsetRect(r,[shadowType xOffset],[shadowType yOffset]);
		float br = [shadowType blurRadius]/* * 3*/;
		s = NSInsetRect(s,-br,-br);
		r = NSUnionRect(r,s);
	   }
	return r;
   }


-(void)adjustGraphicsBoundsOffset:(NSPoint)offset
   {
	[ACSDGroup adjustGraphicsBoundsForArray:graphics offset:offset];
   }

- (NSArray*)originalObjects
   {
	return graphics;
   }

- (NSArray*)graphics
   {
	return graphics;
   }

-(BOOL)canBeMask
   {
	return YES;
   }

-(void)buildPDFData
   {
	if (objectPdfData)
		return;
	objectPdfData = [[ObjectPDFData alloc]initWithObject:self];
   }

- (KnobDescriptor)resizeByMovingKnob:(KnobDescriptor)kd toPoint:(NSPoint)point event:(NSEvent *)theEvent constrain:(BOOL)constrain aroundCentre:(BOOL)aroundCentre
   {
	return kd;
   }

-(CGImageRef)createMaskImage:(NSRect)aRect object:(ACSDGraphic*)g
{
    CGColorSpaceRef colorspace = CGColorSpaceCreateDeviceGray();
    CGContextRef maskContext =
    CGBitmapContextCreate(
                          NULL,
                          aRect.size.width,
                          aRect.size.height,
                          8,
                          aRect.size.width,
                          colorspace,
                          0);
    CGColorSpaceRelease(colorspace);
    
    // Switch to the context for drawing
    NSGraphicsContext *maskGraphicsContext = [NSGraphicsContext graphicsContextWithGraphicsPort:maskContext flipped:NO];
    [NSGraphicsContext saveGraphicsState];
    [NSGraphicsContext setCurrentContext:maskGraphicsContext];
    [[NSGraphicsContext currentContext]saveGraphicsState];
    NSAffineTransform *t = [NSAffineTransform transform];
    [t translateXBy:-aRect.origin.x yBy:-aRect.origin.y];
    [t concat];
    [g draw:aRect inView:nil selected:NO isGuide:NO cacheDrawing:NO options:nil];
    [[NSGraphicsContext currentContext]restoreGraphicsState];
    // Switch back to the window's context
    [NSGraphicsContext restoreGraphicsState];
    CGImageRef alphaMask = CGBitmapContextCreateImage(maskContext);
    return alphaMask;
}

- (void)drawObject:(NSRect)aRect view:(GraphicView*)gView options:(NSMutableDictionary*)options
{
    [NSGraphicsContext saveGraphicsState];
    if (isMask)
	   {
           int ct = (int)[graphics count];
           [[NSGraphicsContext currentContext]saveGraphicsState];
           if (ct > 0)
           {
               ACSDGraphic *clipg = [graphics objectAtIndex:ct - 1];
               //[[clipg clipPath]addClip];
               CGImageRef alphaMask = [self createMaskImage:aRect object:clipg];
               CGContextClipToMask((CGContextRef)[[NSGraphicsContext currentContext]graphicsPort], NSRectToCGRect(aRect), alphaMask);
           }
           for (int i = 0;i < ct - 1;i++)
               [[graphics objectAtIndex:i]draw:aRect inView:nil selected:NO isGuide:NO cacheDrawing:NO options:options];
           [[NSGraphicsContext currentContext]restoreGraphicsState];
       }
    else
	   {
           NSEnumerator *objEnum = [graphics objectEnumerator];
           ACSDGraphic *curGraphic;
           while ((curGraphic = [objEnum nextObject]) != nil)
           {
               [curGraphic setCurrentDrawingDestination:[self currentDrawingDestination]];
               [curGraphic draw:aRect inView:nil selected:NO isGuide:NO cacheDrawing:NO options:options];
           }
       }
    [NSGraphicsContext restoreGraphicsState];
}

-(FlippableView*)setCurrentDrawingDestination:(FlippableView*)dest
   {
	NSEnumerator *objEnum = [graphics objectEnumerator];
	ACSDGraphic *curGraphic;
    while ((curGraphic = [objEnum nextObject]) != nil)
		[curGraphic setCurrentDrawingDestination:dest];
	return [super setCurrentDrawingDestination:dest];
   }


-(NSSet*)usedFills
   {
	NSMutableSet *fillSet = [NSMutableSet setWithCapacity:[graphics count]];
	NSEnumerator *objEnum = [graphics objectEnumerator];
	ACSDGraphic *curGraphic;
    while ((curGraphic = [objEnum nextObject]) != nil)
		[fillSet unionSet:[curGraphic usedFills]];
	return fillSet;
   }

-(NSSet*)usedShadows
   {
	NSMutableSet *shadowSet = [NSMutableSet setWithCapacity:[graphics count]];
	NSEnumerator *objEnum = [graphics objectEnumerator];
	ACSDGraphic *curGraphic;
    while ((curGraphic = [objEnum nextObject]) != nil)
		[shadowSet unionSet:[curGraphic usedShadows]];
	return shadowSet;
   }

-(NSSet*)usedStrokes
   {
	NSMutableSet *strokeSet = [NSMutableSet setWithCapacity:[graphics count]];
	NSEnumerator *objEnum = [graphics objectEnumerator];
	ACSDGraphic *curGraphic;
    while ((curGraphic = [objEnum nextObject]) != nil)
		[strokeSet unionSet:[curGraphic usedStrokes]];
	return strokeSet;
   }

-(NSSet*)subObjects
   {
	NSMutableSet *objSet = [NSMutableSet setWithCapacity:[graphics count]];
	NSEnumerator *objEnum = [graphics objectEnumerator];
	ACSDGraphic *curGraphic;
    while ((curGraphic = [objEnum nextObject]) != nil)
		[objSet unionSet:[curGraphic allTheObjects]];
	return objSet;
   }

-(NSSet*)allTheObjects
   {
	NSMutableSet *objSet = [NSMutableSet setWithSet:[self subObjects]];
	[objSet addObject:self];
	return objSet;
   }

- (BOOL)hasNonTransparentFillOrStroke
   {
	return YES;
   }

-(void)writeSVGData:(SVGWriter*)svgWriter
   {
//	[[svgWriter contents]appendFormat:@"%@<g id=\"%@\" transform=\"translate(%g,%g)\">\n",[svgWriter indentString],name,bounds.origin.x,bounds.origin.y];
	[[svgWriter contents]appendFormat:@"%@<g id=\"%@\" %@",[svgWriter indentString],self.name,[self svgTransform]];
    if (self.hidden)
        [[svgWriter contents] appendString:@"visibility=\"hidden\" "];
	if (shadowType)
		[shadowType writeSVGData:svgWriter];
	[[svgWriter contents]appendString:@">\n"];
	[svgWriter indentDef];
	if (isMask)
	   {
		NSString *saveName = [svgWriter clipPathName];
		[svgWriter setClipPathName:[NSString stringWithFormat:@"clip%ld",(NSUInteger)self]];
		[[svgWriter contents]appendFormat:@"%@<clipPath id=\"%@\">\n",[svgWriter indentString],[svgWriter clipPathName]];
		NSBezierPath *clipPath = [NSBezierPath bezierPath];
		int ct = (int)[graphics count];
		for (int i = ct - 1;i > 0;i--)
			[clipPath appendBezierPath:[[graphics objectAtIndex:i]clipPath]];
		[svgWriter indentDef];
		[[svgWriter contents]appendFormat:@"%@<path d=\"%@\" />\n",[svgWriter indentString],string_from_path(clipPath)];
		[svgWriter outdentDef];
		[[svgWriter contents]appendFormat:@"%@</clipPath>\n",[svgWriter indentString]];
		if (ct > 0)
			[[graphics objectAtIndex:0]writeSVGData:svgWriter];
		[svgWriter setClipPathName:saveName];
	   }
	else
	   {
		NSEnumerator *objEnum = [graphics objectEnumerator];
		ACSDGraphic *curGraphic;
		while ((curGraphic = [objEnum nextObject]) != nil)
			[curGraphic writeSVGData:svgWriter];
	   }
	[svgWriter outdentDef];
	[[svgWriter contents]appendFormat:@"%@</g>\n",[svgWriter indentString]];
   }

-(BOOL)isOrContainsImage
   {
	return [graphics orMakeObjectsPerformSelector:@selector(isOrContainsImage)];
   }

-(void)writeCanvasData:(CanvasWriter*)canvasWriter
{
	if (transform)
	{
		[[canvasWriter contents]appendString:@"ctx.save();\n"];
		NSAffineTransformStruct t = [transform transformStruct];
		[[canvasWriter contents]appendFormat:@"ctx.transform(%g,%g,%g,%g,%g,%g);\n",t.m11, t.m12, t.m21, t.m22, t.tX, t.tY];
	}
	[graphics makeObjectsPerformSelector:@selector(writeCanvasData:) withObject:canvasWriter];
	if (transform)
		[[canvasWriter contents]appendString:@"ctx.restore();\n"];
}

-(NSString*)graphicXMLForEvent:(NSMutableDictionary*)options
{
    NSMutableString *gString = [NSMutableString stringWithCapacity:200];
    NSString *indent = [options objectForKey:xmlIndent];
    [gString appendFormat:@"%@<group id=\"%@\" %@>\n",indent,self.name,[self graphicAttributesXML:options]];
    [options setObject:[indent stringByAppendingString:@"\t"] forKey:xmlIndent];
    for (int i = 0;i < [graphics count];i++)
        [graphics[i] tempSettings][@"gzidx"] = @(i);
    NSArray *gs = OrderGraphics(graphics);
    for (ACSDGraphic *g in gs)
        [gString appendString:[g graphicXMLForEvent:options]];
    [gString appendFormat:@"%@</group>\n",indent];
    [options setObject:indent forKey:xmlIndent];
    return gString;
}

-(int)zDepth
{
	int tot = 0;
	for (ACSDGraphic *g in graphics)
		tot += [g zDepth];
	return tot;
}

-(BOOL)isSameAs:(id)obj
{
	if (![super isSameAs:obj])
		return NO;
	NSUInteger ct = [graphics count];
	if (ct != [[obj graphics]count])
		return NO;
	for (unsigned i = 0;i < ct;i++)
		if (!([graphics[i] isSameAs:[((ACSDGroup*)obj) graphics][i]]))
			return NO;
	return YES;
}

@end
