//
//  ACSDSVGImage.h
//  ACSDraw
//
//  Created by alan on 11/02/22.
//

#import "ACSDImage.h"
@class SVGDocument;

@interface ACSDSVGImage : ACSDImage

@property NSData *svgData;
@property SVGDocument *svgDocument;

@end

