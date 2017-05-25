//
//  CoderAdditions.mm
//  ACSDraw
//
//  Created by alan on 25/11/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import "CoderAdditions.h"


@implementation NSCoder(CoderAdditions)

-(float) decodeFloatForKey:(NSString*)key withDefault:(float)dflt
{
	if ([self containsValueForKey:key])
		return [self decodeFloatForKey:key];
	else
		return dflt;
}


@end
