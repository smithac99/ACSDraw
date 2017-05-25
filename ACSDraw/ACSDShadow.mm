//
//  ACSDShadow.mm
//  ACSDraw
//
//  Created by Alan Smith on Thu Feb 14 2002.
//  Copyright (c) 2001 __MyCompanyName__. All rights reserved.
//

#import "ACSDGraphic.h"
#import "GraphicView.h"
#import "ACSDShadow.h"
#import "float_array.h"
#include <iostream>

@implementation ACSDShadow

-(id)initWithXOffset:(float)x yOffset:(float)y isColour:(BOOL)isCol alpha:(float)a stdDev:(int)b graphic:(ACSDGraphic*)g
   {
	if (self = [super init])
	   {
		xOffset = x;
		yOffset = y;
		graphic = g;
		shadowImage = nil;
		isColour = isCol;
		alpha = a;
		stdDev = b;
	   }
	return self;
   }

-(void)dealloc
   {
	if (shadowImage)
		[shadowImage release];
	[super dealloc];
   }

-(float)xOffset
   {
	return xOffset;
   }

-(float)yOffset
   {
	return yOffset;
   }

-(int)stdDev
   {
	return stdDev;
   }

-(NSRect)bounds
   {
	NSRect r;
	r.origin = [graphic bounds].origin;
	r.size = [shadowImage size];
	r = NSOffsetRect(r,xOffset,yOffset);
	return r;
   }

-(void)setXOffset:(float)x
   {
	xOffset = x;
   }

-(void)setYOffset:(float)y
   {
	yOffset = y;
   }

-(void)setStdDev:(int)r
   {
	stdDev = r;
   }

-(void)setShadowImage:(NSImage*)im
   {
	if (shadowImage)
		[shadowImage release];
	if (im)
		shadowImage = [im retain];
   }


@end
