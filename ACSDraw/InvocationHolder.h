//
//  InvocationHolder.h
//  ACSDraw
//
//  Created by alan on 19/03/06.
//  Copyright 2006 Alan C Smith. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface InvocationHolder : NSObject
   {
   }

@property (retain) NSInvocation *invocation;
@property (retain) NSString *name;

+(InvocationHolder*)holderForInvocation:(NSInvocation*)i name:(NSString*)n;
-(id)initWithInvocation:(NSInvocation*)i name:(NSString*)n;

@end
