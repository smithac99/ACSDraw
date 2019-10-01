//
//  ACSDPath.h
//  ACSDraw
//
//  Created by Alan Smith on Sun Feb 03 2002.
//  Copyright (c) 2001 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ACSDGraphic.h"
#import "ACSDSubPath.h"

@class SelectedElement;
@class XMLNode;

void generateSubPath(NSBezierPath* path,NSMutableArray* pathElements,BOOL isClosed);
NSBezierPath* bezierPathFromSVGPath(NSString *str);
NSBezierPath *bezierPathFromCGPath(CGPathRef path);
CGPathRef createCGPathFromNSBezierPath(NSBezierPath *bez);
NSBezierPath *outlinedStrokePath(NSBezierPath *inPath);

@class ACSDPathElement;

@interface ACSDPath : ACSDGraphic
   {
	NSBezierPath *path,*addingPointPath;
	NSMutableArray *subPaths;
	NSInteger currentSubPathInd;
	BOOL isCreating;
	NSMutableSet *selectedElements;
   }

+(id)pathWithSubPaths:(NSArray*)subPaths;
+(id)pathWithPath:(NSBezierPath*)p;
+(id)pathWithSVGPath:(NSBezierPath*)p settings:(NSMutableDictionary*)settings;
+(id)pathWithSVGNode:(XMLNode*)xmlnode settingsStack:(NSMutableArray*)settingsStack;
+(id)polylineWithSVGNode:(XMLNode*)xmlnode settingsStack:(NSMutableArray*)settingsStack;
+(id)polygonWithSVGNode:(XMLNode*)xmlnode settingsStack:(NSMutableArray*)settingsStack;
+(id)pathLineWithSVGNode:(XMLNode*)xmlnode settingsStack:(NSMutableArray*)settingsStack;
+(id)pathRectWithSVGNode:(XMLNode*)xmlnode settingsStack:(NSMutableArray*)settingsStack;
+(id)ellipseWithSVGNode:(XMLNode*)xmlnode settingsStack:(NSMutableArray*)settingsStack;
+(id)circleWithSVGNode:(XMLNode*)xmlnode settingsStack:(NSMutableArray*)settingsStack;
+(ACSDPath*)aNotBSubPathsFromObjects:(NSArray*)objectArray;
+(ACSDPath*)unionSubPathsFromObjects:(NSArray*)objectArray;
+(ACSDPath*)intersectedSubPathsFromObjects:(NSMutableArray*)objectArray;
+(ACSDPath*)xorSubPathsFromObjects:(NSMutableArray*)objectArray;
-(id)initWithName:(NSString*)n fill:(ACSDFill*)f stroke:(ACSDStroke*)str rect:(NSRect)r layer:(ACSDLayer*)l bezierPath:(NSBezierPath*)p
		   xScale:(float)xs yScale:(float)ys rotation:(float)rot shadowType:(ShadowType*)st label:(ACSDLabel*)lab alpha:(float)a;
-(id)initWithName:(NSString*)n fill:(ACSDFill*)f stroke:(ACSDStroke*)str rect:(NSRect)r layer:(ACSDLayer*)l bezierPath:(NSBezierPath*)p;
-(id)initWithName:(NSString*)n fill:(ACSDFill*)f stroke:(ACSDStroke*)str rect:(NSRect)r layer:(ACSDLayer*)l subPaths:(NSMutableArray*)sp;
-(id)initWithName:(NSString*)n fill:(ACSDFill*)f stroke:(ACSDStroke*)str rect:(NSRect)r layer:(ACSDLayer*)l subPaths:(NSMutableArray*)sp
		   xScale:(float)xs yScale:(float)ys rotation:(float)rot shadowType:(ShadowType*)st label:(ACSDLabel*)lab alpha:(float)a;
- (void)setPath:(NSBezierPath*)p;
- (NSBezierPath*)path;
- (NSBezierPath*)addingPointPath;
- (void)addPoint:(NSPoint)pt;
- (BOOL)trackAndAddPointWithEvent:(NSEvent *)theEvent inView:(GraphicView *)view;
- (void)generatePath;
- (void)setAddingPointPath:(NSBezierPath*)p;
- (void)setSubPaths:(NSMutableArray*)p;
- (void)setIsCreating:(BOOL)b;
- (NSMutableArray*)pathElements;
- (ACSDSubPath*)currentSubPath;
- (NSMutableArray*)subPaths;
-(BOOL)lastPoint:(NSPoint*)pt;
-(BOOL)lastControlPoint:(NSPoint*)pt;
-(void)constructAddingPointPath;
-(bool)reversePathWithStrokeList:(NSMutableArray*)strokes;
- (void)addSubPath:(ACSDSubPath*)asp;
- (void)addSubPaths:(NSArray*)arr;
-(void)recalcBounds;
- (void)completeRebuild;
- (void)trackSplitKnob:(KnobDescriptor&)kd withEvent:(NSEvent *)theEvent copy:(BOOL)copy inView:(GraphicView*)view;
- (KnobDescriptor)resizeByMovingKnob:(const KnobDescriptor)kd by:(NSPoint)point event:(NSEvent *)theEvent constrain:(BOOL)constrain;
-(void)applyTransform;
- (BOOL)splitPathWithEvent:(NSEvent *)theEvent copy:(BOOL)copy inView:(GraphicView*)view;
- (float)roughArea;
- (BOOL)isCounterClockWise;
- (ACSDPath*)outlineStroke;
-(NSMutableArray*)reversedSubPaths;
- (void)makeSubPathsCounterClockWise;
- (BOOL)removePathElementWithEvent:(NSEvent *)theEvent inView:(GraphicView*)view;
-(void)setSubPathsAndRebuild:(NSMutableArray*) arr;
-(NSMutableArray*)transformedSubPaths;
-(NSPoint)firstPoint;
-(NSPoint)lastPoint;
-(void)offsetPointValue:(NSValue*)vp;

-(void)selectElement:(SelectedElement*)se;
-(void)selectElementFromKnob:(KnobDescriptor)kd;
-(void)deselectElement:(SelectedElement*)se;
-(void)deselectElementFromKnob:(KnobDescriptor)kd;
-(void)uDeselectElement:(SelectedElement*)se;
-(void)uSelectElement:(SelectedElement*)se;
-(void)uSelectElementFromKnob:(KnobDescriptor)kd extend:(BOOL)extend;
-(void)uDeselectElementFromKnob:(KnobDescriptor)kd;
-(BOOL)elementIsSelected:(KnobDescriptor)kd;
-(void)setSelectedElements:(NSSet*)objects;
-(void)uReplaceSubPathsInRange:(NSRange)r withSubPaths:(NSArray*)spArray;
-(BOOL)uClearSelectedElements;
-(void)clearSelectedElements;
-(BOOL)knobIsSelected:(const KnobDescriptor&)k;
- (KnobDescriptor)knobOrLineUnderPoint:(NSPoint)point view:(GraphicView*)gView;
-(BOOL)deleteSelectedElements;
-(void)uInsertPathElement:(ACSDPathElement*)pe forKnob:(const KnobDescriptor)kd;
-(void)uDeletePathElement:(const KnobDescriptor)kd;
-(void)uReplacePathElementWithElement:(ACSDPathElement*)pr forKnob:(const KnobDescriptor)kd;
-(KnobDescriptor)uDuplicateKnob:(const KnobDescriptor)kd;
-(BOOL)uSetSubPathsIsClosedTo:(NSNumber*)ncl;
-(BOOL)hasPathsWithClosed:(BOOL)cl;
-(BOOL)graphicCanMergePoints;
-(BOOL)uMergePoints;
-(NSArray*)sortedSelectedElements;
+ (NSMutableArray*)outlineStrokeFromPath:(ACSDPath*)path;
-(NSMutableSet *)selectedElements;
-(NSMutableArray*)mercatorSubPathsWithRect:(NSRect)r;
-(NSMutableArray*)demercatorSubPathsWithRect:(NSRect)r;
-(NSPoint)centroid;
-(SelectedElement*)selectedElement;
-(KnobDescriptor)elementAfter:(KnobDescriptor)kd;
-(BOOL)selectNextElement;
-(BOOL)selectPrevElement;
- (void)uChangeElement:(ACSDPathElement*)el point:(NSPoint)pt preControlPoint:(NSPoint)preCP postControlPoint:(NSPoint)postCP
    hasPreControlPoint:(BOOL) hasPreCP hasPostControlPoint:(BOOL)hasPostCP isLineToPoint:(BOOL)iltp
controlPointsContinuous:(BOOL) cpc;



@end
