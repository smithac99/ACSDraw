//
//  QuartzImage.h
//  ACSDraw
//
//  Created by alan on 24/11/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "Quartz/Quartz.h"
#import "QuartzCore/QuartzCore.h"


@interface QuartzImage : NSObject 
{
	CGContextRef cgBitmap;
}

-(id)initWithWidth:(float)w height:(float)h;
-(CGContextRef)context;

@end
