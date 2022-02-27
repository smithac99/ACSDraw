//
//  ACSDSVGImage.m
//  ACSDraw
//
//  Created by alan on 11/02/22.
//

#import "ACSDSVGImage.h"
#import "ACSDLayer.h"
#import "ACSDPage.h"
#import "AffineTransformAdditions.h"
#import "SVGWriter.h"
#import "ACSDPrefsController.h"
#import "XMLManager.h"
#import "SVGDocument.h"
#import "ACSDGradient.h"
#import "GradientElement.h"

@implementation ACSDSVGImage

-(id)initWithName:(NSString*)n fill:(ACSDFill*)f stroke:(ACSDStroke*)str rect:(NSRect)r layer:(ACSDLayer*)l document:(SVGDocument*)svgDoc
{
	if ((self = [super initWithName:n fill:f stroke:str rect:r layer:l image:nil]))
	{
		self.svgDocument = svgDoc;
		NSRect rect = self.svgDocument.svgNode.viewBox;
		frame.origin = NSMakePoint(0.0,0.0);
		frame.size = rect.size;
	}
	return self;
}

- (void)encodeWithCoder:(NSCoder*)coder
{
	[super encodeWithCoder:coder];
	[coder encodeObject:self.svgDocument.svgData forKey:@"svgData"];
}

- (id) initWithCoder:(NSCoder*)coder
{
	self = [super initWithCoder:coder];
	NSData *svgData = [coder decodeObjectForKey:@"svgData"];
	XMLManager *xmlMan = [[XMLManager alloc]init];
	XMLNode *xmlRoot = [xmlMan parseData:svgData];
	self.svgDocument = [[SVGDocument alloc]initWithXMLNode:xmlRoot];
	[self setUpSubstitutionColours:[self fill]];
	return self;
}

- (id)copyWithZone:(NSZone *)zone
{
	ACSDSVGImage *obj = [super copyWithZone:zone];
	NSData *svgData = self.svgDocument.svgData;
	obj.svgDocument = [[SVGDocument alloc]initWithData:svgData];
	[obj invalidateGraphicSizeChanged:YES shapeChanged:NO redraw:YES notify:NO];
	return obj;
}

-(NSRect)imageRect
{
	NSSize sz = self.svgDocument.svgNode.viewBox.size;
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
	[self setUpSubstitutionColours:fill];
	[self.svgDocument drawInRect:[self bounds]];
	
	[options removeObjectForKey:@"subfill"];

	[NSGraphicsContext restoreGraphicsState];
}

-(void)setUpSubstitutionColours:(ACSDFill*)fill
{
	if (fill == nil)
	{
		_svgDocument.substitutionColours = nil;
		return;
	}
	if ([fill isMemberOfClass:[ACSDFill class]])
	{
		NSColor *col = [fill colour];
		if (col)
			_svgDocument.substitutionColours = col;
		else
			_svgDocument.substitutionColours = nil;
	}
	else if ([fill isMemberOfClass:[ACSDGradient class]])
	{
		NSMutableArray *cols = [NSMutableArray array];
		NSArray<GradientElement*>*ges = [((ACSDGradient*)fill) gradientElements];
		for (GradientElement *ge in ges)
		{
			[cols addObject:[ge colour]];
		}
		_svgDocument.substitutionColours = cols;
	}}

-(void)setFill:(ACSDFill*)fill
{
	[super setFill:fill];
	[self setUpSubstitutionColours:fill];
}
@end
