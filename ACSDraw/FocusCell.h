//
//  FocusCell.h
//  ACSDraw
//
//  Created by alan on 29/10/06.
//  Copyright 2006 Alan C Smith. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@protocol FocusCellDelegate <NSObject>

-(NSInteger)rowForContextualMenu;

@end

@interface FocusCell :  NSCell
   {
	
   }

-(void)drawFocusRingFrame:(NSRect)cellFrame controlView:(NSView *)controlView;

@end
