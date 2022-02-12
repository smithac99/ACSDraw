//
//  ACSDSVGImage.h
//  ACSDraw
//
//  Created by alan on 11/02/22.
//

#import "ACSDImage.h"
@class SVGDocument;

@interface ACSDSVGImage : ACSDImage

@property (retain) SVGDocument *svgDocument;

-(id)initWithName:(NSString*)n fill:(ACSDFill*)f stroke:(ACSDStroke*)str rect:(NSRect)r layer:(ACSDLayer*)l document:(SVGDocument*)svgDoc;

@end

