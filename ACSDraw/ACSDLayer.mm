//
//  ACSDLayer.m
//  ACSDraw
//
//  Created by Alan Smith on Wed Jan 23 2002.
//  Copyright (c) 2001 __MyCompanyName__. All rights reserved.
//

#import "ACSDLayer.h"
#import "ACSDPage.h"
#import "SelectionSet.h"
#import "SVGWriter.h"
#import "ACSDGraphic.h"
#import "ArrayAdditions.h"
#import "ACSDText.h"
#import "ACSDGroup.h"
#import "TriggerTableSource.h"
#import "ACSDLink.h"
#import "NSString+StringAdditions.h"


@implementation ACSDLayer

@synthesize visible,editable,exportable,page,name;

+ (NSString*)nextNameForDocument:(ACSDrawDocument*)doc
   {
    NSMutableDictionary *dict = [doc nameCounts];
	id val;
	int intVal;
	NSString *objName = @"Layer";
	if ((val = [dict objectForKey:objName]) == nil)
		intVal = 0;
	else
	    intVal = [val intValue];
	intVal++;
	val = [NSNumber numberWithInt:intVal];
	[dict setObject:val forKey:objName];
	return [NSString stringWithFormat:@"%@%d",objName,intVal];
   }

-(id)initWithName:(NSString*)n isGuideLayer:(BOOL)gl
{
	if ((self = [super init]))
	{
		graphics = [[NSMutableArray arrayWithCapacity:15]retain];
		selectedGraphics = [[SelectionSet alloc] initWithCapacity:15];
		visible = YES;
		editable = YES;
		exportable = !gl;
		name = [n copy];
		isGuideLayer = gl;
		page = nil;
	}
	return self;
}

- (void) encodeWithCoder:(NSCoder*)coder
{
	[coder encodeObject:graphics forKey:@"ACSDLayer_elements"];
	[coder encodeObject:name forKey:@"ACSDLayer_name"];
	[coder encodeBool:visible forKey:@"ACSDLayer_visible"];
	[coder encodeBool:editable forKey:@"ACSDLayer_editable"];
	[coder encodeBool:isGuideLayer forKey:@"ACSDLayer_isGuideLayer"];
    [coder encodeBool:exportable forKey:@"ACSDLayer_exportable"];
    [coder encodeInt:self.zPosOffset forKey:@"ACSDLayer_zPosOffset"];
}

- (id)initWithCoder:(NSCoder*)coder
{
	self = [super init];
	graphics = [[coder decodeObjectForKey:@"ACSDLayer_elements"]retain];
	name = [[coder decodeObjectForKey:@"ACSDLayer_name"]retain];
	visible = [coder decodeBoolForKey:@"ACSDLayer_visible"];
	editable = [coder decodeBoolForKey:@"ACSDLayer_editable"];
	isGuideLayer = [coder decodeBoolForKey:@"ACSDLayer_isGuideLayer"];
	//id b = [coder decodeObjectForKey:@"ACSDLayer_exportable"];
	//NSLog(@"%@,%@",b,NSStringFromClass([b class]));
	exportable = [coder decodeBoolForKey:@"ACSDLayer_exportable"];
	//exportable = [b boolValue];
	selectedGraphics = [[SelectionSet alloc] initWithCapacity:15];
	page = nil;
    self.zPosOffset = [coder decodeIntForKey:@"ACSDLayer_zPosOffset"];
	return self;
}

-(id)copy
{
	ACSDLayer *layer = [[[self class]alloc] initWithName:name isGuideLayer:isGuideLayer];
	[layer setVisible:visible];
	[layer setEditable:editable];
	[layer setExportable:exportable];
	NSMutableArray *newGraphics = [NSMutableArray arrayWithCapacity:[graphics count]];
	for (ACSDGraphic *g in graphics)
	{
		ACSDGraphic *gc = [[g copy] autorelease];
		[gc setLayer:layer];
		[newGraphics addObject:gc];
	}
	[layer setGraphics:newGraphics];
	return layer;
}

-(void)dealloc
{
	[graphics makeObjectsPerformSelector:@selector(setLayer:)withObject:nil];
	[graphics makeObjectsPerformSelector:@selector(clearReferences)];
	[graphics release];
	[selectedGraphics release];
	[name release];
	[triggers release];
	[super dealloc];
}

- (BOOL)isEqual:(id)anObject
{
	return (self == anObject);
}

- (NSUInteger)hash
{
	return (NSUInteger)self;
}

-(void)setLayerVisible:(BOOL)v
{
	[self setVisible:v];
	for (ACSDGraphic *g in graphics)
		[g invalidateGraphicSizeChanged:NO shapeChanged:NO redraw:YES notify:NO];
}

-(BOOL)isGuideLayer
{
    return isGuideLayer;
}

-(NSMutableArray*)graphics
{
	return graphics;
}

-(void)setGraphics:(NSMutableArray*)gs
{
	if (graphics != gs)
	{
		[graphics release];
		graphics = [gs retain];
	}
}

-(SelectionSet*)selectedGraphics
{
	return selectedGraphics;
}

-(NSIndexSet*)indexesOfSelectedGraphics
{
    NSSet *objects = selectedGraphics.objects;
    NSMutableIndexSet *ixs = [NSMutableIndexSet indexSet];
    [graphics enumerateObjectsUsingBlock:^(id g, NSUInteger idx, BOOL *stop) {
        if ([objects containsObject:g])
            [ixs addIndex:idx];
    }];
    return ixs;
}
-(BOOL)addTrigger:(NSDictionary*)t
{
	if (!triggers)
		triggers = [[NSMutableArray arrayWithCapacity:10]retain];
	[triggers addObject:t];
	return YES;
}

-(BOOL)removeTrigger:(NSDictionary*)t
{
	NSUInteger i = [triggers indexOfObjectIdenticalTo:t];
	if (i == NSNotFound)
		return NO;
	[triggers removeObjectAtIndex:i];
	return YES;
}

- (int)showIndicator
{
	if ([(id)[self selectedGraphics]count] > 0)
		return 1;
	return 0;
}

-(void)deRegisterWithDocument:(ACSDrawDocument*)doc
{
	[doc deRegisterObject:self];
	[graphics makeObjectsPerformSelector:@selector(deRegisterWithDocument:)withObject:doc];
}

-(void)registerWithDocument:(ACSDrawDocument*)doc
{
	[doc registerObject:self];
	[graphics makeObjectsPerformSelector:@selector(registerWithDocument:)withObject:doc];
}


-(void)addGraphic:(ACSDGraphic*)graphic
{
    [graphics addObject:graphic];
    [graphic setLayer:self];
}

-(void)addGraphic:(ACSDGraphic*)graphic atIndex:(NSInteger)idx
{
    [graphics insertObject:graphic atIndex:idx];
    [graphic setLayer:self];
}

-(void)addGraphics:(NSArray*)gArray
{
	[graphics addObjectsFromArray:gArray];
	[graphics makeObjectsPerformSelector:@selector(setLayer:)withObject:self];
}

-(void)removeGraphic:(ACSDGraphic*)graphic
{
    [graphic setLayer:nil];
    [graphics removeObject:graphic];
}

-(void)removeGraphicAtIndex:(NSInteger)idx
{
    [graphics[idx] setLayer:nil];
    [graphics removeObjectAtIndex:idx];
}

-(void)updateForStyle:(id)style oldAttributes:(NSDictionary*)oldAttrs
{
	[graphics makeObjectsPerformSelector:@selector(updateForStyle:oldAttributes:)withObject:style andObject:oldAttrs];
}

-(void)removeGraphics:(NSArray*)gArray
{
	[gArray makeObjectsPerformSelector:@selector(setLayer:)withObject:nil];
	[graphics removeObjectsInArray:gArray];
}

-(void)magnifyAllObjects:(double)mag
{
	for (ACSDGraphic *g in graphics)
		[g setMagnification:mag];
}

-(NSSet*)allTheObjects
{
	NSMutableSet *set = [NSMutableSet setWithCapacity:[graphics count]];
	for (ACSDGraphic *g in graphics)
		[set unionSet:[g allTheObjects]];
	return set;
}

-(void)freePDFData
{
	for (ACSDGraphic *g in graphics)
		[g freePDFData];
}

-(void)buildPDFData
{
	for (ACSDGraphic *g in graphics)
		[g buildPDFData];
}

-(void)moveGraphicsByValue:(NSValue*)val
{
	[graphics makeObjectsPerformSelector:@selector(moveByValue:) withObject:val];
}

-(NSRect)unionGraphicBounds
{
    NSRect r = NSZeroRect;
    for (ACSDGraphic *g in graphics)
        r = NSUnionRect(r,[g transformedBounds]);
    return r;
}

-(NSRect)unionStrictGraphicBounds
{
    NSRect r = NSZeroRect;
    for (ACSDGraphic *g in graphics)
        r = NSUnionRect(r,[g transformedStrictBounds]);
    return r;
}

-(NSMutableArray*)triggers
{
	return triggers;
}

-(BOOL)atLeastOneObjectExists
{
	return [graphics count] > 0;
}

-(BOOL)containsImages
{
	return [graphics orMakeObjectsPerformSelector:@selector(isOrContainsImage)];
}


-(void)writeSVGData:(SVGWriter*)svgWriter
{
	[[svgWriter contents] appendFormat:@"%@<g id=\"%@\" ",[svgWriter indentString],name];
	if (!visible)
		[[svgWriter contents] appendString:@"visibility=\"hidden\" "];
	[[svgWriter contents] appendString:@">\n"];
	if (triggers)
	{
		for (int i = 0,ct = (int)[triggers count];i < ct;i++)
		{
			NSDictionary *t = [triggers objectAtIndex:i];
			[[svgWriter contents] appendString:@"<set attributeName=\"display\" to="];
			NSString *temp;
			if ([[t objectForKey:@"action"]intValue] == TRIGGER_SHOW)
				temp = @"inline";
			else
				temp = @"none";
			int j = [[t objectForKey:@"event"]intValue];
			[[svgWriter contents] appendFormat:@"\"%@\" begin=\"%@.%@\"/>\n",temp,[[t objectForKey:@"graphic"]name],triggerEventStrings[j]];
		}
	}
	[svgWriter indentDef];
	for (ACSDGraphic *g in graphics)
		[g writeSVGData:svgWriter];
	[svgWriter outdentDef];
	[[svgWriter contents] appendFormat:@"%@</g>\n",[svgWriter indentString]];
}

-(NSString*)htmlDivName
{
	if ([page pageType] == PAGE_TYPE_MASTER)
		return [NSString stringWithFormat:@"m-%@",[self name]];
	return [self name];
}

-(void)processHTMLOptions:(NSMutableDictionary*)options
{
	if (isGuideLayer)
		return;
	if ((visible || (triggers && [triggers count] > 0)) && graphics && [graphics count] > 0)
	{
		NSMutableString *bodyString = [options objectForKey:@"bodyString"];
		NSSize sz = [[self document]documentSize];
		[bodyString appendFormat:@"<div id=\"%@\"style='margin-left:auto;margin-right:auto;width:%dpx;height:%dpx;",[self htmlDivName],(int)sz.width,(int)sz.height];
		if (!visible)
			[bodyString appendString:@"visibility:hidden;"];
		[bodyString appendFormat:@"background-color:%@;position:relative;'",string_from_nscolor([page backgroundColour])];
		[bodyString appendString:@">\n"];
		[graphics makeObjectsPerformSelector:@selector(processHTMLOptions:)withObject:options];
		[bodyString appendString:@"</div>\n"];
	}
}

-(ACSDrawDocument*)document
{
	return [page document];
}

-(NSMutableArray*)allTextObjects
{
	NSMutableArray *textObjects = [NSMutableArray arrayWithCapacity:10];
	for (ACSDGraphic *g in graphics)
		if ([g isKindOfClass:[ACSDText class]])
			[textObjects addObject:g];
	return textObjects;
}

-(void)fixTextBoxLinks
{
	for (ACSDGraphic *g in graphics)
	{
		if ([g isKindOfClass:[ACSDText class]])
		{
			if ([(ACSDText*)g previousText] == nil && [(ACSDText*)g nextText] != nil)
				[ACSDText sortOutLinkedTextGraphics:(ACSDText*)g];
		}
		else if ([g isKindOfClass:[ACSDGroup class]])
			[(ACSDGroup*)g fixTextBoxLinks];
	}
}

-(void)addLinksForPDFContext:(CGContextRef) context
{
	[graphics makeObjectsPerformSelector:@selector(addLinksForPDFContext:)withObject:(__bridge id)context];
}

-(void)invalidateTextFlowersOverlappingGraphics:(NSArray*)graphicArray maxIndex:(int)maxIndex
{
	int ct = (int)[graphicArray count];
	for (int j = 0;j < maxIndex;j++)
	{
		ACSDGraphic *behindGraphic = [graphics objectAtIndex:j];
		if ([behindGraphic doesTextFlow])
			for (int i = 0;i < ct;i++)
				if (NSIntersectsRect([behindGraphic displayBounds],[[graphicArray objectAtIndex:i]displayBounds]))
					[behindGraphic invalidateTextFlower];
	}
}

-(void)invalidateTextFlowersBehindGraphics:(NSArray*)graphicArray
{
	int foremostInd = -1,ct = (int)[graphicArray count];
	for (int i = 0;i < ct;i++)
	{
		int j = (int)[graphics indexOfObjectIdenticalTo:[graphicArray objectAtIndex:i]];
		if (j > foremostInd)
			foremostInd = j;
	}
	[self invalidateTextFlowersOverlappingGraphics:graphicArray maxIndex:foremostInd];
}

-(void)addGraphicsInFrontOfGraphic:(ACSDGraphic*)g toSet:(NSMutableSet*)set
{
	int i = (int)[graphics indexOfObjectIdenticalTo:g];
	for (int j = i + 1,ct = (int)[graphics count];j < ct;j++)
		[set addObject:[graphics objectAtIndex:j]];
	NSInteger layerInd = [page currentLayerInd] + 1;
	NSArray *layers = [page layers];
	for (NSInteger j = layerInd,ct = (NSInteger)[layers count];j < ct;j++)
	{
		ACSDLayer *l = [layers objectAtIndex:j];
		if ([l visible])
			[set addObjectsFromArray:[l graphics]];
	}
}

-(void)permanentScale:(float)sc transform:(NSAffineTransform*)t
{
	for (ACSDGraphic *g in graphics)
		[g permanentScale:sc transform:t];
}

-(NSString*)graphicXML:(NSMutableDictionary*)options
{
	if ((!isGuideLayer) && [graphics count] > 0)
	{
		NSMutableString *layerString = [NSMutableString stringWithCapacity:200];
		NSString *indent = [options objectForKey:xmlIndent];
		[layerString appendFormat:@"%@<layer name=\"%@\">\n",indent,name];
		[options setObject:[indent stringByAppendingString:@"\t"] forKey:xmlIndent];
		for (ACSDGraphic *g in graphics)
		{
			[layerString appendString:[g graphicXML:options]];
		}
		[layerString appendFormat:@"%@</layer>\n",indent];
		[options setObject:indent forKey:xmlIndent];
		return layerString;
	}
	return @"";
}

NSArray* OrderGraphics(NSArray* toDo)
{
    if ([toDo count] == 0)
        return toDo;
    NSMutableSet *set = [NSMutableSet set];
    for (ACSDGraphic *g in toDo)
        if (g.link != nil)
        {
            if ([g.link isKindOfClass:[ACSDLink class]])
                [set addObject:[NSValue valueWithNonretainedObject:((ACSDLink*)g.link).toObject]];
        }
    NSMutableArray *parents = [NSMutableArray array];
    NSMutableArray *nonparents = [NSMutableArray array];
    for (ACSDGraphic *g in toDo)
    {
        NSValue *v = [NSValue valueWithNonretainedObject:g];
        if ([set containsObject:v])
            [parents addObject:g];
        else
            [nonparents addObject:g];
    }
    NSArray *arr1 = OrderGraphics(parents);
    NSArray *arr2 = [nonparents sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
        return [[obj1 name]caseInsensitiveCompareWithNumbers:[obj2 name]];
    }];
    return [arr1 arrayByAddingObjectsFromArray:arr2];
}

static NSArray *GraphicHasLoop(ACSDGraphic *g)
{
	NSMutableArray *chain = [NSMutableArray arrayWithObject:g];
	id ptr = g;
	while (ptr)
	{
		if ([ptr respondsToSelector:@selector(link)] && [ptr link] && [[ptr link] isKindOfClass:[ACSDLink class]])
		{
			ACSDLink *l = [ptr link];
			ptr = l.toObject;
            if (ptr)
                [chain addObject:ptr];
			if (ptr == g)
				return chain;
		}
		else
			ptr = nil;
	}
	return nil;
}

-(NSString*)graphicXMLForEvent:(NSMutableDictionary*)options
{
	if ((!isGuideLayer) && [graphics count] > 0)
	{
		NSMutableString *layerString = [NSMutableString stringWithCapacity:200];
		BOOL okToContinue = YES;
        for (int i = 0;i < [graphics count];i++)
		{
            [graphics[i] tempSettings][@"gzidx"] = @(i);
			NSArray *chain;
			if ((chain = GraphicHasLoop(graphics[i])))
			{
				[layerString appendString:@"graphic parentage loop - "];
				for (ACSDGraphic *gc in chain)
					[layerString appendFormat:@"%@--",gc.name];
				[layerString appendString:@"\n"];
				okToContinue = NO;
				options[@"errors"] = @([options[@"errors"]intValue]+1);
			}
		}
		if (okToContinue)
		{
			NSArray *gs = OrderGraphics(graphics);
			for (ACSDGraphic *g in gs)
				[layerString appendString:[g graphicXMLForEvent:options]];
		}
		return layerString;
	}
	return @"";
}

@end
