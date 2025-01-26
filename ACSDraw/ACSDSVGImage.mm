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
	[coder encodeObject:self.svgDocument.svgData forKey:@"ACSDSVGImage_svgData"];
}

- (id) initWithCoder:(NSCoder*)coder
{
	self = [super initWithCoder:coder];
	NSData *svgData = [coder decodeObjectOfClass:[NSData class] forKey:@"ACSDSVGImage_svgData"];
	self.svgDocument = [[SVGDocument alloc]initWithData:svgData];
	[self setUpSubstitutionColours:[self fill]];
	return self;
}

+(BOOL)supportsSecureCoding
{
    return YES;
}
- (id)copyWithZone:(NSZone *)zone
{
	ACSDSVGImage *obj = [super copyWithZone:zone];
	NSData *svgData = self.svgDocument.svgData;
	obj.svgDocument = [[SVGDocument alloc]initWithData:svgData];
	[obj invalidateGraphicSizeChanged:YES shapeChanged:NO redraw:YES notify:NO];
	return obj;
}

-(NSString*)xmlEventTypeName
{
    return @"vector";
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
	else if ([fill isKindOfClass:[ACSDGradient class]])
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

-(NSString*)svgStringFromData:(NSData*)svgData
{
    NSString *str = [[NSString alloc]initWithData:svgData encoding:NSUTF8StringEncoding];
    NSArray *arr = [str componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]];
    NSInteger i = 0;
    while (i < [arr count] && ![arr[i]rangeOfString:@"<svg"].length > 0)
        i++;
    arr = [arr subarrayWithRange:NSMakeRange(i, [arr count] - i)];
    return [arr componentsJoinedByString:@"\n"];
}

-(void)writeSVGDataInline:(SVGWriter*)svgWriter
{
    NSString *sourceName = [[self.sourcePath lastPathComponent]stringByDeletingPathExtension];
    if (svgWriter.sources[sourceName] == nil)
    {
        SVG_svg *svgNode = self.svgDocument.svgNode;
        [[svgWriter defs]appendFormat:@"\t<g id=\"%@\" width=\"%g\" height=\"%g\">\n",sourceName,svgNode.width,svgNode.height];
        [[svgWriter defs]appendString:[self svgStringFromData:self.svgDocument.svgData]];
        [[svgWriter defs]appendString:@"</g>\n"];
        svgWriter.sources[sourceName] = @"";
    }

    [[svgWriter contents] appendFormat:@"\t<use id=\"%@\" xlink:href=\"#%@\" %@",self.name,sourceName,[self svgTransform:svgWriter]];
    if (self.hidden)
        [[svgWriter contents] appendString:@" visibility=\"hidden\" "];
    [[svgWriter contents] appendString:@"/>\n"];
}

-(NSString*)svgTransform:(SVGWriter*)svgWriter
{
    NSMutableString *mstr = [NSMutableString string];
    NSPoint pt = bounds.origin;
    if (svgWriter.shouldInvertSVGCoords)
    {
        pt = NSMakePoint(pt.x, NSMaxY(bounds));
        pt = [svgWriter.inversionTransform transformPoint:pt];
    }
    [mstr appendFormat:@"translate(%g,%g)",pt.x,pt.y];
    if (self.rotation != 0.0 || self.xScale != 1.0 || self.yScale != 1.0)
    {
        float h2 = bounds.size.height / 2.0;
        float w2 = bounds.size.width / 2.0;
        [mstr appendFormat:@" translate(%g,%g)",w2,h2];
        if (self.rotation != 0.0)
        {
            float rot = self.rotation;
            if (svgWriter.shouldInvertSVGCoords)
                rot = -self.rotation;
            [mstr appendFormat:@" rotate(%g)",rot];
        }
        if (self.xScale != 1.0 || self.yScale != 1.0)
            [mstr appendFormat:@" scale(%g %g)",self.xScale,self.yScale];
        [mstr appendFormat:@" translate(%g,%g)",-w2,-h2];
    }
    if ([mstr length] > 0)
    {
        mstr = [[NSMutableString alloc]initWithString:[NSString stringWithFormat:@" transform=\"%@\"",mstr]];
    }
    return mstr;
}

-(void)writeSVGDataWithRef:(SVGWriter*)svgWriter
{
    NSString *sourceName = [[self.sourcePath lastPathComponent]stringByDeletingPathExtension];
    if (svgWriter.sources[sourceName] == nil)
    {
        [[svgWriter defs]appendFormat:@"\t<image id=\"%@\" width=\"%g\" height=\"%g\" xlink:href=\"%@\"/>\n",sourceName,bounds.size.width,bounds.size.height,[self.sourcePath lastPathComponent]];
        svgWriter.sources[sourceName] = @"";
    }

    [[svgWriter contents] appendFormat:@"\t<use id=\"%@\" xlink:href=\"#%@\" %@",self.name,sourceName,[self svgTransform:svgWriter]];
    if (self.hidden)
        [[svgWriter contents] appendString:@" visibility=\"hidden\" "];
    [[svgWriter contents] appendString:@"/>\n"];
}


-(void)writeSVGData:(SVGWriter*)svgWriter
{
    BOOL embedInline = [[NSUserDefaults standardUserDefaults]boolForKey:prefSVGInlineEmbedded];
    if (embedInline)
        [self writeSVGDataInline:svgWriter];
    else
        [self writeSVGDataWithRef:svgWriter];
}

@end
