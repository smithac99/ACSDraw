//
//  TextStyleHolder.h
//  ACSDraw
//
//  Created by alan on 08/01/07.
//  Copyright 2007 Alan C Smith. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface TextStyleHolder : NSObject<NSCopying>
{
	NSString *fontFamilyName;
	NSColor *colour;
	int alignment,underline;
	float firstLineIndent,indent,lineHeight,afterSpace,beforeSpace,fontSize,leading;
	BOOL generateAppleHelp;
}

@property float firstLineIndent,indent,lineHeight,afterSpace,beforeSpace,fontSize,leading;
@property BOOL generateAppleHelp;
@property int alignment,underline;

+(TextStyleHolder*)textStyleHolderWithFont:(NSFont*)f colour:(NSColor*)col paragraph:(NSParagraphStyle*)ps underline:(int)ul;
+(TextStyleHolder*)textStyleHolderWithFont:(NSFont*)f colour:(NSColor*)col paragraph:(NSParagraphStyle*)ps underline:(int)ul  lineHeight:(float)lh;
- (id)initWithFont:(NSFont*)f colour:(NSColor*)col paragraph:(NSParagraphStyle*)ps underline:(int)ul;
- (id)initWithFont:(NSFont*)f colour:(NSColor*)col paragraph:(NSParagraphStyle*)ps underline:(int)ul lineHeight:(float)lh;

-(NSString*)fontFamilyName;
-(NSColor*)colour;
-(int)alignment;
-(int)underline;

@end
