//
//  SVGPaintServer.h
//  Vectorius
//
//  Created by Alan Smith on 09/08/2020.
//  Copyright © 2020 Alan Smith. All rights reserved.
//

#import "SVGNode.h"


@interface SVGPaintServer : SVGNode

-(void)preFill:(NSBezierPath*)path context:(NSMutableDictionary*)context;
-(void)doFill:(NSBezierPath*)path context:(NSMutableDictionary*)context;
-(void)postFill;

-(void)fillPath:(NSBezierPath*)path context:(NSMutableDictionary*)context;
-(void)calculateTransforms;
-(void)applyTransforms;
@end

