//
//  DragView.h
//  ACSDraw
//
//  Created by alan on 19/01/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface DragView : NSView 
{
	float left,right;
	NSPoint dragOffset;
}

-(void)setLeft:(float)l;
-(void)setRight:(float)r;
-(float)minTitleWidth;
-(BOOL)containsScreenPoint:(NSPoint)screenPt;

@end
