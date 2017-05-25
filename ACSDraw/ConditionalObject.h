//
//  ConditionalObject.h
//  ACSDraw
//
//  Created by alan on 30/01/07.
//  Copyright 2007 Alan C Smith. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface ConditionalObject : NSObject 
   {
	id obj;
   }

+ (ConditionalObject*)conditionalObject:(id)o;
-(id)initWithObject:(id)o;
-(void) encodeWithCoder:(NSCoder*)coder;
-(id) initWithCoder:(NSCoder*)coder;
-(id)obj;

@end
