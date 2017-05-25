//
//  TextSubstitution.h
//  ACSDraw
//
//  Created by alan on 18/03/07.
//  Copyright 2007 Alan C Smith. All rights reserved.
//

#import <Cocoa/Cocoa.h>

extern NSString *TextSubstitutionAttribute;

enum
   {
	TEXT_SUBSTITUTION_CURRENT_PAGE = 1,
	TEXT_SUBSTITUTION_TOTAL_PAGES,
	TEXT_SUBSTITUTION_CURRENT_DATE,
   };

@interface TextSubstitution : NSObject 
   {
	int substitutionType;
	NSMutableDictionary *parameters;
   }

+(id)textSubstitutionWithType:(int)sType;
-(id)initWithType:(int)n;
-(int)substitutionType;
-(NSDictionary*)parameters;
-(NSString*)substitutedValueFromDictionary:(NSDictionary*)dict;

@end
