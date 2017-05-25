//
//  GradientElement.h
//  ACSDraw
//
//  Created by Alan Smith on Sat Feb 09 2002.
//  Copyright (c) 2001 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface GradientElement : NSObject
   {
   }

@property float position;
@property (strong) NSColor *colour;

-(id)initWithPosition:(float)pos colour:(NSColor*)col;
-(BOOL)isSameAs:(id)obj;
-(NSInteger)comparePositionWith:(GradientElement*)ge;

@end
