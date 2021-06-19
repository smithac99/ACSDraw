//
//  ACSDGraphic.h
//  ACSDraw
//
//  Created by Alan Smith on Mon Jan 14 2002.
//  Copyright (c) 2001 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "ACSDStroke.h"
#import "ACSDFill.h"
#import "ACSDLayer.h"
#import "ACSDShadow.h"
#import "ACSDLabel.h"
#import "GraphicCache.h"
#import "FlippableView.h"
#import "KeyedObject.h"


enum
   {
	centreKnob = -4,
	previousTextKnob = -3,
	nextTextKnob = -2,
	NoKnob = -1,
    LowerLeftKnob=0,
    LowerMiddleKnob,
    LowerRightKnob,
    MiddleRightKnob,
    UpperRightKnob,
    UpperMiddleKnob,
    UpperLeftKnob,
    MiddleLeftKnob,
	OtherKnob,
	CurveKnob
   };

enum VerticalAlignment
   {
    VERTICAL_ALIGNMENT_TOP,
	VERTICAL_ALIGNMENT_CENTRE,
	VERTICAL_ALIGNMENT_BOTTOM
   };

enum StrokeType
   {
    STROKE_OUTLINE,
	STROKE_CELLS,
	STROKE_BOTH
   };

enum GraphicMode
   {
	GRAPHIC_MODE_NORMAL,
	GRAPHIC_MODE_OUTLINE
   };

enum
   {
    NoKnobsMask = 0,
    UpperLeftKnobMask = 1 << UpperLeftKnob,
    UpperMiddleKnobMask = 1 << UpperMiddleKnob,
    UpperRightKnobMask = 1 << UpperRightKnob,
    MiddleLeftKnobMask = 1 << MiddleLeftKnob,
    MiddleRightKnobMask = 1 << MiddleRightKnob,
    LowerLeftKnobMask = 1 << LowerLeftKnob,
    LowerMiddleKnobMask = 1 << LowerMiddleKnob,
    LowerRightKnobMask = 1 << LowerRightKnob,
    AllKnobsMask = 0xffffffff,
   };

enum
{
	INVAL_FLAGS_CLEAR,
	INVAL_FLAGS_SIZE_CHANGE = 1,
	INVAL_FLAGS_SHAPE_CHANGE = 2,
	INVAL_FLAGS_REDRAW = 4
};

enum
{
    DRAW_HANDLES_PATH_DIR = 1
};

#define ACSD_HALF_HANDLE_WIDTH 3.0
#define ACSD_HANDLE_WIDTH (ACSD_HALF_HANDLE_WIDTH * 2.0)
#define DEGREES(x) ((x)*(360.0/(2.0 * M_PI)))

CGFloat angleForPoints(NSPoint pt1,NSPoint pt2);
float getAngleForPoints(NSPoint pt1,NSPoint pt2);
void restrictTo45(NSPoint pt1,NSPoint *pt2);
void restrictToStraight(CGPoint *currPoint,CGPoint origPoint,CGPoint prevPoint);
NSString *imageNameForOptions(NSDictionary* options);
CGRect CGRectFromNSRect(NSRect r);
float normalisedAngle(float ang);

@class GraphicView;
@class ACSDPath;
@class ShadowType;
@class ACSDrawDocument;
@class ObjectPDFData;
@class ACSDConnector;
@class ACSDStyle;
@class ACSDLink;
@class ACSDGroup;
@class CanvasWriter;
@class SVGWriter;
extern NSString *ACSDGraphicDidChangeNotification;
NSString *substitute_characters(NSString* string);

enum
{
	LINK_ALIGN_CENTRE = 0,
	LINK_ALIGN_LEFT = 2,
	LINK_ALIGN_RIGHT = 1,
	LINK_ALIGN_BOTTOM = 4,
	LINK_ALIGN_TOP = 8
};

struct KnobDescriptor
   {
	NSInteger subPath;
	NSInteger knob;
	NSInteger controlPoint;
	BOOL isLine;
	KnobDescriptor(){subPath=0;knob=0;controlPoint=0;isLine=NO;};
	KnobDescriptor(NSInteger k){subPath=0;knob=k;controlPoint=0;isLine=NO;};
	KnobDescriptor(NSInteger i,NSInteger k,NSInteger c){subPath=i;knob=k;controlPoint=c;isLine=NO;};
	KnobDescriptor(NSInteger i,NSInteger k,NSInteger c,BOOL b){subPath=i;knob=k;controlPoint=c;isLine=b;};
   };

@protocol ACSDGraphicCornerRadius <NSObject>
-(float)cornerRadius;
-(void)setCornerRadius:(float)r;
-(BOOL)setGraphicCornerRadius:(float)r notify:(BOOL)notify;
-(float)maxCornerRadius;
-(void)setGraphicCornerRadius:(float)rad from:(float)oldRad notify:(BOOL)notify;
@end

@interface ACSDGraphic : KeyedObject<NSCopying,NSCoding>
   {
	ACSDFill *fill;
	ACSDStroke *stroke;
	id link;
	NSMutableSet *linkedObjects;
	float alpha;
	NSRect bounds,			//bounds of path
		displayBounds;		//cache bounds rotated + shadow
	BOOL displayBoundsValid,deleted;
	float rotation;
	float xScale,yScale;
	float textPad;
	GraphicMode graphicMode;
	NSPoint rotationPoint;
	ACSDLayer *layer;
	ACSDGroup *parent;
	ACSDLabel *textLabel;
	NSString *toolTip;
	NSPoint *handlePoints;
	NSAffineTransform *transform;
	int noHandlePoints;
	NSDate *selectionTimeStamp;
	ShadowType *shadowType;
	BOOL manipulatingBounds,moving;
	NSPoint moveOffset;
	NSRect originalBounds;
	float originalXScale,originalYScale;
	NSMutableDictionary *events,*filterSettings;
	GraphicCache *graphicCache;
	BOOL usesCache;
	BOOL drawingToCache;
	BOOL addingPoints;
	BOOL isMask;
	NSPoint addingPoint,actualAddingPoint;
	ObjectPDFData *objectPdfData;
	FlippableView *currentDrawingDestination;
	NSMutableArray *connectors;
	NSBezierPath *outlinePath;
	BOOL outlinePathValid;
	NSBezierPath *bezierPath;
	BOOL bezierPathValid;
	ACSDStroke *preOutlineStroke;
	ACSDFill *preOutlineFill;
	BOOL opCancelled;
	NSMutableArray *triggers;
	float exposure,saturation,brightness,contrast,unsharpmaskRadius,unsharpmaskIntensity,gaussianBlurRadius;
   }

@property (nonatomic) float xScale,yScale,alpha,rotation;
@property GraphicMode graphicMode;
@property NSPoint rotationPoint,addingPoint,actualAddingPoint,moveOffset;
@property (retain,nonatomic) NSDate *selectionTimeStamp;
@property (copy) NSString *name;
@property (retain,nonatomic) NSAffineTransform *transform;
@property (retain,nonatomic) ACSDStroke *preOutlineStroke;
@property (retain,nonatomic) ACSDFill *preOutlineFill;
@property (retain) NSMutableDictionary *filterSettings;
@property (assign) ACSDLayer *layer;
@property (assign) ACSDGroup *parent;
@property BOOL usesCache,bezierPathValid,displayBoundsValid,isMask,addingPoints,outlinePathValid,moving,opCancelled;
@property float exposure,saturation,brightness,contrast,unsharpmaskRadius,unsharpmaskIntensity,gaussianBlurRadius;
@property (copy) NSString *sourcePath;
@property u_int8_t linkAlignmentFlags;
@property BOOL hidden;
@property (retain) NSMutableDictionary *tempSettings;
@property NSPoint originalPos,scaleAnchorPos;
@property float originalScale;
@property (strong) ACSDGraphic *clipGraphic;

+ (NSString*)nextNameForDocument:(ACSDrawDocument*)doc;
+ (NSString*)graphicTypeName;
+ (void) encodePoint:(NSPoint)pt coder:(NSCoder*)coder forKey:(NSString*)key;
+ (void) encodeSize:(NSSize)sz coder:(NSCoder*)coder forKey:(NSString*)key;
+ (void) encodeRect:(NSRect)r coder:(NSCoder*)coder forKey:(NSString*)key;
+ (NSPoint) decodePointForKey:(NSString*)key coder:(NSCoder*)coder;
+ (NSSize) decodeSizeForKey:(NSString*)key coder:(NSCoder*)coder;
+ (NSRect) decodeRectForKey:(NSString*)key coder:(NSCoder*)coder;
+(void)postChangeOfBounds:(NSRect)b;
+(void)postChangeFromAnchorPoint:(NSPoint)anchorPoint toPoint:(NSPoint)point;
+(void)postShowCoordinates:(BOOL)show;
+ (NSInteger)flipKnob:(NSInteger)knob horizontal:(BOOL)horizFlag;
-(NSString*)svgType;
-(NSString*)svgTypeSpecifics:(SVGWriter*)svgWriter boundingBox:(NSRect)bb;

- (NSRect)handleRect:(NSPoint)point magnification:(float)magnification;

- (id)initWithName:(NSString*)n fill:(ACSDFill*)f stroke:(ACSDStroke*)str rect:(NSRect)b layer:(ACSDLayer*)l;
-(id)initWithName:(NSString*)n fill:(ACSDFill*)f stroke:(ACSDStroke*)str rect:(NSRect)b layer:(ACSDLayer*)l
		   xScale:(float)xs yScale:(float)ys rotation:(float)rot shadowType:(ShadowType*)st label:(ACSDLabel*)lab alpha:(float)a;
- (id)copyWithZone:(NSZone *)zone;


- (NSUndoManager*)undoManager;
- (NSBezierPath *)bezierPath;
-(BOOL)hasAFilter;

-(ACSDFill*)fill;
-(ACSDStroke*)stroke;
-(ACSDStroke*)graphicStroke;
-(ShadowType*)shadowType;
-(NSRect)bounds;
-(NSRect)strictBounds;
-(NSRect)transformedBounds;
-(NSRect)displayBounds;
-(NSRect)transformedStrictBounds;
-(NSMutableDictionary*)events;
-(void)setFill:(ACSDFill*)f;
-(void)setStroke:(ACSDStroke*)s;
-(void)setShadowType:(ShadowType*)s;
- (void)setGraphicAlpha:(float)f notify:(BOOL)notify;
-(BOOL)setGraphicShadowType:(ShadowType*)s notify:(BOOL)notify;
-(BOOL)setGraphicGaussianBlurRadius:(float)f notify:(BOOL)notify;
- (void)setGraphicExposure:(float)f notify:(BOOL)notify;
- (BOOL)setGraphicSaturation:(float)f notify:(BOOL)notify;
- (BOOL)setGraphicBrightness:(float)f notify:(BOOL)notify;
- (BOOL)setGraphicContrast:(float)f notify:(BOOL)notify;
- (BOOL)setGraphicUnsharpmaskIntensity:(float)f notify:(BOOL)notify;
- (BOOL)setGraphicUnsharpmaskRadius:(float)f notify:(BOOL)notify;
-(BOOL)setGraphicLevelsBlack:(float)newBlackLevel white:(float)newWhiteLevel grey:(float)newGreyLevel notify:(BOOL)notify;
-(void)setBounds:(NSRect)r;
-(BOOL)canBeMask;
-(void)setDeleted:(BOOL)d;
-(BOOL)deleted;
- (void)flipHorizontally;
- (void)flipVertically;
-(NSRect)controlPointBounds;
-(NSRect)constrainRect:(NSRect)newBounds usingKnob:(NSInteger)knob;
-(BOOL)isTextObject;
-(BOOL)mayContainSubstitutions;

- (NSBezierPath *)clipPath;
-(FlippableView*)setCurrentDrawingDestination:(FlippableView*)dest;
-(FlippableView*)currentDrawingDestination;
-(BOOL)graphicCanDrawFill;
-(BOOL)graphicCanDrawStroke;
-(BOOL)visible;
-(BOOL)isEditable;
-(NSPoint)centrePoint;
- (ACSDrawDocument*)document;
-(NSTextStorage*)labelText;
-(BOOL)setGraphicLabelText:(NSTextStorage*)tx notify:(BOOL)notify;
-(BOOL)setGraphicLabelFlipped:(BOOL)fl notify:(BOOL)notify;
-(BOOL)hasClosedPath;
-(ACSDLabel*)textLabel;
- (void)drawCentrePointMagnification:(float)mag;
-(void)tempMoveBy:(NSValue*)offsetV;
- (void)startMove;
- (void)stopMove:(NSNumber*)n;
- (void)didChangeNeedRedraw:(BOOL)reDraw;
- (double)magnification;
- (void)setMagnification:(double)mag;
-(float)paddingRequired;
- (NSRect)displayBoundsSansShadow;
- (void)computeDisplayBounds;
- (void)draw:(NSRect)aRect inView:(GraphicView*)gView selected:(BOOL)isSelected isGuide:(BOOL)isGuide cacheDrawing:(BOOL)cacheDrawing options:(NSMutableDictionary*)options
;
-(NSColor*)setHandleColour:(BOOL)forGuide;
- (void)drawHandlesGuide:(BOOL)forGuide  magnification:(float)mag options:(NSUInteger)options;
- (void)postChangeOfBounds;
- (void)moveBy:(NSPoint)vector;
-(void)moveByValue:(NSValue*)val;
- (void)uMoveBy:(NSPoint)vector;
-(void)uMoveByValue:(NSValue*)val;
-(NSBezierPath*)transformedOutlinePath;
- (BOOL)setHeight:(float)ht;
- (BOOL)setWidth:(float)w;
- (BOOL)setRight:(float)r;
- (BOOL)setTop:(float)t;
- (BOOL)setX:(float)f;
- (BOOL)setY:(float)f;
- (BOOL)setGraphicRotation:(float)rot notify:(BOOL)notify;
- (BOOL)setGraphicXScale:(float)f notify:(BOOL)notify;
- (BOOL)setGraphicYScale:(float)f notify:(BOOL)notify;
- (void)computeTransform;
- (void)drawObject:(NSRect)aRect view:(GraphicView*)gView options:(NSMutableDictionary*)options;
- (void)drawObjectWithEffect:(NSRect)aRect inView:(GraphicView*)gView useCache:(BOOL)useCache
			   options:(NSMutableDictionary*)options;
-(void)setGraphicName:(NSString*)n;
-(BOOL)setGraphicFill:(ACSDFill*)f notify:(BOOL)notify;
-(BOOL)setGraphicBoundsTo:(NSRect)newBounds from:(NSRect)oldBounds;
-(void)setBoundsTo:(NSRect)newBounds from:(NSRect)oldBounds; 
-(BOOL)setGraphicStroke:(ACSDStroke*)s notify:(BOOL)notify;
- (void)setGraphicXScale:(float)fx yScale:(float)fy undo:(bool)undo;
-(BOOL)setGraphicLabelVPos:(float)f notify:(BOOL)notify;
-(BOOL)setGraphicLabelHPos:(float)f notify:(BOOL)notify;
-(void)setToolTip:(NSString*)tip;
- (void)setGraphicToolTip:(NSString*)tip;
- (BOOL)setGraphicSourcePath:(NSString*)sou;
-(NSString*)toolTip;
-(NSRect)viewableBounds;
-(NSSize)displayBoundsOffset;
-(NSBezierPath*)outlinePath;
-(void)uSetGraphicMode:(GraphicMode)gm;
-(NSImage*)imageForDrag;
-(ACSDPath*)wholeOutline;
-(ACSDPath*)wholeFilledRect;

- (NSBezierPath *)transformedBezierPath;

- (BOOL)intersectsWithRect:(NSRect)selectionRect;
- (BOOL)hitTest:(NSPoint)point isSelected:(BOOL)isSelected view:(GraphicView*)gView;
- (BOOL)createWithEvent:(NSEvent *)theEvent inView:(GraphicView *)view ;
- (KnobDescriptor)knobUnderPoint:(NSPoint)point view:(GraphicView*)gView;
- (KnobDescriptor)resizeByMovingKnob:(KnobDescriptor)kd toPoint:(NSPoint)point event:(NSEvent *)theEvent constrain:(BOOL)constrain aroundCentre:(BOOL)aroundCentre;
- (void)addHandleRectsForView:(GraphicView*)view;
-(NSPoint)pointForKnob:(const KnobDescriptor&)kd;
- (void)otherTrackKnobNotifiesView:(GraphicView*)gView;
- (void)otherTrackKnobAdjustments;
-(BOOL)trackInit:(KnobDescriptor&)kd withEvent:(NSEvent *)theEvent inView:(GraphicView*)view ok:(BOOL*)success;
-(void)trackMid:(KnobDescriptor&)kd withEvent:(NSEvent *)theEvent point:(NSPoint)point lastPoint:(NSPoint)lastPoint
selectedGraphics:(NSSet*)selectedGraphics;
- (void)setHandleBitsForview:(GraphicView*)gView;
- (void)startBoundsManipulation;
- (void)stopBoundsManipulation;
- (NSRect)rectFromAnchorPoint:(NSPoint)anchorPt movingPoint:(NSPoint)movingPt constrainedPoint:(NSPoint*)constrainedPoint 
			   dragFromCentre:(BOOL)centreDrag constrain:(BOOL)constrained;
- (ACSDPath*)convertToPath;
-(void)writeSVGDefs:(SVGWriter*)svgWriter;
-(void)writeSVGData:(SVGWriter*)svgWriter;
-(void)writeSVGOtherAttributes:(SVGWriter*)svgWriter;

-(BOOL)isSameAs:(id)obj;
-(void) readjustCache;
- (void)flipH;
- (void)flipV;
-(KnobDescriptor)nearestKnobForPoint:(NSPoint)pt;
-(NSInteger)nearestHandleToPoint:(NSPoint)pt maxDistance:(float)maxDistance xOffset:(float*)xOff yOffset:(float*)yOff;
-(void)computeTransformedHandlePoints;
-(NSSet*)usedFills;
-(NSSet*)usedShadows;
-(NSSet*)usedStrokes;
-(NSSet*)subObjects;
-(NSSet*)allTheObjects;
-(void)setGraphicTransform:(NSAffineTransform*)t;
- (void)drawInCache:(NSRect)aRect view:(GraphicView*)gView options:(NSMutableDictionary*)options;
-(void)buildPDFData;
-(void)freePDFData;
-(ObjectPDFData*)objectPdfData;
-(void)removeReferences;
-(void)setAllFills:(ACSDFill*)f;
-(void)rotateByDegrees:(float)rotationAmount aroundPoint:(NSPoint)centre;
-(BOOL)graphicUsesStroke:(ACSDStroke*)str;
-(BOOL)graphicUsesFill:(ACSDFill*)f;
-(BOOL)uClearSelectedElements;
-(NSComparisonResult)compareTimeStampWith:(id)obj;
-(void)addConnector:(ACSDConnector*)c;
-(void)removeConnector:(ACSDConnector*)c;
-(void)invalidateConnectors;
-(void)invalidateInView;
- (BOOL)shapeUnderPoint:(NSPoint)point includeKnobs:(BOOL)includeKnobs view:(GraphicView*)vw;
- (BOOL)shapeUnderPointValue:(id)v;
-(void)preDelete;
-(void)postUndelete;
-(void)mapCopiedObjectsFromDictionary:(NSDictionary*)map;
-(BOOL)usuallyUsesCache;
-(void)freeCache;
-(void)allocHandlePoints;
-(void)finishInit;
-(void)computeHandlePoints;
-(void)invalidateGraphicSizeChanged:(BOOL)sizeChanged shapeChanged:(BOOL)shapeChanged redraw:(BOOL)redraw notify:(BOOL)notify;
-(NSPoint)invertPoint:(NSPoint)point;
-(NSPoint)invertOffset:(NSPoint)offset;
-(BOOL)isOrContainsImage;
-(void)processHTMLOptions:(NSMutableDictionary*)options;
-(void)setAbsoluteLink:(NSURL*)url;
-(void)setLink:(id)l;
-(void)uSetLink:(id)l;
-(id)link;
-(NSString*) stringFromURL:(NSURL*)url options:(NSMutableDictionary*)options;
-(void)moveWithinBoundsOfView:(NSView*)view;
-(void)updateForStyle:(ACSDStyle*)style oldAttributes:(NSDictionary*)oldAttrs;
-(void)drawHighlightRect:(NSRect)r colour:(NSColor*)col hotPoint:(NSPoint)hotPoint modifiers:(NSUInteger)modifiers;
-(void)uRemoveLinkedObject:(id)obj;
-(void)uAddLinkedObject:(id)obj;
-(NSString*)linkUrlStringOptions:(NSMutableDictionary*)options;
-(NSString*)link:(id)l urlStringOptions:(NSMutableDictionary*)options;
-(id)checkLink:(ACSDLink*)l overflow:(BOOL*)overflow;
-(void)addLinksForPDFContext:(CGContextRef) context;
-(BOOL)doesTextFlow;
-(void)invalidateTextFlower;
-(float)midX;
-(float)midY;
-(NSComparisonResult)compareUsingXPos:(ACSDGraphic*)g;
-(NSComparisonResult)compareUsingYPos:(ACSDGraphic*)g;
-(BOOL)drawStrokeWithoutTransform;
-(NSString*)pathTextInvertY:(BOOL)invertY;
-(void)setParent:(ACSDGroup*)p;
-(ACSDGroup*)parent;
-(void)allocTriggers;
-(NSMutableArray*)triggers;
-(BOOL)addTrigger:(NSDictionary*)t;
-(BOOL)removeTrigger:(NSDictionary*)t;
-(void)writeCanvasGraphic:(CanvasWriter*)canvasWriter;
-(void)writeCanvasData:(CanvasWriter*)canvasWriter;
-(NSInteger)totalElementCount:(NSBezierPath*)p;
-(NSBezierPath*)pathTextGetPath;
-(void)processHTMLTriggers:(NSMutableString*)bodyString;
-(int)htmlVectorModeOptions:(NSMutableDictionary*)options;
-(void)permanentScale:(float)sc transform:(NSAffineTransform*)t;
-(void)createInit:(NSPoint)anchorPoint event:(NSEvent*)theEvent;
-(void)createMid:(NSPoint)anchorPoint currentPoint:(NSPoint*)currPoint event:(NSEvent*)theEvent;
-(BOOL)createCleanUp:(BOOL)cancelled;
-(BOOL)needsRestrictTo45;
-(NSString*)xmlAttributes:(NSMutableDictionary*)options;
-(NSString*)graphicXML:(NSMutableDictionary*)options;
-(NSString*)graphicXMLForEvent:(NSMutableDictionary*)options;
-(void)setValue:(id)value forKey:(NSString *)key invalidateFlags:(NSInteger)invalFlags;
- (void)setGraphicMaskObj:(id)n;
-(NSPoint)positionRelativeToRect:(NSRect)rect;
-(void)setPosition:(NSPoint)pt;
-(BOOL)uInsertAttributeName:(NSString*)nm value:(NSString*)val atIndex:(NSInteger)idx notify:(BOOL)notif;
-(BOOL)uSetAttributeName:(NSString*)nm atIndex:(NSInteger)idx notify:(BOOL)notif;
-(BOOL)uSetAttributeValue:(NSString*)val atIndex:(NSInteger)idx notify:(BOOL)notif;
-(BOOL)uDeleteAttributeAtIndex:(NSInteger)idx notify:(BOOL)notif;
-(BOOL)uSetAttributeValue:(NSString*)val forName:(NSString*)nme notify:(BOOL)notif;
-(BOOL)uDeleteAttributeForName:(NSString*)nme notify:(BOOL)notif;
-(NSString*)xmlEventTypeName;
- (BOOL)setGraphicHidden:(BOOL)b;
-(void)uSetAttributes:(NSMutableArray*)arr;
-(NSString*)svgTransform:(SVGWriter*)svgWriter;
-(NSString*)graphicAttributesXML:(NSMutableDictionary*)options;
-(NSRect)parentRect:(NSMutableDictionary*)options;

-(ACSDGroup*)primogenitor;
-(NSMutableSet*)linkedObjects;
-(int)zDepth;
-(NSArray*)indexPathFromAncestor:(ACSDGroup*)anc;
- (BOOL)setCentreX:(float)f;
- (BOOL)setCentreY:(float)f;

@end

@interface ACSDGraphic (ACSDEventHandling)

- (BOOL)createWithEvent:(NSEvent *)theEvent inView:(GraphicView *)view ;
- (BOOL)isEditable;
- (void)startEditingWithEvent:(NSEvent *)event inView:(GraphicView *)view;
- (void)endEditingInView:(GraphicView *)view;

- (BOOL)hitTest:(NSPoint)point isSelected:(BOOL)isSelected view:(GraphicView*)gView;
- (void)drawHandleAtPoint:(NSPoint)point magnification:(float)mag;
- (BOOL)usesSimplePath;
- (void)clearReferences;

@end

int operator==(const KnobDescriptor &kd1,const KnobDescriptor &kd2);

BOOL upperKnob(NSInteger knob);
BOOL lowerKnob(NSInteger knob);
BOOL leftKnob(NSInteger knob);
BOOL rightKnob(NSInteger knob);

