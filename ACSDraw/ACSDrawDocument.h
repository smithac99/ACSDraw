//
//  MyDocument.h
//  ACSDraw
//
//  Created by Alan Smith on Mon Jan 14 2002.
//  Copyright (c) 2001 __MyCompanyName__. All rights reserved.
//


#import <Cocoa/Cocoa.h>
#import "MainWindowController.h"
@class ACSDLineEnding;
@class ACSDPattern;
@class HtmlExportController;
@class ImageExportController;
@class KeyedObject;
@class ACSDImage;
@class XMLNode;

struct saveContextInfo
   {
	SEL shouldCloseSelector;
	void *contextInfo;
	id delegate;
   };


extern NSString *backgroundColourKey;
extern NSString *ACSDrawDocumentBackgroundDidChangeNotification;
extern NSString *xHTMLString1;
extern NSString *xHTMLString2;
extern NSString *xmlDocWidth;
extern NSString *xmlDocHeight;
extern NSString *xmlIndent;

NSString* Creator();

@interface ACSDrawDocument : NSDocument
{
	NSMutableArray<ACSDPage*> *pages;
	MainWindowController *mainWindowController;
	NSMutableArray *strokes;
	NSMutableArray *fills;
	NSMutableArray *lineEndings;
	NSMutableArray *styles;
	NSMutableDictionary *miscValues;
	NSURL *exportDirectory;
	saveContextInfo sci;
	id hPaddingField,vPaddingField,selectNameField;
	NSColor *backgroundColour;
// Transient stuff
	int maxViewNumber;
	//NSCalendarDate *documentKey;
	unsigned nextObjectKey;
	NSMutableDictionary *keyedObjects;
}

@property NSSize documentSize;

@property (strong) NSMutableDictionary *nameCounts;
@property (strong) NSString *scriptURL;
@property (strong,nonatomic) NSMutableArray *shadows;
@property (strong) NSString *additionalCSS;

@property (strong) NSSet *linkGraphics;
@property (strong) NSArray *linkRanges;
@property (strong) NSString *docTitle;


@property (retain) HtmlExportController *exportHTMLController;
@property (retain) ImageExportController *exportImageController;
@property (strong) NSMutableDictionary *htmlSettings,*exportImageSettings;

@property (retain) IBOutlet NSPanel *paddingSheet,*selectNameSheet;
@property (strong) IBOutlet NSPanel *indentSheet;
@property (retain) NSDate *documentKey;

@property (weak) IBOutlet NSTextField *indentH;
@property (weak) IBOutlet NSTextField *indentV;


-(MainWindowController*)frontmostMainWindowController;
-(NSSize)documentSize;
-(NSMutableArray*)strokes;
-(NSMutableArray*)fills;
-(NSMutableArray*)shadows;
-(NSMutableArray*)lineEndings;
-(NSMutableArray*)styles;
-(NSColor*)backgroundColour;
-(void)setBackgroundColour:(NSColor*)c;
-(BOOL)uSetBackgroundColour:(NSColor*)c;
-(NSMutableDictionary*)nameCounts;
-(NSMutableDictionary*)miscValues;
- (NSMutableArray<ACSDPage*>*)pages;
- (NSMutableArray*)systemLineEndings;
-(unsigned)nextObjectKey;
-(void)deRegisterObject:(KeyedObject*)ko;
-(KeyedObject*)registerObject:(KeyedObject*)ko;
-(NSDictionary*)keyedObjects;

-(void)setStrokes:(NSMutableArray*)a;
-(void)setDocumentSize:(NSSize)sz;
-(void)setFills:(NSMutableArray*)a;
-(void)setShadows:(NSMutableArray*)a;
-(void)setNameCounts:(NSMutableDictionary*)d;
-(void)setLineEndings:(NSMutableArray*)a;
-(void)setStyles:(NSMutableArray*)a;
-(void)setPages:(NSMutableArray*)a;
-(void)setDocTitle:(NSString*)s;
-(NSString*)docTitle;
-(void)setScriptURL:(NSString*)s;
-(NSString*)scriptURL;
-(void)setAdditionalCSS:(NSString*)s;
-(NSString*)additionalCSS;

- (NSURL*)exportDirectory;
- (void)setExportDirectory:(NSURL*)expd;

-(void)createLineEndingWindowWithLineEnding:(ACSDLineEnding*)le isNew:(bool)isNew;
-(void)createPatternWindowWithPattern:(ACSDPattern*)pat isNew:(bool)isNew;

-(void)deleteFillAtIndex:(NSInteger)i;
-(void)insertFill:(id)fill atIndex:(NSInteger)i;
-(void)deleteStrokeAtIndex:(NSInteger)i;
-(void)insertStroke:(id)stroke atIndex:(NSInteger)i;
-(void)deleteShadowAtIndex:(NSInteger)i;
-(void)insertShadow:(id)sh atIndex:(NSInteger)i;
-(void)deleteLineEndingAtIndex:(NSInteger)i;
-(void)insertLineEnding:(id)le atIndex:(NSInteger)i;

-(NSArray*)linkRanges;
-(void)setLinkRanges:(NSArray*)r;
-(void)sizeToRect:(NSRect)r;
-(void)exportAnImage:(ACSDImage*)im;
- (IBAction)closeSelectNameSheet: (id)sender;

- (IBAction)cropToOpaque:(id)sender;
-(NSArray*)svgBodyString;
-(NSSet*)getAttributesFromSVGNode:(XMLNode*)child settings:(NSMutableDictionary*)settings;
-(void)createPagesFromStrings:(NSArray*)pageNames;

@end

