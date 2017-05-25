/*
 *  gProtocol.h
 *  ACSDraw
 *
 *  Created by alan on 12/02/2005.
 *  Copyright 2005 Alan C Smith. All rights reserved.
 *
 */

@protocol gProtocol
-(NSPoint)firstPoint;
-(NSPoint)lastPoint;
-(void)firstPoint:(NSPoint*)fp secondPoint:(NSPoint*)sp;
-(void)lastPoint:(NSPoint*)fp secondLastPoint:(NSPoint*)sp;
-(int)direction;
-(void)setDirection:(int)dir;
-(NSPoint)startDirectionVector;
-(NSPoint)endDirectionVector;
-(void)setStartDirectionVector:(NSPoint)v1;
-(void)setEndDirectionVector:(NSPoint)v2;
-(float)length;
- (id<gProtocol>)objectFromMinT:(double)minT toMaxT:(double)maxT;
-(void)setLength:(float)l;
-(void)setLengthFrom:(float)l;
-(NSAffineTransform*)transformForLength:(CGFloat)l;
-(float)lengthFrom;
-(void)calculateLength;
-(float)tForS:(float)s;
-(void)setFractionalLength:(float)l;
-(float)fractionalLength;
-(id<gProtocol>)elementUpToT:(float)t;

@end

