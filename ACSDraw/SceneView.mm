//
//  SceneView.m
//  ACSDraw
//
//  Created by alan on 06/02/16.
//
//

#import "SceneView.h"
#import "GroupViewController.h"

@implementation SceneView

- (BOOL)acceptsFirstResponder
{
	return YES;
}

-(void)mouseUp:(NSEvent *)theEvent
{
	[self.controller mouseUp:theEvent];
}

-(void)mouseDragged:(NSEvent *)theEvent
{
	[self.controller mouseDragged:theEvent];
}

-(void)mouseDown:(NSEvent *)theEvent
{
	[self.controller mouseDown:theEvent];
}

@end
