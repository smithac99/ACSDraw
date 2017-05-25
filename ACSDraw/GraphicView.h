/* GraphicView */

#import <Cocoa/Cocoa.h>
#import "ViewProtocols.h"
#import "FlippableView.h"

extern NSString *ACSDrawGraphicPasteboardType;
extern NSString *ACSDrawGraphicRefPasteboardType;

@class ACSDGraphic;
@class ACSDrawDocument;
@class ACSDStroke;
@class ACSDFill;
@class ACSDText;
@class ACSDPath;
@class ACSDLayer;
@class ACSDPage;
@class ShadowType;
@class SelectionSet;
@class SnapLine;
@class HighLightLayer;
@class ACSDLink;
@class ACSDGroup;
@class MarkerView;
struct KnobDescriptor;

extern NSString *ACSDCancelOpNotification;
extern NSString *ACSDGraphicViewTextSelectionDidChangeNotification;
extern NSString *ACSDGraphicViewSelectionDidChangeNotification;
extern NSString *ACSDDocumentDidChangeNotification;
extern NSString *ACSDMouseDidMoveNotification;
extern NSString *ACSDDimensionChangeNotification;
extern NSString *ACSDSizePanelParamChangeNotification;
extern NSString *ACSDFillAdded;
extern NSString *ACSDExposureChangedNotification;
extern NSString *ACSDRefreshLineEndingsNotification;
extern NSString *ACSDPageChanged;
extern NSString *ACSDLayerSelectionChanged;
extern NSString *ACSDCurrentLayerChanged;
extern NSString *ACSDGraphicListChanged;
extern NSString *ACSDGraphicAttributeChanged;
extern NSString *ACSDRefreshShadowsNotification;
extern NSString *ACSDRefreshStrokesNotification;
extern NSString *ACSDrawAttributePasteboardType;

#define PASTE_CASCADE_DELTA 30

#define RADIANS(x) ((x)/(360.0/(2.0 * M_PI)))
#define DEGREES(x) ((x)*(360.0/(2.0 * M_PI)))

enum GV_Cursor_Mode
{
    GV_MODE_NONE,
	GV_MODE_LINKING_TEXT_BLOCKS,
	GV_MODE_DOING_LINK,
	GV_ROTATION_AWAITING_SELECTION,
	GV_ROTATION_AWAITING_CLICK,
	GV_ROTATION_SHOWING_DIALOG,
	GV_ROTATION_AWAITING_ROTATE
};

@interface GraphicView : FlippableView
{
	NSMutableArray *pages,*repeatQueue;
	NSInteger currentPageInd;
	ACSDFill *defaultFill;
	ACSDStroke *defaultStroke;
	//ShadowType *defaultShadow;
	NSShadow *handleShadow;
	int defaultMatrixRows,defaultMatrixColumns,defaultPolygonSides;
	NSRect rubberbandRect;
	NSSet *rubberbandGraphics;
	ACSDGraphic *creatingGraphic,*trackingGraphic;
    ACSDGraphic *editingGraphic;
    ACSDGraphic *creatingPath;
	BOOL rubberbandIsDeselecting;
	NSLayoutManager *layoutManager;
	NSTextView *editor;
	BOOL editorInUse,repeatingAction;
	BOOL spaceDown,drawGrid;
	CGContextRef drawingToPDF;
	float magnification;
	long *verticalHandleBits,
	*horizontalHandleBits;
	NSPoint lineAnchorPoint,lineDragPoint;
	BOOL snap,showSelection;
	int snapSize,hotSpotSize;
	NSColor *guideColour,*selectionColour;
	char *snapVOffsets,*snapHOffsets;
	BOOL cacheDrawing,documentBased;
	GV_Cursor_Mode cursorMode;
	ACSDText *linkingTextBlock;
	NSPoint rotationPoint;
	NSTextField *polygonTextField;
	ACSDGraphic *dragGraphic;
	NSSize dragOffset;
	HighLightLayer *highLightLayer;
	IBOutlet MarkerView *markerView;
}

@property BOOL documentBased,editorInUse,showSelection,recordNextMove;
@property NSInteger currentPageInd;
@property GV_Cursor_Mode cursorMode;
@property int defaultMatrixRows,defaultMatrixColumns,defaultPolygonSides;
@property NSPoint rotationPoint;
@property (assign) ACSDGraphic *creatingGraphic,*creatingPath,*editingGraphic;
@property (retain,nonatomic) ACSDFill *defaultFill;
@property (retain,nonatomic) ACSDStroke *defaultStroke;
@property (retain,nonatomic) ShadowType *defaultShadow;
@property (retain) NSPanel *polygonSheet;
@property (retain) NSArray *savedEyeClick;



-(void) setPages:(NSMutableArray*)list;
- (NSMutableArray*)layers;
- (NSMutableArray*)pages;
- (float)magnification;
-(CGContextRef)drawingToPDF;
-(void)setDrawingToPDF:(CGContextRef)d;
- (NSColor*)backgroundColour;
- (ACSDrawDocument*)document;
- (ACSDGraphic*)editingGraphic;
- (id)selectedGraphics;
- (NSLayoutManager*)layoutManager;
- (NSTextView*)editor;
- (void)changeDocTitle:(NSString*)t;
- (void)changePageTitle:(NSString*)t;
- (void)changeScriptURL:(NSString*)t;
- (void)changeAdditionalCSS:(NSString*)t;
- (void)setCurrentEditableLayerIndex:(NSInteger)i force:(BOOL)force select:(BOOL)sel withUndo:(BOOL)withUndo;
- (void)setCurrentPageIndex:(NSInteger)i force:(BOOL)force withUndo:(BOOL)withUndo;
- (void)addNewPageAtIndex:(NSInteger)index;
- (void)adjustPageNumbersFromIndex:(NSInteger)index;
- (ACSDLayer*)currentEditableLayer;
- (ACSDPage*)currentPage;
- (void)addPage:(ACSDPage*)page atIndex:(NSInteger)index;
- (BOOL)clearSelection;
- (void)setEditingGraphic:(ACSDGraphic *)graphic;
- (void)startEditingGraphic:(ACSDGraphic*)graphic withEvent:(NSEvent*)event;
- (void)endEditing;
- (NSColor*)guideColour;
- (NSDictionary*)dictionaryFromLayer:(ACSDLayer*)layer position:(id)pos;
- (void) refreshLayer:(int)l;
-(void)rotateselectedGraphicsWithDict:(NSDictionary*)dict;
-(HighLightLayer*)highLightLayer;

- (BOOL)graphicIsSelected:(ACSDGraphic*)graphic;
- (BOOL)selectGraphic:(ACSDGraphic *)graphic;
- (BOOL)deselectGraphic:(ACSDGraphic *)graphic;
- (BOOL)selectGraphics:(NSArray*)graphicArray;
- (void)addLayer:(ACSDLayer*)layer atIndex:(NSInteger)index;
- (void)addNewLayerAtIndex:(NSInteger)index;
- (void)invalidateGraphic:(ACSDGraphic*)graphic;
- (void)invalidateGraphics:(NSArray *)graphics;
- (void)deleteSelectedGraphics;
- (NSDictionary*)duplicateWithCascade:(float)cascadeAmount;
- (void)reCalcHandleBitsIgnoreSelected:(BOOL)ignoreSelected;
- (void)resizeHandleBits;
- (void)setHandleBitsH:(int)h v:(int)v;
- (void)changeDocumentWidth:(float)f;
- (void)changeDocumentHeight:(float)f;
- (void)createImage:(NSImage*)im name:(NSString*)name location:(NSPoint*)loc fileName:(NSString*)fileName;
- (float)adjustHSmartGuide:(float)x tool:(int)selectedTool;
- (float)adjustVSmartGuide:(float)y tool:(int)selectedTool;
-(int)snapSize;
- (void)setGuideColour:(NSColor*)col;
- (void)setSelectionColour:(NSColor*)col;
- (void)guideColourChanged:(NSNotification *)notification;
- (void)snapSizeChanged:(NSNotification *)notification;
- (void)hotSpotSizeChanged:(NSNotification *)notification;
- (void)snapButtonDidChange:(NSNotification *)notification;
- (void)insertGraphic:(ACSDGraphic*)element atIndex:(NSInteger)i;
-(void)createLineEndingWindowForSelectedGraphics;
- (void)duplicateInPlace:(id)sender;
- (void)deleteGraphicAtIndex:(NSInteger)i;
- (void)insertNewGraphicFromSubPaths:(NSMutableArray*)subPaths modelObject:(ACSDGraphic*)oldG;
- (ACSDGraphic*)shapeUnderPoint:(NSPoint)point extending:(BOOL)extending;
-(NSShadow*)handleShadow;
- (void)setNeedsDisplay;
+ (NSMutableArray*)intersectedSubPathsFromVertexList:(NSArray*)vertexList;

- (void)uInsertGraphic:(ACSDGraphic*)g intoLayer:(ACSDLayer*) l atIndex:(NSInteger)i;
- (void)uAppendSubPath:(id)subPath toPath:(ACSDPath*)path;
- (void)uRebuildPathUndo:(ACSDPath*)path;
- (void)uRebuildPath:(ACSDPath*)path;
- (void)uRestoreSubPaths:(NSMutableArray*)subPaths forPath:(ACSDPath*)path;
+ (NSMutableArray*)subPathsFromObjects:(NSArray*)arr;
- (NSMutableArray*)subPathsFromSelectedObjects:(NSArray*)arr;
-(void)setLinkFromObjects:(NSSet*)fromObjects toObject:(id)toObject modifiers:(NSUInteger)modifiers;
- (BOOL)trackGraphic:(ACSDGraphic*)g knob:(KnobDescriptor&)kd withEvent:(NSEvent *)theEvent selectedGraphics:(NSSet*)selectedGraphics;

- (void)unlinkText:(ACSDText*)lText;
- (void)linkText:(ACSDText*)lText toText:(ACSDText*)sText;
-(void)addRepeatableAction:(SEL)selector name:(NSString*)n argument:(void*)arg;
-(void)emptyRepeatQueue;
- (void)repeatAction:(id)sender;
- (void)addElement:(ACSDGraphic*)element;
-(BOOL)recursionForObject:(id)obj;
- (void)changeDocumentSize:(NSSize)sz matrixRow:(int)row matrixColumn:(int)col;
- (void)changeDocumentSize:(NSSize)sz;
- (NSInteger)moveLayerFromIndex:(NSInteger)fromInd toIndex:(NSInteger)toInd;
-(void)uMoveLayerAtIndex:(NSInteger)fromInd page:(ACSDPage*)fromPage toIndex:(NSInteger)toInd page:(ACSDPage*)toPage;
- (NSUInteger)movePageFromIndex:(NSUInteger)fromInd toIndex:(NSUInteger)toInd;
- (void)moveSelectedGraphicsToLayer:(NSInteger)toInd;
- (void)deleteCurrentPage;
- (void)deleteCurrentLayer;
-(void)setPageType:(int)pType;
-(void)setCurrentLayerExportable:(BOOL)b;
-(void)setCurrentLayerZPosOffset:(float)f;
-(void)resolveMasters;
-(void)drawPage:(ACSDPage*)page rect:(NSRect)aRect drawingToScreen:(BOOL)drawingToScreen drawMarkers:(BOOL)drawMarkers drawingToPDF:(CGContextRef)drPDF substitutions:(NSMutableDictionary*)substitutions options:(NSDictionary*)options;
-(void)moveAllObjectsBy:(NSPoint)vector;
- (void)pasteFromPasteBoard:(NSPasteboard*)pBoard location:(NSPoint*)loc;
-(void)copySelectedGraphicsToPasteBoard:(NSPasteboard*)pb draggedGraphic:(ACSDGraphic*)dg altDown:(BOOL)altDown;
-(BOOL)scrollIfNecessaryPoint:(NSPoint)point periodicStarted:(BOOL)periodicStarted;
-(ACSDGraphic*)dragGraphic;
-(void)updateForStyle:(id)style oldAttributes:(NSDictionary*)oldAttrs;
-(ACSDLink*)uLinkFromObject:(id)fromObject range:(NSValue*)textRange toObject:(id)toObject anchor:(int)anchor;
-(void)setMasterType:(int)mType;
-(void)setUseMaster:(int)mType;
-(void)addGraphic:(ACSDGraphic*)g;
-(void)toggleVisibilityForLayer:(ACSDLayer*)l modifierFlags:(NSUInteger)modifierFlags;
-(void)toggleLockingForLayer:(ACSDLayer*)l;
-(void)setPageInactive:(BOOL)ia;
- (void)uInsertIntoCurrentLayerGraphic:(ACSDGraphic*)graphic atIndex:(NSInteger)i;
-(void)uRemoveFromCurrentLayerGraphicAtIndex:(NSInteger)i;
- (void)removeFromCurrentLayerGraphic:(ACSDGraphic*)g;
- (void)removeSelectedGraphicsFromCurrentLayer;
-(void)uRemoveTrigger:(NSMutableDictionary*)t fromLayer:(ACSDLayer*)l;
-(void)uAddTrigger:(NSMutableDictionary*)t toLayer:(ACSDLayer*)l;
-(void)uAddTrigger:(NSMutableDictionary*)t toGraphic:(ACSDGraphic*)g;
-(void)uRemoveTrigger:(NSMutableDictionary*)t fromGraphic:(ACSDGraphic*)g;
-(void)uGroupGraphicsFromIndexSet:(NSIndexSet*)ixs intoGroup:(ACSDGroup*)gp atIndex:(NSInteger)ind;

- (void)cropToRectangle:(id)sender;
-(void)selectGraphicsInCurrentLayerFromSet:(NSSet*)gset;
-(void)selectGraphicWithName:(NSString*)nm;
- (void)scaleDocumentBy:(float)f;
- (void)cancelOp:(id)sender;
- (void)backgroundChanged:(id)sender;
-(void)hideLayersWithName:(NSString*)nm;
-(void)selectLayersWithName:(NSString*)nm;
-(NSImage*)imageFromCurrentPageOfSize:(NSSize)sz;
-(void)duplicatePageAtIndex:(NSInteger)index;
-(void)renameSelectedGraphicsUsingParams:(NSMutableArray*)params startA:(NSString*)starta startN:(int)startN orderBy:(int)orderBy rowAscending:(BOOL)rowAscending colAscending:(BOOL)colAscending;
-(int)renameSelectedGraphicsUsingRegularExpression:(NSRegularExpression*)regexp template:(NSString*)templateString;
-(void)selectGraphicsInCurrentLayerFromIndexSet:(NSIndexSet*)ixs;
-(void)uSetGraphics:(NSMutableArray*)gs forLayer:(ACSDLayer*)l;      //assumes this is just a different ordering
NSString *IncrementString(NSString *s);
-(IBAction)reloadImage:(id)sender;
-(void)reloadImages:(NSArray*)arr;
-(void)moveGraphicsFromLayer:(ACSDLayer*) fromLayer atIndexes:(NSIndexSet*)fromIxs toLayer:(ACSDLayer*)toLayer atIndexes:(NSIndexSet*)toIxs;
-(void)uSetSelectionForLayer:(ACSDLayer*)l toObjects:(NSArray*)arr;
-(void)processLinkToObj:(id)obj modifierFlags:(NSEventModifierFlags)modifierFlags;
-(void)repeatSelectedGraphicsRows:(NSInteger)rows cols:(NSInteger)cols xinc:(CGFloat)xinc yinc:(CGFloat)yinc rowOffset:(CGFloat)rowOffset;
-(void)updateSelectedPointFromDictionary:(NSDictionary*)dict;

@end
