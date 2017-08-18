//
//  ACSDPage.mm
//  ACSDraw
//
//  Created by alan on Tue Feb 17 2004.
//  Copyright (c) 2004 __MyCompanyName__. All rights reserved.
//

#import "ACSDPage.h"
#import "ACSDLayer.h"
#import "ACSDrawDocument.h"
#import "ArrayAdditions.h"
#import "GraphicView.h"
#import "TextStyleHolder.h"
#import "SVGWriter.h"
#import "ObjectAdditions.h"
#import "HtmlExportController.h"
#import "ACSDText.h"
#import "GXPArchiveDelegate.h"

int weight_from_float(float w);
NSString* stringForAlignment(int ali);

NSString *ACSDPageAttributeChanged = @"ACSDPageAttributeChanged";

@implementation ACSDPage

@synthesize name,document,pageTitle,inactive,currentLayerInd,pageNo,guideLayerInd;

-(id)init
{
	if ((self = [super init]))
	{
		nextLayer = 1;
		layers = [[NSMutableArray arrayWithCapacity:10]retain];
		[layers addObject:[[[ACSDLayer alloc]initWithName:@"Guide Layer" isGuideLayer:YES]autorelease]];
		[layers addObject:[[[ACSDLayer alloc]initWithName:[self nextLayerName] isGuideLayer:NO]autorelease]];
		graphicViews = [[NSMutableSet alloc]initWithCapacity:2];
		currentLayerInd = 1;
		guideLayerInd = 0;
		[self setLayerPages];
		self.animations = [NSMutableArray arrayWithCapacity:5];
	}
	return self;
}

-(id)initWithDocument:(ACSDrawDocument*)d
{
	if ((self = [self init]))
	{
		document = d;
		[document performSelector:@selector(registerObject:)withObjectsFromArray:layers];
	}
	return self;
}

-(id)copy
{
    //ACSDPage *p = [[ACSDPage alloc]initWithDocument:document];
    ACSDPage *p = [super copy];
    p.document = document;
	NSMutableArray *newLayers = [NSMutableArray arrayWithCapacity:[layers count]];
	for (ACSDLayer *l in layers)
		[newLayers addObject:[[l copy]autorelease]];
	[p setLayers:newLayers];
	[p setLayerPages];
    [p registerWithDocument:document];
	return p;
}

-(NSString*)nextLayerName
{
	NSInteger nl = nextLayer++;
	return [NSString stringWithFormat:@"Layer %ld",nl];
}

-(void)deRegisterWithDocument:(ACSDrawDocument*)doc
{
	[doc deRegisterObject:self];
	[layers makeObjectsPerformSelector:@selector(deRegisterWithDocument:)withObject:doc];
}

-(void)registerWithDocument:(ACSDrawDocument*)doc
{
	[doc registerObject:self];
	[layers makeObjectsPerformSelector:@selector(registerWithDocument:)withObject:doc];
}

-(void)workOutIndexes
{
	currentLayerInd = -1;
	guideLayerInd = -1;
	for (NSInteger i = 0,count = [layers count];i < count && (guideLayerInd < 0 || currentLayerInd < 0);i++)
	{
		ACSDLayer *l = [layers objectAtIndex:i];
		if ([l isGuideLayer])
			guideLayerInd = i;
		else
			currentLayerInd = i;
	}
	if (currentLayerInd < 0)
		currentLayerInd = 0;
}

- (void) dealloc
{
	[name release];
	[pageTitle release];
	[layers release];
	[graphicViews release];
	[backgroundColour release];
	self.previouslyVisibleLayers = nil;
	self.animations = nil;
	[super dealloc];
}

- (void) encodeWithCoder:(NSCoder*)coder
{
	[super encodeWithCoder:coder];
	NSArray *arr;
	if ([(id)coder delegate] && [[(id)coder delegate]respondsToSelector:@selector(filterLayers:)])
	{
		NSIndexSet *ixs = [layers indexesOfObjectsPassingTest:^(id obj,NSUInteger i,BOOL *stop){return [obj exportable];}];
		arr = [layers objectsAtIndexes:ixs];
	}
	else
		arr = layers;
	[coder encodeObject:arr forKey:@"ACSDPage_layers"];

//	[coder encodeObject:layers forKey:@"ACSDPage_layers"];
	if (backgroundColour)
		[coder encodeObject:backgroundColour forKey:@"ACSDPage_backgroundColour"];
	[coder encodeInteger:nextLayer forKey:@"ACSDGraphic_nextLayer"];
	[coder encodeObject:name forKey:@"ACSDPage_name"];
	[coder encodeObject:pageTitle forKey:@"ACSDPage_pageTitle"];
	[coder encodeInt:pageType forKey:@"ACSDGraphic_pageType"];
	[coder encodeInt:masterType forKey:@"ACSDGraphic_masterType"];
	[coder encodeInt:useMasterType forKey:@"ACSDGraphic_useMasterType"];
	[coder encodeBool:inactive forKey:@"ACSDPage_inactive"];
	[coder encodeObject:self.animations forKey:@"ACSDPage_animations"];
}

- (id) initWithCoder:(NSCoder*)coder
{
	self = [super initWithCoder:coder];
	graphicViews = [[NSMutableSet alloc]initWithCapacity:2];
	layers = [[coder decodeObjectForKey:@"ACSDPage_layers"]retain];
	backgroundColour = [[coder decodeObjectForKey:@"ACSDPage_backgroundColour"]retain];
	nextLayer = [coder decodeIntegerForKey:@"ACSDGraphic_nextLayer"];
	name = [[coder decodeObjectForKey:@"ACSDPage_name"]retain];
	pageTitle = [[coder decodeObjectForKey:@"ACSDPage_pageTitle"]retain];
	pageType = [coder decodeIntForKey:@"ACSDGraphic_pageType"];
	masterType = [coder decodeIntForKey:@"ACSDGraphic_masterType"];
	useMasterType = [coder decodeIntForKey:@"ACSDGraphic_useMasterType"];
	inactive = [coder decodeBoolForKey:@"ACSDPage_inactive"];
	if (nextLayer == 0)
		nextLayer = [layers count];
	[self workOutIndexes];
	[self setLayerPages];
    self.animations = [coder decodeObjectForKey:@"ACSDPage_animations"];
	return self;
}

-(void)allocMasters
{
	if (masters == nil)
		masters = [[NSMutableArray alloc]initWithCapacity:2];
}

-(void)allocSlaves
{
	if (slaves == nil)
		slaves = [[NSMutableArray alloc]initWithCapacity:8];
}

-(void)setLayerPages
{
    NSEnumerator *lEnum = [layers objectEnumerator];
    ACSDLayer *layer;
    while ((layer = [lEnum nextObject]) != nil) 
		[layer setPage:self];
}

- (NSMutableArray*)layers
{
	return layers;
}

-(void)setLayers:(NSMutableArray*)arr
{
	if (arr != layers)
	{
		[layers release];
		layers  = [arr retain];
	}
}

- (ACSDLayer*)currentLayer
{
	return [layers objectAtIndex:currentLayerInd];
}

- (ACSDLayer*)guideLayer
{
	return [layers objectAtIndex:guideLayerInd];
}

-(void)setPageType:(int)pt
{
	pageType = pt;
	[self synchroniseWindowTitles];
}

-(void)setMasterType:(int)pt
{
	masterType = pt;
	[self synchroniseWindowTitles];
}

-(void)setUseMasterType:(int)pt
{
	useMasterType = pt;
	[self synchroniseWindowTitles];
}

- (int)pageType
{
	return pageType;
}

- (int)masterType
{
	return masterType;
}

- (int)useMasterType
{
	return useMasterType;
}

-(NSMutableArray*)masters
{
	return masters;
}

-(NSMutableArray*)slaves
{
	return slaves;
}

-(void)setCurrentLayer:(ACSDLayer*)l
{
	NSUInteger i = [layers indexOfObjectIdenticalTo:l];
	[self setCurrentLayerInd:i];
}

-(NSColor*)backgroundColour
{
	if (backgroundColour == nil)
		return [document backgroundColour];
	if ([backgroundColour alphaComponent] == 0.0)
		return [document backgroundColour];
	return backgroundColour;
}

-(void)setBackgroundColour:(NSColor*)n
{
	if (backgroundColour == n)
		return;
	if (backgroundColour)
		[backgroundColour release];
	backgroundColour = n;
	if (backgroundColour)
		[backgroundColour retain];
}

-(BOOL)uSetBackgroundColour:(NSColor*)c
{
	[[[document undoManager] prepareWithInvocationTarget:self] uSetBackgroundColour:[self backgroundColour]];
	[self setBackgroundColour:c];
	[graphicViews makeObjectsPerformSelector:@selector(setNeedsDisplay)];
	return YES;
}

-(BOOL)uDeleteAttributeAtIndex:(NSInteger)idx notify:(BOOL)notify
{
	NSArray *arr = self.attributes[idx];
	[[[document undoManager] prepareWithInvocationTarget:self] uInsertAttributeName:arr[0]value:arr[1] atIndex:idx notify:YES];
	[self.attributes removeObjectAtIndex:idx];
	if (notify)
		[[NSNotificationCenter defaultCenter]postNotificationName:ACSDPageAttributeChanged object:self];
	return YES;
}

-(BOOL)uInsertAttributeName:(NSString*)nm value:(NSString*)val atIndex:(NSInteger)idx notify:(BOOL)notify
{
	[[[document undoManager] prepareWithInvocationTarget:self] uDeleteAttributeAtIndex:idx notify:YES];
	if (self.attributes == nil)
		self.attributes = [NSMutableArray arrayWithCapacity:6];
	if (notify)
		[[NSNotificationCenter defaultCenter]postNotificationName:ACSDPageAttributeChanged object:self];
	[self.attributes insertObject:@[nm,val] atIndex:idx];
	return YES;
}

-(BOOL)uSetAttributeName:(NSString*)nm atIndex:(NSInteger)idx notify:(BOOL)notify
{
	NSArray *arr = self.attributes[idx];
	[[[document undoManager] prepareWithInvocationTarget:self] uSetAttributeName:arr[0] atIndex:idx notify:YES];
	[self.attributes replaceObjectAtIndex:idx withObject:@[nm,arr[1]]];
	if (notify)
		[[NSNotificationCenter defaultCenter]postNotificationName:ACSDPageAttributeChanged object:self];
	return YES;
}

-(BOOL)uSetAttributeValue:(NSString*)val forName:(NSString*)nme notify:(BOOL)notify
{
	NSInteger idx = 0;
	for (NSArray *arr in self.attributes)
	{
		if ([arr[0] isEqual:nme])
		{
			[self uSetAttributeValue:val atIndex:idx notify:YES];
			return YES;
		}
		idx++;
	}
	idx = [self.attributes count];
	[self uInsertAttributeName:nme value:val atIndex:idx notify:notify];
	return YES;
}

-(BOOL)uSetAttributeValue:(NSString*)val atIndex:(NSInteger)idx notify:(BOOL)notify
{
	NSArray *arr = self.attributes[idx];
	[[[document undoManager] prepareWithInvocationTarget:self] uSetAttributeValue:arr[1] atIndex:idx notify:YES];
	[self.attributes replaceObjectAtIndex:idx withObject:@[arr[0],val]];
	if (notify)
		[[NSNotificationCenter defaultCenter]postNotificationName:ACSDPageAttributeChanged object:self];
	return YES;
}

-(NSString*)Desc
{
	if (pageType == PAGE_TYPE_MASTER)
	{
		if (pageTitle != nil)
			return [NSString stringWithFormat:@"%@ - %@",name,pageTitle];
		return name;
	}
	if (pageTitle != nil)
		return [NSString stringWithFormat:@"%ld - %@",pageNo,pageTitle];
	return [NSString stringWithFormat:@"%ld",pageNo];
}

-(void)addGraphicView:(GraphicView*)gv
{
	[graphicViews addObject:gv];
}

-(void)removeGraphicView:(GraphicView*)gv
{
	[graphicViews removeObject:gv];
}

-(NSMutableSet*)graphicViews
{
	return graphicViews;
}

-(void)moveGraphicsByValue:(NSValue*)val
{
	[layers makeObjectsPerformSelector:@selector(moveGraphicsByValue:) withObject:val];
}

-(void)updateForStyle:(id)style oldAttributes:(NSDictionary*)oldAttrs
{
	[layers makeObjectsPerformSelector:@selector(updateForStyle:oldAttributes:)withObject:style andObject:oldAttrs];
}

-(NSRect)unionGraphicBounds
{
	NSRect r = NSZeroRect;
	for (ACSDLayer *l in layers)
		r = NSUnionRect(r,[l unionGraphicBounds]);
	return r;
}

-(void)freePDFData
{
	for (ACSDLayer *l in layers)
		[l freePDFData];
}

-(void)buildPDFData
{
	for (ACSDLayer *l in layers)
		[l buildPDFData];
}

-(void)fixTextBoxLinks
{
	[layers makeObjectsPerformSelector:@selector(fixTextBoxLinks)];
}

-(BOOL)atLeastOneObjectExists
{
	return [layers orMakeObjectsPerformSelector:@selector(atLeastOneObjectExists)];
}

-(BOOL)containsImages
{
	return [layers orMakeObjectsPerformSelector:@selector(containsImages)];
}

-(void)uAddMaster:(ACSDPage*)masterPage atIndex:(int)ind
{
	if (masters == nil)
		[self allocMasters];
	[[[document undoManager] prepareWithInvocationTarget:self] uRemoveMaster:masterPage];
	[masters insertObject:masterPage atIndex:ind];
}

-(void)uRemoveMaster:(ACSDPage*)masterPage
{
	if (masters == nil)
		return;
	NSUInteger ind = [masters indexOfObjectIdenticalTo:masterPage];
	if (ind != NSNotFound)
	{
		[[[document undoManager] prepareWithInvocationTarget:self] uAddMaster:masterPage atIndex:(int)ind];
		[masters removeObjectAtIndex:ind];
	}
}

-(void)uSetMaster:(ACSDPage*)masterPage
{
	if (masters != nil)
		while ([masters count] > 0)
			[self uRemoveMaster:[masters objectAtIndex:0]];
	[self uAddMaster:masterPage atIndex:0];
}

-(void)uRemoveSlave:(ACSDPage*)slavePage
{
	if (slaves == nil)
		return;
	NSUInteger ind = [slaves indexOfObjectIdenticalTo:slavePage];
	if (ind != NSNotFound)
	{
		[[[document undoManager] prepareWithInvocationTarget:self] uAddSlave:slavePage];
		[slaves removeObjectAtIndex:ind];
	}
}

-(void)uAddSlave:(ACSDPage*)slavePage
{
	if (slaves == nil)
		[self allocSlaves];
	[[[document undoManager] prepareWithInvocationTarget:self] uRemoveSlave:slavePage];
	[slaves addObject:slavePage];
}

-(NSArray*)allTextObjectsOrderedByPosition
{
	NSMutableArray *textObjects = [NSMutableArray arrayWithCapacity:10];
	for (ACSDLayer *l in layers)
	{
		if (![l isGuideLayer])
			[textObjects addObjectsFromArray:[l allTextObjects]]; 
	}
	[textObjects sortUsingSelector:@selector(compareBoundsudlr:)];
	return textObjects;
}

int weight_from_float(float w)
{
	if (w == 0.0)
		return 400;
	float owt;
	if (w > 0.0)
	{
		owt = 400 + w * 500;
		return (int)(owt + 50) / 100 * 100;
	}
	owt = 400 + w * 300;
	return (int)(owt + 50) / 100 * 100;
}

NSString* stringForAlignment(int ali)
{
	NSString *str;
	switch(ali)
	{
		case NSLeftTextAlignment:
			str = @"left";
			break;
		case NSRightTextAlignment:
			str = @"right";
			break;
		case NSCenterTextAlignment:
			str = @"center";
			break;
		case NSJustifiedTextAlignment:
			str = @"justify";
			break;
		default:
			return @"";
	}
	return [NSString stringWithFormat:@"text-align:%@;",str];
}

-(void)addFontsToCSS:(NSMutableString*)cssString fontDict:(NSDictionary*)fontDict
{
	NSEnumerator *enumerator = [fontDict keyEnumerator];
	TextStyleHolder *tsh;
	while ((tsh = [enumerator nextObject]))
	{
		int fno = [[fontDict objectForKey:tsh]intValue];
		[cssString appendFormat:@"\t\t\t.p%d {font-family: '%@'; font-size:%gpx;",fno,[tsh fontFamilyName],[tsh fontSize]];
		if ([tsh colour])
			[cssString appendFormat:@"color:%@;",string_from_nscolor([tsh colour])];
		[cssString appendFormat:@"text-decoration:%@;",([tsh underline] > 0)?@"underline":@"none"];
		[cssString appendFormat:@"margin:0;padding-left:%gpx;padding-top:%gpx;padding-bottom:%gpx;text-indent:%gpx;line-height:%gpx;%@",[tsh indent],[tsh beforeSpace],
		 [tsh afterSpace],[tsh firstLineIndent]-[tsh indent],[tsh lineHeight],stringForAlignment([tsh alignment])];
		[cssString appendString:@"}\n"];
	}
}

-(NSString*)pageTitleForHTML
{
	NSString *temp;
	if (pageTitle == nil)
	{
		temp = [document docTitle];
		if (temp == nil)
			temp = [document displayName];
	}
	else
		temp = pageTitle;
	return temp;
}

-(void)uRemoveLinkedObject:(id)obj
{
	if (!linkedObjects)
		return;
	[[[document undoManager] prepareWithInvocationTarget:self] uAddLinkedObject:obj];
	[linkedObjects removeObject:obj];
}

-(void)uAddLinkedObject:(id)obj
{
	if (!linkedObjects)
		linkedObjects = [[NSMutableSet alloc]initWithCapacity:3];
	[[[document undoManager] prepareWithInvocationTarget:self] uRemoveLinkedObject:obj];
	[linkedObjects addObject:obj];
}

-(void)synchroniseWindowTitles
{
	NSMutableSet *controllers = [NSMutableSet setWithCapacity:5];
	NSArray *views = [graphicViews allObjects];
	for (unsigned i=0;i < [views count];i++)
		[controllers addObject:[[[views objectAtIndex:i]window]windowController]];
	[controllers makeObjectsPerformSelector:@selector(synchronizeWindowTitleWithDocumentName)];
}

-(void)processHtmlObjectsOptions:(NSMutableDictionary*)options
{
	if (masters)
		[masters makeObjectsPerformSelector:@selector(processHtmlObjectsOptions:)withObject:options];
	NSSize sz = [document documentSize];
	NSImage *im = [[[NSImage alloc]initWithSize:sz]autorelease];
	GraphicView *graphicView = [[[GraphicView alloc]initWithFrame:NSMakeRect(0,0,sz.width,sz.height)]autorelease];
	NSMutableDictionary *substitutions = [NSMutableDictionary dictionaryWithCapacity:5];
	[im lockFocus];
	CGContextSetInterpolationQuality((CGContextRef)[[NSGraphicsContext currentContext] graphicsPort],kCGInterpolationHigh);
	[graphicView drawPage:self rect:NSMakeRect(0,0,sz.width,sz.height) drawingToScreen:NO drawMarkers:NO drawingToPDF:nil substitutions:substitutions
                  options:[NSDictionary dictionaryWithObject:[NSNumber numberWithFloat:1.0] forKey:@"overrideScale"]];
	[im unlockFocus];
	[options setObject:im forKey:@"pageImage"];
	[layers reverseMakeObjectsPerformSelector:@selector(processHTMLOptions:)withObject:options];
}

-(NSString*)htmlRepresentationOptions:(NSMutableDictionary*)options
{
	[options setObject:[NSNumber numberWithInteger:pageNo] forKey:@"pageNo"];
	[options setObject:[NSString stringWithFormat:@"%@_%ld.html",[options objectForKey:@"dTitle"],pageNo] forKey:@"pageName"];
	[options setObject:[NSNumber numberWithInt:1] forKey:@"imageNo"];
	[options setObject:[NSNumber numberWithInt:1] forKey:@"fontNo"];
	[options setObject:[NSMutableDictionary dictionaryWithCapacity:10] forKey:@"fontDict"];
	[options setObject:[NSMutableString stringWithCapacity:100] forKey:@"cssString"];
	[options setObject:[NSMutableString stringWithCapacity:200] forKey:@"bodyString"];
	[options setObject:[NSMutableString stringWithCapacity:10] forKey:@"ieString"];
	int vectorMode = [[[options objectForKey:@"htmlSettings"]objectForKey:@"vectorGraphicsType"]intValue];
	if (vectorMode == VECTOR_GRAPHICS_CANVAS)
	{
		[options setObject:[NSMutableString stringWithCapacity:10] forKey:@"canvasScriptString"];
		[options setObject:[NSMutableArray arrayWithCapacity:10] forKey:@"canvasScriptNames"];
	}
	[options setObject:[NSMutableString stringWithCapacity:10] forKey:@"ieString"];
	NSMutableString *pageString = [NSMutableString stringWithCapacity:400];
	[pageString appendString:xHTMLString1];
	[pageString appendFormat:@"%@\t<head>\n\t\t<title>%@</title>\n",xHTMLString2,[self pageTitleForHTML]];
	[self processHtmlObjectsOptions:options];
	[self addFontsToCSS:[options objectForKey:@"cssString"] fontDict:[options objectForKey:@"fontDict"]];
	[pageString appendString:@"\t\t<meta charset=macintosh\"/>\n"];
	[pageString appendString:@"\t\t<meta name=\"generator\" content=\"ACSDraw\">\n\t\t<style type=\"text/css\"/>\n"];
	[pageString appendString:[options objectForKey:@"cssString"]];
	[pageString appendString:@"\t\tp { white-space: pre-wrap }\n"];
	if ([ document additionalCSS])
		[pageString appendString:[document additionalCSS]];
	[pageString appendString:@"\t\t</style>\n"];
	NSString *scriptURL = [options objectForKey:@"scriptURL"];
	if (scriptURL)
		[pageString appendFormat:@"\t\t<script src='%@'>\n\t\t</script>\n",scriptURL];
	NSString *canvasScriptString = [options objectForKey:@"canvasScriptString"];
	if (canvasScriptString)
	{
		[pageString appendFormat:@"<script type=\"application/x-javascript\">\n%@\n",canvasScriptString];
		[pageString appendString:@"function draw_all()\n{"];
		NSArray *fNames = [options objectForKey:@"canvasScriptNames"];
		for (unsigned i = 0;i < [fNames count];i++)
			[pageString appendFormat:@"draw_%@();\n",[fNames objectAtIndex:i]];
		[pageString appendString:@"}\n</script>\n"];
	}
	NSColor *docCol = [[self document]backgroundColour];
	NSColor *pageCol = [self backgroundColour];
    if (!pageCol)
		pageCol = docCol;
	[pageString appendString:@"\t</head>\n\t<body"];
	if (pageCol)
		[pageString appendFormat:@" style='background-color:%@'",string_from_nscolor(docCol)];
	if (vectorMode == VECTOR_GRAPHICS_CANVAS)
		[pageString appendString:@" onload=\"draw_all();\""];
	[pageString appendString:@">\n"];
	[pageString appendString:[options objectForKey:@"bodyString"]];
	[pageString appendString:@"\t</body>\n"];
	if ([[options objectForKey:@"ieCompatibility"]boolValue])
	{
		NSString *ieString = [options objectForKey:@"ieString"];
		if ([ieString length] > 0)
		{
			[pageString appendString:@"\t<script language=\"JavaScript\">\n"];
			[pageString appendString:@"\t\tvar isIE;\n"];
			[pageString appendString:@"\t\tisIE = (navigator.appName.indexOf(\"Microsoft\") != -1);\n"];
			[pageString appendString:@"\t\tif(isIE)\n"];
			[pageString appendString:@"\t\t   {\n"];
			[pageString appendString:ieString];
			[pageString appendString:@"\t\t   }\n"];
			[pageString appendString:@"\t</script>\n"];
		}
	}
	[pageString appendString:@"</html>\n"];
	return pageString;
}

-(NSString*)graphicXML:(NSMutableDictionary*)options
{
	NSMutableString *pageString = [NSMutableString stringWithCapacity:200];
	NSString *indent = [options objectForKey:xmlIndent];
	NSSize sz = [[self document]documentSize];
	[pageString appendFormat:@"%@<page id=\"%ld\" name=\"%@\" width=\"%d\" height=\"%d\"",indent,pageNo,name,(int)sz.width,(int)sz.height];
    if (backgroundColour && ![backgroundColour isEqual:[NSColor whiteColor]])
    {
        CGFloat r,g,b,a;
        [[backgroundColour colorUsingColorSpaceName:NSCalibratedRGBColorSpace device:nil]getRed:&r green:&g blue:&b alpha:&a];
        r *= 255;
        g *= 255;
        b *= 255;
        [pageString appendFormat:@" colour=\"%d,%d,%d\"",(int)r,(int)g,(int)b];
    }
    [pageString appendString:@">\n"];
	[options setObject:[indent stringByAppendingString:@"\t"] forKey:xmlIndent];
	for (ACSDLayer *l in layers)
	{
		if (l.exportable)
			[pageString appendString:[l graphicXML:options]];
	}
	[pageString appendFormat:@"%@</page>\n",indent];
	[options setObject:indent forKey:xmlIndent];
	return pageString;
}

static int PageLayerCount(ACSDPage *p)
{
	int tot = (int)[[p layers]count];
	for (ACSDPage *pm in p.masters)
		tot += PageLayerCount(pm);
	return tot;
}
static int MasterLayerCount(ACSDPage *p)
{
	int tot = 0;
	for (ACSDPage *pm in p.masters)
	{
		tot+= PageLayerCount(pm);
	}
	return tot;
}

-(NSString*)layersEventXML:(NSMutableDictionary*)options
{
	NSMutableString *pageString = [NSMutableString stringWithCapacity:200];
    float layerzidx = MasterLayerCount(self);
    for (ACSDLayer *l in [layers reverseObjectEnumerator])
	{
		if (l.exportable)
        {
            if (l.zPosOffset != 0)
                layerzidx = l.zPosOffset;
            options[@"layerzidx"] = @(layerzidx);
			[pageString appendString:[l graphicXMLForEvent:options]];
            layerzidx += 1.0;
        }
	}
	return pageString;
}

-(NSString*)graphicXMLForEvent:(NSMutableDictionary*)options
{
	NSMutableString *pageString = [NSMutableString stringWithCapacity:200];
	NSString *indent = [options objectForKey:xmlIndent];
	NSString *title = pageTitle;
	if (title == nil)
		title = [NSString stringWithFormat:@"%ld",pageNo];
	[pageString appendFormat:@"%@<event id=\"%@\" ",indent,title];
	for (NSArray *attrs in self.attributes)
    {
        if (![attrs[0] isEqualToString:@""])
            [pageString appendFormat:@"%@=\"%@\" ",attrs[0],attrs[1]];
    }
    if (backgroundColour && ![backgroundColour isEqual:[NSColor whiteColor]])
    {
        CGFloat r,g,b,a;
        [[backgroundColour colorUsingColorSpaceName:NSDeviceRGBColorSpace device:nil]getRed:&r green:&g blue:&b alpha:&a];
        r *= 255;
        g *= 255;
        b *= 255;
        [pageString appendFormat:@"colour=\"%d,%d,%d\" ",(int)r,(int)g,(int)b];
    }
	[pageString appendString:@">\n"];
	[options setObject:[indent stringByAppendingString:@"\t"] forKey:xmlIndent];
//	for (ACSDPage *m in masters)
//		[pageString appendString:[m layersEventXML:options]];
	[pageString appendString:[self layersEventXML:options]];
	[pageString appendFormat:@"%@</event>\n",indent];
	[options setObject:indent forKey:xmlIndent];
	return pageString;
}

-(void)addLinksForPDFContext:(CGContextRef) context
{
	[layers makeObjectsPerformSelector:@selector(addLinksForPDFContext:)withObject:(__bridge id)context];
}

-(void)permanentScale:(float)sc transform:(NSAffineTransform*)t
{
	for (ACSDLayer *l in layers)
		[l permanentScale:sc transform:t];
}


@end