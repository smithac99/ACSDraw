//
//  ACSDLineEnding.h
//  ACSDraw
//
//  Created by alan on Wed Jan 28 2004.
//  Copyright (c) 2004 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "ACSDAttribute.h"
@class ACSDGraphic;
@class CanvasWriter;


@interface ACSDLineEnding : ACSDAttribute
   {
	__strong ACSDGraphic *graphic;
	float scale;
	float aspect;			//is the horizontal scale relative to scale
	float offset;
   }

+ (id)defaultLineEnding;
+ (NSMutableArray*)initialLineEndings;
+(ACSDLineEnding*)lineEndingWithGraphic:(ACSDGraphic*)g scale:(float)sc aspect:(float)asp offset:(float)of;

-(id)initWithGraphic:(ACSDGraphic*)g scale:(float)sc aspect:(float)asp offset:(float)off;
-(ACSDGraphic*)graphic;
-(float)scale;
-(float)aspect;
-(float)offset;
-(void)setScale:(float)s;
-(void)setAspect:(float)s;
-(void)setOffset:(float)s;
-(void)setGraphic:(ACSDGraphic*)g;
-(NSBezierPath*)lineEndingPathWidth:(float)w;
-(void)drawLineEndingAtPoint:(NSPoint)pt angle:(float)theta lineWidth:(float)lineWidth;
-(void)writeSVGData:(SVGWriter*)svgWriter;
-(void)canvas:(CanvasWriter*)canvasWriter dataForLineEndingAtPoint:(NSPoint)pt angle:(float)theta lineWidth:(float)lineWidth;


@end
