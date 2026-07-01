//
//  XMLNode.h
//  p-1-phonics
//
//  Created by Alan on 11/10/2013.
//  Copyright (c) 2013 Eurotalk. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface XMLNode : NSObject

@property (retain) NSString *nodeName;
@property (retain) NSMutableString *contents;
@property (retain) NSDictionary *attributes;
@property (retain) NSMutableArray *children;

-(instancetype)initWithName:(NSString*)n;
-(NSArray*)childrenOfType:(NSString*)typeName;
-(XMLNode*)childOfType:(NSString*)typeName identifier:(NSString*)ident;
-(XMLNode*)childOfType:(NSString*)typeName key:(NSString*)key value:(NSString*)value;
-(NSString*)attributeStringValue:(NSString*)attrname;
-(float)attributeFloatValue:(NSString*)attrname;
-(NSInteger)attributeIntValue:(NSString*)attrname;
-(BOOL)attributeBoolValue:(NSString*)attrname;

@end
