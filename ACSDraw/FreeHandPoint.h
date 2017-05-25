//
//  FreeHandPoint.h
//  ACSDraw
//
//  Created by alan on 08/03/07.
//  Copyright 2007 Alan C Smith. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface FreeHandPoint : NSObject 
   {
	NSPoint point;
	float length;
	float pressure;
   }

+(FreeHandPoint*)freeHandPoint:(NSPoint)pt pressure:(float)p;
- (id)initWithPoint:(NSPoint)pt pressure:(float)p;
-(NSPoint)point;
-(float)length;
-(float)pressure;;
-(void)setPoint:(NSPoint)p;
-(void)setLength:(float)l;
-(void)moveBy:(NSPoint)p;

@end
