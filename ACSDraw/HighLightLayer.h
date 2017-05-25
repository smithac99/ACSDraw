//
//  HighLightLayer.h
//  ACSDraw
//
//  Created by alan on 02/02/07.
//  Copyright 2007 Alan C Smith. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class GraphicView;

@interface HighLightLayer : NSObject 
   {
	id targetObject;
	BOOL highLightOn;
	int count;
	GraphicView *graphicView;
	NSColor *highLightColour;
	NSUInteger modifierFlags;
   }

- (id)initWithGraphicView:(GraphicView*)gv;
-(void)drawRect:(NSRect)rect hotPoint:(NSPoint)hotPoint;
-(void)highLightObject:(id)obj modifiers:(NSUInteger)modifiers;
-(void)outlineRect:(NSRect)rect;
-(id)targetObject;
-(void)highLightObject:(id)obj times:(int)times interval:(float)sec;
-(void)highLightObject:(id)obj forSeconds:(float)sec;

@end
