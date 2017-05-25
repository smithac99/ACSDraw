//
//  ContainerTab.h
//  ACSDraw
//
//  Created by alan on 07/02/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface ContainerTab : NSObject 
{
	NSString *title;
	NSRect frame;
}

-(id)initWithTitle:(NSString*)t;

@end
