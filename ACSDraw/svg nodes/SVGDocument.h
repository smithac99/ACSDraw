//
//  SVGDocument.h
//  Vectorius
//
//  Created by Alan Smith on 06/08/2020.
//  Copyright © 2020 Alan Smith. All rights reserved.
//

#import "SVGNode.h"
#import "SVG_svg.h"

@interface SVGDocument : SVGNode

@property XMLNode *rootXMLNode;
@property SVG_svg *svgNode;
@property NSColor *backgroundColour;
@property NSMutableDictionary *context;
-(instancetype)initWithXMLNode:(XMLNode*)xmlNode;
-(void)drawInRect:(NSRect)destRect;
@end

