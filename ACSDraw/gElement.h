//
//  gElement.h
//  ACSDraw
//
//  Created by alan on 30/07/14.
//
//

#import <Foundation/Foundation.h>

@interface gElement : NSObject

@property (nonatomic) CGFloat length,lengthFrom;
@property float fractionalLength;
@property 	int direction;
@property NSPoint startDirectionVector,endDirectionVector;

-(NSPoint)firstPoint;
-(NSPoint)lastPoint;
-(void)firstPoint:(NSPoint*)fp secondPoint:(NSPoint*)sp;
-(void)lastPoint:(NSPoint*)fp secondLastPoint:(NSPoint*)sp;
-(void)calculateDirectionVectors;
-(void)calculateLength;
-(float)tForS:(float)s;
-(gElement*)elementUpToT:(float)t;
-(NSAffineTransform*)transformForLength:(CGFloat)l;
- (gElement*)objectFromMinT:(double)minT toMaxT:(double)maxT;

@end
