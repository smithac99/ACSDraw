//
//  DashFormatter.mm
//  ACSDraw
//
//  Created by Alan Smith on Fri Feb 08 2002.
//  Copyright (c) 2001 __MyCompanyName__. All rights reserved.
//

#import "DashFormatter.h"


@implementation DashFormatter

- (NSString *)stringForObjectValue:(id)anObject
   {
    if (![anObject isKindOfClass:[NSArray class]])
        return @"";
	NSMutableString *str = [NSMutableString stringWithCapacity:10];
	[str appendString:@""];
	for (int i = 0;i < (signed)[anObject count];i++)
	   {
		if (i > 0)
			[str appendString:@","];
		[str appendString:[[anObject objectAtIndex:i]stringValue]];
	   }
    return str;
   }

- (BOOL)getObjectValue:(id*)anObject forString:(NSString *)string errorDescription:(NSString **)error
   {
	NSScanner *scanner = [NSScanner scannerWithString:string];
	NSMutableArray *result = [NSMutableArray arrayWithCapacity:5];
	while (![scanner isAtEnd])
	   {
		float f;
		if ([scanner scanFloat:&f])
			[result addObject:[NSNumber numberWithFloat:f]];
		else
		   {
			*error = @"invalid number";
			return NO;
		   }
		if ([scanner isAtEnd])
		   {
		    *anObject = result;
			return YES;
		   }
		if (![scanner scanString:@"," intoString:(__autoreleasing NSString**)nil])
		   {
			*error = @"Number must be separated with a comma";
			return NO;
		   }
	   }
	*anObject = result;
	return YES;
   }
   
- (BOOL)isPartialStringValid:(NSString *)partialString newEditingString:(NSString **)newString
	errorDescription:(NSString **)error;
   {
	NSScanner *scanner = [NSScanner scannerWithString:partialString];
	*newString = nil;
	while (![scanner isAtEnd])
	   {
		float f;
		if (![scanner scanFloat:&f])
		   {
			*error = @"invalid number";
			return NO;
		   }
		if ([scanner isAtEnd])
			return YES;
		NSString *dummy;
		if (![scanner scanString:@"," intoString:&dummy])
		   {
			*error = @"Number must be separateed with a comma";
			return NO;
		   }
	   }
	return YES;
   }


@end
