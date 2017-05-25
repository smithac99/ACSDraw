//
//  XXAffineTransform.h
//  GeogXPert
//
//  Created by alan on 28/05/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

#define RADIANS(x) ((x)/(360.0/(2.0 * M_PI)))


@interface XXAffineTransform : NSObject 
{
	CGAffineTransform _transform;
}

+(id)transform;
-(id)initWithTransform:(XXAffineTransform*)t;
-(void)scaleBy:(float)amount;
-(void)translateXBy:(float)x yBy:(float)y;
-(void)rotateByDegrees:(float)amount;
-(void)scaleXBy:(float)x yBy:(float)y;
-(void)appendTransform:(XXAffineTransform*)t;
-(void)prependTransform:(XXAffineTransform*)t;
-(void)invert;
-(CGPoint)transformPoint:(CGPoint)pt;
-(CGAffineTransform) transform;

@end
