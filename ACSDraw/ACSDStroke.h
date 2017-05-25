//
//  ACSDStroke.h
//  ACSDraw
//
//  Created by Alan Smith on Mon Jan 14 2002.
//  Copyright (c) 2001 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "ACSDAttribute.h"


@class GraphicView;
@class ACSDGraphic;
@class ACSDLineEnding;

@interface ACSDStroke : ACSDAttribute
   {
   }

@property 	(copy) NSColor *colour;
@property 	float lineWidth;
@property 	int lineCap,lineJoin;
@property (strong)	NSArray *dashes;
@property 	float dashPhase;
@property (nonatomic,strong) 	ACSDLineEnding *lineStart,*lineEnd;

+ (id)defaultStroke;
+ (id)tinyStroke;
+ (NSMutableArray*)initialStrokes;

-(id)initWithColour:(NSColor*)col width:(float)w;

-(void)setLineStart:(ACSDLineEnding*)l;
-(void)setLineEnd:(ACSDLineEnding*)l;
-(void)changeLineWidth:(float)lw view:(GraphicView*)gView;
-(void)changeColour:(NSColor*)col view:(GraphicView*)gView;
-(void)strokePath:(NSBezierPath*)path;
-(void)setDashes:(NSArray*)d view:(GraphicView*)gView;
-(void)changeLineStart:(ACSDLineEnding*)le view:(GraphicView*)gView;
-(void)changeLineEnd:(ACSDLineEnding*)le view:(GraphicView*)gView;
-(void)changeLineCap:(int)lc view:(GraphicView*)gView;
-(void)changeDashPhase:(float)dp view:(GraphicView*)gView;
-(void)changeLineJoin:(int)lj view:(GraphicView*)gView;
-(float)paddingRequired;
-(ACSDStroke*)strokeWithReversedLineEndingsFromList:(NSMutableArray*)strokes;

@end
