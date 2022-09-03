//
//  ACSDImageRep.mm
//  ACSDraw
//
//  Created by Alan Smith on 02/02/2008.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "ACSDImageRep.h"
#import "ACSDrawDocument.h"
#import "GraphicView.h"
#import "AffineTransformAdditions.h"


@implementation ACSDImageRep

+ (void)initialize
{
	//[NSImageRep registerImageRepClass:[ACSDImageRep class]];
}

+ (NSArray *)imageUnfilteredTypes
{
	return [NSArray arrayWithObject:@"com.alancsmith.acsd"];
}

+ (BOOL)canInitWithData:(NSData *)data
{
	return YES;
}

+ (id)imageRepWithData:(NSData*)data
{
	return [[ACSDImageRep alloc]initWithData:data];
}

- (id)initWithData:(NSData*)d
{
	if ((self = [super init]))
	{
		data = d;
		document = [[ACSDrawDocument alloc]init];
		[document readFromData:data ofType:@"acsd" error:nil];
		NSRect r;
		r.origin.x = r.origin.y = 0.0;
		r.size = [document documentSize];
		graphicView = [[GraphicView alloc]initWithFrame:r];
		[graphicView setPages:[document pages]];
	}
	return self;
}

- (id) initWithCoder:(NSCoder*)coder
{
	self = [self initWithData:[coder decodeObjectForKey:@"ACSDImageRep_data"]];
	return self;
}

- (void) encodeWithCoder:(NSCoder*)coder
{
	[super encodeWithCoder:coder];
	[coder encodeObject:data forKey:@"ACSDImageRep_data"];
}

- (BOOL)drawAtPoint:(NSPoint)aPoint
{
	[NSGraphicsContext saveGraphicsState];
	[[NSAffineTransform transformWithTranslateXBy:aPoint.x yBy:aPoint.y]concat];
	[self draw];
	[NSGraphicsContext restoreGraphicsState];
	return YES;
}

- (BOOL)drawInRect:(NSRect)rect
{
	[NSGraphicsContext saveGraphicsState];
	[[NSAffineTransform transformWithScaleXBy:rect.size.width/[self size].width
															  yBy:rect.size.height/[self size].height]concat];
	[[NSAffineTransform transformWithTranslateXBy:-rect.origin.x yBy:-rect.origin.y]concat];
	[self draw];
	[NSGraphicsContext restoreGraphicsState];
	return YES;
}

- (BOOL)draw
{
	[graphicView drawPage:[[document pages]objectAtIndex:0] rect:[graphicView bounds] drawingToScreen:NO
			  drawMarkers:NO drawingToPDF:nil substitutions:nil options:nil];
	return YES;
}

- (BOOL)hasAlpha
{
	return YES;
}

- (BOOL)isOpaque
{
	return NO;
}

-(NSSize)size
{
	return [document documentSize];
}

- (NSInteger)pixelsWide
{
	return [self size].width;
}

- (NSInteger)pixelsHigh
{
	return [self size].height;
}

@end
