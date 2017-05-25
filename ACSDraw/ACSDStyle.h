//
//  ACSDStyle.h
//  ACSDraw
//
//  Created by alan on 30/01/07.
//  Copyright 2007 Alan C Smith. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "KeyedAttributeObject.h"
@class ACSDrawDocument;

extern NSString *StyleAttribute;

extern NSString *StyleFontFamilyName;
extern NSString *StyleFontPointSize;
extern NSString *StyleFirstIndent;
extern NSString *StyleLeftIndent;
extern NSString *StyleRightIndent;
extern NSString *StyleLeading;
extern NSString *StyleSpaceAfter;
extern NSString *StyleSpaceBefore;


@interface ACSDStyle : KeyedAttributeObject 
   {
	BOOL nullStyle,generateAppleHelp;
	ACSDStyle *basedOn,*nextStyle;
	NSMutableDictionary *attributes;
	NSMutableSet *referrers;
   }

@property (strong) NSString *name;

@property BOOL nullStyle,generateAppleHelp;

+(NSMutableArray*)initialStyles;
+(ACSDStyle*)defaultStyle;
+(NSMutableDictionary*)attributesFromTypingAttributes:(NSDictionary*)typing;
+(ACSDStyle*) styleFromTypingAttributes:(NSDictionary*)typing;
+(NSMutableDictionary*)defaultAttributes;
+(NSDictionary*)stylesByKey:(NSArray*)styles;
+(NSDictionary*)stylesByName:(NSArray*)styles;
-(id)initWithName:(NSString*)n font:(NSFont*)f;
- (id)initWithAttributes:(NSMutableDictionary*)d;
- (id)initWithNoAttributes;
- (id)initWithName:(NSString*)n;
- (id)initWithName:(NSString*)n basedOn:(ACSDStyle*)b;
-(void)addReferrer:(ACSDStyle*)style;
-(void)removeReferrer:(ACSDStyle*)style;
-(void)setBasedOn:(ACSDStyle*)style;
-(ACSDStyle*)basedOn;
-(NSString*)name;
-(void)setName:(NSString*)n;
-(NSMutableDictionary*)attributes;
-(void)setAttributes:(NSMutableDictionary*)a;
-(id)attributeForKey:(id)key;
-(void)setAttribute:(id)attr forKey:(id)key;
-(id)chainedObjectForKey:(id)key;
-(NSString*)fontFace;
-(void)setFontFace:(id)ff;
-(NSString*)fontFamily;
-(void)setFontFamily:(id)ff;
-(NSColor*)foregroundColour;
-(void)setForegroundColour:(id)col;
-(float)fontPointSize;
-(void)setFontPointSize:(float)f;
-(NSTextAlignment)textAlignment;
-(void)setTextAlignment:(NSTextAlignment)a;
-(NSFont*)fontForAttributes;
-(NSMutableDictionary*)textAttributes;
-(float)floatValueForKey:(id)key;
-(BOOL)basedOnWouldCreateCycle:(ACSDStyle*)bo;
-(NSMutableDictionary*)textAndStyleAttributes;
-(void)setFloatValue:(float)f forKey:(id)k;
-(NSMutableDictionary*)baseFontAttributes;
-(NSMutableDictionary*)fullAttributes;
-(NSMutableDictionary*)attributesOverridingStyle:(NSDictionary*)typing;
+(NSMutableDictionary*)typingAttributes:(NSDictionary*)typing overridingStyleAttributes:(NSDictionary*)styleAttributes;
+(NSMutableDictionary*)attributesFrom:(NSDictionary*)a1 notIn:(NSDictionary*)a2;
+(NSMutableDictionary*)typingAttributesFromAttributes:(NSDictionary*)attrs existingParagraphStyle:(NSParagraphStyle*)existingPS;
+(NSMutableDictionary*)typingAttributesFromAttributes:(NSDictionary*)attrs existingAttributes:(NSDictionary*)existingAttrs existingParagraphStyle:(NSParagraphStyle*)existingPS;
+(NSDictionary*)attributesFrom:(NSDictionary*)a1 differingFrom:(NSDictionary*)a2;

@end
