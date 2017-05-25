//
//  GraphicRulerView.h
//  ACSDraw
//
//  Created by alan on 18/03/06.
//  Copyright 2006 Alan C Smith. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface GraphicRulerView : NSRulerView
   {
	id delegate;
   }

-(void)setDelegate:(id)del;


@end

@interface NSObject(RulerController)

-(void)horizontalRulerMovedToOffset:(float)f;
-(void)verticalRulerMovedToOffset:(float)f;

@end
