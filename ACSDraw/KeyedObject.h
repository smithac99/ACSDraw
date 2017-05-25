//
//  KeyedObject.h
//  ACSDraw
//
//  Created by alan on 14/02/07.
//  Copyright 2007 Alan C Smith. All rights reserved.
//

#import <Cocoa/Cocoa.h>
@class ACSDrawDocument;

@interface KeyedObject : NSObject<NSCopying,NSCoding>
   {
   }

@property (strong) NSMutableArray *attributes;
@property int objectKey;

-(void)deRegisterWithDocument:(ACSDrawDocument*)doc;
-(void)registerWithDocument:(ACSDrawDocument*)doc;

@end
