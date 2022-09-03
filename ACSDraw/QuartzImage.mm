//
//  QuartzImage.mm
//  ACSDraw
//
//  Created by alan on 24/11/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import "QuartzImage.h"
#import "Quartz/Quartz.h"


@implementation QuartzImage


-(id)initWithWidth:(float)w height:(float)h
{
    if (self = [super init])
    {
        int bitmapBytesPerRow   = (w * 4);
        CGColorSpaceRef colourSpace = CGColorSpaceCreateWithName(kCGColorSpaceGenericRGB);
        cgBitmap = CGBitmapContextCreate (NULL,w,h,8,bitmapBytesPerRow,colourSpace,kCGImageAlphaPremultipliedLast);
        CFRelease(colourSpace);
    }
    return self;
}

-(void)dealloc
{
	if (cgBitmap)
		CGContextRelease(cgBitmap);
}

-(CGContextRef)context
{
	return cgBitmap;
}

@end
