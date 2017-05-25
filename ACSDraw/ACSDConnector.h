//
//  ACSDConnector.h
//  ACSDraw
//
//  Created by alan on 30/04/06.
//  Copyright 2006 Alan C Smith. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "ACSDGraphic.h"

enum
   {
	NO_ELBOW = 0,
	SINGLE_ELBOW = 1
   };

@interface ACSDConnector : ACSDGraphic
   {
	int elbow;
   }

@property (strong) NSMutableArray *fromGraphics,*toGraphics;

-(id)initWithName:(NSString*)n fill:(ACSDFill*)f stroke:(ACSDStroke*)str rect:(NSRect)r  layer:(ACSDLayer*)l
		  graphic:(ACSDGraphic*)g knobDescriptor:(const KnobDescriptor&)kd offset:(NSPoint)os distance:(float)d;
-(void)setFromGraphics:(NSMutableArray*)arr;
-(void)setToGraphics:(NSMutableArray*)arr;
-(void)setFromGraphic:(ACSDGraphic*)g knob:(const KnobDescriptor&)kd offset:(NSPoint)pt distance:(float)d;
-(void)setToGraphic:(ACSDGraphic*)g knob:(const KnobDescriptor&)kd offset:(NSPoint)pt distance:(float)d;
-(void)reformConnector;
- (void)generateBezierPath;
-(int)elbow;
-(void)setElbow:(int)e;

@end
