//
//  GradientElement.mm
//  ACSDraw
//
//  Created by Alan Smith on Sat Feb 09 2002.
//  Copyright (c) 2001 __MyCompanyName__. All rights reserved.
//

#import "GradientElement.h"


@implementation GradientElement

-(id)initWithPosition:(float)pos colour:(NSColor*)col
   {
	if (self = [super init])
	   {
		self.position = pos;
		self.colour = col;
	   }
	return self;
   }


- (void) encodeWithCoder:(NSCoder*)coder
   {
	[coder encodeObject:self.colour forKey:@"ACSDGradientElement_colour"];
	[coder encodeFloat:self.position forKey:@"ACSDGradientElement_position"];
   }

- (id) initWithCoder:(NSCoder*)coder
   {
	self = [super init];
	self.colour = [coder decodeObjectForKey:@"ACSDGradientElement_colour"];;
	self.position = [coder decodeFloatForKey:@"ACSDGradientElement_position"];
	return self;
   }

- (id)copyWithZone:(NSZone *)zone
   {
    id obj = [[GradientElement alloc]initWithPosition:self.position colour:self.colour];
	return obj;
   }

-(BOOL)isSameAs:(id)obj
   {
	if ([self class] != [obj class])
		return NO;
	return (self.position == [(GradientElement*)obj position] && [self.colour isEqual:[obj colour]]);
   }

-(NSInteger)comparePositionWith:(GradientElement*)ge
   {
	if (self.position < [ge position])
		return NSOrderedAscending;
	if (self.position > [ge position])
		return NSOrderedDescending;
	return NSOrderedSame;
   }

@end
