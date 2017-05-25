//
//  AnimationEntry.h
//  ACSDraw
//
//  Created by Alan on 30/06/2014.
//
//

#import <Foundation/Foundation.h>

enum
{
    AE_IS_SNAPSHOT = 1
};

@interface AnimationEntry : NSObject

@property (copy) NSString *name,*text;
@property NSUInteger flags;
@property (retain) NSMutableDictionary *settings;

@end
