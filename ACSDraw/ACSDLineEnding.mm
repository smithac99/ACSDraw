//
//  ACSDLineEnding.mm
//  ACSDraw
//
//  Created by alan on Wed Jan 28 2004.
//  Copyright (c) 2004 __MyCompanyName__. All rights reserved.
//

#import "ACSDLineEnding.h"
#import "ACSDGraphic.h"
#import "GraphicView.h"
#import "SVGWriter.h"
#import "ACSDPath.h"
#import "AffineTransformAdditions.h"
#import "CanvasWriter.h"


@implementation ACSDLineEnding

+ (id)defaultLineEnding
   {
    static ACSDLineEnding *defaultLineEnding = nil;
	if (!defaultLineEnding)
        defaultLineEnding = [[ACSDLineEnding alloc] initWithGraphic:nil scale:0.0 aspect:1.0 offset:0.0];
    return defaultLineEnding;
   }

+ (NSMutableArray*)initialLineEndings
   {
	NSMutableArray* arr = [NSMutableArray arrayWithCapacity:10];
	NSBezierPath *path;
	[arr addObject:[self defaultLineEnding]];
	path = [NSBezierPath bezierPath];
	[path moveToPoint:NSMakePoint(0,-0.5)];
	[path lineToPoint:NSMakePoint(0,0.5)];
	[path lineToPoint:NSMakePoint(1,0)];
	[path closePath];
	ACSDPath *ap = [[ACSDPath alloc]initWithName:@"arr1" fill:[ACSDFill parentFill] stroke:nil rect:NSZeroRect layer:nil
			bezierPath:path];
	for (int i = 0;i < 5;i++)
		[arr addObject:[[ACSDLineEnding alloc]initWithGraphic:ap scale:2.5 aspect:(0.5 + i * 0.5) offset:-0.01]];
	path = [NSBezierPath bezierPath];
	[path moveToPoint:NSMakePoint(-0.5,-0.5)];
	[path lineToPoint:NSMakePoint(0,0)];
	[path lineToPoint:NSMakePoint(-0.5,0.5)];
	[path lineToPoint:NSMakePoint(2,0)];
	[path closePath];
	ap = [[ACSDPath alloc]initWithName:@"arr2" fill:[ACSDFill parentFill] stroke:nil rect:NSZeroRect layer:nil
		bezierPath:path];
	for (int i = 0;i < 4;i++)
		[arr addObject:[[ACSDLineEnding alloc]initWithGraphic:ap scale:2.5 aspect:(0.5 + i * 0.5) offset:-0.01]];
	path = [NSBezierPath bezierPathWithOvalInRect:NSMakeRect(-0.5,-0.5,1.0,1.0)];
	ap = [[ACSDPath alloc]initWithName:@"circlearr" fill:[ACSDFill parentFill] stroke:nil rect:NSZeroRect layer:nil
		bezierPath:path];
	[arr addObject:[[ACSDLineEnding alloc]initWithGraphic:ap scale:2.0 aspect:1.0 offset:0.0]];
    return arr;
   }

+(ACSDLineEnding*)lineEndingWithGraphic:(ACSDGraphic*)g scale:(float)sc aspect:(float)asp offset:(float)of
   {
	ACSDLineEnding *a = [[ACSDLineEnding alloc]initWithGraphic:g scale:sc aspect:asp offset:of];
	return a;
   }

-(id)initWithGraphic:(ACSDGraphic*)g scale:(float)sc aspect:(float)asp offset:(float)off
   {
	if (self = [super init])
	   {
		graphic = g;
		scale = sc;
		aspect = asp;
		offset = off;
		[g setUsesCache:NO];
	   }
	return self;
   }

- (id)copyWithZone:(NSZone *)zone 
   {
    return [[[self class] allocWithZone:zone] initWithGraphic:[self graphic] scale:[self scale] aspect:[self aspect] offset:[self offset]];
   }

- (void) encodeWithCoder:(NSCoder*)coder
   {
	[coder encodeObject:[self graphic] forKey:@"ACSDLineEnding_graphic"];
	[coder encodeFloat:[self scale] forKey:@"ACSDLineEnding_scale"];
	[coder encodeFloat:[self aspect] forKey:@"ACSDLineEnding_aspect"];
	[coder encodeFloat:[self offset] forKey:@"ACSDLineEnding_offset"];
   }

- (id) initWithCoder:(NSCoder*)coder
   {
	self = [super initWithCoder:coder];
	graphic = [coder decodeObjectForKey:@"ACSDLineEnding_graphic"];
	scale = [coder decodeFloatForKey:@"ACSDLineEnding_scale"];
	aspect = [coder decodeFloatForKey:@"ACSDLineEnding_aspect"];
	if (aspect == 0.0)
		aspect = 1.0;
	offset = [coder decodeFloatForKey:@"ACSDLineEnding_offset"];
	if ([graphic fill] == nil)
		[graphic setFill:[ACSDFill parentFill]];
	[graphic setUsesCache:NO];
	return self;
   }

-(ACSDGraphic*)graphic
   {
    return graphic;
   }

-(void)setGraphic:(ACSDGraphic*)g
   {
	if (g == graphic)
		return;
	[self invalidateGraphicsRefreshCache:NO];
	graphic = g;
	[graphic setUsesCache:NO];
	[self invalidateGraphicsRefreshCache:YES];
   }

-(float)scale
   {
    return scale;
   }
   
-(float)aspect
   {
    return aspect;
   }
   
-(float)offset
   {
    return offset;
   }
   
-(void)setScale:(float)s
   {
    if (scale == s)
		return;
	[self invalidateGraphicsRefreshCache:NO];
	scale = s;
	[self invalidateGraphicsRefreshCache:YES];
   }
   
-(void)setAspect:(float)s
   {
    if (aspect == s)
		return;
	[self invalidateGraphicsRefreshCache:NO];
	aspect = s;
	[self invalidateGraphicsRefreshCache:YES];
   }
   
-(void)setOffset:(float)s
   {
    if (offset == s)
		return;
	[self invalidateGraphicsRefreshCache:NO];
	offset = s;
	[self invalidateGraphicsRefreshCache:YES];
   }
   
-(NSBezierPath*)lineEndingPathWidth:(float)w
   {
	NSBezierPath *p = [graphic bezierPath];
	if (!p)
		return nil;
	p = [p copy];
	NSAffineTransform *tf = [NSAffineTransform transform];
	float yScale = scale * w;
	float xScale = yScale * aspect;
	[tf scaleXBy:xScale yBy:yScale];
	[tf translateXBy:offset yBy:0.0];
	[p transformUsingAffineTransform:tf];
	return p;
   }

-(void)drawLineEndingAtPoint:(NSPoint)pt angle:(float)theta lineWidth:(float)lineWidth
   {
	float yScale = lineWidth * scale;
	float xScale = yScale * aspect;
	[NSGraphicsContext saveGraphicsState];
	[[NSAffineTransform transformWithTranslateXBy:pt.x yBy:pt.y]concat];
	[[NSAffineTransform transformWithRotationByDegrees:theta]concat];
	[[NSAffineTransform transformWithTranslateXBy:offset * yScale yBy:0]concat];
	[[NSAffineTransform transformWithScaleXBy:xScale yBy:yScale]concat];
	[[self graphic]drawObject:NSZeroRect view:nil options:nil];
	[NSGraphicsContext restoreGraphicsState];
   }

-(void)canvas:(CanvasWriter*)canvasWriter dataForLineEndingAtPoint:(NSPoint)pt angle:(float)theta lineWidth:(float)lineWidth
{
	float yScale = lineWidth * scale;
	float xScale = yScale * aspect;
	[[canvasWriter contents] appendString:@"ctx.save();\n"];
	[[canvasWriter contents] appendFormat:@"ctx.translate(%g,%g);\n",pt.x,pt.y];
	[[canvasWriter contents] appendFormat:@"ctx.rotate(%g);\n",RADIANS(theta)];
	[[canvasWriter contents] appendFormat:@"ctx.translate(%g,%g);\n",offset * yScale,0.0];
	[[canvasWriter contents] appendFormat:@"ctx.scale(%g,%g);\n",xScale,yScale];
	[[self graphic]writeCanvasData:canvasWriter];
	[[canvasWriter contents] appendString:@"ctx.restore();\n"];
}

-(void)writeSVGData:(SVGWriter*)svgWriter
   {
	if (!graphic)
		return;
	int itemNo = [self objectKey];
	NSRect r = [graphic bounds];
	[[svgWriter defs]appendFormat:@"<marker id=\"markerS%d\" viewBox=\" %g %g %g %g \" ",itemNo,
		(-r.size.width-r.origin.x-offset)*aspect,r.origin.y,r.size.width*aspect,r.size.height];
	[[svgWriter defs]appendString:@"refX=\"0\" refY=\"0\" markerUnits=\"strokeWidth\" "];
	[[svgWriter defs]appendFormat:@"markerWidth=\"%g\" markerHeight=\"%g\" ",r.size.width*scale*aspect,r.size.height*scale];
	[[svgWriter defs]appendString:@"orient=\"auto\"> \n"];
	[[svgWriter defs]appendFormat:@"<g transform=\"rotate(180) scale(%g,1) translate(%g,0) \">",aspect,offset];
	[[svgWriter defs]appendFormat:@"<path d=\"%@\" />",string_from_path([graphic bezierPath])];
	[[svgWriter defs]appendString:@"</g> \n"];
	[[svgWriter defs]appendString:@"</marker> \n"];
	
	[[svgWriter defs]appendFormat:@"<marker id=\"markerE%d\" viewBox=\" %g %g %g %g \" ",itemNo,
		(r.origin.x+offset)*aspect,r.origin.y,r.size.width*aspect,r.size.height];
	[[svgWriter defs]appendString:@"refX=\"0\" refY=\"0\" markerUnits=\"strokeWidth\" "];
	[[svgWriter defs]appendFormat:@"markerWidth=\"%g\" markerHeight=\"%g\" ",r.size.width*scale*aspect,r.size.height*scale];
	[[svgWriter defs]appendString:@"orient=\"auto\"> \n"];
	[[svgWriter defs]appendFormat:@"<g transform=\"scale(%g,1) translate(%g,0) \">",aspect,offset];
	[[svgWriter defs]appendFormat:@"<path d=\"%@\" />",string_from_path([graphic bezierPath])];
	[[svgWriter defs]appendString:@"</g> \n"];
	[[svgWriter defs]appendString:@"</marker> \n"];
   }

-(BOOL)isSameAs:(id)obj
   {
	if (![super isSameAs:obj])
		return NO;
	if (!(scale == [((ACSDLineEnding*)obj) scale] && aspect == [obj aspect]&& offset == [(ACSDLineEnding*)obj offset]))
		return NO;
	if ((graphic == nil) != ([obj graphic] == nil))
		return NO;
	if (graphic)
		return [graphic isSameAs:[obj graphic]];
	return YES;
   }
   
-(void)invalidateGraphicsRefreshCache:(BOOL)redo
   {
	NSEnumerator *objEnum = [graphics objectEnumerator];
	id obj;
    while ((obj = [objEnum nextObject]) != nil)
		if ([obj respondsToSelector:@selector(invalidateGraphicsRefreshCache:)])
			[obj invalidateGraphicsRefreshCache:redo];
   }

-(NSSet*)usedStrokes
   {
	if (graphic)
		return [graphic usedStrokes];
	return [NSSet set];
   }

-(NSSet*)usedFills
   {
	if (graphic)
		return [graphic usedFills];
	return [NSSet set];
   }

-(NSSet*)usedShadows
   {
	if (graphic)
		return [graphic usedShadows];
	return [NSSet set];
   }


-(void)notifyOnADDOrRemove
{
    [self postNotify:ACSDRefreshLineEndingsNotification object:self];
}


@end
