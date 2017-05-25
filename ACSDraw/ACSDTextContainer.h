//
//  ACSDTextContainer.h
//  ACSDraw
//
//  Created by alan on 17/02/07.
//  Copyright 2007 Alan C Smith. All rights reserved.
//

#import <Cocoa/Cocoa.h>
@class ACSDText;

@interface ACSDTextContainer : NSTextContainer
   {
	ACSDText *graphic;
	
   }

- (id)initWithContainerSize:(NSSize)aSize graphic:(ACSDText*)g;

@end
