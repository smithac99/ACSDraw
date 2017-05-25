//
//  ToolWindow.mm
//  ACSDraw
//
//  Created by alan on 25/04/06.
//  Copyright 2006 Alan C Smith. All rights reserved.
//

#import "ToolWindow.h"


@implementation ToolWindow

-(void)awakeFromNib
   {
	standardRect = [self frame];
   }

- (void)zoom:(id)sender
   {
	NSRect currentFrame = [self frame],newFrame = currentFrame;
	if (currentFrame.size.height < 50)
	   {
		newFrame.size.height = [self maxSize].height;
		newFrame.origin.y -= ([self maxSize].height - currentFrame.size.height);
	   }
	else
	   {
		newFrame.size.height = 20;
		newFrame.origin.y -= (20 - currentFrame.size.height);
	   }
	[self setFrame:newFrame display:YES];
   }

@end
