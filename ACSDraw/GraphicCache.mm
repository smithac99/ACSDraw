//
//  GraphicCache.mm
//  ACSDraw
//
//  Created by alan on Sat Jan 24 2004.
//  Copyright (c) 2004 __MyCompanyName__. All rights reserved.
//

#import "GraphicCache.h"
#import "MainWindowController.h"

NSInteger blockedSize(float inputSize,int blockSize);

@implementation GraphicCache

@synthesize bitmap;

- (id)initWithWidth:(float)w height:(float)h
{
	if ((self = [super init]))
	{
		magnification = 1.0;
		valid = NO;
		requestedWidth = w;
		requestedHeight = h;
		allocatedWidth = allocatedHeight = 0.0;
		[self resizeToWidth:w height:h];
	}
	return self;
}

-(void)dealloc
{
	[image release];
	[bitmap release];
	[timeLastResized release];
	[super dealloc];
}

-(NSImage*)image
   {
	return image;
   }

NSInteger blockedSize(float inputSize,int blockSize)
   {
	int iw = (int)ceil(inputSize);
	iw = ((iw + (blockSize - 1)) / blockSize) * blockSize;
	if (iw == 0)
		iw = blockSize;
	return iw;
   }

-(void)allocImageWidth:(float)aw height:(float)ah
{
	aw = blockedSize(aw,256);
	ah = blockedSize(ah,64);
	//BOOL flipped = NO;
	if (image)
		if (aw == allocatedWidth && ah == allocatedHeight)
			return;
		else
		{
			//flipped = [image isFlipped];
			[image release];
			self.bitmap = nil;
		}
	[self setValid:NO];
	allocatedWidth = aw;
	allocatedHeight = ah;
	self.bitmap = newBitmap(aw, ah);
	image = [[NSImage alloc]initWithSize:NSMakeSize(allocatedWidth,allocatedHeight)];
	[image addRepresentation:bitmap];
	//[image setFlipped:flipped];
}
   
-(void)resizeRegardlessToWidth:(float)w height:(float)h
   {
	requestedWidth = w;
	requestedHeight = h;
	[self allocImageWidth:[self magnifiedImageWidth] height:[self magnifiedImageHeight]];
   }
   
-(void)resizeToWidth:(float)w height:(float)h
   {
	if (w == requestedWidth && h == requestedHeight && image != nil)
		return;
	[self resizeRegardlessToWidth:w height:h];
   }
   
-(float)imageWidth
   {
	return requestedWidth;
   }
   
-(float)imageHeight
   {
	return requestedHeight;
   }
   
-(float)magnifiedImageWidth
   {
	return [self imageWidth] * magnification;
   }
   
-(float)magnifiedImageHeight
   {
	return [self imageHeight] * magnification;
   }

-(BOOL)valid
   {
	return valid;
   }
   
-(void)setValid:(BOOL)v
   {
	valid = v;
   }

-(NSRect)imageBounds
   {
	return NSMakeRect(0.0,0.0,[self imageWidth],[self imageHeight]);
   }

-(NSRect)magnifiedImageBounds
   {
	return NSMakeRect(0.0,0.0,[self magnifiedImageWidth],[self magnifiedImageHeight]);
   }

-(NSRect)allocatedBounds
   {
	return NSMakeRect(0.0,0.0,allocatedWidth,allocatedHeight);
   }

-(NSRect)requestedBounds
   {
	return NSMakeRect(0.0,0.0,requestedWidth,requestedHeight);
   }

- (double)magnification
   {
    return magnification;
   }

- (void)setMagnification:(double)mag
   {
	if (mag == magnification)
		return;
	magnification = mag;
	valid = NO;
	[self resizeRegardlessToWidth:requestedWidth height:requestedHeight];
   }

- (void)checkAndSetMagnification:(double)mag
   {
	if (mag != magnification)
		[self setMagnification:mag];
   }

-(BOOL)hitTestX:(int)x y:(int)y
{
    NSColor *col = [bitmap colorAtX:x y:allocatedHeight - y];
    return [col alphaComponent] > 0.0;
}
@end
