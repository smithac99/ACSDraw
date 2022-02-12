//
//  ObjectView.h
//  ACSDraw
//
//  Created by alan on 15/02/06.
//  Copyright 2006 Alan C Smith. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "ACSDGraphic.h"
#import "FlippableView.h"


@interface ObjectView : FlippableView
{
	ACSDGraphic *graphic;
	float xOffset,yOffset;
}

- (id)initWithObject:(ACSDGraphic*)object;
- (NSPoint)offset;

@end
