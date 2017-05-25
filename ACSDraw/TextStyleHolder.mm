//
//  TextStyleHolder.mm
//  ACSDraw
//
//  Created by alan on 08/01/07.
//  Copyright 2007 Alan C Smith. All rights reserved.
//

#import "TextStyleHolder.h"
#import "SVGWriter.h"


@implementation TextStyleHolder

@synthesize firstLineIndent,indent,lineHeight,afterSpace,beforeSpace,fontSize,leading,generateAppleHelp,alignment,underline;

+(TextStyleHolder*)textStyleHolderWithFont:(NSFont*)f colour:(NSColor*)col paragraph:(NSParagraphStyle*)ps underline:(int)ul
   {
	return [[[TextStyleHolder alloc]initWithFont:f colour:col paragraph:ps underline:ul]autorelease];
   }

+(TextStyleHolder*)textStyleHolderWithFont:(NSFont*)f colour:(NSColor*)col paragraph:(NSParagraphStyle*)ps underline:(int)ul  lineHeight:(float)lh
{
	return [[[TextStyleHolder alloc]initWithFont:f colour:col paragraph:ps underline:ul lineHeight:lh]autorelease];
}

- (id)initWithFont:(NSFont*)f colour:(NSColor*)col paragraph:(NSParagraphStyle*)ps underline:(int)ul
   {
	if ((self = [super init]))
	   {
		fontFamilyName = [[f familyName]copy];
		fontSize = [f pointSize];
		leading = [f leading];
		lineHeight = ([f ascender] - [f descender]) + [f leading];
		underline = ul;
		colour = [col copy];
		if (ps)
		   {
			alignment = (int)[ps alignment];
			firstLineIndent = [ps firstLineHeadIndent];
			indent = [ps headIndent];
			afterSpace = [ps paragraphSpacing];
			beforeSpace = [ps paragraphSpacingBefore];
		   }
	   }
	return self;
   }

- (id)initWithFont:(NSFont*)f colour:(NSColor*)col paragraph:(NSParagraphStyle*)ps underline:(int)ul lineHeight:(float)lh
{
	if ((self = [super init]))
	{
		fontFamilyName = [[f familyName]copy];
		fontSize = [f pointSize];
		leading = [f leading];
		lineHeight = lh;
		underline = ul;
		colour = [col copy];
		if (ps)
		{
			alignment = (int)[ps alignment];
			firstLineIndent = [ps firstLineHeadIndent];
			indent = [ps headIndent];
			afterSpace = [ps paragraphSpacing];
			beforeSpace = [ps paragraphSpacingBefore];
		}
	}
	return self;
}

- (id)initWithFontFamilyName:(NSString*)fs fontSize:(float)fsz leading:(float)l colour:(NSColor*)col underline:(int)ul lineHeight:(float)lh
				   alignment:(int)a firstLineIndent:(float)fli indent:(float)ind afterSpace:(float)af beforeSpace:(float)bef
   {
	if ((self = [super init]))
	   {
		fontFamilyName = [fs copy];
		fontSize = fsz;
		leading = l;
		colour = [col copy];
		alignment = a;
		firstLineIndent = fli;
		indent = ind;
		afterSpace = af;
		beforeSpace = bef;
		underline = ul;
		lineHeight = lh;
	   }
	return self;
   }

- (id)copyWithZone:(NSZone *)zone
   {
	return [[TextStyleHolder alloc]initWithFontFamilyName:fontFamilyName fontSize:fontSize leading:leading colour:colour underline:underline lineHeight:lineHeight
		alignment:alignment firstLineIndent:firstLineIndent indent:indent afterSpace:afterSpace beforeSpace:beforeSpace];
   }

-(void)dealloc
   {
	if (fontFamilyName)
		[fontFamilyName release];
	if (colour)
		[colour release];
	[super dealloc];
   }


-(NSString*)fontFamilyName
   {
	return fontFamilyName;
   }

-(NSColor*)colour
   {
	return colour;
   }

- (BOOL)isEqual:(id)anObject
   {
	if (![anObject isMemberOfClass:[self class]])
		return NO;
	if (![fontFamilyName isEqual:[anObject fontFamilyName]])
		return NO;
	if ((colour == nil) != ([anObject colour] == nil))
		return NO;
	if (colour && ![colour isEqual:[anObject colour]])
		return NO;
	return (fontSize == [(TextStyleHolder*)anObject fontSize]) && (leading == [(TextStyleHolder*)anObject leading])
		 && (alignment == [(TextStyleHolder*)anObject alignment]) && (firstLineIndent == [(TextStyleHolder*)anObject firstLineIndent]) && (indent == [(TextStyleHolder*)anObject indent]) && (afterSpace == [(TextStyleHolder*)anObject afterSpace])
		&& (beforeSpace == [(TextStyleHolder*)anObject beforeSpace]) && (underline == [(TextStyleHolder*)anObject underline]) && (lineHeight == [(TextStyleHolder*)anObject lineHeight]);
   }

- (NSUInteger)hash
   {
	return [[NSString stringWithFormat:@"%@/%@/%g/%g/%d/%g/%g/%g/%g%d%g",fontFamilyName,string_from_nscolor(colour),fontSize,leading,
		alignment,firstLineIndent,indent,afterSpace,beforeSpace,underline,lineHeight]hash];
   }

@end
