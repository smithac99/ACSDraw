//
//  BackingView.h
//  ACSDraw
//
//  Created by alan on 10/03/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface BackingView : NSView
{
	int backingType;
	NSColor *backingColour;
}

@property (copy) NSColor *backingColour;

@end
