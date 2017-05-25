//
//  ACSDImage.h
//  ACSDraw
//
//  Created by alan on Thu Feb 12 2004.
//  Copyright (c) 2004 __MyCompanyName__. All rights reserved.
//

#import "ACSDGraphic.h"
#import "QuartzImage.h"

extern NSString *ACSDHistogramDidChangeNotification;

NSBitmapImageRep *createRGBBitmap(int width,int height);
CGContextRef CreateArgbContext(int width,int height);

@interface ACSDImage : ACSDGraphic
{
	NSImage *image;
	NSRect frame,originalFrame;
	NSPoint originalCentrePoint;
	CIContext *ciContext;	//even though we never use it, we have to retain it
	NSImage *spareImage;
	float *histogram;
}

@property (retain)	NSImage *image;
@property NSRect frame;


-(id)initWithName:(NSString*)n fill:(ACSDFill*)f stroke:(ACSDStroke*)str rect:(NSRect)r layer:(ACSDLayer*)l image:(NSImage*)im;
- (ACSDImage*)rotatedACSDImage ;
- (ACSDImage*)wideCylinderHalfWrapACSDImage;
- (ACSDImage*)wideCylinderHalfUnwrapACSDImage;
- (ACSDImage*)demercatorACSDImage;
-(float*)histogram;

@end
