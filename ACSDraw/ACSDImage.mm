//
//  ACSDImage.mm
//  ACSDraw
//
//  Created by alan on Thu Feb 12 2004.
//  Copyright (c) 2004 __MyCompanyName__. All rights reserved.
//

#import "ACSDImage.h"
#import "AffineTransformAdditions.h"
#import "HtmlExportController.h"
#import "AppDelegate.h"
#import "CoderAdditions.h"
#import "ShadowType.h"
#import <QuartzCore/QuartzCore.h>
#import <Quartz/Quartz.h>
#import "geometry.h"
#import "GraphicView.h"
#import <Accelerate/Accelerate.h>
#import "SVGWriter.h"

CIFilter *_wideCylinderHalfWrapFilter = nil;
CIFilter *_wideCylinderHalfUnwrapFilter = nil;
CIFilter *_demercatorFilter = nil;

NSString *ACSDHistogramDidChangeNotification = @"ACSDHistogramDidChange";

@implementation ACSDImage

@synthesize image,frame;

+ (NSString*)graphicTypeName
{
	return @"Image";
}

-(id)initWithName:(NSString*)n fill:(ACSDFill*)f stroke:(ACSDStroke*)str rect:(NSRect)r layer:(ACSDLayer*)l image:(NSImage*)im
{
	if ((self = [super initWithName:n fill:f stroke:str rect:r layer:l]))
	{
		if (im)
		{
			image = [im retain];
			frame.origin = NSMakePoint(0.0,0.0);
			frame.size = [im size];
		}
		exposure = 0.0;
		saturation = 1.0;
		brightness = 0.0;
		contrast = 1.0;
	}
	return self;
}

-(id)initWithName:(NSString*)n fill:(ACSDFill*)f stroke:(ACSDStroke*)str rect:(NSRect)r layer:(ACSDLayer*)l
		   xScale:(float)xs yScale:(float)ys rotation:(float)rot shadowType:(ShadowType*)st label:(ACSDLabel*)lab  alpha:(float)a 
			image:(NSImage*)im exposure:(float)e saturation:(float)sat brightness:(float)bri contrast:(float)con 
{
    if ((self = [super initWithName:n fill:f stroke:str rect:r layer:l xScale:xs yScale:ys rotation:rot shadowType:st label:lab alpha:a]))
	{
		if (im)
		{
			image = [im retain];
			frame.origin = NSMakePoint(0.0,0.0);
			frame.size = [im size];
		}
		exposure = e;
		saturation = sat;
		brightness = bri;
		contrast = con;
		[self invalidateGraphicSizeChanged:YES shapeChanged:NO redraw:YES notify:NO];
	}
	return self;
}

-(void)dealloc
{
	[image release];
	[spareImage release];
	[ciContext release];
	if (histogram)
		free(histogram);
	[super dealloc];
}

- (void) encodeWithCoder:(NSCoder*)coder
{
	[super encodeWithCoder:coder];
	[coder encodeObject:image forKey:@"ACSDImage_image"];
	[coder encodeFloat:exposure forKey:@"ACSDImage_exposure"];
	[coder encodeFloat:saturation forKey:@"ACSDImage_saturation"];
	[coder encodeFloat:brightness forKey:@"ACSDImage_brightness"];
	[coder encodeFloat:contrast forKey:@"ACSDImage_contrast"];
	[ACSDGraphic encodeRect:frame coder:coder forKey:@"ACSDImage_frame"];
}

- (id) initWithCoder:(NSCoder*)coder
{
	self = [super initWithCoder:coder];
	image = [[coder decodeObjectForKey:@"ACSDImage_image"]retain];
	if ([coder containsValueForKey:@"ACSDImage_framex"])
		frame = [ACSDGraphic decodeRectForKey:@"ACSDImage_frame" coder:coder];
	else
	{
		frame.size = bounds.size;
		frame.origin.x = frame.origin.y = 0.0;
	}
	exposure = [coder decodeFloatForKey:@"ACSDImage_exposure" withDefault:0.0];
	saturation = [coder decodeFloatForKey:@"ACSDImage_saturation" withDefault:1.0];
	brightness = [coder decodeFloatForKey:@"ACSDImage_brightness" withDefault:0.0];
	contrast = [coder decodeFloatForKey:@"ACSDImage_contrast" withDefault:1.0];
	return self;
}

- (id)copyWithZone:(NSZone *)zone 
{
    ACSDImage *obj = [super copyWithZone:zone];
    obj.image =self.image;
    obj.frame = self.frame;
    obj.exposure = self.exposure;
    obj.saturation = self.saturation;
    obj.brightness = self.brightness;
    obj.contrast = self.contrast;
    [obj invalidateGraphicSizeChanged:YES shapeChanged:NO redraw:YES notify:NO];
/*
    id obj = [[ACSDImage alloc]initWithName:[self name] fill:[self fill] stroke:[self stroke] rect:[self bounds]
									  layer:[self layer] xScale:xScale yScale:yScale rotation:rotation shadowType:[self shadowType] label:textLabel alpha:alpha 
									  image:[image copyWithZone:zone] exposure:exposure saturation:saturation brightness:brightness contrast:contrast];*/
	return obj;
}

-(BOOL)usuallyUsesCache
   {
	return YES;
   }

-(NSRect)imageRect
   {
	NSSize sz = [image size];
	return NSMakeRect(0.0,0.0,sz.width,sz.height);
   }

-(NSImage*)rotatedImage
{
	NSImageRep *oldImageRep = [image bestRepresentationForRect:[self imageRect]context:nil hints:nil];
	float w = [oldImageRep pixelsWide];
	float h = [oldImageRep pixelsHigh];
	NSRect r = NSMakeRect(0.0,0.0,w,h);
	NSBezierPath *rectPath = [NSBezierPath bezierPathWithRect:r];
	NSAffineTransform *trans = [NSAffineTransform transformWithTranslateXBy:-w/2.0 yBy:-h/2.0];
	[trans rotateByDegrees:rotation];
	[trans translateXBy:w/2.0 yBy:h/2.0];
	rectPath = [trans transformBezierPath:rectPath];
	NSRect transformedRect = [rectPath bounds];
	float newW = transformedRect.size.width;
	float newH = transformedRect.size.height;
	int bytesPerRow = (((int)newW) * 4 + 15) & ~15;
	float iw = w/[image size].width * newW;
	float ih = h/[image size].height * newH;
	NSBitmapImageRep *newBitmapRep;
	NSImage *newImage = [[NSImage alloc]initWithSize:NSMakeSize(iw,ih)];
	if ([oldImageRep isKindOfClass:[NSBitmapImageRep class]])
	{
		NSBitmapImageRep *oldBitmapImageRep = (NSBitmapImageRep*)oldImageRep;
		newBitmapRep = [[NSBitmapImageRep alloc]initWithBitmapDataPlanes:nil pixelsWide:newW pixelsHigh:newH
																		 bitsPerSample:[oldBitmapImageRep bitsPerSample]samplesPerPixel:[oldBitmapImageRep samplesPerPixel]hasAlpha:[oldBitmapImageRep hasAlpha]
																			  isPlanar:[oldBitmapImageRep isPlanar]colorSpaceName:[oldBitmapImageRep colorSpaceName]bytesPerRow:bytesPerRow bitsPerPixel:[oldBitmapImageRep bitsPerPixel]];
		[newBitmapRep setSize:NSMakeSize(newW,newH)];
		[newImage addRepresentation:[newBitmapRep autorelease]];
	}
	[newImage lockFocus];
	[[NSColor clearColor]set];
	NSRectFill(NSMakeRect(0.0,0.0,iw,ih));
	[[NSAffineTransform transformWithTranslateXBy:iw/2.0 yBy:ih/2.0] concat];
	[[NSAffineTransform transformWithRotationByDegrees:rotation] concat];
	[[NSAffineTransform transformWithTranslateXBy:-w/2.0 yBy:-h/2.0] concat];
	[oldImageRep drawInRect:NSMakeRect(0.0,0.0,w,h)];
	[newImage unlockFocus];
	return [newImage autorelease];
}


NSBitmapImageRep *createRGBBitmap(int width,int height)
{
	return [[[NSBitmapImageRep alloc]initWithBitmapDataPlanes:nil pixelsWide:width pixelsHigh:height
												bitsPerSample:8 samplesPerPixel:4 hasAlpha:YES
													 isPlanar:NO colorSpaceName:NSCalibratedRGBColorSpace bytesPerRow:0 bitsPerPixel:0]autorelease];
}

-(NSImage*)demercatorImage
{
	CGImageRef cgImage = [image CGImageForProposedRect:nil context:nil hints:nil]; 
	float w = CGImageGetWidth(cgImage);
	float oldH = CGImageGetHeight(cgImage);
	float newH = floor(oldH / 2.0);
	NSBitmapImageRep *newBitmapRep,*tempBitmapRep;
	
	if (_demercatorFilter == nil)
		_demercatorFilter = [[CIFilter filterWithName:@"DemercatorFilter"]retain];
	CIImage *ciImage = [CIImage imageWithCGImage:cgImage];
	[_demercatorFilter setValue:ciImage forKey: @"inputImage"];
	ciImage = [_demercatorFilter valueForKey: @"outputImage"];
	
	tempBitmapRep = createRGBBitmap(w,oldH);
	[tempBitmapRep setSize:NSMakeSize(w,oldH)];
	NSGraphicsContext *oldContext = [NSGraphicsContext currentContext];
	[NSGraphicsContext setCurrentContext:[NSGraphicsContext graphicsContextWithBitmapImageRep:tempBitmapRep]];
	NSRect oldRect = NSMakeRect(0,0,w,oldH);
	NSRect newRect = NSMakeRect(0,0,w,newH);
	[[NSColor whiteColor]set];
	NSRectFill(oldRect);
    [ciImage drawInRect:oldRect fromRect:oldRect operation:NSCompositingOperationSourceOver fraction:1.0];
	
	newBitmapRep = createRGBBitmap(w,newH);
	[newBitmapRep setSize:NSMakeSize(w,newH)];
	[NSGraphicsContext setCurrentContext:[NSGraphicsContext graphicsContextWithBitmapImageRep:newBitmapRep]];
	[[NSColor whiteColor]set];
	NSRectFill(newRect);
	oldRect = NSMakeRect(0,(oldH-newH)/2,w,newH);
    [tempBitmapRep drawInRect:newRect fromRect:oldRect operation:NSCompositingOperationSourceOver fraction:1.0 respectFlipped:NO hints:nil];
	[NSGraphicsContext setCurrentContext:oldContext];
	CGImageRef cgr = [newBitmapRep CGImage];
	NSImage *newImage = [[NSImage alloc]initWithCGImage:cgr size:NSZeroSize];
	
	return [newImage autorelease];
}

-(NSImage*)wideCylinderHalfWrapImage
{
	CGImageRef cgImage = [image CGImageForProposedRect:nil context:nil hints:nil]; 
	float w = CGImageGetWidth(cgImage);
	float oldH = CGImageGetHeight(cgImage);
	float newH = floor(2.0 / M_PI * oldH);
	NSImage *newImage = [[NSImage alloc]initWithSize:NSMakeSize(w,newH)];
	NSBitmapImageRep *newBitmapRep;

	if (_wideCylinderHalfWrapFilter == nil)
		_wideCylinderHalfWrapFilter = [[CIFilter filterWithName:@"WideCylinderHalfWrapFilter"]retain];
	CIImage *ciImage = [CIImage imageWithCGImage:cgImage];
	[_wideCylinderHalfWrapFilter setValue:ciImage forKey: @"inputImage"];
	ciImage = [_wideCylinderHalfWrapFilter valueForKey: @"outputImage"];
	newBitmapRep = createRGBBitmap(w,newH);
	[newBitmapRep setSize:NSMakeSize(w,newH)];
	NSGraphicsContext *oldContext = [NSGraphicsContext currentContext];
	[NSGraphicsContext setCurrentContext:[NSGraphicsContext graphicsContextWithBitmapImageRep:newBitmapRep]];
	NSRect newRect = NSMakeRect(0,0,w,newH);
	[[NSColor redColor]set];
	NSRectFill(newRect);
	[ciImage drawInRect:newRect fromRect:newRect operation:NSCompositeSourceOver fraction:1.0];
	[NSGraphicsContext setCurrentContext:oldContext];
	[newImage addRepresentation:newBitmapRep];
	
	return [newImage autorelease];
}

-(NSImage*)wideCylinderHalfUnwrapImage
{
	CGImageRef cgImage = [image CGImageForProposedRect:nil context:nil hints:nil]; 
	float w = CGImageGetWidth(cgImage);
	float oldH = CGImageGetHeight(cgImage);
	float newH = ceil(M_PI / 2.0 * oldH);
	NSImage *newImage = [[NSImage alloc]initWithSize:NSMakeSize(w,newH)];
	NSGraphicsContext *oldContext = [NSGraphicsContext currentContext];
	NSBitmapImageRep *tempBitmapRep = createRGBBitmap(w,newH);
	[NSGraphicsContext setCurrentContext:[NSGraphicsContext graphicsContextWithBitmapImageRep:tempBitmapRep]];
	CGRect destR = CGRectMake(0.0,0.0,w,oldH);
    CGContextDrawImage([[NSGraphicsContext currentContext]CGContext],destR,cgImage);
	if (_wideCylinderHalfUnwrapFilter == nil)
		_wideCylinderHalfUnwrapFilter = [[CIFilter filterWithName:@"WideCylinderHalfUnwrapFilter"]retain];
	CIImage *ciImage = [CIImage imageWithCGImage:[tempBitmapRep CGImage]];
	[_wideCylinderHalfUnwrapFilter setValue:ciImage forKey: @"inputImage"];
	ciImage = [_wideCylinderHalfUnwrapFilter valueForKey: @"outputImage"];
	NSBitmapImageRep *newBitmapRep = createRGBBitmap(w,newH);
	[newBitmapRep setSize:NSMakeSize(w,newH)];
	[NSGraphicsContext setCurrentContext:[NSGraphicsContext graphicsContextWithBitmapImageRep:newBitmapRep]];
	[[NSColor redColor]set];
	NSRectFill(NSMakeRect(0,0,w,newH));
    [ciImage drawAtPoint:NSMakePoint(0.0,0.0) fromRect:NSMakeRect(0.0,0.0,w,newH) operation:/*NSCompositeCopy*/NSCompositingOperationSourceOver fraction:1.0];
	[NSGraphicsContext setCurrentContext:oldContext];
	[newImage addRepresentation:newBitmapRep];
	return [newImage autorelease];
}

- (ACSDImage*)rotatedACSDImage 
{
	NSImage *im = [self rotatedImage];
	float w2 = ([im size].width - [image size].width)/ 2.0;
	float h2 = ([im size].height - [image size].height) / 2.0;
	NSRect b = [self bounds];
	b.origin.x -= w2;
	b.origin.y -= h2;
	b.size.width = [im size].width;
	b.size.height = [im size].height;
    ACSDImage* obj = [[[ACSDImage alloc]initWithName:[self name] fill:[self fill] stroke:[self stroke] rect:b
									  layer:[self layer] xScale:xScale yScale:yScale rotation:0.0 shadowType:[self shadowType] label:textLabel alpha:alpha 
									  image:im exposure:exposure saturation:saturation brightness:brightness contrast:contrast]autorelease];
	return obj;
}

- (ACSDImage*)demercatorACSDImage 
{
	NSImage *im = [self demercatorImage];
	float w2 = ([im size].width - [image size].width)/ 2.0;
	float h2 = ([im size].height - [image size].height) / 2.0;
	NSRect b = [self bounds];
	b.origin.x -= w2;
	b.origin.y -= h2;
	b.size.width = [im size].width;
	b.size.height = [im size].height;
    ACSDImage* obj = [[[ACSDImage alloc]initWithName:[self name] fill:[self fill] stroke:[self stroke] rect:b
											  layer:[self layer] xScale:xScale yScale:yScale rotation:0.0 shadowType:[self shadowType] label:textLabel alpha:alpha 
											  image:im exposure:exposure saturation:saturation brightness:brightness contrast:contrast]autorelease];
	return obj;
}

- (ACSDImage*)wideCylinderHalfWrapACSDImage 
{
	NSImage *im = [self wideCylinderHalfWrapImage];
	float w2 = ([im size].width - [image size].width)/ 2.0;
	float h2 = ([im size].height - [image size].height) / 2.0;
	NSRect b = [self bounds];
	b.origin.x -= w2;
	b.origin.y -= h2;
	b.size.width = [im size].width;
	b.size.height = [im size].height;
    ACSDImage* obj = [[[ACSDImage alloc]initWithName:[self name] fill:[self fill] stroke:[self stroke] rect:b
											  layer:[self layer] xScale:xScale yScale:yScale rotation:0.0 shadowType:[self shadowType] label:textLabel alpha:alpha 
											  image:im exposure:exposure saturation:saturation brightness:brightness contrast:contrast]autorelease];
	return obj;
}

- (ACSDImage*)wideCylinderHalfUnwrapACSDImage 
{
	NSImage *im = [self wideCylinderHalfUnwrapImage];
	float w2 = ([im size].width - [image size].width)/ 2.0;
	float h2 = ([im size].height - [image size].height) / 2.0;
	NSRect b = [self bounds];
	b.origin.x -= w2;
	b.origin.y -= h2;
	b.size.width = [im size].width;
	b.size.height = [im size].height;
    ACSDImage* obj = [[[ACSDImage alloc]initWithName:[self name] fill:[self fill] stroke:[self stroke] rect:b
											  layer:[self layer] xScale:xScale yScale:yScale rotation:0.0 shadowType:[self shadowType] label:textLabel alpha:alpha 
											  image:im exposure:exposure saturation:saturation brightness:brightness contrast:contrast]autorelease];
	return obj;
}

-(void)allocSpareImage
{
	if (spareImage)
		return;
//	NSBitmapImageRep *oldBitmapRep = (NSBitmapImageRep*)[image bestRepresentationForDevice:nil];
	NSData *imData = [image TIFFRepresentation];
	NSBitmapImageRep *oldBitmapRep = [NSBitmapImageRep imageRepWithData:imData];
	NSBitmapImageRep *newBitmapRep = [[NSBitmapImageRep alloc]initWithBitmapDataPlanes:nil pixelsWide:[oldBitmapRep pixelsWide]pixelsHigh:[oldBitmapRep pixelsHigh]
				bitsPerSample:[oldBitmapRep bitsPerSample]samplesPerPixel:[oldBitmapRep samplesPerPixel]hasAlpha:[oldBitmapRep hasAlpha]
				isPlanar:[oldBitmapRep isPlanar]colorSpaceName:[oldBitmapRep colorSpaceName]bytesPerRow:[oldBitmapRep bytesPerRow]bitsPerPixel:[oldBitmapRep bitsPerPixel]];
	[newBitmapRep setSize:NSMakeSize([newBitmapRep pixelsWide],[newBitmapRep pixelsHigh])];
	spareImage = [[NSImage alloc]initWithSize:NSMakeSize([newBitmapRep pixelsWide],[newBitmapRep pixelsHigh])];
	[spareImage addRepresentation:[newBitmapRep autorelease]];
}

-(void)drawFilteredImage
{
	NSData *imData = [image TIFFRepresentation];
	NSBitmapImageRep *imageRep = [NSBitmapImageRep imageRepWithData:imData];
	CIImage *ciImage = [[[CIImage alloc]initWithBitmapImageRep:(NSBitmapImageRep*)imageRep]autorelease];
	CIImage *resultImage = ciImage;
	for (NSString *s in [NSArray arrayWithObjects:@"ACSLevels",nil])
	{
		NSDictionary *d = [filterSettings objectForKey:s];
		if (d)
		{
			CIFilter *f = [CIFilter filterWithName:s];
			if (f)
			{
				[f setDefaults];
				[f setValue:resultImage forKey: @"inputImage"];
				for (NSString *k in [d allKeys])
					[f setValue:[d objectForKey:k]forKey:k];
				resultImage = [f valueForKey: @"outputImage"];
			}
		}
	}
	if (exposure != 0.0)
	   {
		CIFilter *exposureFilter = [CIFilter filterWithName:@"CIExposureAdjust"];
		[exposureFilter setDefaults];
		[exposureFilter setValue: resultImage forKey: @"inputImage"];
		[exposureFilter setValue: [NSNumber numberWithFloat: exposure]forKey: @"inputEV"];
		resultImage = [exposureFilter valueForKey: @"outputImage"];
	   }
	if (saturation != 1.0 || brightness != 0.0 ||contrast != 1.0)
	   {
		CIFilter *colourFilter = [CIFilter filterWithName:@"CIColorControls"];
		[colourFilter setDefaults];
		[colourFilter setValue: resultImage forKey: @"inputImage"];
		[colourFilter setValue: [NSNumber numberWithFloat: saturation]forKey: @"inputSaturation"];
		[colourFilter setValue: [NSNumber numberWithFloat: brightness]forKey: @"inputBrightness"];
		[colourFilter setValue: [NSNumber numberWithFloat: contrast]forKey: @"inputContrast"];
		resultImage = [colourFilter valueForKey: @"outputImage"];
	   }
	if (unsharpmaskRadius > 0.0 && unsharpmaskIntensity > 0.0)
	{
		CIFilter *unsharpmaskFilter = [CIFilter filterWithName:@"CIUnsharpMask"];
		[unsharpmaskFilter setDefaults];
		[unsharpmaskFilter setValue: resultImage forKey: @"inputImage"];
		[unsharpmaskFilter setValue: [NSNumber numberWithFloat: unsharpmaskRadius]forKey: @"inputRadius"];
		[unsharpmaskFilter setValue: [NSNumber numberWithFloat: unsharpmaskIntensity]forKey: @"inputIntensity"];
		resultImage = [unsharpmaskFilter valueForKey: @"outputImage"];
	}
	if (gaussianBlurRadius > 0.0)
	{
		CIFilter *filter = [CIFilter filterWithName:@"CIGaussianBlur"];
		[filter setDefaults];
		[filter setValue: resultImage forKey: @"inputImage"];
		[filter setValue: [NSNumber numberWithFloat: gaussianBlurRadius]forKey: @"inputRadius"];
		resultImage = [filter valueForKey: @"outputImage"];
	}
	if (!ciContext)
		ciContext = [[[NSGraphicsContext currentContext]CIContext]retain];
	[self allocSpareImage];
	[NSGraphicsContext saveGraphicsState];
	[spareImage lockFocus];
	NSRect nDestRect = NSMakeRect(0.0,0.0,[image size].width,[imageRep size].height);
    [resultImage drawInRect:nDestRect fromRect:nDestRect operation:NSCompositingOperationCopy fraction:1.0];
	[spareImage unlockFocus];
	[NSGraphicsContext restoreGraphicsState];
}

-(void)drawImageOverlaidWithColour:(NSColor*)col
{
	NSData *imData = [image TIFFRepresentation];
	NSBitmapImageRep *imageRep = [NSBitmapImageRep imageRepWithData:imData];
	CIImage *ciImage = [[[CIImage alloc]initWithBitmapImageRep:(NSBitmapImageRep*)imageRep]autorelease];
	CIImage *resultImage = ciImage;
	CIFilter *filter = [CIFilter filterWithName:@"OverlayFilter"];
	[filter setDefaults];
	[filter setValue: resultImage forKey: @"inputImage"];
	[filter setValue:[CIColor colorWithCGColor:[col CGColor]]forKey:@"colour"];
	resultImage = [filter valueForKey: @"outputImage"];
	if (!ciContext)
		ciContext = [[[NSGraphicsContext currentContext]CIContext]retain];
	[self allocSpareImage];
	[NSGraphicsContext saveGraphicsState];
	[spareImage lockFocus];
	NSRect nDestRect = NSMakeRect(0.0,0.0,[image size].width,[imageRep size].height);
    [resultImage drawInRect:nDestRect fromRect:nDestRect operation:NSCompositingOperationCopy fraction:1.0];
	[spareImage unlockFocus];
	[NSGraphicsContext restoreGraphicsState];
}

-(void)computeHandlePoints
{
	NSRect r = frame;
	r.origin.x += [self bounds].origin.x;
	r.origin.y += [self bounds].origin.y;
	float x = r.origin.x;
	float y = r.origin.y;
	float incX = r.size.width / 2.0;
	float incY = r.size.height / 2.0;
	handlePoints[0].x = handlePoints[6].x = handlePoints[7].x = x;
	x += incX;
	handlePoints[1].x = handlePoints[5].x = x;
	x += incX;
	handlePoints[2].x = handlePoints[3].x = handlePoints[4].x = x;
	handlePoints[0].y = handlePoints[1].y = handlePoints[2].y = y;
	y += incY;
	handlePoints[3].y = handlePoints[7].y = y;
	y += incY;
	handlePoints[4].y = handlePoints[5].y = handlePoints[6].y = y;
}

- (NSBezierPath *)bezierPath
{
    NSRect r = frame;
	r.origin.x += [self bounds].origin.x;
	r.origin.y += [self bounds].origin.y;
	return [NSBezierPath bezierPathWithRect:r];
}

-(NSRect)transformedBounds
{
	return [[self transformedBezierPath]bounds];
}


-(BOOL)drawStrokeWithoutTransform
{
	return YES;
}

- (void)drawObject:(NSRect)aRect view:(GraphicView*)gView options:(NSMutableDictionary*)options
{
	[NSGraphicsContext saveGraphicsState];
	[[NSBezierPath bezierPathWithRect:NSOffsetRect(frame,bounds.origin.x,bounds.origin.y)]addClip];
	if ([self hasAFilter])
	{
		[self drawFilteredImage];
		[[spareImage bestRepresentationForRect:bounds context:nil hints:nil]drawInRect:bounds];
	}
    else if (fill && [fill colour])
    {
		[self drawImageOverlaidWithColour:[fill colour]];
		[[spareImage bestRepresentationForRect:bounds context:nil hints:nil]drawInRect:bounds];
    }
	else
	{
		NSImageRep *rep = [[[image bestRepresentationForRect:bounds context:nil hints:nil]copy]autorelease];
		NSPoint pt = [self bounds].origin;
		[rep drawAtPoint:pt];
	}
	[NSGraphicsContext restoreGraphicsState];
}

- (void)startBoundsManipulation
   {
    [super startBoundsManipulation];
	originalCentrePoint = rotationPoint;
    originalFrame = frame;
	originalXScale = xScale;
	originalYScale = yScale;
   }

-(NSAffineTransform*)computeFrameTransform
{
	NSAffineTransform *t = [NSAffineTransform transform];
	[t translateXBy:[self bounds].origin.x yBy:[self bounds].origin.y];
	[t translateXBy:-rotationPoint.x yBy:-rotationPoint.y];
	NSAffineTransform *t2 = [NSAffineTransform transform];
	[t2 scaleXBy:xScale yBy:yScale];
	[t appendTransform:t2];
	t2 = [NSAffineTransform transform];
	[t2 rotateByDegrees:rotation];
	[t appendTransform:t2];
	t2 = [NSAffineTransform transform];
	[t2 translateXBy:rotationPoint.x yBy:rotationPoint.y];
	[t appendTransform:t2];
	return t;
}

-(BOOL)setGraphicFrameTo:(NSRect)newFrame from:(NSRect)oldFrame 
{
    if (NSEqualRects(newFrame, oldFrame))
		return NO;
	   {
		   [self invalidateGraphicSizeChanged:NO shapeChanged:NO redraw:NO notify:NO];
		   if (!manipulatingBounds)
			   [[[self undoManager] prepareWithInvocationTarget:self] setGraphicFrameTo:oldFrame from:newFrame];
		   frame = newFrame;
		   if (newFrame.size.width != oldFrame.size.width || newFrame.size.height != oldFrame.size.height)
		   {
			   [self invalidateGraphicSizeChanged:YES shapeChanged:YES redraw:YES notify:NO];
			   [self invalidateConnectors];
		   }
		   else
			   [self invalidateGraphicSizeChanged:NO shapeChanged:NO redraw:NO notify:NO];
       }
	   return YES;
}

- (void)stopBoundsManipulation
{
    if (manipulatingBounds)
	   {
		manipulatingBounds = NO;
        if (!NSEqualRects(originalBounds,bounds))
		{
            [self setGraphicBoundsTo:bounds from:originalBounds];
		}
		else
			if (!NSEqualRects(originalFrame,frame))
			{
				[self setGraphicFrameTo:frame from:originalFrame];
			}
       }
}

#define MAGPROP(a) ((a) < 1.0)?(1.0/(a)):(a)

-(NSRect)constrainFrame:(NSRect)newFrame usingKnob:(NSInteger)knob
{
	if (originalFrame.size.height == 0.0 || originalFrame.size.width == 0.0)
		return newFrame;
	float newX = newFrame.origin.x,
	newY = newFrame.origin.y,
	newWidth = newFrame.size.width,
	newHeight = newFrame.size.height;
	float xProportion = newWidth / originalFrame.size.width;
	float yProportion = newHeight / originalFrame.size.height;
	float xx = MAGPROP(xProportion);
	float yy = MAGPROP(yProportion);
	//	if (MAGPROP(yProportion) > MAGPROP(xProportion))
    if ((knob == UpperMiddleKnob) || (knob == LowerMiddleKnob))
    {
        newWidth = originalFrame.size.width * yProportion;
        float cx = CGRectGetMidX(newFrame);
        newX = cx - newWidth / 2;
        if (lowerKnob(knob))
            newY -=(newHeight - newFrame.size.height);
    }
    else if ((knob == MiddleLeftKnob) || (knob == MiddleRightKnob))
    {
        newHeight = originalFrame.size.height * xProportion;
        float cy = CGRectGetMidY(newFrame);
        newY = cy - newHeight / 2;
        if (leftKnob(knob))
            newX -=(newWidth - newFrame.size.width);
    }
	else if (yy > xx)
	{
		newWidth = originalFrame.size.width * yProportion;
		if (leftKnob(knob))
			newX -=(newWidth - newFrame.size.width);
	}
	else
	{
		newHeight = originalFrame.size.height * xProportion;
		if (lowerKnob(knob))
			newY -=(newHeight - newFrame.size.height);
	}
	return NSMakeRect(newX,newY,newWidth,newHeight);
}

-(void)permanentScale:(float)sc transform:(NSAffineTransform*)t
{
	NSPoint oldCentrePoint = [self centrePoint],newCentrePoint = oldCentrePoint;
	newCentrePoint.x *= sc;
	newCentrePoint.y *= sc;
	NSRect b = bounds;
	b.origin.x = newCentrePoint.x - (bounds.size.width / 2.0);
	b.origin.y = newCentrePoint.y - (bounds.size.height / 2.0);
//	rotationPoint = [self centrePoint];
	[self setGraphicBoundsTo:b from:bounds];
	[self setGraphicXScale:xScale * sc notify:NO];
	[self setGraphicYScale:yScale * sc notify:NO];
}

- (KnobDescriptor)resizeFrameByMovingKnob:(KnobDescriptor)kd toPoint:(NSPoint)point event:(NSEvent *)theEvent constrain:(BOOL)constrain
{
	NSAffineTransform *aff = [NSAffineTransform transformWithTranslateXBy:-rotationPoint.x yBy:-rotationPoint.y];
	[aff appendTransform:[NSAffineTransform transformWithScaleXBy:xScale yBy:yScale]];
	[aff appendTransform:[NSAffineTransform transformWithRotationByDegrees:rotation]];
	[aff appendTransform:[NSAffineTransform transformWithTranslateXBy:rotationPoint.x yBy:rotationPoint.y]];
	[aff invert];
	point = [aff transformPoint:point];
    BOOL altDown = (([theEvent modifierFlags] & NSEventModifierFlagOption)!=0);
	point.x -= [self bounds].origin.x;
	point.y -= [self bounds].origin.y;
	if (point.x < 0.0)
		point.x = 0;
	if (point.x > [self bounds].size.width)
		point.x = [self bounds].size.width;
	if (point.y < 0.0)
		point.y = 0;
	if (point.y > [self bounds].size.height)
		point.y = [self bounds].size.height;
    if (leftKnob(kd.knob))
	{
		if (point.x >= 0.0 && point.x < [self bounds].size.width)
		{
			float widthChange = point.x - NSMinX(frame);
			frame.origin.x = point.x;
			frame.size.width -= widthChange;
			if (altDown)
				frame.size.width -= widthChange;
		}
	}
	else if (rightKnob(kd.knob))
   {
		if (point.x >= 0.0 && point.x < [self bounds].size.width)
		{
			float widthChange = NSMaxX(frame) - point.x;
			frame.size.width = point.x - frame.origin.x;
			if (altDown)
				frame.size.width -= widthChange;
		}
    }
    if (upperKnob(kd.knob))
	{
		if (point.y >= 0.0 && point.y < [self bounds].size.height)
		{
			float heightChange = NSMaxY(frame) - point.y;
			frame.size.height = point.y - frame.origin.y;
			if (altDown)
				frame.size.height -= heightChange;
		}
	}
	else if (lowerKnob(kd.knob))
	{
		if (point.y >= 0.0 && point.y < [self bounds].size.height)
		{
			float heightChange = point.y - NSMinY(frame);
			frame.origin.y = point.y;
			frame.size.height -= heightChange;
			if (altDown)
				frame.size.height -= heightChange;
		}
	}
	if (constrain)
		frame = [self constrainFrame:frame usingKnob:kd.knob];
	return kd;
}

- (KnobDescriptor)resizeByMovingKnob:(KnobDescriptor)kd toPoint:(NSPoint)point event:(NSEvent *)theEvent constrain:(BOOL)constrain aroundCentre:(BOOL)aroundCentre
{
    if ([theEvent type] == NSEventTypeFlagsChanged)
	{
		bounds = originalBounds;
		frame = originalFrame;
		[self setGraphicXScale:originalXScale yScale:originalYScale undo:NO];
	}
    BOOL commandDown = (([theEvent modifierFlags] & NSEventModifierFlagCommand)!=0);
	if (commandDown)
		return [self resizeFrameByMovingKnob:kd toPoint:point event:theEvent constrain:(BOOL)constrain];
	if (rotation != 0.0)
	   {
		NSAffineTransform *aff = [NSAffineTransform transformWithTranslateXBy:-rotationPoint.x yBy:-rotationPoint.y];
		[aff appendTransform:[NSAffineTransform transformWithRotationByDegrees:rotation]];
		[aff appendTransform:[NSAffineTransform transformWithTranslateXBy:rotationPoint.x yBy:rotationPoint.y]];
		[aff invert];
		point = [aff transformPoint:point];
	   }
    BOOL altDown = (([theEvent modifierFlags] & NSEventModifierFlagOption)!=0);
    NSRect tBounds = [self bounds],tFrame = frame;
	tFrame.origin.x += tBounds.origin.x;
	tFrame.origin.y += tBounds.origin.y;
	float xRatio = (NSMidX(tBounds) - NSMinX(tFrame)) / tFrame.size.width;
	float yRatio = (NSMidY(tBounds) - NSMinY(tFrame)) / tFrame.size.height;
	if (transform)
	   {
		NSPoint cp = [self centrePoint];
		tBounds = [[NSAffineTransform transformWithTranslateXBy:-cp.x yBy:-cp.y] transformRect:tBounds];
		tBounds = [[NSAffineTransform transformWithScaleXBy:xScale yBy:yScale] transformRect:tBounds];
		tBounds = [[NSAffineTransform transformWithTranslateXBy:cp.x yBy:cp.y] transformRect:tBounds];
//		tFrame = [[NSAffineTransform transformWithTranslateXBy:-(cp.x - NSMinX(bounds)) yBy:-(cp.y - NSMinY(bounds))] transformRect:tFrame];
		tFrame = [[NSAffineTransform transformWithTranslateXBy:-cp.x yBy:-cp.y] transformRect:tFrame];
		tFrame = [[NSAffineTransform transformWithScaleXBy:xScale yBy:yScale] transformRect:tFrame];
		tFrame = [[NSAffineTransform transformWithTranslateXBy:cp.x yBy:cp.y] transformRect:tFrame];
	   }
    if (leftKnob(kd.knob))
	   {
		float widthChange = point.x - NSMinX(tFrame);
        tFrame.origin.x = point.x;
        tFrame.size.width -= widthChange;
		if (altDown)
			tFrame.size.width -= widthChange;
	   }
	else if (rightKnob(kd.knob))
	   {
		float widthChange = NSMaxX(tFrame) - point.x;
        tFrame.size.width = point.x - tFrame.origin.x;
		if (altDown)
			tFrame.size.width -= widthChange;
       }
    if (tFrame.size.width < 0.0)
	   {
        kd.knob = [ACSDGraphic flipKnob:kd.knob horizontal:YES];
        tFrame.size.width = -tFrame.size.width;
        tFrame.origin.x -= tFrame.size.width;
		[self flipHorizontally];
       }
    if (upperKnob(kd.knob))
	   {
		float heightChange = NSMaxY(tFrame) - point.y;
        tFrame.size.height = point.y - tFrame.origin.y;
		if (altDown)
			tFrame.size.height -= heightChange;
       }
	else if (lowerKnob(kd.knob))
	   {
		float heightChange = point.y - NSMinY(tFrame);
        tFrame.origin.y = point.y;
        tFrame.size.height -= heightChange;
		if (altDown)
			tFrame.size.height -= heightChange;
       }
    if (tFrame.size.height < 0.0)
	   {
        kd.knob = [ACSDGraphic flipKnob:kd.knob horizontal:NO];
        tFrame.size.height = -tFrame.size.height;
        tFrame.origin.y -= tFrame.size.height;
        [self flipVertically];
       }
	if (constrain)
		tFrame = [self constrainFrame:tFrame usingKnob:kd.knob];
	float newX = (xRatio * tFrame.size.width) + NSMinX(tFrame);
	float newY = (yRatio * tFrame.size.height) + NSMinY(tFrame);
	float dx = newX - NSMidX(bounds);
	float dy = newY - NSMidY(bounds);
	bounds.origin.x += dx;
	bounds.origin.y += dy;
	[self setGraphicXScale:tFrame.size.width/frame.size.width yScale:tFrame.size.height/frame.size.height undo:YES];
    return kd;
}
/*
- (BOOL)trackKnob:(KnobDescriptor&)kd withEvent:(NSEvent *)theEvent inView:(GraphicView*)view selectedGraphics:(NSSet*)selectedGraphics
{
    NSPoint point = [view convertPoint:[theEvent locationInWindow] fromView:nil];
	NSPoint origPoint = point;
	[[NSNotificationCenter defaultCenter] postNotificationName:ACSDShowCoordinatesNotification object:self
													  userInfo:[NSDictionary dictionaryWithObject:[NSNumber numberWithBool:YES] forKey:@"vis"]];
	BOOL can = NO,periodicStarted=NO;
    while (1)
	   {
		if (can = opCancelled)
		{
			[self setOpCancelled:NO];
			break;
		}
        theEvent = [[view window] nextEventMatchingMask:(NSLeftMouseDraggedMask | NSLeftMouseUpMask | NSFlagsChangedMask | NSKeyDownMask | NSPeriodicMask)];
		if ([theEvent type] == NSKeyDown)
		{
			[view keyDown:theEvent];
			continue;
		}
        if ([theEvent type] == NSPeriodic)
		{
			[view scrollRectToVisible:RectFromPoint(point,30.0,[view magnification])];
			point = [view convertPoint:[[view window] mouseLocationOutsideOfEventStream] fromView:nil];
		}
		else
		{
			if ([theEvent type] != NSFlagsChanged)
//			{
//				bounds = originalBounds;
//				frame = originalFrame;
//				[self setGraphicXScale:originalXScale yScale:originalYScale undo:NO];
//			}
//			else
				point = [view convertPoint:[theEvent locationInWindow] fromView:nil];
		}
		point.y = [view adjustHSmartGuide:point.y tool:1];
		point.x = [view adjustVSmartGuide:point.x tool:1];
		[self invalidateGraphicSizeChanged:NO shapeChanged:NO redraw:NO notify:NO];
		   kd = [self resizeByMovingKnob:kd toPoint:point event:theEvent constrain:(([theEvent modifierFlags] & NSShiftKeyMask)!=0)
							aroundCentre:(([theEvent modifierFlags] & NSAlternateKeyMask)!=0)];
		[self otherTrackKnobAdjustments];
		[self invalidateGraphicSizeChanged:YES shapeChanged:YES redraw:YES notify:NO];
		NSRect r = [self bounds];
		[self postChangeOfBounds];
		[ACSDGraphic postChangeFromAnchorPoint:origPoint toPoint:point];
		[self otherTrackKnobNotifiesView:view];
		periodicStarted = [view scrollIfNecessaryPoint:point periodicStarted:periodicStarted];
        if ([theEvent type] == NSLeftMouseUp)
            break;
       }
	if (periodicStarted)
		[NSEvent stopPeriodicEvents];
	[self invalidateGraphicSizeChanged:YES shapeChanged:YES redraw:YES notify:YES];
	[[NSNotificationCenter defaultCenter] postNotificationName:ACSDShowCoordinatesNotification object:self
													  userInfo:[NSDictionary dictionaryWithObject:[NSNumber numberWithBool:NO] forKey:@"vis"]];
    [[self undoManager] setActionName:@"Resize"];
	return !can;
}*/


-(float)alphaAtPoint:(NSPoint)p
{
	unsigned char pixel[1] = {0};
	CGContextRef context = CGBitmapContextCreate(pixel, 1, 1, 8, 1, NULL,kCGImageAlphaOnly);
//	CGContextTranslateCTM(context, -p.x, -p.y);
//	[self renderInContext:context];
	[NSGraphicsContext setCurrentContext:[NSGraphicsContext graphicsContextWithGraphicsPort:context flipped:NO]];
	NSAffineTransform *t = [NSAffineTransform transformWithTranslateXBy:-p.x yBy:-p.y];
	if (transform)
	{
		//[transform concat];
		//[t prependTransform:transform];
	}
	[t concat];
	//[[NSAffineTransform transformWithTranslateXBy:-p.x yBy:-p.y]concat];
	[self drawObject:NSZeroRect view:nil options:nil];
	CGContextRelease(context);	
	return pixel[0]/255.0;
}

- (BOOL)hitTest:(NSPoint)point isSelected:(BOOL)isSelected view:(GraphicView*)gView
{
	if (isSelected && ([self knobUnderPoint:point view:gView].knob != NoKnob))
        return YES;
	if (transform)
		point = [self invertPoint:point];
	if (!NSPointInRect(point, [self bounds]))
		return NO;
	float f = [self alphaAtPoint:point];
	return f > 0.0;
}

-(BOOL)isOrContainsImage
   {
	return YES;
   }

-(NSImage*)scaledImage
{
	NSRect db = NSIntegralRect([self displayBounds]);
	NSImage *im = [[[NSImage alloc]initWithSize:db.size]autorelease];
	NSAffineTransform *t = [NSAffineTransform transformWithTranslateXBy:-rotationPoint.x yBy:-rotationPoint.y];
	[t appendTransform:[NSAffineTransform transformWithScaleXBy:xScale yBy:yScale]];
	[t appendTransform:[NSAffineTransform transformWithRotationByDegrees:rotation]];
	[t appendTransform:[NSAffineTransform transformWithTranslateXBy:rotationPoint.x - db.origin.x yBy:rotationPoint.y - db.origin.y]];
	[im lockFocus];
	[[shadowType itsShadow]set];
	[t concat];
    CGContextSetInterpolationQuality([[NSGraphicsContext currentContext] CGContext],kCGInterpolationHigh);
	if ([self hasAFilter])
	   {
		[self drawFilteredImage];
		[[spareImage bestRepresentationForRect:bounds context:nil hints:nil]drawInRect:bounds];
	   }
	else
		[[image bestRepresentationForRect:bounds context:nil hints:nil]drawInRect:bounds];
	[im unlockFocus];
	return im;
}

-(BOOL)processClickThrough:(NSMutableDictionary*)options size:(NSSize*)finalSize
   {
	NSMutableDictionary *htmlSettings = [options objectForKey:@"htmlSettings"];
	if (![[htmlSettings objectForKey:@"clickThrough"]boolValue])
		return NO;
	NSImage *im;
	int clickThroughLimitType = [[htmlSettings objectForKey:@"clickThroughLimitType"]intValue];
	BOOL isFiltered = [self hasAFilter];
	if (clickThroughLimitType == PICS_ORIGINAL && !isFiltered)
		im = image;
	else
	   {
		NSImageRep *oldRep = [image bestRepresentationForRect:bounds context:nil hints:nil];		
		NSSize sz = NSMakeSize([oldRep pixelsWide],[oldRep pixelsHigh]);
		float scale = 1.0;
		float clickThroughLimit = [[htmlSettings objectForKey:@"clickThroughLimit"]floatValue];
		if (clickThroughLimit < 100)
			clickThroughLimit = 100;
		if (clickThroughLimitType == PICS_MAX_DIM)
		   {
			float m = fmax(sz.width,sz.height);
			scale = fmin(1.0,clickThroughLimit / m);
		   }
		else if (clickThroughLimitType == PICS_MAX_AREA)
		   {
			float a = sz.width * sz.height;
			scale = fmin(1.0,clickThroughLimit / a);
		   }
		if (scale == 1.0 && !isFiltered)
			im = image;
		else
		   {
			NSSize destSz = sz;
			destSz.width *= scale;
			destSz.height *= scale;
			NSImage *destImage = [[[NSImage alloc]initWithSize:destSz]autorelease];
			if ([oldRep isKindOfClass:[NSBitmapImageRep class]])
			{
				NSBitmapImageRep *oldBitmapRep = (NSBitmapImageRep*)oldRep;
				NSBitmapImageRep *newBitmapRep = [[NSBitmapImageRep alloc]initWithBitmapDataPlanes:nil pixelsWide:destSz.width pixelsHigh:destSz.height 
																					 bitsPerSample:[oldBitmapRep bitsPerSample]samplesPerPixel:[oldBitmapRep samplesPerPixel]hasAlpha:[oldBitmapRep hasAlpha]
																						  isPlanar:[oldBitmapRep isPlanar]colorSpaceName:[oldBitmapRep colorSpaceName]
																					   bytesPerRow:destSz.width*[oldBitmapRep samplesPerPixel] bitsPerPixel:[oldBitmapRep bitsPerPixel]];
				[newBitmapRep setSize:NSMakeSize([newBitmapRep pixelsWide],[newBitmapRep pixelsHigh])];
				[destImage addRepresentation:[newBitmapRep autorelease]];
			}
			NSRect sourceRect,destRect;
			sourceRect.origin = destRect.origin = NSMakePoint(0.0,0.0);
			sourceRect.size = sz;
			destRect.size = destSz;
			[destImage lockFocus];
			if (isFiltered)
			   {
				[self drawFilteredImage];
				[[spareImage bestRepresentationForRect:bounds context:nil hints:nil]drawInRect:destRect];
			   }
			else
				[[image bestRepresentationForRect:bounds context:nil hints:nil]drawInRect:destRect];
			[destImage unlockFocus];
			im = destImage;
		   }
	   }
	NSImageRep *rep = [im bestRepresentationForRect:bounds context:nil hints:nil];
	*finalSize = NSMakeSize([rep pixelsWide],[rep pixelsHigh]);
	NSData *imData = [im TIFFRepresentation];
	CGImageSourceRef cgImageSource = CGImageSourceCreateWithData((CFDataRef)imData,NULL);
	CGImageRef cgImageref = CGImageSourceCreateImageAtIndex(cgImageSource,0,NULL);
	CFRelease(cgImageSource);
	NSString *fileName = [imageNameForOptions(options) stringByAppendingPathExtension:@"jpg"];
	NSString *pathName = [options objectForKey:@"largeimages"];
	NSError *err;
	if (![[NSFileManager defaultManager]fileExistsAtPath:pathName])
		if (![[NSFileManager defaultManager] createDirectoryAtPath:pathName withIntermediateDirectories:NO attributes:nil error:&err])
        {
            CGImageRelease(cgImageref);
			return show_error_alert([NSString stringWithFormat:@"Error creating directory: %@; %@",pathName,[err localizedDescription]]);
        }
	pathName = [pathName stringByAppendingPathComponent:fileName];
	NSURL *url = [NSURL fileURLWithPath:pathName];
	CGImageDestinationRef cgImageDest = CGImageDestinationCreateWithURL((CFURLRef)url,kUTTypeJPEG,1,NULL);
	if (!cgImageDest)
		return show_error_alert([NSString stringWithFormat:@"Error creating image destination: %@",[url description]]);
	CGImageDestinationAddImage(cgImageDest,cgImageref,NULL);
	CGImageDestinationFinalize(cgImageDest);
	CFRelease(cgImageDest);
	CGImageRelease(cgImageref);
	return YES;
   }	

-(ACSDPath*)wholeOutline
   {
	return [self wholeFilledRect];
   }

-(NSString*)xmlAttributes:(NSMutableDictionary*)options
{
	NSString *source;
	if (self.sourcePath)
		source = [[self.sourcePath lastPathComponent]stringByDeletingPathExtension];
	else
		source = self.name;
	return [[super xmlAttributes:options]stringByAppendingFormat:@" source=\"%@\"",source];
}

CGContextRef CreateArgbContext(int width,int height)
{
	int bytesPerRow = (width * 4 + 15) & ~15;
	CGColorSpaceRef space = CGColorSpaceCreateWithName(kCGColorSpaceGenericRGB);
	CGContextRef context = CGBitmapContextCreate(NULL,width,height,8,bytesPerRow,space,kCGImageAlphaPremultipliedFirst);
	CFRelease(space);
	return context;
}

-(void)postHistChange
{
	[[NSNotificationCenter defaultCenter] postNotificationName:ACSDHistogramDidChangeNotification object:self
													  userInfo:nil];	
}

-(void)doHistogramWithContext:(CGContextRef)context width:(int)width height:(int)height
{
	vImagePixelCount *hist[4];
	for (int i = 0;i < 4;i++)
		hist[i] = (vImagePixelCount*)malloc(256 * sizeof(vImagePixelCount));
	vImage_Buffer srcBuffer;
	srcBuffer.data = CGBitmapContextGetData(context);
	srcBuffer.height = height;
	srcBuffer.width = width;
	srcBuffer.rowBytes = CGBitmapContextGetBytesPerRow(context);
	vImageHistogramCalculation_ARGB8888(&srcBuffer,hist,0);
	CGContextRelease(context);
	if (histogram)
		free(histogram);
	histogram = (float*)malloc(256 * sizeof(float));
	for (int i = 0;i < 256;i++)
		histogram[i] = (hist[1][i] + hist[2][i] + hist[3][i] + 1)/* / totalPixels*/;
	for (int i = 0;i < 4;i++)
		free(hist[i]);
	[self performSelectorOnMainThread:@selector(postHistChange) withObject:nil waitUntilDone:NO];
}

-(void)createHistogram
{
	NSSize sz = [image size];
	CGContextRef context = CreateArgbContext(sz.width, sz.height);
	[NSGraphicsContext saveGraphicsState];
	[NSGraphicsContext setCurrentContext:[NSGraphicsContext graphicsContextWithGraphicsPort:context flipped:NO]];
    [image drawAtPoint:NSMakePoint(0.0,0.0) fromRect:NSMakeRect(0.0,0.0,sz.width,sz.height) operation:NSCompositingOperationSourceOver fraction:1.0];
	[NSGraphicsContext restoreGraphicsState];
	dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
		[self doHistogramWithContext:context width:sz.width height:sz.height];
	});
}

-(float*)histogram
{
	if (histogram == nil)
		[self createHistogram];
	return histogram;
}

-(void)writeSVGDataWithRef:(SVGWriter*)svgWriter
{
    NSString *sourceName = [self.sourcePath lastPathComponent];
    if (svgWriter.sources[sourceName] == nil)
    {
        [[svgWriter defs]appendFormat:@"\t<image id=\"%@\" width=\"%g\" height=\"%g\" xlink:href=\"%@\"/>\n",sourceName,bounds.size.width,bounds.size.height,[self.sourcePath lastPathComponent]];
        svgWriter.sources[sourceName] = @"";
    }

    NSRect r = [self transformedStrictBounds];
    [[svgWriter contents] appendFormat:@"\t<use id=\"%@\" x=\"%g\" y=\"%g\" width=\"%g\" height=\"%g\" xlink:href=\"#%@\" %@",self.name,r.origin.x,r.origin.y,r.size.width,r.size.height,sourceName,[self svgTransform:svgWriter]];
    if (self.hidden)
        [[svgWriter contents] appendString:@" visibility=\"hidden\" "];
    [[svgWriter contents] appendString:@"/>\n"];
}

-(void)writeSVGData:(SVGWriter*)svgWriter
{
    [self writeSVGDataWithRef:svgWriter];
}

@end
