//
//  XXImageAdditions.h
//  ACSDraw
//
//  Created by alan on 30/05/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "XXImage.h"
#import <Cocoa/Cocoa.h>

@interface XXImage(XXImageAdditions)

+(id)XXImageWithNSImage:(NSImage*)im;
-(id)initWithNSImage:(NSImage*)im;


@end
