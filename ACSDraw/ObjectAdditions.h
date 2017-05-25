//
//  ObjectAdditions.h
//  ACSDraw
//
//  Created by alan on 29/01/07.
//  Copyright 2007 Alan C Smith. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface NSObject(ObjectAdditions)

-(void)performSelector:(SEL)theSelector withObjectsFromArray:(NSArray*)array;

@end
