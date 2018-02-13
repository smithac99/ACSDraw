//
//  ACSDStroke.mm
//  ACSDraw
//
//  Created by Alan Smith on Mon Jan 14 2002.
//  Copyright (c) 2001 __MyCompanyName__. All rights reserved.
//

#import "ACSDStroke.h"
#import "ACSDGraphic.h"
#import "ACSDLineEnding.h"
#import "GraphicView.h"
#import "SVGWriter.h"



@implementation ACSDStroke

+ (id)defaultStroke
   {
    static ACSDStroke *defaultStroke = nil;
	if (!defaultStroke)
        defaultStroke = [[ACSDStroke alloc] initWithColour:[NSColor blackColor] width:1.0];
    return defaultStroke;
   }

+ (id)tinyStroke
   {
    static ACSDStroke *tinyStroke = nil;
	if (!tinyStroke)
        tinyStroke = [[ACSDStroke alloc] initWithColour:[NSColor blackColor] width:0.0];
    return tinyStroke;
   }

+ (NSMutableArray*)initialStrokes
   {
	NSMutableArray* arr = [NSMutableArray arrayWithCapacity:10];
	[arr addObject:[[ACSDStroke alloc]initWithColour:nil width:0.0]];
	[arr addObject:[[ACSDStroke alloc]initWithColour:[NSColor blackColor] width:0.25]];
	[arr addObject:[[ACSDStroke alloc]initWithColour:[NSColor blackColor] width:1.0]];
	[arr addObject:[[ACSDStroke alloc]initWithColour:[NSColor blackColor] width:2.0]];
	[arr addObject:[[ACSDStroke alloc]initWithColour:[NSColor blackColor] width:3.0]];
	[arr addObject:[[ACSDStroke alloc]initWithColour:[NSColor blackColor] width:5.0]];
	[arr addObject:[[ACSDStroke alloc]initWithColour:[NSColor blueColor] width:2.0]];
	[arr addObject:[[ACSDStroke alloc]initWithColour:[NSColor redColor] width:3.0]];
	[arr addObject:[[ACSDStroke alloc]initWithColour:[NSColor greenColor] width:4.0]];
    return arr;
   }

-(id)initWithColour:(NSColor*)col width:(float)w
   {
	if (self = [super init])
	   {
		self.colour = col;
		self.lineWidth = w;
		self.dashes = [NSArray array];
		self.lineStart = [ACSDLineEnding defaultLineEnding];
		self.lineEnd = [ACSDLineEnding defaultLineEnding];
		self.lineCap = 0;
		self.dashPhase = 0.0;
	   }
	return self;
   }

-(id)initWithColour:(NSColor*)col width:(float)w lineStart:(ACSDLineEnding*)ls lineEnd:(ACSDLineEnding*)le dashes:(NSArray*)d dashPhase:(float) dp lineCap:(int)lc
   {
	if (self = [super init])
	   {
		self.colour = col;
		self.lineWidth = w;
		self.dashes = d;
		self.lineStart = ls;
		self.lineEnd = le;
		self.lineCap = lc;
		self.dashPhase = dp;
	   }
	return self;
   }

- (id)copyWithZone:(NSZone *)zone 
   {
    id obj =  [[[self class] allocWithZone:zone] initWithColour:[self colour] width:[self lineWidth] lineStart:self.lineStart lineEnd:self.lineEnd
		dashes:[self dashes] dashPhase:[self dashPhase] lineCap:[self lineCap]];
	[((ACSDStroke*)obj) setLineJoin:[self lineJoin]];
	return obj;
   }

- (void) encodeWithCoder:(NSCoder*)coder
   {
	[super encodeWithCoder:coder];
	[coder encodeObject:[self colour] forKey:@"ACSDStroke_colour"];
	[coder encodeFloat:self.lineWidth forKey:@"ACSDStroke_lineWidth"];
	[coder encodeFloat:self.dashPhase forKey:@"ACSDStroke_dashPhase"];
	[coder encodeObject:[self dashes] forKey:@"ACSDStroke_dashes"];
	[coder encodeConditionalObject:self.lineStart forKey:@"ACSDStroke_lineStart"];
	[coder encodeConditionalObject:self.lineEnd forKey:@"ACSDStroke_lineEnd"];
	[coder encodeInt:self.lineCap forKey:@"ACSDStroke_lineCap"];
	[coder encodeInt:self.lineJoin forKey:@"ACSDStroke_lineJoin"];
   }

- (id) initWithCoder:(NSCoder*)coder
   {
	self = [super initWithCoder:coder];
	self.colour = [coder decodeObjectForKey:@"ACSDStroke_colour"];
	self.lineWidth = [coder decodeFloatForKey:@"ACSDStroke_lineWidth"];
	self.dashPhase = [coder decodeFloatForKey:@"ACSDStroke_dashPhase"];
	self.dashes = [coder decodeObjectForKey:@"ACSDStroke_dashes"];
	[self setLineStart:[coder decodeObjectForKey:@"ACSDStroke_lineStart"]];
	[self setLineEnd:[coder decodeObjectForKey:@"ACSDStroke_lineEnd"]];
	[self setLineCap:[coder decodeIntForKey:@"ACSDStroke_lineCap"]];
	[self setLineJoin:[coder decodeIntForKey:@"ACSDStroke_lineJoin"]];
	return self;
   }

-(BOOL)isSameAs:(id)obj
   {
	if (![super isSameAs:obj])
		return NO;
	if (!([self.colour isEqual:[obj colour]] && self.lineWidth == [(ACSDStroke*)obj lineWidth] && self.lineCap == [((ACSDStroke*)obj) lineCap] && self.dashPhase == [((ACSDStroke*)obj) dashPhase]))
		return NO;
	if ((self.dashes == nil) != ([obj dashes] == nil))
		return NO;
	if (self.dashes && ![self.dashes isEqualToArray:[obj dashes]])
		return NO;
	if ((self.lineStart == nil) != ([obj lineStart] == nil))
		return NO;
	if (self.lineStart && ![self.lineStart isSameAs:[obj lineStart]])
		return NO;
	if ((self.lineEnd == nil) != ([obj lineEnd] == nil))
		return NO;
	if (self.lineEnd && ![self.lineEnd isSameAs:[obj lineEnd]])
		return NO;
	return YES;
   }
   
-(ACSDStroke*)strokeWithReversedLineEndingsFromList:(NSMutableArray*)strokes
   {
	ACSDStroke *tempStroke = [self copy];
	ACSDLineEnding *tempLe = [tempStroke lineStart];
	[tempStroke setLineStart:[tempStroke lineEnd]];
	[tempStroke setLineEnd:tempLe];
	for (ACSDStroke *s in strokes)
		if ([tempStroke isSameAs:s])
			return s;
	[strokes addObject:tempStroke];
	return tempStroke;
   }

-(void)setLineStart:(ACSDLineEnding*)l
   {
	   if (l == self.lineStart)
		   return;
	if (self.lineStart)
	   {
		[self.lineStart removeGraphic:self];
	   }
	if (l)
		[l addGraphic:self];
	_lineStart = l;
   }

-(void)setLineEnd:(ACSDLineEnding*)l
   {
	if (l == self.lineEnd)
		return;
	if (self.lineEnd)
	   {
		[self.lineEnd removeGraphic:self];
	   }
	if (l)
		[l addGraphic:self];
	_lineEnd = l;
   }

-(void)setDashes:(NSArray*)d view:(GraphicView*)gView
   {
	[self setDashes:d];
	[self invalidateGraphicsRefreshCache:YES];
   }

-(void)changeLineWidth:(float)lw view:(GraphicView*)gView
   {
	[self invalidateGraphicsRefreshCache:NO];
	[self setLineWidth:lw];
	[self invalidateGraphicsRefreshCache:YES];
   }

-(void)changeDashPhase:(float)dp view:(GraphicView*)gView
   {
	[self invalidateGraphicsRefreshCache:NO];
	[self setDashPhase:dp];
	[self invalidateGraphicsRefreshCache:YES];
   }

-(void)changeLineCap:(int)lc view:(GraphicView*)gView
   {
	[self invalidateGraphicsRefreshCache:NO];
	[self setLineCap:lc];
	[self invalidateGraphicsRefreshCache:YES];
   }

-(void)changeLineJoin:(int)lj view:(GraphicView*)gView
{
	[self invalidateGraphicsRefreshCache:NO];
	[self setLineJoin:lj];
	[self invalidateGraphicsRefreshCache:YES];
}

-(void)changeColour:(NSColor*)col view:(GraphicView*)gView
   {
	[self invalidateGraphicsRefreshCache:NO];
	[self setColour:col];
	[self invalidateGraphicsRefreshCache:YES];
   }

-(void)changeLineStart:(ACSDLineEnding*)le view:(GraphicView*)gView
   {
    if (le == self.lineStart)
		return;
	[self invalidateGraphicsRefreshCache:NO];
	[self setLineStart:le];
	[self invalidateGraphicsRefreshCache:YES];
   }

-(void)changeLineEnd:(ACSDLineEnding*)le view:(GraphicView*)gView
   {
    if (le == self.lineEnd)
		return;
	[self invalidateGraphicsRefreshCache:NO];
	[self setLineEnd:le];
	[self invalidateGraphicsRefreshCache:YES];
   }

-(void)strokePath:(NSBezierPath*)path
   {
	if ([self colour])
	   {
		[NSGraphicsContext saveGraphicsState];
		[path setLineWidth:[self lineWidth]];
		[self.colour set];
		if (self.dashes)
		   {
			NSInteger ct = (NSInteger)[self.dashes count];
			if (ct > 0)
			   {
				CGFloat *farr = new CGFloat[ct];
				for (int i = 0;i < ct;i++)
					farr[i] = [[self.dashes objectAtIndex:i]floatValue];
				[path setLineDash: farr count: ct phase: self.dashPhase];
				delete[]farr;
			   }
		   }
		if ([self lineCap])
			[path setLineCapStyle:(NSLineCapStyle)[self lineCap]];
		[path setLineJoinStyle:(NSLineJoinStyle)[self lineJoin]];
		[path stroke];
		[path setLineDash:NULL count:0 phase:0.0];
		[path setLineCapStyle:NSButtLineCapStyle];
		[NSGraphicsContext restoreGraphicsState];
	   }
   }

-(float)paddingRequired
   {
	float pad = [self lineWidth];
	if ([self lineStart] && [[self lineStart]graphic])
	   {
		float x = [[[self lineStart]graphic]bounds].size.width * [[self lineStart]scale]* [[self lineStart]aspect] * [self lineWidth];
		if (x > pad)
			pad = x;
	   }
	if ([self lineEnd] && [[self lineEnd]graphic])
	   {
		float x = [[[self lineEnd]graphic]bounds].size.width * [[self lineEnd]scale]* [[self lineEnd]aspect] * [self lineWidth];
		if (x > pad)
			pad = x;
	   }
	return pad * 2.0;
   }

-(void)notifyOnADDOrRemove
   {
	[[NSNotificationCenter defaultCenter] postNotificationName:ACSDRefreshStrokesNotification object:self];
   }

-(void)writeSVGData:(SVGWriter*)svgWriter
   {
	if (self.colour == nil)
	   {
		[[svgWriter contents]appendString:@"stroke=\"none\" "];
		return;
	   }
	[[svgWriter contents]appendFormat:@"stroke=\"%@\" ",string_from_nscolor([self colour])];
	if (self.lineWidth == 0)
		[[svgWriter contents]appendString:@"stroke-width=\"0.001\" "];
	else
		[[svgWriter contents]appendFormat:@"stroke-width=\"%g\" ",[self lineWidth]];
	float opacity = [[self colour]alphaComponent];
	if (opacity < 1.0)
		[[svgWriter contents]appendFormat:@"stroke-opacity=\"%g\" ",opacity];
	if (self.lineCap > 0)
	   {
		NSString *lcString;
		if (self.lineCap == 1)
			lcString = @"round";
		else 
			lcString = @"square";
		[[svgWriter contents]appendFormat:@"stroke-linecap=\"%@\" ",lcString];
	   }
	   if (self.lineJoin > 0)
	   {
		   NSString *ljString;
		   if (self.lineJoin == 1)
			   ljString = @"round";
		   else
			   ljString = @"bevel";
		   [[svgWriter contents]appendFormat:@"stroke-linejoin=\"%@\" ",ljString];
	   }
	NSInteger count;
	if ((count = [self.dashes count]) > 0)
	   {
		[[svgWriter contents]appendFormat:@"stroke-dashoffset=\"%g\" ",self.dashPhase];
		[[svgWriter contents]appendFormat:@"stroke-dasharray=\"%g",[[self.dashes objectAtIndex:0]floatValue]];
		for (int i = 1;i < count;i++)
			[[svgWriter contents]appendFormat:@",%g",[[self.dashes objectAtIndex:i]floatValue]];
		[[svgWriter contents]appendString:@"\" "];
	   }
   }

-(NSString*)canvasData:(CanvasWriter*)canvasWriter
{
	NSMutableString *resultString = [NSMutableString stringWithCapacity:50];
	if (self.lineCap > 0)
	{
		NSString *lcString;
		if (self.lineCap == 1)
			lcString = @"round";
		else 
			lcString = @"square";
		[resultString appendFormat:@"ctx.linecap=\"%@\";",lcString];
	}
	if (self.lineJoin > 0)
	{
		NSString *lcString;
		if (self.lineJoin == 1)
			lcString = @"round";
		else 
			lcString = @"bevel";
		[resultString appendFormat:@"ctx.lineJoin=\"%@\";",lcString];
	}
	[resultString appendFormat:@"ctx.strokeStyle=\"%@\";\nctx.lineWidth=\"%g\";",rgba_from_nscolor([self colour]),self.lineWidth];
	return resultString;
}

-(NSSet*)usedShadows
   {
	NSMutableSet *shadowSet = [NSMutableSet setWithCapacity:10];
	if (self.lineEnd)
		[shadowSet unionSet:[self.lineEnd usedShadows]];
	if (self.lineStart)
		[shadowSet unionSet:[self.lineStart usedShadows]];
	return shadowSet;
   }

-(NSSet*)usedStrokes
   {
	NSMutableSet *strokeSet = [NSMutableSet setWithCapacity:10];
	if (self.lineEnd)
		[strokeSet unionSet:[self.lineEnd usedStrokes]];
	if (self.lineStart)
		[strokeSet unionSet:[self.lineStart usedStrokes]];
	return strokeSet;
   }

-(NSSet*)usedFills
   {
	NSMutableSet *fillSet = [NSMutableSet setWithCapacity:10];
	if (self.lineEnd)
		[fillSet unionSet:[self.lineEnd usedFills]];
	if (self.lineStart)
		[fillSet unionSet:[self.lineStart usedFills]];
	return fillSet;
   }

-(void)setDeleted:(BOOL)d
   {
	if (d == deleted)
		return;
	[super setDeleted:d];
	int inc = (deleted?-1:1);
	if (self.lineStart)
		[self.lineStart addToNonDeletedCount:inc];
	if (self.lineEnd)
		[self.lineEnd addToNonDeletedCount:inc];
   }


@end
