//
//  ACSDTextStorage.mm
//  ACSDraw
//
//  Created by alan on 17/03/07.
//  Copyright 2007 Alan C Smith. All rights reserved.
//

#import "ACSDTextStorage.h"


@implementation ACSDTextStorage

- (id)init
   {
	if (self = [super init])
	   {
		mutableAttributedString = [[NSMutableAttributedString alloc]init];
	   }
	return self;
   }

- (id)initWithAttributedString:(NSAttributedString *)attributedString
   {
	if (self = [super init])
	   {
		mutableAttributedString = [[NSMutableAttributedString alloc]initWithAttributedString:attributedString];
	   }
	return self;
   }

- (NSString *)string
   {
	return [mutableAttributedString string];
   }

- (id)attribute:(NSString *)attributeName atIndex:(NSUInteger)index effectiveRange:(NSRangePointer)aRange
   {
	return [mutableAttributedString attribute:attributeName atIndex:index effectiveRange:aRange];
   }

- (NSDictionary *)attributesAtIndex:(NSUInteger)index effectiveRange:(NSRangePointer)aRange
   {
	return [mutableAttributedString attributesAtIndex:index effectiveRange:aRange];
   }


- (void)replaceCharactersInRange:(NSRange)aRange withString:(NSString *)aString
   {
	NSInteger changeInLength = [aString length] - aRange.length;
	[mutableAttributedString beginEditing];
	[mutableAttributedString replaceCharactersInRange:aRange withString:aString];
	[mutableAttributedString endEditing ];
	[self edited:NSTextStorageEditedCharacters range:aRange changeInLength:changeInLength];

   }

- (void)setAttributes:(NSDictionary *)attributes range:(NSRange)aRange
   {
	[mutableAttributedString beginEditing];
	[mutableAttributedString setAttributes:attributes range:aRange];
	[mutableAttributedString endEditing ];
	[self edited:NSTextStorageEditedCharacters range:aRange changeInLength:0];
   }

@end
