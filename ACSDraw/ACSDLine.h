//
//  ACSDLine.h
//  ACSDraw
//
//  Created by Alan Smith on Sat Mar 02 2002.
//  Copyright (c) 2001 __MyCompanyName__. All rights reserved.
//

#import "ACSDGraphic.h"


@interface ACSDLine : ACSDGraphic
   {
   }

@property 	NSPoint fromPt,toPt;

+ (ACSDLine*)lineFrom:(NSPoint)f to:(NSPoint)t stroke:(ACSDStroke*)str layer:(ACSDLayer*)l;

@end
