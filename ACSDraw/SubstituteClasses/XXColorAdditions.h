//
//  XXColorAdditions.h
//  ACSDraw
//
//  Created by alan on 30/05/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "XXColor.h"


@interface XXColor(XXColorAdditions)

+(id)XXColorWithNSColor:(NSColor*)nsc;
-(id)initWithNSColor:(NSColor*)nsc;

@end
