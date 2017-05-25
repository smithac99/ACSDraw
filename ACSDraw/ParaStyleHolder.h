//
//  ParaStyleHolder.h
//  ACSDraw
//
//  Created by alan on 11/01/07.
//  Copyright 2007 Alan C Smith. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface ParaStyleHolder : NSObject 
   {
	int alignment;
	float firstLineIndent;
	float indent;
	float afterSpace,beforeSpace;
	float padding;
   }

@end
