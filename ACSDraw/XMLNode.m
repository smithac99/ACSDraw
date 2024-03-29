//
//  XMLNode.m
//  p-1-phonics
//
//  Created by Alan on 11/10/2013.
//  Copyright (c) 2013 Eurotalk. All rights reserved.
//

#import "XMLNode.h"

@implementation XMLNode

-(id)init
{
	if (self = [super init])
	{
		self.contents = [NSMutableString stringWithCapacity:32];
		self.children = [NSMutableArray arrayWithCapacity:8];
	}
	return self;
}

-(instancetype)initWithName:(NSString*)n
{
    if (self = [self init])
    {
        self.nodeName = n;
    }
    return self;
}
-(NSArray*)childrenOfType:(NSString*)typeName
{
    NSIndexSet *ixs = [_children indexesOfObjectsPassingTest:^BOOL(id obj, NSUInteger idx, BOOL *stop)
                       {
                           return ([[obj nodeName]isEqualToString:typeName]);
                       }];
    return [_children objectsAtIndexes:ixs];
}

-(XMLNode*)childOfType:(NSString*)typeName identifier:(NSString*)ident
{
    NSIndexSet *ixs = [_children indexesOfObjectsPassingTest:^BOOL(XMLNode *obj, NSUInteger idx, BOOL *stop)
                       {
                           return ([[obj nodeName]isEqualToString:typeName] && (ident == nil || [[obj attributeStringValue:@"id"]isEqualToString:ident]));
                       }];
    NSArray *arr = [_children objectsAtIndexes:ixs];
    if ([arr count] > 0)
        return arr[0];
    return nil;
}

-(NSString*)attributeStringValue:(NSString*)attrname
{
	return [_attributes objectForKey:attrname];
}

-(float)attributeFloatValue:(NSString*)attrname
{
    NSString *str = [[_attributes objectForKey:attrname]stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    float div = 1;
    if ([str hasSuffix:@"%"])
    {
        str = [str substringWithRange:NSMakeRange(0, [str length]-1)];
        div = 100;
    }
	return [str floatValue] / div;
}

-(NSInteger)attributeIntValue:(NSString*)attrname
{
	return [[_attributes objectForKey:attrname]integerValue];
}

-(BOOL)attributeBoolValue:(NSString*)attrname
{
	NSString *attr = [[[_attributes objectForKey:attrname]lowercaseString]stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
	return [attr isEqualToString:@"yes"] ||[attr isEqualToString:@"true"] ||[attr isEqualToString:@"y"] ;
}

@end
