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
	NSPoint dragOffset;
}

@property (retain) NSString *title;
@property (assign) ContainerPalletteController *cpController;
@property (nonatomic) BOOL active;


- (id)initWithFrame:(NSRect)frame title:(NSString*)t controller:(ContainerPalletteController*)cpc;

@end
