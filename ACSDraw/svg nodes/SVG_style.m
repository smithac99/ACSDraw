//
//  SVG_style.m
//  Vectorius
//
//  Created by Alan Smith on 08/08/2020.
//  Copyright © 2020 Alan Smith. All rights reserved.
//

#import "SVG_style.h"

static void AddToDict(NSMutableDictionary *dict,NSString *key,NSMutableDictionary *attributes)
{
    NSMutableDictionary *entry = dict[key];
    if (entry)
        [entry addEntriesFromDictionary:attributes];
    else
        dict[key] = attributes;
}

static NSDictionary* attributesFromCSSStyleString(NSString *cssstr)
{
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    NSScanner *scanner = [NSScanner scannerWithString:cssstr];
    [scanner scanCharactersFromSet:[NSCharacterSet whitespaceAndNewlineCharacterSet] intoString:NULL];
    BOOL ok = YES;
    while (![scanner isAtEnd] && ok)
    {
        NSString *ident = nil;
        ok = [scanner scanUpToString:@"{" intoString:&ident];
        if (ok)
        {
            [scanner scanString:@"{" intoString:NULL];
            NSMutableDictionary *attrs = [NSMutableDictionary dictionary];
            NSString *body = nil;
            [scanner scanUpToString:@"}" intoString:&body];
            [scanner scanString:@"}" intoString:NULL];
            body = [body stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
            if (ok)
            {
                for (NSString *component in [body componentsSeparatedByString:@";"])
                {
                    if ([component length] > 2)
                    {
                        NSArray *attr = [component componentsSeparatedByString:@":"];
                        if ([attr count] > 1)
                        {
                            NSString *key = [attr[0] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
                            NSString *val = [attr[1] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
                            attrs[key] = val;
                        }
                    }
                }
            }
            for (NSString *cls in [ident componentsSeparatedByString:@","])
            {
                NSString *k = [cls stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
                AddToDict(dict, k, [attrs mutableCopy]);
            }
        }
    }
    return dict;
}
@implementation SVG_style

-(void)buildTree:(XMLNode*)xmlNode context:(NSMutableDictionary*)context
{
    NSDictionary *dict = attributesFromCSSStyleString(xmlNode.contents);
    if ([dict count] > 0)
    {
        NSMutableDictionary *styleDict = context[@"styledict"];
        [styleDict addEntriesFromDictionary:dict];
    }
}

@end
