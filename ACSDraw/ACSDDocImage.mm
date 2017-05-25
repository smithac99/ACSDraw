//
//  ACSDDocImage.m
//  ACSDraw
//
//  Created by alan on 09/01/15.
//
//

#import "ACSDDocImage.h"
#import "ACSDLayer.h"
#import "ACSDPage.h"
#import "AffineTransformAdditions.h"
#import "SVGWriter.h"

@implementation ACSDDocImage

-(id)initWithName:(NSString*)n fill:(ACSDFill*)f stroke:(ACSDStroke*)str rect:(NSRect)r layer:(ACSDLayer*)l drawDoc:(ACSDrawDocument*)drawDoc
{
	if ((self = [super initWithName:n fill:f stroke:str rect:r layer:l image:nil]))
	{
		self.drawDoc = drawDoc;
		frame.origin = NSMakePoint(0.0,0.0);
		frame.size = self.drawDoc.documentSize;
		exposure = 0.0;
		saturation = 1.0;
		brightness = 0.0;
		contrast = 1.0;
	}
	return self;
}

-(void)dealloc
{
	self.drawDoc = nil;
	[super dealloc];
}

- (void) encodeWithCoder:(NSCoder*)coder
{
	[super encodeWithCoder:coder];
	[coder encodeObject:[self.drawDoc dataOfType:@"acsd" error:nil] forKey:@"drawDoc"];
}

- (id) initWithCoder:(NSCoder*)coder
{
	self = [super initWithCoder:coder];
	NSData *d = [coder decodeObjectForKey:@"drawDoc"];
	ACSDrawDocument *adoc = [[[ACSDrawDocument alloc]init]autorelease];
	[adoc readFromData:d ofType:@"acsd" error:nil];
	self.drawDoc = adoc;
	return self;
}

- (id)copyWithZone:(NSZone *)zone
{
	ACSDDocImage *obj = [super copyWithZone:zone];
	obj.drawDoc = self.drawDoc;
	[obj invalidateGraphicSizeChanged:YES shapeChanged:NO redraw:YES notify:NO];
	return obj;
}

-(NSRect)imageRect
{
	NSSize sz = self.drawDoc.documentSize;
	return NSMakeRect(0.0,0.0,sz.width,sz.height);
}

- (void)drawObject:(NSRect)aRect view:(GraphicView*)gView options:(NSMutableDictionary*)options
{
	[NSGraphicsContext saveGraphicsState];
	[[NSBezierPath bezierPathWithRect:NSOffsetRect(frame,bounds.origin.x,bounds.origin.y)]addClip];
	NSPoint pt = [self bounds].origin;
	[[NSAffineTransform transformWithTranslateXBy:pt.x yBy:pt.y]concat];
    if (fill)
    {
        options[@"subfill"] = fill;
    }
	for (ACSDPage *page in self.drawDoc.pages)
	{
		for (ACSDLayer *l in [[page layers]reverseObjectEnumerator])
		{
			if ([l visible] && !([l isGuideLayer]))
			{
				for (ACSDGraphic *curGraphic in [l graphics])
				{
					//[curGraphic drawObjectWithEffect:aRect inView:nil useCache:NO options:options];
					[curGraphic draw:aRect inView:nil selected:NO isGuide:NO cacheDrawing:NO options:options];
				}
			}
		}
	}
    [options removeObjectForKey:@"subfill"];
	[NSGraphicsContext restoreGraphicsState];
}

-(BOOL)usuallyUsesCache
{
	return NO;
}

-(float*)histogram
{
	return NULL;
}

-(NSString*)xmlEventTypeName
{
	return @"vector";
}

-(void)writeSVGData:(SVGWriter*)svgWriter
{
	[[svgWriter contents] appendFormat:@"<g id=\"%@\" transform=\"translate(%g,%g)\"",self.name,bounds.origin.x,bounds.origin.y];
    if (self.hidden)
        [[svgWriter contents] appendString:@" visibility=\"hidden\" "];
    [[svgWriter contents]appendString:@" >\n"];
	NSArray *arr = [self.drawDoc svgBodyString];
	[[svgWriter defs]appendString:arr[0]];
	[[svgWriter contents] appendString:arr[1]];
	[[svgWriter contents] appendString:@"</g>\n"];
}
@end
