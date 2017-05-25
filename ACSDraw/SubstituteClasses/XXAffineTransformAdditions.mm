//
//  XXAffineTransformAdditions.mm
//  ACSDraw
//
//  Created by alan on 31/05/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "XXAffineTransformAdditions.h"


@implementation XXAffineTransform(XXAffineTransformAdditions)

+(id)XXAffineTransformWithNSAffineTransform:(NSAffineTransform*)t
{
	return [[XXAffineTransform alloc]initWithNSAffineTransform:t];
}

-(id)initWithNSAffineTransform:(NSAffineTransform*)t
{
	if (self = [super init])
	{
		NSAffineTransformStruct ts = [t transformStruct];
		_transform.a = ts.m11;
		_transform.b = ts.m12;
		_transform.c = ts.m21;
		_transform.d = ts.m22;
		_transform.tx = ts.tX;
		_transform.ty = ts.tY;
	}
	return self;
}

@end
