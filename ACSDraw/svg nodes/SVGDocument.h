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

@property (retain) XMLNode *rootXMLNode;
@property (retain) SVG_svg *svgNode;
@property (retain) NSData *svgData;
@property (retain) NSColor *backgroundColour;
@property (retain) NSMutableDictionary *context;
@property (retain) NSURL *fileURL;
@property (retain) id substitutionColours;

-(instancetype)initWithXMLNode:(XMLNode*)xmlNode;
-(instancetype)initWithData:(NSData*)data;
-(void)rebuild;
-(NSSize)size;
-(void)drawInRect:(NSRect)destRect;
@end

