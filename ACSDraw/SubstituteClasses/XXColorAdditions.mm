//
//  XXColorAdditions.mm
//  ACSDraw
//
//  Created by alan on 30/05/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "XXColorAdditions.h"


@implementation XXColor(XXColorAdditions)

+(id)XXColorWithNSColor:(NSColor*)nsc
{
	return [[XXColor alloc]initWithNSColor:nsc];
}

-(id)initWithNSColor:(NSColor*)nsc
{
	if (self = [super init])
	{
		NSColor *c = [nsc colorUsingColorSpace:[NSColorSpace deviceRGBColorSpace]];
		_r = [c redComponent];
		_g = [c greenComponent];
		_b = [c blueComponent];
		_a = [c alphaComponent];
	}
	return self;
}

@end
