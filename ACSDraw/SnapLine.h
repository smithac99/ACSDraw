//
//  SnapLine.h
//  ACSDraw
//
//  Created by alan on 01/04/06.
//  Copyright 2006 Alan C Smith. All rights reserved.
//

#import <Cocoa/Cocoa.h>


enum
   {
	SNAPLINE_HORIZONTAL,
	SNAPLINE_VERTICAL
   };

@interface SnapLine : NSObject 
   {
	NSView *graphicView;
	float location;
	int orientation;
	BOOL visible;
	NSColor *colour;
	NSRect displayRect;
   }

-(id)initWithGraphicView:(NSView*)gView orientation:(int)orn;
-(void)setLocation:(float)loc;
-(float)location;
- (void)setVisible:(BOOL)d;
-(NSRect)rectForDisplay;
- (void)drawRect:(NSRect)aRect;
- (BOOL)visible;

@end
