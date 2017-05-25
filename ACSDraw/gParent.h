//
//  gParent.h
//  ACSDraw
//
//  Created by alan on 15/02/2005.
//  Copyright 2005 Alan C Smith. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "gElement.h"


@interface gParent : NSObject
   {
	NSMutableArray *leftLines,*rightLines;
	int direction;
	NSPoint startDirectionVector,endDirectionVector;
   }

+ (void)extendFirstElementOf:(NSMutableArray*)lines toPoint:(NSPoint)pt;
+ (void)extendLastElementOf:(NSMutableArray*)lines toPoint:(NSPoint)pt;
+ (gParent*)parentWithDirection:(int)dir startVector:(NSPoint)sv endVector:(NSPoint)ev;
- (id)initWithDirection:(int)dir startVector:(NSPoint)sv endVector:(NSPoint)ev;
-(NSMutableArray*)leftLines;
-(NSMutableArray*)rightLines;
-(int)direction;
-(NSPoint)startDirectionVector;
-(NSPoint)endDirectionVector;
-(void)setEndDirectionVector:(NSPoint)edv;
-(NSPoint)firstRightPoint;
-(NSPoint)lastRightPoint;
-(NSPoint)firstLeftPoint;
-(NSPoint)lastLeftPoint;
-(void)reverseLeftLines;
-(void) addLinesToPath:(NSBezierPath*)path isClosed:(BOOL)isClosed startLineCap:(int)startLineCap endLineCap:(int)endLineCap;
-(void)addBetweenFor:(gParent*)nextParent;

@end
