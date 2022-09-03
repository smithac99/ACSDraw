//
//  ACSDPage.h
//  ACSDraw
//
//  Created by alan on Tue Feb 17 2004.
//  Copyright (c) 2004 __MyCompanyName__. All rights reserved.
//

@class ACSDLayer;
@class GraphicView;
@class ACSDrawDocument;
@class XMLNode;

#import <Cocoa/Cocoa.h>
#import "KeyedObject.h"

extern NSString *ACSDPageAttributeChanged;

enum
   {
	PAGE_TYPE_NORMAL=0,
	PAGE_TYPE_MASTER
   };

enum
   {
	MASTER_TYPE_ALL=0,
	MASTER_TYPE_ODD,
	MASTER_TYPE_EVEN,
	MASTER_TYPE_NONE
   };

enum
   {
	USE_MASTER_DEFAULT=0,
	USE_MASTER_NONE,
	USE_MASTER_LIST
   };

@interface ACSDPage : KeyedObject<NSCoding>
   {
	NSMutableArray *layers;
	NSString *name;
	NSMutableSet *graphicViews;
	NSInteger currentLayerInd,guideLayerInd,pageNo,nextLayer;
	int pageType;
	int masterType;
	int useMasterType;
	NSMutableArray *masters,*slaves;
	NSString *pageTitle;
	NSColor *backgroundColour;
	NSMutableSet *linkedObjects;
	BOOL inactive;
   }

@property (copy) NSString *name,*pageTitle,*xmlEventName;
@property (assign) ACSDrawDocument *document;
@property BOOL inactive;
@property NSInteger currentLayerInd,pageNo,guideLayerInd;
@property (retain) NSArray *previouslyVisibleLayers;
@property (retain) NSMutableArray *animations;


-(id)initWithDocument:(ACSDrawDocument*)d;
-(id)initWithXMLNode:(XMLNode*)pageNode document:(ACSDrawDocument*)doc settingsStack:(NSMutableArray*)settingsStack objectDict:(NSMutableDictionary*)objectDict;
-(NSString*)nextLayerName;
- (NSMutableArray*)layers;
- (ACSDLayer*)currentLayer;
- (ACSDLayer*)guideLayer;
-(void)setLayerPages;
-(NSString*)Desc;
-(void)setCurrentLayer:(ACSDLayer*)l;
-(void)freePDFData;
-(void)buildPDFData;
-(void)moveGraphicsByValue:(NSValue*)val;
-(NSRect)unionGraphicBounds;
-(BOOL)atLeastOneObjectExists;
- (int)pageType;
- (int)masterType;
- (int)useMasterType;
-(void)setPageType:(int)pt;
-(NSMutableArray*)masters;
-(NSMutableArray*)slaves;
-(void)uAddMaster:(ACSDPage*)masterPage atIndex:(int)ind;
-(void)uRemoveMaster:(ACSDPage*)masterPage;
-(void)uSetMaster:(ACSDPage*)masterPage;
-(void)uRemoveSlave:(ACSDPage*)slavePage;
-(void)uAddSlave:(ACSDPage*)slavePage;
-(void)allocMasters;
-(void)allocSlaves;
-(NSString*)htmlRepresentationOptions:(NSMutableDictionary*)options;
-(BOOL)containsImages;
-(void)setDocument:(ACSDrawDocument*)d;
-(ACSDrawDocument*)document;
-(void)addGraphicView:(GraphicView*)gv;
-(void)removeGraphicView:(GraphicView*)gv;
-(NSMutableSet*)graphicViews;
-(void)synchroniseWindowTitles;
-(void)updateForStyle:(id)style oldAttributes:(NSDictionary*)oldAttrs;
-(void)uAddLinkedObject:(id)obj;
-(void)addLinksForPDFContext:(CGContextRef) context;
-(NSColor*)backgroundColour;
-(void)setBackgroundColour:(NSColor*)n;
-(BOOL)uSetBackgroundColour:(NSColor*)c;
-(void)setMasterType:(int)pt;
-(void)setUseMasterType:(int)pt;
-(NSArray*)allTextObjectsOrderedByPosition;
-(void)fixTextBoxLinks;
-(void)permanentScale:(float)sc transform:(NSAffineTransform*)t;
-(NSString*)graphicXML:(NSMutableDictionary*)options;
-(NSString*)graphicXMLForEvent:(NSMutableDictionary*)options;
-(BOOL)uDeleteAttributeAtIndex:(NSInteger)idx notify:(BOOL)notify;
-(BOOL)uInsertAttributeName:(NSString*)nm value:(NSString*)val atIndex:(NSInteger)idx notify:(BOOL)notify;
-(BOOL)uSetAttributeName:(NSString*)nm atIndex:(NSInteger)idx notify:(BOOL)notify;
-(BOOL)uSetAttributeValue:(NSString*)val atIndex:(NSInteger)idx notify:(BOOL)notify;
-(BOOL)uSetAttributeValue:(NSString*)val forName:(NSString*)nme notify:(BOOL)notify;
-(NSRect)unionStrictGraphicBounds;
-(NSArray*)graphicsWithName:(NSString*)nm;
-(NSArray*)layersWithName:(NSString*)nm;

@end
