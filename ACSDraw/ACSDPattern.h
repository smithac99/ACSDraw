//
//  ACSDPattern.h
//  ACSDraw
//
//  Created by alan on 22/02/2005.
//  Copyright 2005 Alan C Smith. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "ACSDFill.h"
#import "GraphicCache.h"
@class ACSDGraphic;
@class GraphicView;
@class FlippableView;

enum
{
	ACSD_PATTERN_SINGLE = 0,
	ACSD_PATTERN_MIRROR,
	ACSD_PATTERN_MIRROR_UPDOWN,
	ACSD_PATTERN_MIRROR_UPSIDE,
	ACSD_PATTERN_MIRROR_UPSIDE_LEFTRIGHT,
	ACSD_PATTERN_DOUBLE_MIRROR,
	ACSD_PATTERN_ROTATE
};

enum
{
    OFFSET_MODE_NONE,
    OFFSET_MODE_X,
    OFFSET_MODE_Y
};

enum
{
    LAYOUT_MODE_RECT,
    LAYOUT_MODE_C4,
    LAYOUT_MODE_C6
};

@interface ACSDPattern : ACSDFill
{
	GraphicCache *graphicCache;
	NSPDFImageRep *pdfImageRep;
	NSPoint pdfOffset;
}

@property (retain) NSColor *backgroundColour;
@property (retain) ACSDGraphic *graphic;
@property float scale;
@property float spacing;
@property float offset;
@property float alpha;
@property float rotation;
@property int mode;
@property int offsetMode;
@property int layoutMode;
@property NSRect patternBounds;
@property BOOL clip;
@property NSPoint patternOrigin;
@property (retain) NSString *tempName,*tempNameOffset;
@property BOOL usePatternCentre;

+(ACSDPattern*)defaultPattern;
+(ACSDPattern*)patternWithGraphic:(ACSDGraphic*)g;
+(ACSDPattern*)patternWithGraphic:(ACSDGraphic*)g scale:(float)sc spacing:(float)sp offset:(float)o offsetMode:(int)om alpha:(float)al mode:(int)m patternBounds:(NSRect)r;
-(id)initWithGraphic:(ACSDGraphic*)g scale:(float)sc spacing:(float)sp offset:(float)o offsetMode:(int)om alpha:(float)al mode:(int)m patternBounds:(NSRect)r;
-(void)changeCache;
-(void)changeScale:(float)sc view:(GraphicView*)gView;
-(void)changeSpacing:(float)sp view:(GraphicView*)gView;
-(void)changeOffset:(float)f view:(GraphicView*)gView;
-(void)changeOffsetMode:(int)om view:(GraphicView*)gView;
-(void)changeMode:(int)m view:(GraphicView*)gView;
-(void)changeAlpha:(float)f view:(GraphicView*)gView;
-(void)changeClip:(BOOL)clip view:(GraphicView*)gView;
-(void)changeRotation:(float)rot view:(GraphicView*)gView;

-(void)changeGraphic:(ACSDGraphic*)g view:(GraphicView*)gView;
-(FlippableView*)setCurrentDrawingDestination:(FlippableView*)dest;
-(void)setPdfImageRep:(NSPDFImageRep*)pir;
-(void)setPdfOffset:(NSPoint)p;
-(NSPDFImageRep*)pdfImageRep;
-(NSPoint)pdfOffset;
-(void)writeSVGPatternDef:(SVGWriter*)svgWriter allPatterns:(NSArray<ACSDPattern*>*)allPatterns;
-(void)writeSVGPatternDef:(SVGWriter*)svgWriter allPatterns:(NSArray*)allPatterns bounds:(NSRect)bnds name:(NSString*)pname;
-(NSString*)graphicXMLForEvent:(NSMutableDictionary*)options;
-(NSString*)svgName:(ACSDrawDocument*)doc;
-(void)writeSVGPatternDef:(SVGWriter*)svgWriter allPatterns:(NSArray*)allPatterns bounds:(NSRect)objectBounds name:(NSString*)pname offsetRun:(int)offsetRun;

@end
