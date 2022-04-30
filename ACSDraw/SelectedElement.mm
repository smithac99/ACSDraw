//
//  SelectedElement.mm
//  ACSDraw
//
//  Created by alan on 28/04/06.
//  Copyright 2006 Alan C Smith. All rights reserved.
//

#import "SelectedElement.h"

@implementation SelectedElement

+(id)SelectedElementWithKnobDescriptor:(const KnobDescriptor&)kd
{
    return [[SelectedElement alloc]initWithKnobDescriptor:kd];
}

-(id)initWithKnobDescriptor:(const KnobDescriptor&)kd
{
    if (self = [self init])
    {
        knobDescriptor = new KnobDescriptor(kd.subPath,kd.knob,kd.controlPoint,kd.isLine);
    }
    return self;
}

-(void)dealloc
{
	if (knobDescriptor)
		delete knobDescriptor;
}

- (void) encodeWithCoder:(NSCoder*)coder
{
    [coder encodeInteger:knobDescriptor->subPath forKey:@"SelectedElement_subPath"];
    [coder encodeInteger:knobDescriptor->knob forKey:@"SelectedElement_knob"];
    [coder encodeInteger:knobDescriptor->controlPoint forKey:@"SelectedElement_controlPoint"];
    [coder encodeBool:knobDescriptor->isLine forKey:@"SelectedElement_isLine"];
}

- (id) initWithCoder:(NSCoder*)coder
{
	self = [self init];
	knobDescriptor = new KnobDescriptor(
										[coder decodeIntForKey:@"SelectedElement_subPath"],
										[coder decodeIntForKey:@"SelectedElement_knob"],
										[coder decodeIntForKey:@"SelectedElement_controlPoint"],
										[coder decodeBoolForKey:@"SelectedElement_isLine"]
										);
	return self;
}

-(KnobDescriptor)knobDescriptor
{
	return *knobDescriptor;
}

- (id)copyWithZone:(NSZone *)zone 
{
    SelectedElement *obj =  [[[self class] allocWithZone:zone] initWithKnobDescriptor:*knobDescriptor];
	return obj;
}

- (BOOL)isEqual:(id)anObject
{
	return (*knobDescriptor == [anObject knobDescriptor]);
}

- (NSUInteger)hash
{
	NSUInteger c1 = 0,c2 = 0,c3 = 0;
	if (knobDescriptor->isLine)
		c1 = 1;
	c2 = knobDescriptor->subPath << 1;
	c3 = (knobDescriptor->knob << 17);
	return c1 | c2 | c3;
}

-(NSComparisonResult)compareWith:(id)obj
{
	KnobDescriptor k1 = [self knobDescriptor],k2 = [obj knobDescriptor];
	if (k1.subPath < k2.subPath)
		return NSOrderedAscending;
	else if (k1.subPath > k2.subPath)
		return NSOrderedDescending;
	if (k1.knob < k2.knob)
		return NSOrderedAscending;
	else if (k1.knob > k2.knob)
		return NSOrderedDescending;
	if (k1.isLine < k2.isLine)
		return NSOrderedAscending;
	else if (k1.isLine > k2.isLine)
		return NSOrderedDescending;
	return NSOrderedSame;
}


@end
