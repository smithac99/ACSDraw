//
//  XXAffineTransformAdditions.h
//  ACSDraw
//
//  Created by alan on 31/05/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "XXAffineTransform.h"


@interface XXAffineTransform(XXAffineTransformAdditions)

+(id)XXAffineTransformWithNSAffineTransform:(NSAffineTransform*)t;
-(id)initWithNSAffineTransform:(NSAffineTransform*)t;

@end
