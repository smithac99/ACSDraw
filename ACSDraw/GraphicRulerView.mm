//
//  GraphicRulerView.mm
//  ACSDraw
//
//  Created by alan on 18/03/06.
//  Copyright 2006 Alan C Smith. All rights reserved.
//

#import "GraphicRulerView.h"


@implementation GraphicRulerView

- (void)mouseDown:(NSEvent *)theEvent 
   {
	NSPoint curPoint = [self convertPoint:[theEvent locationInWindow] fromView:nil];
	float origin = [self originOffset];
	float offset;
	if ([self orientation] == NSHorizontalRuler)
		offset = curPoint.x - origin;
	else
		offset = curPoint.y - origin;
	NSRulerMarker *m = [[self markers]objectAtIndex:0];
	if (NSPointInRect(curPoint,[m imageRectInRuler]))
	   {
		[m trackMouse:theEvent adding:NO];
		return;
	   }
//	[super mouseDown:theEvent];
    while (1)
	   {
		if ([self orientation] == NSHorizontalRuler)
		   {
			[self setOriginOffset:curPoint.x - offset];
			if (delegate && [delegate respondsToSelector:@selector(horizontalRulerMovedToOffset:)])
				[(id)delegate horizontalRulerMovedToOffset:curPoint.x - offset];
		   }
		else
		   {
			[self setOriginOffset:curPoint.y - offset];		
			if (delegate && [delegate respondsToSelector:@selector(verticalRulerMovedToOffset:)])
				[(id)delegate verticalRulerMovedToOffset:curPoint.y - offset];
		   }
           theEvent = [[self window] nextEventMatchingMask:(NSEventMaskLeftMouseDragged | NSEventMaskLeftMouseUp)];
           if ([theEvent type] == NSEventTypeLeftMouseUp)
            break;
		curPoint = [self convertPoint:[theEvent locationInWindow] fromView:nil];
       }
   }

-(void)setDelegate:(id)del
   {
	delegate = del;
   }

@end
