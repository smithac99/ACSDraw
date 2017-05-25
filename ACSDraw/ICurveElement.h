//
//  ICurveElement.h
//  Drawtest4
//
//  Created by alan on 29/01/2005.
//  Copyright 2005 Alan C Smith. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "ISegElement.h"


@interface ICurveElement : ISegElement
   {
   }

@property 	NSPoint cp1,cp2;

-(id)initWithVertex:(IVertex*)v inside:(bool)ins collinearSection:(bool)collinear cp1:(NSPoint)cPoint1 cp2:(NSPoint) cPoint2 marked:(bool)m;

@end
