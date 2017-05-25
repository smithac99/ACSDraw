//
//  GraphicCache.h
//  ACSDraw
//
//  Created by alan on Sat Jan 24 2004.
//  Copyright (c) 2004 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface GraphicCache : NSObject
{
	NSImage *image;
	NSBitmapImageRep *bitmap;
	NSDate *timeLastResized;
	float requestedWidth,requestedHeight,				//the size asked for
	allocatedWidth,allocatedHeight,				//actual size of the cache
	magnification;
	BOOL valid;
}

@property (retain) NSBitmapImageRep *bitmap;

- (id)initWithWidth:(float)w height:(float)h;
-(NSImage*)image;
-(BOOL)valid;
-(void)setValid:(BOOL)v;
-(void)allocImageWidth:(float)w height:(float)h;
-(void)resizeToWidth:(float)w height:(float)h;
-(NSRect)imageBounds;
-(NSRect)magnifiedImageBounds;
-(NSRect)allocatedBounds;
-(NSRect)requestedBounds;
- (double)magnification;
- (void)setMagnification:(double)mag;
- (void)checkAndSetMagnification:(double)mag;
-(float)imageWidth;
-(float)imageHeight;
-(float)magnifiedImageWidth;
-(float)magnifiedImageHeight;
-(BOOL)hitTestX:(int)x y:(int)y;

@end
