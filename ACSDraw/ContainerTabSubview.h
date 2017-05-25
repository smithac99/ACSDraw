//
//  ContainerTabSubview.h
//  ACSDraw
//
//  Created by alan on 07/02/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
@class ContainerPalletteController;

@interface ContainerTabSubview : NSView 
{
	NSString *title;
	NSPoint dragOffset;
	BOOL active;
	ContainerPalletteController *cpController;
}

- (id)initWithFrame:(NSRect)frame title:(NSString*)t controller:(ContainerPalletteController*)cpc;
-(void)setActive:(BOOL)b;
-(BOOL)active;

@end
