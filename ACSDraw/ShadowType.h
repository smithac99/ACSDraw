//
//  ShadowType.h
//  ACSDraw
//
//  Created by Alan Smith on Fri Feb 15 2002.
//  Copyright (c) 2001 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "ACSDAttribute.h"

@class ACSDrawDocument;

@interface ShadowType : ACSDAttribute
   {
	NSShadow *itsShadow,*scaledShadow;
   }

+ (NSMutableArray*)initialShadows;

-(id)initWithBlurRadius:(float)bR xOffset:(float)x yOffset:(float)y colour:(NSColor*)col;
-(id)init;
-(float)blurRadius;
-(float)xOffset;
-(float)yOffset;
-(NSColor*)colour;
-(void)setBlurRadius:(float)br;
-(void)setOffset:(NSSize)sz;
-(void)setColour:(NSColor*)col;
-(NSShadow*)shadowWithScale:(float) scale;
-(NSString*)svgName:(ACSDrawDocument*)doc;
-(void)writeSVGShadowDef:(SVGWriter*)svgWriter;
-(void)writeSVGData:(SVGWriter*)svgWriter;
-(NSShadow*)itsShadow;

@end
