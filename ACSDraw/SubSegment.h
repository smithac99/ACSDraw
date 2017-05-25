//
//  SubSegment.h
//  Drawtest4
//
//  Created by alan on 18/01/2005.
//  Copyright 2005 Alan C Smith. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "IVertex.h"


@interface SubSegment : NSObject
   {
   }

@property 	double s;
@property (strong) IVertex *fromVertex;
@property bool inside,flipInside,collinearSection;
@property NSPoint cp1,cp2;

-(id)initWithVertex:(IVertex*)v s:(double)sVal;

@end
