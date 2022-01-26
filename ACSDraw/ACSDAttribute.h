//
//  ACSDAttribute.h
//  ACSDraw
//
//  Created by Alan Smith on Sat Mar 02 2002.
//  Copyright (c) 2001 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "KeyedAttributeObject.h"

@class ACSDGraphic;
@class GraphicView;
@class CanvasWriter;
@class SVGWriter;

@interface ACSDAttribute : KeyedAttributeObject 
   {
	NSMutableSet *graphics;
	int nonDeletedCount;
	BOOL deleted;
   }

-(void)addGraphic:(id)g;
-(void)removeGraphic:(id)g;
-(NSMutableSet*)graphics;
-(void)writeSVGData:(SVGWriter*)svgWriter;
-(void)invalidateGraphicsRefreshCache:(BOOL)redo;
-(BOOL)isSameAs:(id)obj;
-(NSSet*)usedStrokes;
-(NSSet*)usedFills;
-(NSSet*)usedShadows;
- (int)showIndicator;
-(BOOL)addToNonDeletedCount:(int)inc;
-(void)setDeleted:(BOOL)d;
-(BOOL)deleted;
-(int)nonDeletedCount;
-(void)notifyOnADDOrRemove;
-(NSString*)canvasData:(CanvasWriter*)canvasWriter;
-(void)postNotify:(NSString*)notif object:(id)obj;

@end
