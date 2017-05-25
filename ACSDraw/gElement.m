//
//  gElement.m
//  ACSDraw
//
//  Created by alan on 30/07/14.
//
//

#import "gElement.h"

@implementation gElement

-(NSPoint)firstPoint
{
	return NSZeroPoint;
}

-(NSPoint)lastPoint
{
	return NSZeroPoint;
}

-(void)firstPoint:(NSPoint*)fp secondPoint:(NSPoint*)sp
{
	
}
-(void)lastPoint:(NSPoint*)fp secondLastPoint:(NSPoint*)sp
{
	
}
-(void)calculateDirectionVectors
{
	
}

-(void)calculateLength
{
	
}

-(float)tForS:(float)s
{
	return s;
}

-(gElement*)elementUpToT:(float)t
{
	return nil;
}

-(NSAffineTransform*)transformForLength:(CGFloat)l
{
	return nil;
}

- (gElement*)objectFromMinT:(double)minT toMaxT:(double)maxT
{
	return nil;
}

-(CGFloat)length
{
    if (_length < 0)
        [self calculateLength];
    return _length;
}
@end
