//
//  PositionalObject.h
//  ACSDraw
//
//  Created by Alan Smith on Sat Feb 02 2002.
//  Copyright (c) 2001 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface PositionalObject : NSObject
   {
	NSInteger position;
	id  object;
   }

@property NSInteger position;
@property (retain) id object;

- (id)initWithPosition:(NSInteger)pos object:(id)obj;


@end
