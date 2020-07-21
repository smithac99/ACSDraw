//
//  SVGWriter.h
//  ACSDraw
//
//  Created by Alan Smith on Thu Mar 07 2002.
//  Copyright (c) 2001 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "ACSDrawDocument.h"
@class ShadowType;
@class ACSDGradient;
@class ACSDLineEnding;
@class ACSDGraphic;
@class ACSDFill;
@class ACSDStroke;

NSString* string_from_nscolor(NSColor *col);
NSString* string_from_path(NSBezierPath* path);
NSString* string_from_transform(NSAffineTransform *trans);
NSString* canvas_string_from_path(NSBezierPath* path);
NSString* rgba_from_nscolor(NSColor *col);
NSColor *colorFromRGBString(NSString* str);
id fillFromNodeAttributes(NSDictionary* attrs);
ACSDStroke* strokeFromNodeAttributes(NSDictionary* attrs);


@interface SVGWriter : NSObject
{
    ACSDrawDocument *document;
    NSMutableString *prefix,*defs,*contents;
    NSInteger page;
    NSString *clipPathName;
    NSMutableSet *lineEndings,*shadows;
    NSMutableArray *contentsStack;
    NSMutableArray *otherDefStrings;
    NSString *indentString;
}

@property (strong) NSMutableArray *gradients;
@property (strong) NSMutableArray *patterns;

-(id)initWithSize:(NSSize)sz document:(ACSDrawDocument*)doc page:(NSInteger)p;
-(void)createData;
-(void)createDataForGraphic:(ACSDGraphic*)g;
-(ACSDrawDocument*)document;
-(NSMutableString*)contents;
-(NSMutableString*)prefix;
-(NSMutableString*)defs;
-(void)addShadow:(ShadowType*)shad;
-(void)addGradient:(NSDictionary*)d;
-(void)addLineEnding:(ACSDLineEnding*)le;
-(void)addOtherDefString:(NSString*)defstr;
-(void)addPattern:(id)g;
-(NSString*)clipPathName;
-(void)setClipPathName:(NSString*)s;
-(NSString*)indentString;
-(void)indentDef;
-(void)outdentDef;
-(NSString*)fullString;
-(void)saveContents;
-(void)restoreContents;

@end
