//
//  TextSubstitution.mm
//  ACSDraw
//
//  Created by alan on 18/03/07.
//  Copyright 2007 Alan C Smith. All rights reserved.
//

#import "TextSubstitution.h"

NSString *TextSubstitutionAttribute = @"TextSub";


@implementation TextSubstitution

+(id)textSubstitutionWithType:(int)sType
   {
	return [[TextSubstitution alloc]initWithType:sType];
   }

-(id)initWithType:(int)n
   {
	if (self = [super init])
	   {
		substitutionType = n;
	   }
	return self;
   }

- (void)encodeWithCoder:(NSCoder*)coder
   {
	[coder encodeInt:substitutionType forKey:@"TextSubstitution_substitutionType"];
	if (parameters)
		[coder encodeObject:parameters forKey:@"TextSubstitution_parameters"];
   }

- (id)initWithCoder:(NSCoder*)coder
   {
	self = [self initWithType:[coder decodeIntForKey:@"TextSubstitution_substitutionType"]];
	parameters = [coder decodeObjectForKey:@"TextSubstitution_parameters"];
	return self;
   }

-(int)substitutionType
   {
	return substitutionType;
   }

-(NSDictionary*)parameters
   {
	return parameters;
   }

- (BOOL)isEqual:(id)anObject
   {
	if (substitutionType != [anObject substitutionType])
		return NO;
	if (!parameters)
		return YES;
	return [[anObject parameters]isEqual:parameters];
   }

- (NSUInteger)hash
   {
	int h = substitutionType;
	if (parameters)
	h += [[parameters description]hash];
	return h;
   }

-(NSString*)substitutedValueFromDictionary:(NSDictionary*)dict
   {
	id val = [dict objectForKey:[NSNumber numberWithInt:substitutionType]];
	if (!val)
		return [NSString stringWithFormat:@"%d",substitutionType];
	return [val description];
   }

@end
