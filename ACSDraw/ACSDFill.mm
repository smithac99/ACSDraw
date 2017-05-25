//
//  ACSDFill.mm
//  ACSDraw
//
//  Created by Alan Smith on Mon Jan 14 2002.
//  Copyright (c) 2001 __MyCompanyName__. All rights reserved.
//

#import "ACSDFill.h"
#import "ACSDGradient.h"
#import "ACSDPattern.h"
#import "ACSDGraphic.h"
#import "GraphicView.h"
#import "GradientElement.h"
#import "SVGWriter.h"
#import "ObjectPDFData.h"


@implementation ACSDFill


+ (id)defaultFill
{
	static ACSDFill *defaultFill = nil;
	if (!defaultFill)
		defaultFill = [[ACSDFill alloc] initWithColour:[NSColor whiteColor]];
	return defaultFill;
}

+ (id)parentFill
{
	static ACSDFill *parentFill = nil;
	if (!parentFill)
		parentFill = [[ACSDFill alloc] initUseCurrent];
	return parentFill;
}

+ (NSMutableArray*)initialFills
{
	NSMutableArray* arr = [NSMutableArray arrayWithCapacity:10];
	[arr addObject:[[ACSDFill alloc]initWithColour:nil]];
	[arr addObject:[[ACSDFill alloc]initWithColour:[NSColor whiteColor]]];
	[arr addObject:[[ACSDFill alloc]initWithColour:[NSColor blueColor]]];
	[arr addObject:[[ACSDFill alloc]initWithColour:[NSColor greenColor]]];
	[arr addObject:[[ACSDFill alloc]initWithColour:[NSColor redColor]]];
	[arr addObject:[[ACSDGradient alloc]initWithColour1:[NSColor redColor] colour2:[NSColor blackColor]]];
	[arr addObject:[ACSDPattern defaultPattern]];
	return arr;
}

-(id)initWithColour:(NSColor*)col
{
	if (self = [self initWithColour:col useCurrent:false])
	{
	}
	return self;
}

-(id)initWithColour:(NSColor*)col useCurrent:(BOOL)uc
{
	if (self = [super init])
	{
		self.colour = col;
		self.useCurrent = uc;
	}
	return self;
}

-(id)initUseCurrent
{
	if (self = [self initWithColour:nil useCurrent:YES])
	{
	}
	return self;
}

- (id)copyWithZone:(NSZone *)zone
{
	return [[[self class] allocWithZone:zone] initWithColour:[self colour] useCurrent:self.useCurrent];
}

- (void) encodeWithCoder:(NSCoder*)coder
{
	[super encodeWithCoder:coder];
	[coder encodeObject:[self colour]forKey:@"ACSDFill_colour"];
	[coder encodeObject:[NSNumber numberWithBool:self.useCurrent]forKey:@"ACSDFill_useCurrent"];
}

- (id) initWithCoder:(NSCoder*)coder
{
	self = [super initWithCoder:coder];
	self.colour = [coder decodeObjectForKey:@"ACSDFill_colour"];
	self.useCurrent = [[coder decodeObjectForKey:@"ACSDFill_useCurrent"]boolValue];
	return self;
}

-(void)changeColour:(NSColor*)col view:(GraphicView*)gView
{
	[self setColour:col];
	[self invalidateGraphicsRefreshCache:YES];
}

-(BOOL)canFill
{
	return (self.colour != nil) || self.useCurrent;
}

-(void)fillPath:(NSBezierPath*)path
{
	if (self.colour)
	{
		[self.colour set];
		[path fill];
	}
	else if(self.useCurrent)
		[path fill];
}

-(void)fillPath:(NSBezierPath*)path attributes:(NSDictionary*)attributes
{
	[self fillPath:path];
}

-(NSString*)canvasData:(CanvasWriter*)canvasWriter
{
	if (self.colour)
		return [NSString stringWithFormat:@"ctx.fillStyle=\"%@\";",rgba_from_nscolor([self colour])];
	return @"";
}

-(void)writeSVGData:(SVGWriter*)svgWriter
{
	if (self.colour == nil)
	{
		[[svgWriter contents]appendString:@"fill=\"none\" "];
		return;
	}
	[[svgWriter contents]appendFormat:@"fill=\"%@\" ",string_from_nscolor([self colour])];
	float opacity = [[self colour]alphaComponent];
	if (opacity < 1.0)
		[[svgWriter contents]appendFormat:@"fill-opacity=\"%g\" ",opacity];
}

-(void)notifyOnADDOrRemove
{
	[[NSNotificationCenter defaultCenter] postNotificationName:ACSDFillAdded object:self];
}


-(BOOL)isSameAs:(id)obj
{
	if (![super isSameAs:obj])
		return NO;
	if ([obj useCurrent] != self.useCurrent)
		return NO;
	if ((self.colour == nil) != ([obj colour] == nil))
		return NO;
	if (self.colour)
		if (!([[obj colour]isEqual:self.colour]))
			return NO;
	return YES;
}

-(void)buildPDFData
{
}

-(void)freePDFData
{
}

@end
