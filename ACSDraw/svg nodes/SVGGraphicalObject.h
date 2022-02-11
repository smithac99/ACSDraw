//
//  SVGGraphicalObject.h
//  Vectorius
//
//  Created by Alan Smith on 06/08/2020.
//  Copyright © 2020 Alan Smith. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "SVGNode.h"

@interface SVGGraphicalObject : SVGNode

@property BOOL mustEndTransparencyLayer;

-(void)draw:(NSMutableDictionary*)context;
-(void)applyTransforms;
-(BOOL)preDraw:(NSMutableDictionary*)context;
-(void)postDraw:(NSMutableDictionary*)context;
-(void)drawObject:(NSMutableDictionary*)context;
-(void)calculateTransforms;
-(NSRect)bounds:(NSMutableDictionary*)context;
@end

