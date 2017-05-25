//
//  SubSegment.mm
//  Drawtest4
//
//  Created by alan on 18/01/2005.
//  Copyright 2005 Alan C Smith. All rights reserved.
//

#import "SubSegment.h"


@implementation SubSegment

-(id)initWithVertex:(IVertex*)v s:(double)sVal
   {
    if (self = [super init])
	   {
		self.fromVertex = v;
		self.inside = YES;
		self.flipInside = YES;
		self.s = sVal;
		self.collinearSection = NO;
	   }
	return self;
   }

- (NSString *)description
   {
	return [NSString stringWithFormat:@"Vertex - %@; inside - %@; flipInside - %@; s: %g collinearSection - %@ ",
		self.fromVertex,@(self.inside),@(self.flipInside),self.s,@(self.collinearSection)];
   }



@end
