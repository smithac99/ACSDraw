//
//  SVGDocument.m
//  Vectorius
//
//  Created by Alan Smith on 06/08/2020.
//  Copyright © 2020 Alan Smith. All rights reserved.
//

#import "SVGDocument.h"
#import "XMLManager.h"

@interface SVGDocument ()

@property NSMutableDictionary *objectDict;

@end

@implementation SVGDocument

-(instancetype)initWithXMLNode:(XMLNode*)xmlNode
{
    if (self = [self init])
    {
        self.backgroundColour = [NSColor clearColor];
        if ([xmlNode.nodeName isEqualToString:@"svg"])
        {
            self.context = [NSMutableDictionary dictionary];
            self.context[@"objectdict"] = self.objectDict = [NSMutableDictionary dictionary];
            self.context[@"styledict"] = [NSMutableDictionary dictionary];
            self.context[@"defaultattrs"] = [SVGDocument defaultDocumentAttributes];
            self.svgNode = [[SVG_svg alloc]initWithXMLNode:xmlNode context:self.context];
        }
        else
            return nil;
    }
    return self;
}

-(instancetype)initWithData:(NSData*)data
{
	if (self = [self initWithXMLNode:[[[XMLManager alloc]init]parseData:data]])
	{
		self.svgData = data;
	}
	return self;
}

+(NSDictionary*)defaultDocumentAttributes
{
    return @{
        @"fill":@"#000",
        @"fill-rule":@"nonzero",
        @"fill-opacity":@"1.0",
        @"stroke":@"none",
        @"stroke-width":@"1.0",
        @"stroke-opacity":@"1.0"
    };
}

-(NSSize)size
{
	return NSMakeSize(self.svgNode.width, self.svgNode.height);
}

-(void)drawInRect:(NSRect)destRect
{
    self.context[@"_vwidth"] = @(destRect.size.width);
    self.context[@"_vheight"] = @(destRect.size.height);
    
    [self.svgNode resolveAttributes:self.context];
    NSRect vb = self.svgNode.viewBox;
    float scale = fminf(destRect.size.width/vb.size.width, destRect.size.height/vb.size.height);
    float newWidth = vb.size.width * scale;
    float newHeight = vb.size.height * scale;
    float xoffset = (destRect.size.width-newWidth) / 2.0;
    float yoffset = (destRect.size.height-newHeight) / 2.0;
    NSRect frame = NSMakeRect(xoffset, yoffset, newWidth, newHeight);
    if (self.backgroundColour)
    {
        [self.backgroundColour set];
        NSRectFill(NSMakeRect(xoffset, yoffset, newWidth, newHeight));
    }
    [[NSGraphicsContext currentContext]saveGraphicsState];
    NSAffineTransform *t = [NSAffineTransform transform];
    [t translateXBy:0 yBy:NSMaxY(frame)];
    [t scaleXBy:1.0 yBy:-1.0];
    [t scaleBy:scale];
    [t concat];
    [self.svgNode draw:self.context];
    [[NSGraphicsContext currentContext]restoreGraphicsState];
}
@end
