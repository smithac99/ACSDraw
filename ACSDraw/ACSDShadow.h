//
//  ACSDShadow.h
//  ACSDraw
//
//  Created by Alan Smith on Thu Feb 14 2002.
//  Copyright (c) 2001 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class ACSDGraphic;

@interface ACSDShadow : NSObject
   {
	NSImage *shadowImage;
	ACSDGraphic *graphic;
	BOOL isColour;
	float alpha;
	float xOffset;
	float yOffset;
	int stdDev;
	NSBitmapImageRep *shadowRep;
   }

-(id)initWithXOffset:(float)x yOffset:(float)y isColour:(BOOL)isCol alpha:(float)a stdDev:(int)b graphic:(ACSDGraphic*)g;

-(float)xOffset;
-(float)yOffset;
-(int)stdDev;
-(void)setXOffset:(float)x;
-(void)setYOffset:(float)y;
-(void)setStdDev:(int)r;
-(NSRect)bounds;


@end
