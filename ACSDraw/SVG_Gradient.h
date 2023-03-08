//
//  SVGGradient.h
//  ACSDraw
//
//  Created by Alan on 12/03/2015.
//
//

#import "ACSDGradient.h"

@interface SVG_Gradient : ACSDGradient
@property (retain) NSMutableDictionary *attrs;

-(void)resolveSettingsForOriginalBoundingBox:(NSRect)bb frame:(NSRect)f;
-(void)writeSVGGradientDef:(SVGWriter*)svgWriter;

@end
