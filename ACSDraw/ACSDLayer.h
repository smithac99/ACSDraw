//
//  ACSDLayer.h
//  ACSDraw
//
//  Created by Alan Smith on Wed Jan 23 2002.
//  Copyright (c) 2001 __MyCompanyName__. All rights reserved.
//

#import "ACSDrawDocument.h"
#import "KeyedObject.h"

@class SelectionSet;
@class SVGWriter;
@class ACSDPage;
@class ACSDGraphic;

@interface ACSDLayer : KeyedObject
   {
	NSMutableArray *graphics;
	SelectionSet *selectedGraphics;
	BOOL isGuideLayer;
	NSMutableArray *triggers;
   }

@property BOOL visible,editable,exportable;
@property (weak) ACSDPage *page;
@property (copy) NSString *name;
@property int zPosOffset;

+ (NSString*)nextNameForDocument:(ACSDrawDocument*)doc;
-(id)initWithName:(NSString*)n isGuideLayer:(BOOL)gl;


-(void)setLayerVisible:(BOOL)v;
-(BOOL)isGuideLayer;
-(NSMutableArray*)graphics;
-(SelectionSet*)selectedGraphics;
-(void)writeSVGData:(SVGWriter*)svgWriter;
-(void)magnifyAllObjects:(double)mag;
-(void)freePDFData;
-(void)buildPDFData;
-(void)addGraphic:(ACSDGraphic*)graphic;
-(void)addGraphic:(ACSDGraphic*)graphic atIndex:(NSInteger)idx;
-(void)addGraphics:(NSArray*)gArray;
-(void)moveGraphicsByValue:(NSValue*)val;
-(NSRect)unionGraphicBounds;
-(BOOL)atLeastOneObjectExists;
-(void)removeGraphics:(NSArray*)gArray;
-(void)removeGraphicAtIndex:(NSInteger)idx;
- (int)showIndicator;
-(BOOL)containsImages;
-(NSMutableArray*)allTextObjects;
-(void)processHTMLOptions:(NSMutableDictionary*)options;
-(ACSDrawDocument*)document;
-(void)updateForStyle:(id)style oldAttributes:(NSDictionary*)oldAttrs;
-(void)addLinksForPDFContext:(CGContextRef) context;
-(void)addGraphicsInFrontOfGraphic:(ACSDGraphic*)g toSet:(NSMutableSet*)set;
-(void)invalidateTextFlowersOverlappingGraphics:(NSArray*)graphicArray maxIndex:(int)maxIndex;
-(void)invalidateTextFlowersBehindGraphics:(NSArray*)graphicArray;
-(void)fixTextBoxLinks;
-(BOOL)addTrigger:(NSDictionary*)t;
-(BOOL)removeTrigger:(NSDictionary*)t;
-(NSMutableArray*)triggers;
-(void)permanentScale:(float)sc transform:(NSAffineTransform*)t;
-(NSString*)graphicXML:(NSMutableDictionary*)options;
-(NSString*)graphicXMLForEvent:(NSMutableDictionary*)options;
-(NSIndexSet*)indexesOfSelectedGraphics;
-(void)setGraphics:(NSMutableArray*)gs;
-(NSRect)unionStrictGraphicBounds;
@end

NSArray* OrderGraphics(NSArray* toDo);

