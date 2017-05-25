//
//  ConnectorAttachment.h
//  ACSDraw
//
//  Created by alan on 07/05/06.
//  Copyright 2006 Alan C Smith. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "ACSDGraphic.h"
#import "SelectedElement.h"


@interface ConnectorAttachment : NSObject 
   {
	SelectedElement *knobAttachment;
	ACSDGraphic *graphic;
	NSPoint offset;
	float distance;
   }

+(id)connectorAttachmentWithKnob:(const KnobDescriptor&)kd graphic:(ACSDGraphic*)g offset:(NSPoint)os distance:(float)f;
-(id)initWithKnob:(const KnobDescriptor&)kd graphic:(ACSDGraphic*)g offset:(NSPoint)os distance:(float)f;
-(SelectedElement*)knobAttachment;
-(KnobDescriptor)knob;
-(ACSDGraphic*)graphic;
-(NSPoint)offset;
-(float)distance;
-(void)addConnector:(ACSDConnector*)c;
-(void)removeConnector:(ACSDConnector*)c;

@end
