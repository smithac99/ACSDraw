//
//  FreeHandPoint.mm
//  ACSDraw
//
//  Created by alan on 08/03/07.
//  Copyright 2007 Alan C Smith. All rights reserved.
//

#import "FreeHandPoint.h"


@implementation FreeHandPoint

+(FreeHandPoint*)freeHandPoint:(NSPoint)pt pressure:(float)p
   {
	return [[[FreeHandPoint alloc]initWithPoint:pt pressure:p]autorelease];
   }

- (id)initWithPoint:(NSPoint)pt pressure:(float)p
   {
	if (self = [super init])
	   {
		point = pt;
		pressure = p;
//		NSLog(@"%g",p);
	   }
	return self;
   }

-(NSPoint)point
   {
	return point;
   }

-(float)pressure
   {
	return pressure;
   }

-(float)length
   {
	return length;
   }

-(void)setPoint:(NSPoint)p
   {
	point = p;
   }

-(void)setLength:(float)l
   {
	length = l;
   }

-(void)moveBy:(NSPoint)p
   {
	point.x += p.x;
	point.y += p.y;
   }

@end
