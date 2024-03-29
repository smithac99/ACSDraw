//
//  MyDocument.m
//  ACSDraw
//
//  Created by Alan Smith on Mon Jan 14 2002.
//  Copyright (c) 2001 __MyCompanyName__. All rights reserved.
//

#import "HtmlExportController.h"
#import "ACSDrawDocument.h"
#import "ACSDrawDefs.h"
#import "ACSDLayer.h"
#import "ACSDPage.h"
#import "ACSDPath.h"
#import "ACSDText.h"
#import "ACSDStroke.h"
#import "ACSDCircle.h"
#import "ACSDLineEnding.h"
#import "ACSDStyle.h"
#import "ACSDFill.h"
#import "ShadowType.h"
#import "SVGWriter.h"
#import "LineEndingWindowController.h"
#import "PatternWindowController.h"
#import "ArrayAdditions.h"
#import "ImageExportController.h"
#import "AppDelegate.h"
#import "KeyedObject.h"
#import "ObjectAdditions.h"
#import "ArchiveDelegate.h"
#import "ACSDPrefsController.h"
#import "GXPArchiveDelegate.h"
#import "ACSDImage.h"
#import "XMLManager.h"
#import "AffineTransformAdditions.h"
#import "AnimationsController.h"
#import "GradientElement.h"
#import "ACSDGradient.h"
#import "SVG_Gradient.h"
#import "geometry.h"
#import "NSString+StringAdditions.h"
#import "ACSDLink.h"

NSString *backgroundColourKey = @"backgroundColour";
NSString *lineEndingsKey = @"lineEndings";
NSString *xmlDocWidth = @"xmlDocWidth";
NSString *xmlDocHeight = @"xmlDocHeight";
NSString *xmlIndent = @"xmlIndent";
NSString *ACSDrawDocumentBackgroundDidChangeNotification = @"ACSDDocBGC";

@interface ACSDrawDocument ()
{
    IBOutlet NSTextField *textAccessoryLabel;
    IBOutlet NSTextField *textAccessoryTextField;
    IBOutlet  NSView __strong *textAccessoryView;
}
@end

@implementation ACSDrawDocument

- (id) init
{
    if ((self = [super init]))
	   {
           _nameCounts = [NSMutableDictionary dictionaryWithCapacity:10];
           ACSDrawDocument *doc = (ACSDrawDocument*)[[NSDocumentController sharedDocumentController]currentDocument];
           if (doc)
               self.documentSize = [doc documentSize];
           else
               self.documentSize = [[NSPrintInfo sharedPrintInfo]paperSize];
           mainWindowController = nil;
           keyedObjects = [[NSMutableDictionary alloc]initWithCapacity:100];
           lineEndings = [self systemLineEndings];
           miscValues = [NSMutableDictionary dictionaryWithCapacity:5];
           [self shadows];
           [self pages];
           [self styles];
           exportDirectory = nil;
           maxViewNumber = -1;
           self.documentKey = [NSDate date];
       }
    return self;
}

- (void)setExportDirectory:(NSURL*)expd
{
    if ([exportDirectory isEqual:expd])
		return;
	exportDirectory = [expd copy];
}

-(NSURL*)exportDirectory
{
	if (!exportDirectory)
		if ([self fileURL])
			[self setExportDirectory:[NSURL fileURLWithPath:[[[self fileURL]path]stringByDeletingLastPathComponent]]];
		else
			[self setExportDirectory:[NSURL fileURLWithPath:NSHomeDirectory()]];
	return exportDirectory;
}

-(NSColor*)backgroundColour
   {
	if (backgroundColour == nil)
		backgroundColour = [NSColor whiteColor];
	return backgroundColour;
   }

-(void)updateWindowForBackgroundColour
{
	if ([backgroundColour alphaComponent] < 1.0)
	{
		[[mainWindowController window]setBackgroundColor:[NSColor clearColor]];
		[[mainWindowController window]setOpaque:0.0];
	}
	else
	{
		[[mainWindowController window]setBackgroundColor:[NSColor whiteColor]];
		[[mainWindowController window]setOpaque:1.0];
	}
}

-(void)setBackgroundColour:(NSColor*)c
{
	if (backgroundColour == c)
		return;
	backgroundColour = c;
	[self updateWindowForBackgroundColour];
}

-(BOOL)uSetBackgroundColour:(NSColor*)c
{
	[[[self undoManager] prepareWithInvocationTarget:self] uSetBackgroundColour:[self backgroundColour]];
	[self setBackgroundColour:c];
	[[NSNotificationCenter defaultCenter] postNotificationName:ACSDrawDocumentBackgroundDidChangeNotification object:self];
	return YES;
}

-(NSDictionary*)keyedObjects
{
	return keyedObjects;
}

-(void)deRegisterObject:(KeyedObject*)ko
   {
	[keyedObjects removeObjectForKey:[NSNumber numberWithInt:[ko objectKey]]];
   }

-(KeyedObject*)registerObject:(KeyedObject*)ko
   {
	int k = [ko objectKey];
	if (k == -1)
	   {
		k = [self nextObjectKey];
		[ko setObjectKey:k];
	   }
	[keyedObjects setObject:ko forKey:[NSNumber numberWithInt:k]];
	return ko;
   }

-(unsigned)nextObjectKey
   {
	return nextObjectKey++;
   }

-(NSMutableArray*)strokes
   {
	if (strokes == nil)
	   {
	    strokes = [ACSDStroke initialStrokes];
		[self performSelector:@selector(registerObject:)withObjectsFromArray:strokes];
	   }
    return strokes;
   }

-(NSMutableArray*)styles
   {
	if (styles == nil)
	   {
	    styles = [ACSDStyle initialStyles];
		[self performSelector:@selector(registerObject:)withObjectsFromArray:styles];
	   }
    return styles;
   }

-(NSMutableArray*)fills
   {
	if (fills == nil)
	   {
	    fills = [ACSDFill initialFills];
		[self performSelector:@selector(registerObject:)withObjectsFromArray:fills];
	   }
    return fills;
   }

-(NSMutableArray*)shadows
   {
	if (_shadows == nil)
	   {
	    _shadows = [ShadowType initialShadows];
		[self performSelector:@selector(registerObject:)withObjectsFromArray:_shadows];
	   }
    return _shadows;
   }

-(NSMutableArray*)lineEndings
   {
    return lineEndings;
   }

-(NSMutableDictionary*)miscValues
   {
    return miscValues;
   }

- (NSMutableArray<ACSDPage*>*)pages
   {
	if (!pages)
	   {
		pages = [NSMutableArray arrayWithCapacity:5];
		[pages addObject:(ACSDPage*)[self registerObject:[[ACSDPage alloc]initWithDocument:self]]];
	   }
    return pages;
   }

- (NSMutableArray*)systemLineEndings
   {
	NSMutableArray 	*mArr = [NSMutableArray arrayWithCapacity:30];
	NSString *dPath = [[NSBundle mainBundle]pathForResource:@"systemLineEndings" ofType:@"acsdl"];
	if (dPath)
	   {
		NSKeyedUnarchiver *unarchiver = [[NSKeyedUnarchiver alloc] initForReadingFromData:[NSData dataWithContentsOfFile:dPath]error:NULL];
		[unarchiver setDelegate:[ArchiveDelegate archiveDelegateWithType:ARCHIVE_FILE document:self]];
		id d = [unarchiver decodeObjectForKey:@"root"];
//		id d = [NSKeyedUnarchiver unarchiveObjectWithData:[NSData dataWithContentsOfFile:dPath]];
		if (d && [d isKindOfClass:[NSDictionary class]])
		   {
			NSDictionary *dict = d;
			if (dict)
			   {
				NSArray *arr = [dict objectForKey:lineEndingsKey];
				if (arr)
				   {
					[mArr addObjectsFromArray:arr];
					return mArr;
				   }
			   }
		   }
	   }
	[mArr addObjectsFromArray:[ACSDLineEnding initialLineEndings]];
	[self performSelector:@selector(registerObject:)withObjectsFromArray:mArr];
	return mArr;
   }

- (void)makeWindowControllers
{
	mainWindowController = [[MainWindowController alloc] initWithPages:[self pages]];
	[self addWindowController:mainWindowController];
	[self windowControllerDidLoadNib:mainWindowController];
}

-(MainWindowController*)frontmostMainWindowController
   {
	for (unsigned i = 0;i < [[self windowControllers] count];i++)
	   {
		NSWindowController* cont = [[self windowControllers] objectAtIndex:i];
		if ([cont isMemberOfClass:[MainWindowController class]])
			return (MainWindowController*)cont;
	   }
	return nil;
   }

- (IBAction)addView:(id)sender
   {
	MainWindowController *mwc = [[MainWindowController alloc] initWithPages:[self pages]];
	[self addWindowController:mwc];
	[mwc showWindow:self];
	if (maxViewNumber == -1)
	   {
		maxViewNumber = 0;
		for (unsigned i = 0;i < [[self windowControllers]count];i++)
		   {
			id wc = [[self windowControllers]objectAtIndex:i];
			if ([wc respondsToSelector:@selector(setViewNumber:)])
				[wc setViewNumber:++maxViewNumber];
		   }
	   }
	else
		[mwc setViewNumber:++maxViewNumber];
	[[self windowControllers]makeObjectsPerformSelector:@selector(synchronizeWindowTitleWithDocumentName)];
   }

-(void)createLineEndingWindowWithLineEnding:(ACSDLineEnding*)le isNew:(bool)isNew
   {
	if (isNew)
		[lineEndings addObject:le];
	LineEndingWindowController *lwc = [[LineEndingWindowController alloc] initWithLineEnding:le];
	[self addWindowController:lwc];
	[lwc showWindow:self];
   }

-(void)createPatternWindowWithPattern:(ACSDPattern*)pat isNew:(bool)isNew
   {
	if (isNew)
		[[self fills] addObject:pat];
	PatternWindowController *pc = [[PatternWindowController alloc] initWithPattern:pat];
	[self addWindowController:pc];
	[pc showWindow:self];
   }

- (void)endCanCloseAlert:(NSWindow*)sheet returnCode:(int)returnCode contextInfo:(void*)contextInfo	/*End of alert to save doc*/
   {
	if (returnCode == NSAlertDefaultReturn)			/*Continue*/
	   {
		for (id cont in [self windowControllers])
		   {
			if ([cont isKindOfClass:[LineEndingWindowController class]])
				[[cont window]close];
			else if ([cont isKindOfClass:[PatternWindowController class]])
				[[cont window]close];
		   }
		[super canCloseDocumentWithDelegate:sci.delegate shouldCloseSelector:sci.shouldCloseSelector 
								contextInfo:sci.contextInfo];
	   }
   }
/*
- (void)canCloseDocumentWithDelegate:(id)delegate shouldCloseSelector:(SEL)shouldCloseSelector contextInfo:(void*)contextInfo
   {
	int noLineEndingWindows = 0,noPatternWindows = 0;
	for (unsigned i = 0,ct = [[self windowControllers] count];i < ct;i++)
	   {
		id cont = [[self windowControllers] objectAtIndex:i];
		if ([cont isKindOfClass:[LineEndingWindowController class]])
		   {
			if ([cont dirty])
				noLineEndingWindows++;
			else
				[[cont window]close];
		   }
		else if ([cont isKindOfClass:[PatternWindowController class]])
		   {
			if ([cont dirty])
				noPatternWindows++;
			else
				[[cont window]close];
		   }
	   }
	if  (noLineEndingWindows > 0 || noPatternWindows > 0)
	   {
		sci.shouldCloseSelector = shouldCloseSelector;
		sci.contextInfo = contextInfo;
		sci.delegate = delegate;
		NSMutableString *nsms = [NSMutableString stringWithCapacity:20];
		[nsms appendString:@"There are "];
		if (noLineEndingWindows > 0)
		   {
			[nsms appendString:@"Line Endings "];
			if (noPatternWindows > 0)
				[nsms appendString:@"and "];
		   }
		if (noPatternWindows > 0)
			[nsms appendString:@"Patterns "];
		[nsms appendString:@"that have not been applied. Continuing will discard them."];
		NSBeginAlertSheet(@"Unsaved Stuff",@"Continue",@"Cancel",nil,[[self frontmostMainWindowController] window],self,NULL,
						  @selector(endCanCloseAlert:returnCode:contextInfo:),&sci,nsms);
	   }
	else
		[super canCloseDocumentWithDelegate:delegate shouldCloseSelector:shouldCloseSelector 
								contextInfo:contextInfo];
   }
*/
- (void)windowControllerDidLoadNib:(NSWindowController *) aController
{
    [super windowControllerDidLoadNib:aController];
	NSView *graphicView = [[self frontmostMainWindowController] graphicView];
	NSScrollView *scrollView = [graphicView enclosingScrollView];
	NSClipView *clipView = [scrollView contentView];
	[clipView scrollToPoint:NSMakePoint(0.0,[graphicView frame].size.height - [clipView frame].size.height)];
	[[scrollView verticalScroller]setFloatValue:1.0];
	[self updateWindowForBackgroundColour];
}

//NSString *layersKey = @"layers";
NSString *pagesKey = @"pages";
NSString *strokesKey = @"strokes";
NSString *fillsKey = @"fills";
NSString *shadowsKey = @"shadows";
NSString *stylesKey = @"styles";
NSString *nameCountsKey = @"nameCounts";
NSString *docTitleKey = @"docTitle";
NSString *docSizeKey = @"docSize";
NSString *docSizeWidthKey = @"docSizeW";
NSString *docSizeHeightKey = @"docSizeH";
NSString *currentLayerKey = @"currentLayer";
NSString *sourceKey = @"sourceProgram";
NSString *htmlSettingsKey = @"htmlSettings";
NSString *scriptURLKey = @"scriptURL";
NSString *additionalCSSKey = @"additionalCSS";
NSString *ACSDrawDocumentKey = @"documentKey";
//NSString *nextStyleKeyKey = @"nextStyleKey";

#pragma mark read/write doc

- (NSDictionary *)setupDictionaryFromMemory
   {
	NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];
	[dictionary setObject:pages forKey:pagesKey];
	if (strokes)
		[dictionary setObject:strokes forKey:strokesKey];
	if (fills)
		[dictionary setObject:fills forKey:fillsKey];
	if (_shadows)
		dictionary[shadowsKey] = _shadows;
	if (lineEndings)
		[dictionary setObject:lineEndings forKey:lineEndingsKey];
	dictionary[nameCountsKey] = _nameCounts;
	[dictionary setObject:self.documentKey forKey:ACSDrawDocumentKey];
	if (styles)
		[dictionary setObject:styles forKey:stylesKey];
	if (_docTitle)
		dictionary[docTitleKey] = _docTitle;
	[dictionary setObject:[NSNumber numberWithFloat:self.documentSize.width] forKey:docSizeWidthKey];
	[dictionary setObject:[NSNumber numberWithFloat:self.documentSize.height] forKey:docSizeHeightKey];
	if (backgroundColour)
		[dictionary setObject:backgroundColour forKey:backgroundColourKey];
	id version = [[[NSBundle mainBundle]infoDictionary]objectForKey:@"CFBundleVersion"];
	[dictionary setObject:[NSString stringWithFormat:@"ACSDraw %@",version] forKey:sourceKey];
	NSInteger i = [[[[self frontmostMainWindowController] graphicView] currentPage]currentLayerInd];
	[dictionary setObject:[NSNumber numberWithInteger:i] forKey:currentLayerKey];
	if (self.htmlSettings)
		[dictionary setObject:self.htmlSettings forKey:htmlSettingsKey];
	if (_scriptURL)
		dictionary[scriptURLKey] = _scriptURL;
	if (_additionalCSS)
		dictionary[additionalCSSKey] = _additionalCSS;
    if (miscValues[@"exporteventxml"])
        dictionary[@"exporteventxml"] = miscValues[@"exporteventxml"];
	return dictionary;
   }

-(NSData*)dataOfType:(NSString *)typeName error:(NSError **)outError
{
	NSDictionary *dict;
	dict = [self setupDictionaryFromMemory];
	return [NSKeyedArchiver archivedDataWithRootObject:dict requiringSecureCoding:NO error:NULL];
}

-(BOOL)writeToURL:(NSURL *)url ofType:(NSString *)typeName error:(NSError * _Nullable *)outError
{
    NSError *err = nil;
    [super writeToURL:url ofType:typeName error:&err];
    NSImage *im = [[mainWindowController graphicView]iconImageFromCurrentPageOfSize:512];
    [[NSWorkspace sharedWorkspace]setIcon:im forFile:[url path] options:0];
    return err == nil;
}
- (NSData *)dataRepresentationWithSubstitutedClasses 
{
	NSDictionary *dict = [self setupDictionaryFromMemory];
	NSMutableData *data = [NSMutableData dataWithCapacity:8192];
	NSKeyedArchiver *archiver = [[NSKeyedArchiver alloc]initForWritingWithMutableData:data];
	[archiver setDelegate:[[GXPArchiveDelegate alloc]init]];
	[archiver encodeObject:dict forKey:@"root"];
	[archiver finishEncoding];
    return data;
}


-(BOOL)readFromData:(NSData *)data ofType:(NSString *)typeName error:(NSError **)outError
{
    if ([[typeName lowercaseString]isEqualToString:@"svg"])
        return [self loadSVGData:data];
    if ([[typeName lowercaseString]isEqualToString:@"xml"])
        return [self loadLayoutXMLData:data];
    NSError *err = nil;
    NSKeyedUnarchiver *unarchiver = [[NSKeyedUnarchiver alloc] initForReadingFromData:data error:&err];
    unarchiver.requiresSecureCoding = NO;
    if (err)
        NSLog(@"File read error %@",[err localizedDescription]);
    [unarchiver setDelegate:[ArchiveDelegate archiveDelegateWithType:ARCHIVE_FILE document:self]];
    id d = [unarchiver decodeObjectForKey:@"root"];
    [unarchiver finishDecoding];
    if ([d isKindOfClass:[NSDictionary class]])
    {
        id obj;
        if ((obj = [d objectForKey:strokesKey]))
        {
            if ([obj count] < 5)
                [[self strokes] addObjectsFromArray:obj];
            else
                [self setStrokes:obj];
        }
        if ((obj = [d objectForKey:fillsKey]))
        {
            if ([obj count] < 5)
                [fills addObjectsFromArray:obj];
            else
                [self setFills:obj];
        }
        if ((obj = [d objectForKey:shadowsKey]))
        {
            if ([obj count] < 5)
                [_shadows addObjectsFromArray:obj];
            else
                [self setShadows:obj];
        }
        _documentSize.width = [[d objectForKey:docSizeWidthKey]floatValue];
        _documentSize.height = [[d objectForKey:docSizeHeightKey]floatValue];
        _docTitle = d[docTitleKey];
        _scriptURL = d[scriptURLKey];
        _additionalCSS = d[additionalCSSKey];
        //if ((obj = [d objectForKey:ACSDrawDocumentKey]))
        //[self setDocumentKey:obj];
        if ((obj = [d objectForKey:pagesKey]))
            [self setPages:obj];
        if ((obj = [d objectForKey:nameCountsKey]))
            [self setNameCounts:obj];
        if ((obj = [d objectForKey:lineEndingsKey]))
            [self setLineEndings:obj];
        if ((obj = [d objectForKey:stylesKey]))
            [self setStyles:obj];
        if ((obj = [d objectForKey:backgroundColourKey]))
            [self setBackgroundColour:obj];
        self.htmlSettings = [d objectForKey:htmlSettingsKey];
        [pages makeObjectsPerformSelector:@selector(fixTextBoxLinks)];
        if (d[@"exporteventxml"])
        {
            NSURL *u = d[@"exporteventxml"];
            if ([[NSFileManager defaultManager]fileExistsAtPath:[u path]])
                miscValues[@"exporteventxml"] = u;
        }
        return YES;
    }
    return NO;
}

- (void)setFileURL:(NSURL *)url
{
    [super setFileURL:url];
    [[mainWindowController window]setFrameAutosaveName:[[self fileURL]path]];
    [[mainWindowController window]saveFrameUsingName:[[self fileURL]path]];
}

#pragma mark

-(ACSDStroke*)strokeLikeStroke:(ACSDStroke*)stroke
{
    if (stroke == nil)
        return nil;
    for (ACSDStroke *st in strokes)
    {
        if ([st isSameAs:stroke])
            return st;
    }
    [[self strokes] addObject:stroke];
    [self registerObject:stroke];
    return stroke;
}

-(id)fillLikeFill:(ACSDFill*)fill
{
    if (fill == nil)
        return nil;
	if (![fill isKindOfClass:[ACSDFill class]])
		  return fill;
    for (ACSDFill *fi in [self fills])
    {
        if ([fi isSameAs:fill])
            return fi;
    }
    [[self fills] addObject:fill];
    [self registerObject:fill];
    return fill;
}

-(ACSDGradient*)gradientLikeGradient:(ACSDGradient*)grad
{
	if (grad == nil)
		return nil;
	for (ACSDGradient *fi in [self fills])
	{
		if ([fi isSameAs:grad])
			return fi;
	}
	[[self fills] addObject:grad];
	[self registerObject:grad];
	return grad;
}

#pragma mark -
#pragma mark svg

-(void)setAttributesFromCSSForNode:(XMLNode*)child settings:(NSMutableDictionary*)settings
{
    if (child.attributes[@"class"] == nil)
        return;
    NSString *currStyles = child.attributes[@"styles"];
    NSMutableString *styles = [[NSMutableString alloc]initWithString:currStyles?currStyles:@""];
    NSDictionary *definedStyles = settings[@"css"];
    NSArray *cssclasses = [child.attributes[@"class"] componentsSeparatedByString:@" "];
    BOOL changed = NO;
    for (NSString *cssclass in cssclasses)
    {
        if (cssclass != nil && [cssclass length] > 0)
        {
            NSString *css = definedStyles[cssclass];
            if (css)
            {
                if ([styles length]>0)
                    [styles appendString:@";"];
                [styles appendString:css];
                changed = YES;
            }
        }
    }
    if (changed)
    {
        NSMutableDictionary *mdict = [NSMutableDictionary dictionaryWithDictionary:child.attributes];
        mdict[@"style"] = styles;
        child.attributes = mdict;
    }
}

-(void)setAttributesFromStylesForNode:(XMLNode*)child settings:(NSMutableDictionary*)settings
{
    if (child.attributes[@"style"] == nil)
        return;
    NSMutableDictionary *mdict = nil;
    NSArray *svgstyles = [child.attributes[@"style"] componentsSeparatedByString:@";"];
    for (NSString *style in svgstyles)
    {
        if (style != nil && [style length] > 2)
        {
            NSArray *arr = [style componentsSeparatedByString:@":"];
            if ([arr count] > 1)
            {
                NSString *sty = arr[0];
                NSString *val = arr[1];
                sty = [sty stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
                val = [val stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
                if ([sty length] > 0)
                {
                    if (mdict == nil)
                        mdict = [NSMutableDictionary dictionaryWithDictionary:child.attributes];
                    mdict[sty] = val;
                }
            }
        }
    }
    if (mdict)
        child.attributes = mdict;
}

-(NSAffineTransform*)transFormFromAttrString:(NSString*)transformString
{
	int index = 0;
	NSAffineTransform *transform = [NSAffineTransform transform];
	while (index < [transformString length])
	{
		NSArray *arr = [self svgFunction:transformString index:&index];
		if ([arr count] < 2)
			break;
		NSString *ttype = arr[0];
		NSArray *params = arr[1];
		if ([ttype isEqualToString:@"translate"])
		{
			float dx = 0.0,dy = 0.0;
			if ([params count] > 0)
				dx = [params[0] floatValue];
			if ([params count] > 1)
				dy = [params[1] floatValue];
			[transform translateXBy:dx yBy:dy];
		}
		else if ([ttype isEqualToString:@"scale"])
		{
			float sx = 1.0;
			if ([params count] > 0)
				sx = [params[0] floatValue];
			float sy = sx;
			if ([params count] > 1)
				sy = [params[1] floatValue];
			[transform scaleXBy:sx yBy:sy];
		}
		else if ([ttype isEqualToString:@"rotate"])
		{
			float ang = 0.0;
			if ([params count] > 0)
				ang = [params[0] floatValue];
			float cx = 0.0,cy = 0.0;
			if ([params count] > 1)
				cx = [params[1] floatValue];
			if ([params count] > 2)
				cy = [params[2] floatValue];
			if (cx != 0.0 || cy != 0.0)
				[transform translateXBy:cx yBy:cy];
			[transform rotateByDegrees:ang];
			if (cx != 0.0 || cy != 0.0)
				[transform translateXBy:-cx yBy:-cy];
        }
        else if ([ttype isEqualToString:@"matrix"])
        {
            if ([params count] >= 6)
            {
                NSAffineTransformStruct ts;
                ts.m11 = [params[0] floatValue];
                ts.m12 = [params[1] floatValue];
                ts.m21 = [params[2] floatValue];
                ts.m22 = [params[3] floatValue];
                ts.tX  = [params[4] floatValue];
                ts.tY  = [params[5] floatValue];
                [transform setTransformStruct:ts];
            }
        }
	}
	return transform;
}

NSArray *usedAttrs=@[@"bevel",@"butt",@"cornerradius",@"display",@"fill",@"fill-opacity",@"fillopacity",@"height",@"hidden",@"id",@"inherit",@"linecap",@"miter",@"mitre-limit",@"none",@"opacity",@"pos",@"pxheight",@"pxwidth",@"rotation",@"round",@"scalex",@"scaley",@"square",@"src",@"stroke",@"stroke-dasharray",@"stroke-dashoffset",@"stroke-linecap",@"stroke-linejoin",@"stroke-opacity",@"stroke-width",@"strokewidth",@"transform",@"url",@"visibility",@"width",@"x",@"y",@"zpos"];


-(NSSet*)getAttributesFromSVGNode:(XMLNode*)child settings:(NSMutableDictionary*)settings
{
    [self setAttributesFromCSSForNode:child settings:settings];
    [self setAttributesFromStylesForNode:child settings:settings];
    ACSDStroke *stroke = strokeFromNodeAttributes(child.attributes);
    if (stroke)
        [settings setObject:[self strokeLikeStroke:stroke] forKey:@"stroke"];
    id fill = fillFromNodeAttributes(child.attributes);
    if (fill)
		[settings setObject:[self fillLikeFill:fill] forKey:@"fill"];
    NSString *transformString = [child.attributes objectForKey:@"transform"];
    if (transformString)
    {
        NSAffineTransform *transform = [[settings objectForKey:@"transform"]copy];
		NSAffineTransform *newTransform = [self transFormFromAttrString:transformString];
		[transform prependTransform:newTransform];
		[settings setObject:transform forKey:@"transform"];
    }
    NSString *v = [child.attributes objectForKey:@"visibility"];
    if (v != nil)
    {
        if ([v isEqual:@"hidden"])
            settings[@"hidden"] = @YES;
        else if (![v isEqual:@"inherit"])
            [settings removeObjectForKey:@"hidden"];
    }
    v = [child.attributes objectForKey:@"display"];
    if (v != nil)
    {
        if ([v isEqual:@"none"])
            settings[@"hidden"] = @YES;
    }
    v = [child.attributes objectForKey:@"hidden"];
    if (v != nil)
    {
        if ([v isEqual:@"true"])
            settings[@"hidden"] = @YES;
    }
    NSString *o = [child.attributes objectForKey:@"opacity"];
    if (o != nil)
    {
        float alpha = [o floatValue];
        settings[@"opacity"] = @(alpha);
    }
    NSString *r = child.attributes[@"rotation"];
    if (r != nil)
    {
        float rotation = [r floatValue];
        settings[@"rotation"] = @(rotation);
    }
    NSString *sx = child.attributes[@"scalex"];
    if (sx != nil)
    {
        float sxf = [sx floatValue];
        settings[@"scalex"] = @(sxf);
    }
    NSString *sy = child.attributes[@"scaley"];
    if (sy != nil)
    {
        float syf = [sy floatValue];
        settings[@"scaley"] = @(syf);
    }
    NSSet *usedKeys = [NSSet setWithArray:usedAttrs];
    NSMutableSet *unused = [NSMutableSet set];
    for (NSString *k in child.attributes)
    {
        if (![usedKeys containsObject:k])
            [unused addObject:k];
    }
    return unused;
}

-(NSArray*)svgFunction:(NSString*)str index:(int*)index
{
    while ((*index) < [str length] && [[NSCharacterSet whitespaceAndNewlineCharacterSet]characterIsMember:[str characterAtIndex:(*index)]])
        (*index)++;
    int startidx = (*index);
    while ((*index) < [str length] && ![[NSCharacterSet whitespaceAndNewlineCharacterSet]characterIsMember:[str characterAtIndex:(*index)]] && !([str characterAtIndex:(*index)] == '('))
        (*index)++;
    if (startidx == (*index))
        return @[];
    NSString *cmd = [str substringWithRange:NSMakeRange(startidx, (*index) - startidx)];
    while ((*index) < [str length] && !([str characterAtIndex:(*index)] == '('))
        (*index)++;
    (*index)++;
    if ((*index) >= [str length])
        return @[cmd];
    startidx = (*index);
    while ((*index) < [str length] && !([str characterAtIndex:(*index)] == ')'))
        (*index)++;
    if ((*index) >= [str length])
        return @[cmd];
    NSString *paramString = [str substringWithRange:NSMakeRange(startidx, (*index) - startidx)];
    (*index)++;
    NSMutableCharacterSet *charset = [[NSMutableCharacterSet whitespaceAndNewlineCharacterSet]mutableCopy];
    [charset addCharactersInString:@","];
    NSArray *components = [paramString componentsSeparatedByCharactersInSet:charset];
    return @[cmd,components];
}

-(void)processDefs:(XMLNode*)child settingsStack:(NSMutableArray*)settingsStack
{
    NSMutableDictionary *settings = [settingsStack lastObject];
    NSMutableDictionary *defs = settings[@"defs"];
    for (XMLNode *ch in child.children)
    {
		id obj = [self graphicFromSVGNode:ch settingsStack:settingsStack];
		NSString *idstr = [ch attributeStringValue:@"id"];
		if (idstr && obj)
			defs[idstr] = obj;
    }
}

-(SVG_Gradient*)gradientFromSVGNode:(XMLNode*)child settingsStack:(NSMutableArray*)settingsStack isLinear:(BOOL)linear
{
    SVG_Gradient *grad = [[SVG_Gradient alloc]init];
	if (!linear)
		grad.gradientType = GRADIENT_RADIAL;
	for (NSString *k in @[@"x1",@"y1",@"x2",@"y2",@"gradientUnits",@"spreadMethod",@"cx",@"cy",@"fx",@"fy",@"r"])
	{
		NSString *v = [child.attributes objectForKey:k];
		if (v)
			grad.attrs[k] = v;
	}
    NSString *tr = child.attributes[@"gradientTransform"];
    if (tr)
    {
        NSAffineTransform *trans = [self transFormFromAttrString:tr];
        grad.attrs[@"transform"] = trans;
    }
    NSColor *col = [NSColor blackColor];
    NSMutableArray *elements = [NSMutableArray array];
    for (XMLNode *stopnode in [child childrenOfType:@"stop"])
    {
		[self setAttributesFromStylesForNode:stopnode settings:nil];
        NSString *s = [stopnode.attributes objectForKey:@"offset"];
        float stopf = FloatOrPercentage(s);
        s = [stopnode.attributes objectForKey:@"stop-color"];
        if (s)
            col = colorFromRGBString(s);
        float alpha = 1.0;
        s = [stopnode.attributes objectForKey:@"stop-opacity"];
        if (s)
            alpha = [s floatValue];
        GradientElement *ge = [[GradientElement alloc]initWithPosition:stopf colour:[col colorWithAlphaComponent:alpha]];
        [elements addObject:ge];
    }
    if ([elements count] >= 2)
    {
        [grad setGradientElements:elements];
        return grad;
    }
    return nil;
}

static BOOL isWhiteSp(unichar ch)
{
    static NSCharacterSet *whitesp = nil;
    if (whitesp == nil)
    {
        whitesp = [NSCharacterSet whitespaceAndNewlineCharacterSet];
    }
    return [whitesp characterIsMember:ch];
}

static BOOL isCSSIdent(unichar ch)
{
    return ch != '{' && ! isWhiteSp(ch);
}


-(NSDictionary*)cssClassesFromString:(NSString*)contents
{
    NSMutableDictionary *d = [NSMutableDictionary dictionary];
    NSInteger idx = 0;
    NSInteger len = [contents length];
    while (idx < len)
    {
        unichar uc;
        while (idx < len && isWhiteSp(uc = [contents characterAtIndex:idx]))
            idx++;
        if (idx < len)
        {
            NSInteger st = idx;
            while (idx < len && isCSSIdent(uc = [contents characterAtIndex:idx]))
                idx++;
            if (st < idx)
            {
                if ([contents characterAtIndex:st] == '.')
                    st++;
                NSString *ident = [contents substringWithRange:NSMakeRange(st, idx - st)];
                while (idx < len && isWhiteSp(uc = [contents characterAtIndex:idx]))
                    idx++;
                if (uc != '{')
                    return nil;
                idx++;
                while (idx < len && isWhiteSp(uc = [contents characterAtIndex:idx]))
                    idx++;
                st = idx;
                while (idx < len && '}' != (uc = [contents characterAtIndex:idx]))
                    idx++;
                if (st < idx)
                {
                    NSString *css = [contents substringWithRange:NSMakeRange(st, idx - st)];;
                    idx++;
                    d[ident] = css;
                }
            }
        }
    }
    return d;
}

-(id)graphicFromSVGNode:(XMLNode*)child settingsStack:(NSMutableArray*)settingsStack
{
	NSMutableDictionary *currentSettings = [[settingsStack lastObject]mutableCopy];
    [settingsStack addObject:currentSettings];
    [self getAttributesFromSVGNode:child settings:currentSettings];
    ACSDGraphic *g = nil;
    NSString *nodeName = [child.nodeName lowercaseString];
    if ([nodeName isEqualToString:@"path"])
        g =[ACSDPath pathWithSVGNode:child settingsStack:settingsStack];
    else if ([nodeName isEqualToString:@"polyline"])
        g = [ACSDPath polylineWithSVGNode:child settingsStack:settingsStack];
    else if ([nodeName isEqualToString:@"polygon"])
        g = [ACSDPath polygonWithSVGNode:child settingsStack:settingsStack];
    else if ([nodeName isEqualToString:@"line"])
        g = [ACSDPath pathLineWithSVGNode:child settingsStack:settingsStack];
    else if ([nodeName isEqualToString:@"rect"])
        g = [ACSDPath pathRectWithSVGNode:child settingsStack:settingsStack];
    else if ([nodeName isEqualToString:@"circle"])
        g = [ACSDCircle circleWithSVGNode:child settingsStack:settingsStack];
    else if ([nodeName isEqualToString:@"ellipse"])
        g = [ACSDPath ellipseWithSVGNode:child settingsStack:settingsStack];
    else if ([nodeName isEqualToString:@"g"])
    {
        for (XMLNode *ch in child.children)
            [self processSVGNode:ch settingsStack:settingsStack];
    }
    else if ([nodeName isEqualToString:@"style"])
    {
        [settingsStack removeLastObject];
        NSMutableDictionary *settings = [settingsStack lastObject];
        settings[@"css"] = [self cssClassesFromString:[child contents]];
        return nil;
    }
    else if ([nodeName isEqualToString:@"lineargradient"])
    {
        [settingsStack removeLastObject];
        return [self gradientFromSVGNode:child settingsStack:settingsStack isLinear:YES];
    }
	else if ([nodeName isEqualToString:@"radialgradient"])
	{
        [settingsStack removeLastObject];
		return [self gradientFromSVGNode:child settingsStack:settingsStack isLinear:NO];
	}
    else if ([nodeName isEqualToString:@"pattern"])
    {
        
    }
	else if ([nodeName isEqualToString:@"defs"])
	{
		[self processDefs:child settingsStack:settingsStack];
	}
    if (g)
    {
        [g setStroke:[currentSettings objectForKey:@"stroke"]];
		id f = [currentSettings objectForKey:@"fill"];
		if ([f isKindOfClass:[NSString class]] && [f hasPrefix:@"url("])
		{
			NSString *url = [f substringWithRange:NSMakeRange(5,[f length]-1-5)];
			NSDictionary *defs = currentSettings[@"defs"];
			id obj = defs[url];
			if (obj)
			{
				if ([obj isKindOfClass:[SVG_Gradient class]])
				{
					SVG_Gradient *svgg = [obj copy];
					NSRect bounds = NSZeroRect;
					bounds.size = self.documentSize;
					[svgg resolveSettingsForOriginalBoundingBox:[g bounds] frame:bounds];
					[[self fills] addObject:svgg];
					[self registerObject:svgg];
					[g setFill:svgg];
				}
			}
		}
		else
			[g setFill:f];
		
		
        NSNumber *alphan = [currentSettings objectForKey:@"opacity"];
        if (alphan)
            [g setAlpha:[alphan floatValue]];
        NSString *idstr = [child attributeStringValue:@"id"];
        if (idstr == nil)
            idstr = @"";
        [g setName:idstr];
        if ([currentSettings[@"hidden"]boolValue])
            g.hidden = YES;
        
    }
    [settingsStack removeLastObject];
    return g;
}

-(void)processSVGNode:(XMLNode*)child settingsStack:(NSMutableArray*)settingsStack
{
    NSString *nodeName = [child.nodeName lowercaseString];
    if ([nodeName isEqualToString:@"switch"])
    {
        for (XMLNode *n in child.children)
        {
            [self processSVGNode:n settingsStack:settingsStack];
        }
        return;
    }
    ACSDGraphic *g = [self graphicFromSVGNode:child settingsStack:settingsStack];
    if (g)
    {
        if ([g isKindOfClass:[ACSDGraphic class]])
            [[[self pages][0] currentLayer] addGraphic:g];
        else
        {
            NSString *nm = child.attributes[@"id"];
            if (nm)
            {
                NSMutableDictionary *currSettings = [settingsStack lastObject];
                NSMutableDictionary *defs = currSettings[@"defs"];
                defs[nm] = g;
            }
        }
    }
}

-(BOOL)loadLayoutXMLData:(NSData*)data
{
    XMLManager *xmlman = [[XMLManager alloc]init];
    XMLNode *root = [xmlman parseData:data];
    if (![root.nodeName isEqualToString:@"events"])
        return NO;
    _documentSize.width = 1024;
    _documentSize.height = 768;
    
    NSMutableArray *settingsStack = [NSMutableArray arrayWithCapacity:6];
    NSMutableDictionary *settings = [NSMutableDictionary dictionaryWithCapacity:10];
    //ACSDFill *blackFill = [[[ACSDFill alloc]initWithColour:[NSColor blackColor]]autorelease];
    //[settings setObject:[self fillLikeFill:blackFill] forKey:@"fill"];
    [settings setObject:[NSMutableDictionary dictionaryWithCapacity:10] forKey:@"defs"];
    settings[@"docheight"] = @(self.documentSize.height);
    NSAffineTransform *t = [NSAffineTransform transformWithTranslateXBy:0 yBy:self.documentSize.height];
    [t scaleXBy:1.0 yBy:-1.0];
    settings[@"transform"] = t;
    settings[@"parentrect"] = [NSValue valueWithRect:NSMakeRect(0, 0, self.documentSize.width, self.documentSize.height)];
    [settingsStack addObject:settings];

    NSMutableDictionary *objectDict = [NSMutableDictionary dictionary];
    [[self pages]removeObjectAtIndex:0];
    for (XMLNode *eventNode in root.children)
        [[self pages]addObject:[[ACSDPage alloc]initWithXMLNode:eventNode document:self settingsStack:settingsStack objectDict:objectDict]];
    [self setFileType:@"acsd"];
    if ([self fileURL] != nil)
        [self setFileURL:[NSURL fileURLWithPath:[[[[self fileURL] path]stringByDeletingPathExtension]stringByAppendingPathExtension:@"acsd"]]];
    return YES;
}

-(BOOL)loadSVGData:(NSData*)data
{
    XMLManager *xmlman = [[XMLManager alloc]init];
    XMLNode *root = [xmlman parseData:data];
    if (![root.nodeName isEqualToString:@"svg"])
        return NO;
	int vbw=0,vbh=0;
	NSString *s = [root attributes][@"viewBox"];
	if (s)
	{
		NSArray<NSString*> *arr = [s nonBlankComponentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
		float x = 0,y = 0;
		if ([arr count] > 0)
		{
			x = floorf(([arr[0] floatValue]));
			if ([arr count] > 1)
			{
				y = floorf([arr[1] floatValue]);
				if ([arr count] > 2)
				{
					vbw = (ceilf([arr[2] floatValue]) - x);
					if ([arr count] > 3)
						vbh = (ceilf([arr[3] floatValue]) - y);
				}
			}
		}
	}
    NSString *ws = [root attributeStringValue:@"width"];
    NSString *hs = [root attributeStringValue:@"height"];
    if ([ws hasSuffix:@"%"] || [hs hasSuffix:@"%"])
    {
        
    }
    _documentSize.width = ceilf([root attributeFloatValue:@"width"]);
	if (self.documentSize.width < vbw)
		_documentSize.width = vbw;
    _documentSize.height = ceilf([root attributeFloatValue:@"height"]);
	if (self.documentSize.height < vbh)
		_documentSize.height = vbh;
    NSMutableArray *settingsStack = [NSMutableArray arrayWithCapacity:6];
    NSMutableDictionary *svgSettings = [NSMutableDictionary dictionaryWithCapacity:10];
    
    //[self getAttributesFromSVGNode:root settings:svgSettings];
    
	ACSDFill *blackFill = [[ACSDFill alloc]initWithColour:[NSColor blackColor]];
    [svgSettings setObject:[self fillLikeFill:blackFill] forKey:@"fill"];
    [svgSettings setObject:[NSMutableDictionary dictionaryWithCapacity:10] forKey:@"defs"];
    NSAffineTransform *t = [NSAffineTransform transformWithTranslateXBy:0 yBy:self.documentSize.height];
    [t scaleXBy:1.0 yBy:-1.0];
    [svgSettings setObject:t forKey:@"transform"];
    [settingsStack addObject:svgSettings];
    for (XMLNode *child in root.children)
        [self processSVGNode:child settingsStack:settingsStack];
	[self setFileType:@"acsd"];
	if ([self fileURL] != nil)
		[self setFileURL:[NSURL fileURLWithPath:[[[[self fileURL] path]stringByDeletingPathExtension]stringByAppendingPathExtension:@"acsd"]]];
    return YES;
}

#pragma mark -


#pragma mark -
#pragma mark exports

NSString *xHTMLString1 = @"<!doctype html>\n";
NSString *xHTMLString2 = @"<html>\n";

- (void)writeIndexPage:(NSString*)path firstPage:(NSString*)pg
{
	NSMutableString *contents = [NSMutableString stringWithCapacity:100];
	[contents appendString:xHTMLString1];
	[contents appendString:xHTMLString2];
	[contents appendString:@"\t<head>\n\t\t<title></title>\n\t\t<meta charset=macintosh\"/>\n"];
	[contents appendString:[NSString stringWithFormat:@"\t\t<script>\n\t\t\twindow.location.href=\'%@\';\n\t\t</script>\n\t</head>\n\t<body>\n\t</body>\n</html>",
		pg]];
	NSError *err;
	if (![contents writeToFile:[path stringByAppendingPathComponent:@"index.html"] atomically:NO encoding:NSUnicodeStringEncoding error:&err])
		NSBeep();
}

- (void)htmlSavePanelDidEnd:(NSWindow *)sp returnCode:(int)runResult contextInfo:(void  *)contextInfo
{
    if (runResult == NSModalResponseOK)
	{
		[self setExportDirectory:[(NSSavePanel*)sp directoryURL]];
		NSURL *url = [(NSSavePanel*)sp URL];
		NSFileManager *fileManager = [NSFileManager defaultManager];
		NSError *err;
		if ([fileManager fileExistsAtPath:[url path]])
			[fileManager removeItemAtURL:url error:nil];
		if (![fileManager createDirectoryAtPath:[url path] withIntermediateDirectories:NO attributes:nil error:&err])
		{
			show_error_alert([NSString stringWithFormat:@"Error creating directory: %@, %@",[url path],[err localizedDescription]]);
			return;
		}
		NSString *smallImagesFolderName = [[url path] stringByAppendingPathComponent:@"smallimages"],
		*largeImagesFolderName = [[url path] stringByAppendingPathComponent:@"largeimages"];
		NSString *dTitle = [[self displayName]stringByDeletingPathExtension];
		if (!self.htmlSettings)
            self.htmlSettings = [[NSMutableDictionary alloc]initWithCapacity:5];
		NSMutableDictionary *options = [NSMutableDictionary dictionaryWithCapacity:10];
		[options setObject:dTitle forKey:@"dTitle"];
		[options setObject:[url path] forKey:@"directory"];
		[options setObject:smallImagesFolderName forKey:@"smallimages"];
		[options setObject:largeImagesFolderName forKey:@"largeimages"];
		[options setObject:self.htmlSettings forKey:@"htmlSettings"];
		if (_scriptURL && [_scriptURL length] > 0)
			options[@"scriptURL"] = _scriptURL;
		[_exportHTMLController updateSettingsFromControls:self.htmlSettings];
		[options setObject:[self.htmlSettings objectForKey:@"ieCompatibility"] forKey:@"ieCompatibility"];
		NSString *firstPageFileName = nil;
		for (ACSDPage *page in [self pages])
		{
			if ([page pageType] == PAGE_TYPE_NORMAL)
			{
				NSString *html = [page htmlRepresentationOptions:options];
				int pageNo = [[options objectForKey:@"pageNo"]intValue];
				NSString *pageName = [NSString stringWithFormat:@"%@_%d.html",dTitle,pageNo];
				if (pageNo == 1)
				{
					[self writeIndexPage:[url path] firstPage:pageName];
					firstPageFileName = [[url path] stringByAppendingPathComponent:pageName];
				}
				NSError *err;
				if (![html writeToURL:[url URLByAppendingPathComponent:pageName] atomically:NO encoding:NSUnicodeStringEncoding error:&err])
					NSBeep();
			}
		}
		if ([[self.htmlSettings objectForKey:@"openAfterExport"]boolValue])
			[[NSWorkspace sharedWorkspace] openFile:firstPageFileName];
	}
}

-(NSString*)graphicXMLString
{
	NSMutableString *xmlString = [NSMutableString stringWithCapacity:500];
	NSMutableDictionary *options = [NSMutableDictionary dictionaryWithCapacity:10];
	[options setObject:[NSNumber numberWithInt:self.documentSize.width] forKey:xmlDocWidth];
	[options setObject:[NSNumber numberWithInt:self.documentSize.height] forKey:xmlDocHeight];
	[options setObject:@"\t" forKey:xmlIndent];
	[xmlString appendString:@"<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n"];
	[xmlString appendString:[[[mainWindowController graphicView]currentPage]graphicXML:options]];
	return xmlString;
}

NSString* Creator()
{
    NSString *version = [[[NSBundle mainBundle]infoDictionary]objectForKey:@"CFBundleVersion"];
    NSString *creator;
    if (version)
        creator = [NSString stringWithFormat:@"ACSDraw %@",version];
    else
        creator = @"ACSDraw";
    return creator;
}

-(NSString*)eventsXMLString:(NSArray*)pages
{
	NSMutableString *xmlString = [NSMutableString stringWithCapacity:500];
	NSMutableDictionary *options = [NSMutableDictionary dictionaryWithCapacity:10];
	options[xmlDocWidth] = @(self.documentSize.width);
	options[xmlDocHeight] = @(self.documentSize.height);
	options[@"errors"] = @0;
	options[@"document"] = self;
	options[xmlIndent] = @"\t";
	[xmlString appendString:@"<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<events>\n"];
    [xmlString appendFormat:@"<!--Exported from %@ by %@ using %@  on %@ -->\n",[[self fileURL]lastPathComponent],NSFullUserName(),Creator(),[NSDate date]];
	for (ACSDPage *page in pages)
		[xmlString appendString:[page graphicXMLForEvent:options]];
    [xmlString appendString:@"</events>"];
	return xmlString;
}

-(void)exportAnimation:(id)sender
{
	NSSavePanel *sp;
	NSString *fName = [[[self displayName]stringByDeletingPathExtension]stringByAppendingPathExtension:@"mp4"];
	sp = [NSSavePanel savePanel];
	[sp setAllowedFileTypes:[NSArray arrayWithObject:@"mp4"]];
	[sp setTitle:@"Export Animation"];
	[sp setDirectoryURL:[self exportDirectory]];
	[sp setNameFieldStringValue:fName];
	[sp beginSheetModalForWindow:[[self frontmostMainWindowController] window] completionHandler:^(NSInteger result)
	 {
        if (result == NSModalResponseOK)
		 {
			 [animationsController recordAnimationsToURL:[sp URL]];
		 }
	 }
	 ];
}

- (void)exportLineEndings:(id)menuItem
{
	NSSavePanel *sp;
	NSString *fName = [[[self displayName]stringByDeletingPathExtension]stringByAppendingPathExtension:@"acsdl"];
	sp = [NSSavePanel savePanel];
	[sp setAllowedFileTypes:[NSArray arrayWithObject:@"acsdl"]];
	[sp setTitle:@"Export Line Endings"];
	[sp setDirectoryURL:[self exportDirectory]];
	[sp setNameFieldStringValue:fName];
	[sp beginSheetModalForWindow:[[self frontmostMainWindowController] window] completionHandler:^(NSInteger result)
	 {
        if (result == NSModalResponseOK)
		 {
			 NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];
			 [dictionary setObject:self->lineEndings forKey:lineEndingsKey];
			 NSData *leData  = archivedObject(dictionary);
			 [self setExportDirectory:[sp directoryURL]];
			 if (![leData writeToURL:[sp URL] atomically:NO])
				 NSBeep();
		 }
	 }
	 ];
}

- (void)exportIP:(id)menuItem
{
	NSSavePanel *sp;
	NSString *fName = [[[self displayName]stringByDeletingPathExtension]stringByAppendingPathExtension:@"acsip"];
	sp = [NSSavePanel savePanel];
	[sp setAllowedFileTypes:[NSArray arrayWithObject:@"acsip"]];
	[sp setTitle:@"Export For IP"];
	[sp setDirectoryURL:[self exportDirectory]];
	[sp setNameFieldStringValue:fName];
	[sp beginSheetModalForWindow:[[self frontmostMainWindowController] window] completionHandler:^(NSInteger result)
	 {
        if (result == NSModalResponseOK)
		 {
			 NSData *data  = [self dataRepresentationWithSubstitutedClasses];
			 [self setExportDirectory:[sp directoryURL]];
			 if (![data writeToURL:[sp URL] atomically:NO])
				 NSBeep();
		 }
	 }
	 ];
}

- (void)exportEPS:(id)menuItem
{
	NSSavePanel *sp;
	NSString *fName = [[[self displayName]stringByDeletingPathExtension]stringByAppendingPathExtension:@"eps"];
	sp = [NSSavePanel savePanel];
	[sp setAllowedFileTypes:[NSArray arrayWithObject:@"eps"]];
	[sp setTitle:@"Export EPS"];
	[sp setDirectoryURL:[self exportDirectory]];
	[sp setNameFieldStringValue:fName];
	[sp beginSheetModalForWindow:[[self frontmostMainWindowController] window] completionHandler:^(NSInteger result)
	 {
        if (result == NSModalResponseOK)
		 {
			 NSData *eps  = [[self frontmostMainWindowController] epsRepresentation];
			 [self setExportDirectory:[sp directoryURL]];
			 if (![eps writeToURL:[sp URL] atomically:NO])
				 NSBeep();
		 }
	 }
	 ];
}

- (void)exportHTML:(id)menuItem
{
	NSArray *topLevelObjects = nil;
	if (!_exportHTMLController)
		[[NSBundle mainBundle]loadNibNamed:@"HTMLExport" owner:self topLevelObjects:&topLevelObjects];
	NSSavePanel *sp;
	NSString *fName = [[self displayName]stringByDeletingPathExtension];
	sp = [NSSavePanel savePanel];
	[sp setAllowedFileTypes:nil];
	[sp setTitle:@"Export HTML"];
	[sp setAccessoryView:[_exportHTMLController accessoryView]];
	[_exportHTMLController setControls:self.htmlSettings];
	[sp setDirectoryURL:[self exportDirectory]];
	[sp setNameFieldStringValue:fName];
	[sp beginSheetModalForWindow:[[self frontmostMainWindowController] window] completionHandler:^(NSInteger result)
	 {
        if (result == NSModalResponseOK)
		 {
			 [self setExportDirectory:[(NSSavePanel*)sp directoryURL]];
			 NSURL *url = [(NSSavePanel*)sp URL];
			 NSFileManager *fileManager = [NSFileManager defaultManager];
			 NSError *err;
			 if ([fileManager fileExistsAtPath:[url path]])
				 [fileManager removeItemAtURL:url error:nil];
			 if (![fileManager createDirectoryAtPath:[url path] withIntermediateDirectories:NO attributes:nil error:&err])
			 {
				 show_error_alert([NSString stringWithFormat:@"Error creating directory: %@, %@",[url path],[err localizedDescription]]);
				 return;
			 }
			 NSString *smallImagesFolderName = [[url path] stringByAppendingPathComponent:@"smallimages"],
			 *largeImagesFolderName = [[url path] stringByAppendingPathComponent:@"largeimages"];
			 NSString *dTitle = [[self displayName]stringByDeletingPathExtension];
			 if (!self.htmlSettings)
                 self.htmlSettings = [[NSMutableDictionary alloc]initWithCapacity:5];
			 NSMutableDictionary *options = [NSMutableDictionary dictionaryWithCapacity:10];
			 [options setObject:dTitle forKey:@"dTitle"];
			 [options setObject:[url path] forKey:@"directory"];
			 [options setObject:smallImagesFolderName forKey:@"smallimages"];
			 [options setObject:largeImagesFolderName forKey:@"largeimages"];
			 [options setObject:self.htmlSettings forKey:@"htmlSettings"];
			 if (self.scriptURL && [self.scriptURL length] > 0)
				 options[@"scriptURL"] = self.scriptURL;
			 [self.exportHTMLController updateSettingsFromControls:self.htmlSettings];
			 [options setObject:[self.htmlSettings objectForKey:@"ieCompatibility"] forKey:@"ieCompatibility"];
			 //		[options setObject:[NSMutableDictionary dictionaryWithCapacity:10] forKey:@"fontDict"];
			 NSString *firstPageFileName = nil;
			 for (ACSDPage *page in [self pages])
			 {
				 if ([page pageType] == PAGE_TYPE_NORMAL)
				 {
					 NSString *html = [page htmlRepresentationOptions:options];
					 int pageNo = [[options objectForKey:@"pageNo"]intValue];
					 NSString *pageName = [NSString stringWithFormat:@"%@_%d.html",dTitle,pageNo];
					 if (pageNo == 1)
					 {
						 [self writeIndexPage:[url path] firstPage:pageName];
						 firstPageFileName = [[url path] stringByAppendingPathComponent:pageName];
					 }
					 NSError *err;
					 if (![html writeToURL:[url URLByAppendingPathComponent:pageName] atomically:NO encoding:NSUnicodeStringEncoding error:&err])
						 NSBeep();
				 }
			 }
			 if ([self.htmlSettings [@"openAfterExport"]boolValue])
				 [[NSWorkspace sharedWorkspace] openFile:firstPageFileName];
		 }
	 }
	 ];
}

- (void)exportPDF:(id)menuItem
{
	NSString *fName = [[[self displayName]stringByDeletingPathExtension]stringByAppendingPathExtension:@"pdf"];
	NSSavePanel *sp = [NSSavePanel savePanel];
	[sp setAllowedFileTypes:[NSArray arrayWithObject:@"pdf"]];
	[sp setTitle:@"Export PDF"];
	[sp setAccessoryView:[[ACSDPrefsController sharedACSDPrefsController:nil] exportAccessoryView]];
	[sp setDirectoryURL:[self exportDirectory]];
	[sp setNameFieldStringValue:fName];
	[sp beginSheetModalForWindow:[[self frontmostMainWindowController] window] completionHandler:^(NSInteger result)
	 {
        if (result == NSModalResponseOK)
		 {
			 [[self frontmostMainWindowController] writePDFRepresentationToURL:[sp URL]];
             if ([[[ACSDPrefsController sharedACSDPrefsController:nil]openAfterExportCB]state] == NSControlStateValueOn)
				 [[NSWorkspace sharedWorkspace] performSelector:@selector(openURL:) withObject:[(NSSavePanel*)sp URL] afterDelay:0.02];
		 }
	 }
	 ];
}

-(NSArray*)svgBodyString
{
	SVGWriter *svgWriter = [[SVGWriter alloc]initWithSize:self.documentSize document:self page:0];
	[svgWriter createData];
	return @[[svgWriter defs],[svgWriter contents]];
}

- (void)exportSVG:(id)menuItem
{
	NSSavePanel *sp;
	NSString *fName = [[[self displayName]stringByDeletingPathExtension]stringByAppendingPathExtension:@"svg"];
	sp = [NSSavePanel savePanel];
	[sp setAllowedFileTypes:[NSArray arrayWithObject:@"svg"]];
	[sp setTitle:@"Export SVG"];
	[sp setDirectoryURL:[self exportDirectory]];
	[sp setNameFieldStringValue:fName];
	[sp beginSheetModalForWindow:[[self frontmostMainWindowController] window] completionHandler:^(NSInteger result)
	 {
        if (result == NSModalResponseOK)
		 {
			 [self setExportDirectory:[sp directoryURL]];
			 SVGWriter *svgWriter = [[SVGWriter alloc]initWithSize:self.documentSize document:self page:[[[self frontmostMainWindowController] graphicView]currentPageInd]];
			 [svgWriter createData];
			 NSError *err = nil;
			 if (!([[svgWriter fullString] writeToURL:[(NSSavePanel*)sp URL] atomically:YES encoding:NSUTF8StringEncoding error:&err]))
				 NSBeep();
		 }
	 }
	 ];
}

- (IBAction)exportSVGByPage:(id)menuItem
{
    NSSavePanel *sp;
    NSString *fName = [[self displayName]stringByDeletingPathExtension];
    sp = [NSSavePanel savePanel];
    [sp setAllowedFileTypes:nil];
    [sp setTitle:@"Export SVG By Page"];
    [sp setDirectoryURL:[self exportDirectory]];
    [sp setNameFieldStringValue:fName];
    [sp beginSheetModalForWindow:[[self frontmostMainWindowController] window] completionHandler:^(NSInteger result)
     {
        if (result == NSModalResponseOK)
        {
            [self setExportDirectory:[(NSSavePanel*)sp directoryURL]];
            NSURL *url = [(NSSavePanel*)sp URL];
            NSFileManager *fileManager = [NSFileManager defaultManager];
            NSError *err;
            if ([fileManager fileExistsAtPath:[url path]])
                [fileManager removeItemAtURL:url error:nil];
            if (![fileManager createDirectoryAtPath:[url path] withIntermediateDirectories:NO attributes:nil error:&err])
            {
                show_error_alert([NSString stringWithFormat:@"Error creating directory: %@, %@",[url path],[err localizedDescription]]);
                return;
            }
            for (NSInteger i = 0;i < [self.pages count];i++)
            {
                ACSDPage *page = self.pages[i];
                if ([page pageType] == PAGE_TYPE_NORMAL)
                {
                    NSString *nm = [[NSString stringWithFormat:@"%d_%@",(int)i,page.pageTitle] stringByAppendingPathExtension:@"svg"];
                    NSURL *furl = [url URLByAppendingPathComponent:nm];
                    SVGWriter *svgWriter = [[SVGWriter alloc]initWithSize:self.documentSize document:self page:i];
                    [svgWriter createData];
                    NSError *err = nil;
                    if (!([[svgWriter fullString] writeToURL:furl atomically:YES encoding:NSUTF8StringEncoding error:&err]))
                        show_error_alert([NSString stringWithFormat:@"Error writing svg: %@, %@",furl,[err localizedDescription]]);
                }
            }
        }
    }];
}

- (void)exportGraphicXML:(id)menuItem
{
	NSSavePanel *sp;
	NSString *fName = [[[self displayName]stringByDeletingPathExtension]stringByAppendingPathExtension:@"xml"];
	sp = [NSSavePanel savePanel];
	[sp setAllowedFileTypes:[NSArray arrayWithObject:@"xml"]];
	[sp setTitle:@"Export Graphic XML"];
	[sp setDirectoryURL:[self exportDirectory]];
	[sp setNameFieldStringValue:fName];
	[sp beginSheetModalForWindow:[[self frontmostMainWindowController] window] completionHandler:^(NSInteger result)
	 {
        if (result == NSModalResponseOK)
		 {
			 NSError *err = nil;
			 if (!([[self graphicXMLString] writeToURL:[sp URL] atomically:YES encoding:NSUnicodeStringEncoding error:&err]))
				 NSBeep();
		 }
	 }
	 ];
}

- (void)exportEventXMLFromPages:(id)menuItem
{
    NSSavePanel *sp;
    NSString *fName = [[self displayName]stringByDeletingPathExtension];
    sp = [NSSavePanel savePanel];
    [sp setAllowedFileTypes:nil];
    [sp setTitle:@"Export Page Event XML"];
    [sp setDirectoryURL:[self exportDirectory]];
    [sp setNameFieldStringValue:fName];
    
    if (!textAccessoryView)
        [[NSBundle mainBundle]loadNibNamed:@"TextAccessory" owner:self topLevelObjects:nil];
    [sp setAccessoryView:textAccessoryView];

    
    [sp beginSheetModalForWindow:[[self frontmostMainWindowController] window] completionHandler:^(NSInteger result)
     {
        if (result == NSModalResponseOK)
         {
             [self setExportDirectory:[(NSSavePanel*)sp directoryURL]];
             NSURL *url = [(NSSavePanel*)sp URL];
             NSFileManager *fileManager = [NSFileManager defaultManager];
             NSError *err;
             if ([fileManager fileExistsAtPath:[url path]])
                 [fileManager removeItemAtURL:url error:nil];
             if (![fileManager createDirectoryAtPath:[url path] withIntermediateDirectories:NO attributes:nil error:&err])
             {
                 show_error_alert([NSString stringWithFormat:@"Error creating directory: %@, %@",[url path],[err localizedDescription]]);
                 return;
             }
             NSString *evn = [self->textAccessoryTextField stringValue];
             for (ACSDPage *page in self.pages)
             {
                 if ([page pageType] == PAGE_TYPE_NORMAL)
                 {
                     if ([evn length] > 0)
                         page.xmlEventName = evn;
                     NSString *nm = [page.pageTitle stringByAppendingPathExtension:@"xml"];
                     NSURL *furl = [url URLByAppendingPathComponent:nm];
                     if (!([[self eventsXMLString:@[page]] writeToURL:furl atomically:YES encoding:NSUTF8StringEncoding error:&err]))
                         show_error_alert([NSString stringWithFormat:@"Error writing xml: %@, %@",furl,[err localizedDescription]]);

                 }
             }
         }
    }];
}
- (void)exportEventXML:(id)menuItem
{
	NSSavePanel *sp;
	NSString *fName = [[[self displayName]stringByDeletingPathExtension]stringByAppendingPathExtension:@"xml"];
	sp = [NSSavePanel savePanel];
	[sp setAllowedFileTypes:[NSArray arrayWithObject:@"xml"]];
	[sp setTitle:@"Export Event XML"];
	[sp setDirectoryURL:[self exportDirectory]];
	[sp setNameFieldStringValue:fName];
	[sp beginSheetModalForWindow:[[self frontmostMainWindowController] window] completionHandler:^(NSInteger result)
	 {
        if (result == NSModalResponseOK)
		 {
			 NSError *err = nil;
             self.exportDirectory = [sp directoryURL];
			 self->miscValues[@"exporteventxml"] = [sp URL];
             if (!([[self eventsXMLString:self.pages] writeToURL:[sp URL] atomically:YES encoding:NSUTF8StringEncoding error:&err]))
				 show_error_alert([NSString stringWithFormat:@"Error writing xml: %@, %@",[sp URL],[err localizedDescription]]);
		 }
	 }
	 ];
}

-(IBAction)exportEventXMLToLastFile:(id)sender
{
	NSURL *url = miscValues[@"exporteventxml"];
	if (url == nil)
		return;
	NSError *err = nil;
    if (!([[self eventsXMLString:self.pages] writeToURL:url atomically:YES encoding:NSUTF8StringEncoding error:&err]))
	{
		NSLog(@"%@",[err localizedDescription]);
		NSBeep();
	}
}
- (void)exportTiff:(id)menuItem
{
	NSSavePanel *sp;
	NSString *fName = [[[self displayName]stringByDeletingPathExtension]stringByAppendingPathExtension:@"tiff"];
	sp = [NSSavePanel savePanel];
	[sp setAllowedFileTypes:[NSArray arrayWithObject:@"tiff"]];
	[sp setTitle:@"Export Tiff"];
	[sp setDirectoryURL:[self exportDirectory]];
	[sp setNameFieldStringValue:fName];
	[sp beginSheetModalForWindow:[[self frontmostMainWindowController] window] completionHandler:^(NSInteger result)
	 {
        if (result == NSModalResponseOK)
		 {
			 NSData *tiff  = [[self frontmostMainWindowController] tiffRepresentation];
			 [self setExportDirectory:[(NSSavePanel*)sp directoryURL]];
			 if (![tiff writeToURL:[(NSSavePanel*)sp URL] atomically:NO])
				 NSBeep();			 
		 }
	 }
	 ];
}

- (void)exportSelectionImageDrawSelectionOnly:(BOOL)drawSelectionOnly
{
    if (!_exportImageController)
    {
        NSArray *topLevelObjects;
        [[NSBundle mainBundle] loadNibNamed:@"ImageController" owner:self topLevelObjects:&topLevelObjects];
    }
    NSSavePanel *sp;
    NSString *fName = [[self displayName]stringByDeletingPathExtension];
    sp = [NSSavePanel savePanel];
    if (!self.exportImageSettings)
    {
        self.exportImageSettings = [[NSMutableDictionary alloc]initWithCapacity:5];
        [self.exportImageSettings setObject:[NSNumber numberWithFloat:0.7] forKey:@"compressionQuality"];
    }
    [self.exportImageSettings setObject:[NSNumber numberWithInteger:self.documentSize.width] forKey:@"imageWidth"];
    [self.exportImageSettings setObject:[NSNumber numberWithInteger:self.documentSize.height] forKey:@"imageHeight"];
    [_exportImageController setControls:self.exportImageSettings];
    [_exportImageController prepareSavePanel:sp];
    [sp setTitle:@"Export Image"];
    [sp setDirectoryURL:[self exportDirectory]];
    [sp setNameFieldStringValue:fName];
    [sp beginSheetModalForWindow:[[self frontmostMainWindowController] window] completionHandler:^(NSInteger result)
     {
        if (result == NSModalResponseOK)
         {
             int resolution = 72;
             [self.exportImageController updateSettingsFromControls:self.exportImageSettings];
             NSSize sz;
             sz.width = [[self.exportImageSettings objectForKey:@"imageWidth"]floatValue];
             sz.height = [[self.exportImageSettings objectForKey:@"imageHeight"]floatValue];
             float compressionQuality = [[self.exportImageSettings objectForKey:@"compressionQuality"]floatValue];
             [self setExportDirectory:[sp directoryURL]];
             CGImageRef cgr = [[self frontmostMainWindowController]cgImageFromCurrentPageSelectionOnlyDrawSelectionOnly:drawSelectionOnly];
             CGImageRetain(cgr);
             CGImageDestinationRef dest = CGImageDestinationCreateWithURL((CFURLRef)[sp URL],(CFStringRef)[self.exportImageController uti],1,nil);
             NSDictionary *props = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithFloat:compressionQuality],kCGImageDestinationLossyCompressionQuality,
                                    [NSNumber numberWithInt:resolution],kCGImagePropertyDPIHeight,[NSNumber numberWithInt:resolution],kCGImagePropertyDPIWidth,nil];
             CGImageDestinationAddImage(dest,cgr,(CFDictionaryRef)props);
             CGImageDestinationFinalize(dest);
             CFRelease(dest);
             CGImageRelease(cgr);
         }
     }
     ];
}

- (void)exportSelectionImage:(id)menuItem
{
    [self exportSelectionImageDrawSelectionOnly:YES];
}

- (void)exportSelectionImageDrawAll:(id)menuItem
{
    [self exportSelectionImageDrawSelectionOnly:NO];
    }

-(void)writeImagesToDirUrl:(NSURL *)dirURL
{
    int resolution = 72;
    [self->_exportImageController updateSettingsFromControls:self.exportImageSettings];
    NSSize sz;
    sz.width = [self.exportImageSettings[@"imageWidth"]floatValue];
    sz.height = [self.exportImageSettings[@"imageHeight"]floatValue];
    float compressionQuality = [self.exportImageSettings[@"compressionQuality"]floatValue];
    //[self setExportDirectory:[(NSSavePanel*)sp directoryURL]];
    NSString *dirpath = [dirURL path];
    NSString *suffix = [_exportImageController chosenSuffix];
    for (int i = 0;i < [pages count];i++)
    {
        ACSDPage *p = pages[i];
        CGImageRef cgr = [[self frontmostMainWindowController]cgImageFromPage:i ofSize:sz];
        CGImageRetain(cgr);
        NSString *path = [[dirpath stringByAppendingPathComponent:[p pageTitle]]stringByAppendingPathExtension:suffix];
        NSURL *url = [NSURL fileURLWithPath:path];
        CGImageDestinationRef dest = CGImageDestinationCreateWithURL((CFURLRef)url,(CFStringRef)[self.exportImageController uti],1,nil);
        NSDictionary *props = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithFloat:compressionQuality],kCGImageDestinationLossyCompressionQuality,
                               [NSNumber numberWithInt:resolution],kCGImagePropertyDPIHeight,[NSNumber numberWithInt:resolution],kCGImagePropertyDPIWidth,nil];
        CGImageDestinationAddImage(dest,cgr,(CFDictionaryRef)props);
        CGImageDestinationFinalize(dest);
        CFRelease(dest);
        CGImageRelease(cgr);
    }
}

- (void)exportImages:(id)menuItem
{
    if (!_exportImageController)
    {
        NSArray *topLevelObjects;
        [[NSBundle mainBundle] loadNibNamed:@"ImageController" owner:self topLevelObjects:&topLevelObjects];
    }
    NSSavePanel *sp;
    NSString *fName = [[self displayName]stringByDeletingPathExtension];
    sp = [NSSavePanel savePanel];
    [sp setNameFieldLabel:@"Export As:"];
    [sp setNameFieldStringValue:fName];
    [sp setAllowedFileTypes:nil];
    if (!self.exportImageSettings)
    {
        self.exportImageSettings = [[NSMutableDictionary alloc]initWithCapacity:5];
        [self.exportImageSettings setObject:@(0.7) forKey:@"compressionQuality"];
    }
    [self.exportImageSettings setObject:@(self.documentSize.width) forKey:@"imageWidth"];
    [self.exportImageSettings setObject:@(self.documentSize.height) forKey:@"imageHeight"];
    [_exportImageController setControls:self.exportImageSettings];
    [_exportImageController setIgnoreSavePanel:YES];
    [_exportImageController prepareSavePanel:sp];
    [sp setAllowedFileTypes:nil];
    [sp setTitle:@"Export Image"];
    [sp beginSheetModalForWindow:[[self frontmostMainWindowController] window] completionHandler:^(NSInteger result) {
        if (result == NSModalResponseOK)
        {
            NSURL *dirURL = [(NSSavePanel*)sp URL];
            NSFileManager *fileManager = [NSFileManager defaultManager];
            NSError *err;
            if (![fileManager fileExistsAtPath:[dirURL path]])
                if (![fileManager createDirectoryAtPath:[dirURL path] withIntermediateDirectories:NO attributes:nil error:&err])
                {
                    NSRunAlertPanel(@"Error",@"%@",@"OK",nil,nil,[NSString stringWithFormat:@"Error creating directory: %@, %@",[dirURL path],[err localizedDescription]]);
                    return;
                }
            [self writeImagesToDirUrl:dirURL];
        }
    }];
}

- (void)exportImage:(id)menuItem
{
	if (!_exportImageController)
	{
		NSArray *topLevelObjects;
		[[NSBundle mainBundle] loadNibNamed:@"ImageController" owner:self topLevelObjects:&topLevelObjects];
	}
	NSSavePanel *sp;
	NSString *fName = [[self displayName]stringByDeletingPathExtension];
	sp = [NSSavePanel savePanel];
	[sp setNameFieldLabel:@"Export As:"];
	[sp setNameFieldStringValue:fName];
	if (!self.exportImageSettings)
	{
        self.exportImageSettings = [[NSMutableDictionary alloc]initWithCapacity:5];
		[self.exportImageSettings setObject:@(0.7) forKey:@"compressionQuality"];
	}
	[self.exportImageSettings setObject:[NSNumber numberWithInteger:self.documentSize.width] forKey:@"imageWidth"];
	[self.exportImageSettings setObject:[NSNumber numberWithInteger:self.documentSize.height] forKey:@"imageHeight"];
	[_exportImageController setControls:self.exportImageSettings];
	[_exportImageController prepareSavePanel:sp];
	[sp setTitle:@"Export Image"];
	[sp beginSheetModalForWindow:[[self frontmostMainWindowController] window] completionHandler:^(NSInteger result) {
        if (result == NSModalResponseOK)
		{
			int resolution = 72;
			[self.exportImageController updateSettingsFromControls:self.exportImageSettings];
			NSSize sz;
			sz.width = [[self.exportImageSettings objectForKey:@"imageWidth"]floatValue];
			sz.height = [[self.exportImageSettings objectForKey:@"imageHeight"]floatValue];
			float compressionQuality = [[self.exportImageSettings objectForKey:@"compressionQuality"]floatValue];
			[self setExportDirectory:[(NSSavePanel*)sp directoryURL]];
			CGImageRef cgr = [[self frontmostMainWindowController]cgImageFromCurrentPageOfSize:sz];
			//CGImageRetain(cgr);
			CGImageDestinationRef dest = CGImageDestinationCreateWithURL((CFURLRef)[sp URL],(CFStringRef)[self.exportImageController uti],1,nil);
			NSDictionary *props = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithFloat:compressionQuality],kCGImageDestinationLossyCompressionQuality,
								   [NSNumber numberWithInt:resolution],kCGImagePropertyDPIHeight,[NSNumber numberWithInt:resolution],kCGImagePropertyDPIWidth,nil];
			CGImageDestinationAddImage(dest,cgr,(CFDictionaryRef)props);
			CGImageDestinationFinalize(dest);
			CFRelease(dest);
			CGImageRelease(cgr);
		}
	}];
}

-(void)exportAnImage:(ACSDImage*)im
{
	if (!_exportImageController)
	{
		NSArray *topLevelObjects;
		[[NSBundle mainBundle] loadNibNamed:@"ImageController" owner:self topLevelObjects:&topLevelObjects];
	}
	NSSavePanel *sp;
	NSString *fName = [[im name]stringByDeletingPathExtension];
	sp = [NSSavePanel savePanel];
	if (!self.exportImageSettings)
	{
        self.exportImageSettings = [[NSMutableDictionary alloc]initWithCapacity:5];
		[self.exportImageSettings setObject:[NSNumber numberWithFloat:0.7] forKey:@"compressionQuality"];
	}
	NSRect f = [im frame];
	CGImageRef cgImage = [[im image] CGImageForProposedRect:&f context:nil hints:nil]; 
	float w = CGImageGetWidth(cgImage);
	float h = CGImageGetHeight(cgImage);
	
	[self.exportImageSettings setObject:[NSNumber numberWithInteger:w] forKey:@"imageWidth"];
	[self.exportImageSettings setObject:[NSNumber numberWithInteger:h] forKey:@"imageHeight"];
	[_exportImageController setControls:self.exportImageSettings];
	[_exportImageController prepareSavePanel:sp];
	[sp setTitle:@"Export Image"];
	[sp setDirectoryURL:[self exportDirectory]];
	[sp setNameFieldStringValue:fName];
	[sp beginSheetModalForWindow:[[self frontmostMainWindowController] window] completionHandler:^(NSInteger result) {
        if (result == NSModalResponseOK)
		{
			int resolution = 72;
            [self.exportImageController updateSettingsFromControls:self.exportImageSettings];
			NSSize sz;
			sz.width = [[self.exportImageSettings objectForKey:@"imageWidth"]floatValue];
			sz.height = [[self.exportImageSettings objectForKey:@"imageHeight"]floatValue];
			float compressionQuality = [[self.exportImageSettings objectForKey:@"compressionQuality"]floatValue];
			[self setExportDirectory:[(NSSavePanel*)sp directoryURL]];
			CGImageRef cgr = [[im image] CGImageForProposedRect:nil context:nil hints:nil]; 
			CGImageRetain(cgr);
			CGImageDestinationRef dest = CGImageDestinationCreateWithURL((CFURLRef)[(NSSavePanel*)sp URL],
																		 (CFStringRef)[self.exportImageController uti],
																		 1,nil);
			NSDictionary *props = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithFloat:compressionQuality],kCGImageDestinationLossyCompressionQuality,
								   [NSNumber numberWithInt:resolution],kCGImagePropertyDPIHeight,[NSNumber numberWithInt:resolution],kCGImagePropertyDPIWidth,nil];
			CGImageDestinationAddImage(dest,cgr,(CFDictionaryRef)props);
			CGImageDestinationFinalize(dest);
			CFRelease(dest);
			CGImageRelease(cgr);
		}
	}];
}

- (IBAction)importPicture:(id)sender
{
	NSOpenPanel *panel = [NSOpenPanel openPanel];
	[panel setAllowsMultipleSelection:YES];
	[panel beginSheetModalForWindow:[[self frontmostMainWindowController] window] 
				  completionHandler:^(NSInteger result) 
	 {
        if (result == NSModalResponseOK)
		 {
			 for (NSURL *url in [panel URLs])
				 [[self frontmostMainWindowController] importImage:[url path]];
		 }
	 }];	
}

-(ACSDPage*)addPage:(ACSDPage*)page
{
    [pages addObject:page];
    [page registerWithDocument:self];
    return page;
}

-(void)createPagesFromStrings:(NSArray*)pageNames
{
    NSInteger pageIdx = 0;
    for (NSString *pageName in pageNames)
    {
        while (pageIdx < [pages count] && pages[pageIdx].pageType == PAGE_TYPE_MASTER)
            pageIdx++;
        ACSDPage *page;
        while (pageIdx >= [pages count])
        {
            [[[self frontmostMainWindowController] graphicView]addNewPageAtIndex:[pages count]];
        }
        page = pages[pageIdx];
        page.pageTitle = pageName;
        pageIdx++;
    }
}


-(void)sizeToRect:(NSRect)r
{
	NSPoint antiVector = r.origin;
	antiVector.x = -antiVector.x;
	antiVector.y = -antiVector.y;
	[[[self frontmostMainWindowController] graphicView]moveAllObjectsBy:antiVector];
	[[[self frontmostMainWindowController] graphicView]changeDocumentSize:r.size];
}

-(void)sizeToOpaqueSelectionOnly:(BOOL)selectionOnly
{
    NSRect r = [[self frontmostMainWindowController]rectCroppedToOpaqueSelectionOnly:selectionOnly drawSelectionOnly:YES];
    float cx = r.origin.x + r.size.width / 2.0;
    float cy = r.origin.y + r.size.height / 2.0;
    NSLog(@"sizetoopaque offset %g,%g ; rel centre %g,%g",r.origin.x,self.documentSize.height - (r.origin.y + r.size.height),cx / self.documentSize.width,1.0 - cy / self.documentSize.height);
    [self sizeToRect:r];
}

- (void)sizeToObjectsHPad:(int)hPad vPad:(int)vPad
   {
	NSRect bounds = NSZeroRect;
	for (ACSDPage *p in [self pages])
		bounds = NSUnionRect(bounds,[p unionStrictGraphicBounds]);
	bounds.origin.x -= hPad;
	bounds.origin.y -= vPad;
	bounds.size.width += (hPad * 2);
	bounds.size.height += (vPad * 2);
	if (bounds.size.width < 1 || bounds.size.height < 1)
		return;
	[self sizeToRect:bounds];
   }

-(IBAction)sizeToObjectsAgain:(id)sender
{
    float hpad = [[NSUserDefaults standardUserDefaults]floatForKey:@"hPadding"];
    float vpad = [[NSUserDefaults standardUserDefaults]floatForKey:@"vPadding"];
    [self sizeToObjectsHPad:hpad vPad:vpad];
}

- (IBAction)closePaddingSheet: (id)sender
   {
    NSInteger reply = [sender tag];
    if (reply < 2)
       {
        if (reply == 0)                //OK
            [self sizeToObjectsHPad:(int)[[NSUserDefaults standardUserDefaults]integerForKey:@"hPadding"] vPad:(int)[[NSUserDefaults standardUserDefaults]integerForKey:@"vPadding"]];
       }
    [NSApp endSheet:_paddingSheet];
   }

- (IBAction)closeIndentSheet: (id)sender
   {
    NSInteger reply = [sender tag];
    if (reply < 2)
       {
        if (reply == 0)                //OK
        {
            
            [[[self frontmostMainWindowController] graphicView]indentHBy:[_indentH floatValue] vBy:[_indentV floatValue]];
        }
       }
    [NSApp endSheet:_indentSheet];
   }

- (IBAction)closeSelectNameSheet: (id)sender
{
    NSInteger reply = [sender tag];
	if (reply < 2)
	{
		if (reply == 0)				//OK
			[[[self frontmostMainWindowController] graphicView]selectGraphicWithName:[selectNameField stringValue]];
	}
	[NSApp endSheet:_selectNameSheet];
}

- (void)showSelectByNameDialog:(id)sender
{
    if (!_selectNameSheet)
    {
        [[NSBundle mainBundle]loadNibNamed:@"DocPadding" owner:self topLevelObjects:nil];
    }
    [[[self frontmostMainWindowController] window]beginSheet:_selectNameSheet completionHandler:^(NSModalResponse returnCode) {
        [self.selectNameSheet orderOut:self];
    }];
}

- (void)showIndentPanel:(id)sender
{
    if (!_indentSheet)
    {
        [[NSBundle mainBundle]loadNibNamed:@"DocPadding" owner:self topLevelObjects:nil];
    }
    [[[self frontmostMainWindowController] window]beginSheet:_indentSheet completionHandler:^(NSModalResponse returnCode) {
        [self.indentSheet orderOut:self];
    }];
}

- (void)sizeToObjectsWithDialog
{
    if (!_paddingSheet)
    {
        [[NSBundle mainBundle] loadNibNamed:@"DocPadding" owner:self topLevelObjects:nil];
    }
    [[[self frontmostMainWindowController] window]beginSheet:_paddingSheet completionHandler:^(NSModalResponse returnCode) {
        [self.paddingSheet orderOut:self];
    }];
}

- (IBAction)sizeToObjects:(id)sender
   {
       if ([sender keyEquivalentModifierMask] & NSEventModifierFlagOption)
		[self sizeToObjectsWithDialog];
	else
		[self sizeToObjectsHPad:0 vPad:0];
   }

- (IBAction)cropToOpaque:(id)sender
{
    [self sizeToOpaqueSelectionOnly:NO];
}

- (IBAction)cropToOpaqueSelection:(id)sender
{
    [self sizeToOpaqueSelectionOnly:YES];
}

-(void)setStrokes:(NSMutableArray*)a
   {
	strokes = a;
   }

-(void)setLineEndings:(NSMutableArray*)a
   {
	lineEndings = a;
   }

-(void)setStyles:(NSMutableArray*)a
   {
	if (styles == a)
		return;
	styles = a;
   }

-(void)setFills:(NSMutableArray*)a
   {
	fills = a;
   }

-(void)deleteFillAtIndex:(NSInteger)i
   {
	[[[self undoManager] prepareWithInvocationTarget:self] insertFill:[[self fills] objectAtIndex:i]atIndex:i];
	[[self fills] removeObjectAtIndex:i];
	[[NSNotificationCenter defaultCenter] postNotificationName:ACSDFillAdded object:self];
   }

-(void)insertFill:(id)fill atIndex:(NSInteger)i
   {
	[[[self undoManager] prepareWithInvocationTarget:self] deleteFillAtIndex:i];
	[[self fills] insertObject:fill atIndex:i];
	[[NSNotificationCenter defaultCenter] postNotificationName:ACSDFillAdded object:self];
   }

-(void)deleteStrokeAtIndex:(NSInteger)i
   {
	[[[self undoManager] prepareWithInvocationTarget:self] insertStroke:[strokes objectAtIndex:i]atIndex:i];
	[strokes removeObjectAtIndex:i];
	[[NSNotificationCenter defaultCenter] postNotificationName:ACSDRefreshStrokesNotification object:self];
   }

-(void)insertStroke:(id)stroke atIndex:(NSInteger)i
   {
	[[[self undoManager] prepareWithInvocationTarget:self] deleteStrokeAtIndex:i];
	[strokes insertObject:stroke atIndex:i];
	[[NSNotificationCenter defaultCenter] postNotificationName:ACSDRefreshStrokesNotification object:self];
   }

-(void)deleteShadowAtIndex:(NSInteger)i
   {
	[[[self undoManager] prepareWithInvocationTarget:self] insertShadow:_shadows[i] atIndex:i];
	[_shadows removeObjectAtIndex:i];
	[[NSNotificationCenter defaultCenter] postNotificationName:ACSDRefreshShadowsNotification object:self];
   }

-(void)insertShadow:(id)sh atIndex:(NSInteger)i
   {
	[[[self undoManager] prepareWithInvocationTarget:self] deleteShadowAtIndex:i];
	[_shadows insertObject:sh atIndex:i];
	[[NSNotificationCenter defaultCenter] postNotificationName:ACSDRefreshShadowsNotification object:self];
   }

-(void)deleteLineEndingAtIndex:(NSInteger)i
   {
	[[[self undoManager] prepareWithInvocationTarget:self] insertLineEnding:[lineEndings objectAtIndex:i]atIndex:i];
	[lineEndings removeObjectAtIndex:i];
	[[NSNotificationCenter defaultCenter] postNotificationName:ACSDRefreshLineEndingsNotification object:self];
   }

-(void)insertLineEnding:(id)le atIndex:(NSInteger)i
   {
	[[[self undoManager] prepareWithInvocationTarget:self] deleteLineEndingAtIndex:i];
	[lineEndings insertObject:le atIndex:i];
	[[NSNotificationCenter defaultCenter] postNotificationName:ACSDRefreshLineEndingsNotification object:self];
   }

-(void)setPages:(NSMutableArray*)a
   {
	pages = a;
	[pages makeObjectsPerformSelector:@selector(setDocument:)withObject:self];
   }

static NSString *LastX(NSString* path,int ct)
{
	if (ct == 0)
		return @"…";;
	NSString *pref = [path stringByDeletingLastPathComponent];
	if ([pref length] <= 1)
		return path;
	NSString *last = [path lastPathComponent];
	return [NSString stringWithFormat:@"%@/%@",LastX(pref,ct - 1),last];
}
- (BOOL)validateMenuItem:(id)menuItem
{
	SEL action = [menuItem action];
	if (action == @selector(exportSVG:))
		return YES;
	else if (action == @selector(exportTiff:))
		return YES;
	else if (action == @selector(importPicture:))
		return YES;
	else if (action == @selector(showSelectByNameDialog:))
		return YES;
	else if (action == @selector(sizeToObjects:))
		return [pages orMakeObjectsPerformSelector:@selector(atLeastOneObjectExists)];
    else if (action == @selector(exportSelectionImage:)  || action == @selector(exportSelectionImageDrawAll:))
        return [[[[self frontmostMainWindowController] graphicView] selectedGraphics]count] > 0;
    else if (action == @selector(exportAnimation:))
        return [[[[[self frontmostMainWindowController] graphicView] currentPage]animations] count] > 0;
	else if (action == @selector(exportEventXMLToLastFile:))
	{
		NSURL *url = miscValues[@"exporteventxml"];
		if (url == nil)
			return NO;
		[menuItem setTitle:[NSString stringWithFormat:@"Event XML to %@",LastX([url path],5)]];
		return YES;
	}
    if (action == @selector(sizeToObjectsAgain:))
    {
        float hpad = [[NSUserDefaults standardUserDefaults]floatForKey:@"hPadding"];
        float vpad = [[NSUserDefaults standardUserDefaults]floatForKey:@"vPadding"];
        [menuItem setTitle:[NSString stringWithFormat:@"Size to Objects + %g/%g pad",hpad,vpad]];
        return YES;
    }
	return YES;
}

-(void)updateChangeCount:(NSDocumentChangeType)change
{
    if ((change & NSChangeDiscardable) == 0)
        [super updateChangeCount:change];
}

-(BOOL)bookUpdateParentage
{
    int affectedCount = 0;
    for (ACSDPage *page in self.pages)
    {
        ACSDGraphic *pageImage = nil;
        NSArray *imageLayers = [page layersWithName:@"image"];
        if ([imageLayers count] == 0)
            continue;
        for (ACSDLayer *il in imageLayers)
        {
            NSArray *gs = [il graphicsWithName:@"p[0-9]+"];
            for (ACSDGraphic *g in gs)
                if ([g isKindOfClass:[ACSDImage class]])
                {
                    pageImage = g;
                    break;
                }
        }
        if (pageImage)
        {
            for (ACSDLayer *layer in page.layers)
            {
                if (layer.exportable)
                {
                    for (ACSDGraphic *g in layer.graphics)
                    {
                        if (g.link == nil)
                        {
                            [ACSDLink uLinkFromObject:g toObject:pageImage anchor:-1 substitutePageNo:NO changeAttributes:YES undoManager:[self undoManager]];
                            affectedCount++;
                        }
                    }
                }
            }
        }
    }
    if (affectedCount > 0)
    {
        NSString *pl = affectedCount > 1 ? @"s" : @"";
        [[self undoManager]setActionName:[NSString stringWithFormat:@"Update parentage of %d graphic%@",(int)affectedCount,pl]];
    }
    return affectedCount > 0;
}

-(IBAction)bookUpdateParentage:(id)sender
{
    [self bookUpdateParentage];
}

-(NSArray*)allGraphics
{
    NSMutableArray *objs = [NSMutableArray array];
    for (ACSDPage *p in self.pages)
        [objs addObjectsFromArray:[p allGraphics]];
    return objs;
}


@end
