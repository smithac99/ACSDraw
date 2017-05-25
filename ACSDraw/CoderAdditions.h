//
//  CoderAdditions.h
//  ACSDraw
//
//  Created by alan on 25/11/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface NSCoder(CoderAdditions)

-(float) decodeFloatForKey:(NSString*)key withDefault:(float)dflt;

@end
