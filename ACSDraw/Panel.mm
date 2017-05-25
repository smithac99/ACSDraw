//
//  Panel.mm
//  ACSDraw
//
//  Created by alan on 19/01/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "Panel.h"


@implementation Panel

- (id)initWithContentRect:(NSRect)contentRect styleMask:(NSUInteger)styleMask backing:(NSBackingStoreType)bufferingType defer:(BOOL)deferCreation
{
	if (self = [super initWithContentRect:contentRect styleMask:NSBorderlessWindowMask backing:bufferingType defer:deferCreation])
	{
		[self setBackgroundColor:[NSColor clearColor]];
		[self setOpaque:NO];
		[self setFloatingPanel:YES];
	}
	return self;
}

- (BOOL)canBecomeKeyWindow
{
	return YES;
}


@end
