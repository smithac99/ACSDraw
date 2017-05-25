//
//  gLine.h
//  ACSDraw
//
//  Created by alan on Mon Mar 29 2004.
//  Copyright (c) 2004 __MyCompanyName__. All rights reserved.
//

#import "gElement.h"


@interface gLine : gElement

@property 	NSPoint fromPt,toPt;

+ (gLine*)gLineFrom:(NSPoint)p1 to:(NSPoint)p2;
+ (gLine*)gLineFrom:(NSPoint)p1 to:(NSPoint)p2 direction:(int)dir;
- (id)initWithFromPt:(NSPoint)p1 toPt:(NSPoint)p2;
- (id)initWithFromPt:(NSPoint)p1 toPt:(NSPoint)p2 direction:(int)dir;


@end
