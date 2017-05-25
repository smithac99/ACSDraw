//
//  ACSDFill.h
//  ACSDraw
//
//  Created by Alan Smith on Mon Jan 14 2002.
//  Copyright (c) 2001 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "ACSDAttribute.h"


@interface ACSDFill : ACSDAttribute

@property BOOL useCurrent;
@property (strong) NSColor *colour;

+ (id)defaultFill;
+ (id)parentFill;
+ (NSMutableArray*)initialFills;

-(id)initWithColour:(NSColor*)col;
-(id)initWithColour:(NSColor*)col useCurrent:(BOOL)uc;
- (void) encodeWithCoder:(NSCoder*)coder;
- (id) initWithCoder:(NSCoder*)coder;
-(id)initUseCurrent;

-(BOOL)canFill;

-(void)changeColour:(NSColor*)col view:(GraphicView*)gView;
-(void)fillPath:(NSBezierPath*)path;
-(void)fillPath:(NSBezierPath*)path attributes:(NSDictionary*)attributes;
-(void)buildPDFData;
-(void)freePDFData;

@end
