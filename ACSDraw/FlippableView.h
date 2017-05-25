//
//  FlippableView.h
//  ACSDraw
//
//  Created by alan on 17/02/06.
//  Copyright 2006 Alan C Smith. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface FlippableView : NSView
   {
	BOOL flipped;
   }

-(void)setFlipped:(BOOL)f;
-(BOOL)isFlipped;


@end
