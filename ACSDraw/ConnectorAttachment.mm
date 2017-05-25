//
//  ConnectorAttachment.mm
//  ACSDraw
//
//  Created by alan on 07/05/06.
//  Copyright 2006 Alan C Smith. All rights reserved.
//

#import "ConnectorAttachment.h"


@implementation ConnectorAttachment

+(id)connectorAttachmentWithKnob:(const KnobDescriptor&)kd graphic:(ACSDGraphic*)g offset:(NSPoint)os distance:(float)f
   {
	return [[[ConnectorAttachment alloc]initWithKnob:kd graphic:g offset:os distance:f]autorelease];
   }

-(id)initWithKnob:(const KnobDescriptor&)kd graphic:(ACSDGraphic*)g offset:(NSPoint)os distance:(float)f
   {
	if (self = [super init])
	   {
		knobAttachment = [[SelectedElement SelectedElementWithKnobDescriptor:kd]retain];
		graphic = [g retain];
		offset = os;
		distance = f;
	   }
	return self;
   }


- (id)copyWithZone:(NSZone *)zone 
   {
	return [[ConnectorAttachment alloc]initWithKnob:[knobAttachment knobDescriptor] graphic:graphic offset:offset distance:distance];
   }

- (void) encodeWithCoder:(NSCoder*)coder
   {
	[coder encodeObject:knobAttachment forKey:@"ConnectorAttachment_knob"];
	[coder encodeConditionalObject:graphic forKey:@"ConnectorAttachment_graphic"];
	[ACSDGraphic encodePoint:offset coder:coder forKey:@"ConnectorAttachment_point"];
	[coder encodeFloat:distance forKey:@"ConnectorAttachment_distance"];
   }

- (id) initWithCoder:(NSCoder*)coder
   {
	self = [self init];
	knobAttachment = [[coder decodeObjectForKey:@"ConnectorAttachment_knob"]retain];
	graphic = [[coder decodeObjectForKey:@"ConnectorAttachment_graphic"]retain];
	offset = [ACSDGraphic decodePointForKey:@"ConnectorAttachment_point" coder:coder];
	distance = [coder decodeFloatForKey:@"ConnectorAttachment_distance"];
	return self;
   }


-(void)dealloc
   {
	if (knobAttachment)
		[knobAttachment release];
	if (graphic)
		[graphic release];
	[super dealloc];
   }

-(SelectedElement*)knobAttachment
   {
	return knobAttachment;
   }

-(KnobDescriptor)knob
   {
	return [knobAttachment knobDescriptor];
   }

-(ACSDGraphic*)graphic
   {
	return graphic;
   }

-(NSPoint)offset
   {
	return offset;
   }

-(float)distance
   {
	return distance;
   }

-(void)addConnector:(ACSDConnector*)c
   {
	if (graphic)
		[graphic addConnector:c];
   }

-(void)removeConnector:(ACSDConnector*)c
   {
	if (graphic)
		[graphic removeConnector:c];
   }


@end
