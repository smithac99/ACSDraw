//
//  gCurve.h
//  ACSDraw
//
//  Created by alan on Mon Mar 29 2004.
//  Copyright (c) 2004 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "gElement.h"


@interface gCurve : gElement
{
   }

@property 	NSPoint pt1,pt2,cp1,cp2;

+ (gCurve*)gCurvePt1:(NSPoint)p1 pt2:(NSPoint)p2 cp1:(NSPoint)cc1 cp2:(NSPoint)cc2;
+ (gCurve*)gCurvePt1:(NSPoint)p1 pt2:(NSPoint)p2 cp1:(NSPoint)cc1 cp2:(NSPoint)cc2 direction:(int)dir;
- (id)initWithPt1:(NSPoint)p1 pt2:(NSPoint)p2 cp1:(NSPoint)cc1 cp2:(NSPoint)cc2;
- (id)initWithPt1:(NSPoint)p1 pt2:(NSPoint)p2 cp1:(NSPoint)cc1 cp2:(NSPoint)cc2 direction:(int)dir;

@end
