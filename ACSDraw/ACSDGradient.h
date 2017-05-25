//
//  ACSDGradient.h
//  ACSDraw
//
//  Created by Alan Smith on Sun Feb 10 2002.
//  Copyright (c) 2001 __MyCompanyName__. All rights reserved.
//

#import "ACSDFill.h"

@class ACSDGradient;
@class GradientElement;

struct ShadingInfo
{
	ACSDGradient *gradient;
	int ind,nextInd;
	NSColor *currColour,*nextColour;
	float currVal,nextVal;
};

enum
{
	GRADIENT_LINEAR,
	GRADIENT_RADIAL
};

@interface ACSDGradient : ACSDFill
{
	CGFunctionRef gradientFunction;
	ShadingInfo shadingInfo;
}

@property int gradientType;
@property (nonatomic)float angle;
@property float preOffset,postOffset;
@property NSPoint radialCentre;
@property (retain) 	NSMutableArray *gradientElements;

-(id)initWithColour1:(NSColor*)col1 colour2:(NSColor*)col2;

-(NSColor*)leftColour;
-(NSColor*)rightColour;
-(void)setLeftColour:(NSColor*)c;
-(void)setRightColour:(NSColor*)c;
-(void)setLeftColour:(NSColor*)c inView:(GraphicView*)gView;
-(void)setRightColour:(NSColor*)c inView:(GraphicView*)gView;
-(void)setPreOffset:(float)pre postOffset:(float)post angle:(float)ang view:(GraphicView*)gView;
-(void)writeSVGGradientDef:(SVGWriter*)svgWriter options:(NSDictionary*)options;
-(NSColor*)shadingColourForPosition:(float)pos;
-(void)addGradientElementAndOrder:(GradientElement*)ge;
-(void)fillPath:(NSBezierPath*)path angle:(float)ang;
-(void)changeGradientType:(int)gt;
-(void)changeRadialCentre:(NSPoint)pt;
-(NSString*)svgName:(ACSDrawDocument*)doc;
-(NSString*)graphicXMLForEvent:(NSMutableDictionary*)options;


@end
