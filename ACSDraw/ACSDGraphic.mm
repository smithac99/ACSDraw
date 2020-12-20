//
//  ACSDGraphic.mm
//  ACSDraw
//
//  Created by Alan Smith on Mon Jan 14 2002.
//  Copyright (c) 2001 __MyCompanyName__. All rights reserved.
//

#import "ACSDPage.h"
#import "ACSDGraphic.h"
#import "ACSDGradient.h"
#import "ACSDLineEnding.h"
#import "ACSDrawDocument.h"
#import "ACSDImage.h"
#import "GraphicView.h"
#import "ToolWindowController.h"
#import "ACSDCursor.h"
#import "ACSDPath.h"
#import "ACSDText.h"
#import "ShadowType.h"
#import "SVGWriter.h"
#import "ObjectView.h"
#import "ConnectorAttachment.h"
#include "geometry.h"
#import "ObjectPDFData.h"
#include <iostream>
#import "AffineTransformAdditions.h"
#import "geometry.h"
#import "ACSDConnector.h"
#import "ACSDPrefsController.h"
#import "AppDelegate.h"
#import "ACSDLink.h"
#import "HtmlExportController.h"
#import "ACSDGroup.h"
#import "CanvasWriter.h"
#import "TriggerTableSource.h"
#import "SizeController.h"
#import "SelectionSet.h"
#import "ACSDPattern.h"

#define SIGN(a) (((a)<0)?(-1):(((a)==0)?0:1))

NSString *htmlDirectoryNameForOptions(NSMutableDictionary *options,NSString *dirType);
BOOL getFirstTwoPoints(NSBezierPath *path,NSPoint *pt1,NSPoint *pt2);
BOOL getLastTwoPoints(NSBezierPath *path,NSPoint *pt1,NSPoint *pt2);
BOOL pathIntersectsWithRect(NSBezierPath *p,NSRect pathBounds,NSRect r,BOOL checkBottomLeft,BOOL checkTopLeft,BOOL checkTopRight,BOOL checkBottomRight);

NSString *ACSDGraphicDidChangeNotification = @"ACSDGraphicDidChange";
int knobs[] = {LowerLeftKnob,LowerMiddleKnob,LowerRightKnob,MiddleRightKnob,UpperRightKnob,UpperMiddleKnob,UpperLeftKnob,MiddleLeftKnob};

CGRect CGRectFromNSRect(NSRect r)
   {
	return CGRectMake(r.origin.x,r.origin.y,r.size.width,r.size.height); 
   }

int operator==(const KnobDescriptor &kd1,const KnobDescriptor &kd2)
   {
    return kd1.subPath == kd2.subPath && kd1.knob == kd2.knob && kd1.controlPoint == kd2.controlPoint && kd1.isLine == kd2.isLine;
   }

void restrictTo45(NSPoint pt1,NSPoint *pt2)
   {
//	float theta = getAngleForPoints(*pt2,pt1);
	float xdiff = pt2->x - pt1.x;
	float ydiff = pt2->y - pt1.y;
	float h = sqrt(xdiff*xdiff + ydiff*ydiff);
	float theta = DEGREES(acos(xdiff/h));
	if (theta < 0)
		theta = 360.0 - theta;
	int rem = ((int)theta) % 45;
	int octant = ((int)theta) / 45;
	if (rem >= 23)
		octant++;
	if (octant == 0 || octant == 4)
		pt2->y = pt1.y;
	else if (octant == 2 || octant == 6)
		pt2->x = pt1.x;
	else
	   {
		float a = h / sqrt(2.0);
		pt2->x = pt1.x + (SIGN(xdiff) * a);
		pt2->y = pt1.y + (SIGN(ydiff) * a);
	   }
   }

CGFloat angleForPoints(NSPoint pt1,NSPoint pt2)
{
	CGFloat x = pt2.x - pt1.x;
	CGFloat y = pt2.y - pt1.y;
	return DEGREES(atan2(y,x));
}

float getAngleForPoints(NSPoint pt1,NSPoint pt2)
   {
	float h = sqrt((pt1.x-pt2.x) * (pt1.x-pt2.x) + (pt1.y-pt2.y) * (pt1.y-pt2.y));
	float xPrime = pt1.x - pt2.x;
	if (h == 0.0)
		return 0.0;
	float theta = DEGREES(acos(xPrime/h));
	if (pt2.y > pt1.y)
		theta = 360.0 - theta;
	return theta;
   }

BOOL getFirstTwoPoints(NSBezierPath *path,NSPoint *pt1,NSPoint *pt2)
   {
	int elCount = (int)[path elementCount];
	if (elCount < 2)
		return NO;
	NSPoint pt[3],returnPoints[3];
	int ptInd = 0;	
	for (int i = 0;i < elCount;i++)
	   {
		NSBezierPathElement elType = [path elementAtIndex:i associatedPoints:pt];
		switch(elType)
		   {
			case NSMoveToBezierPathElement:
			case NSLineToBezierPathElement:
				if (ptInd == 0 || !NSEqualPoints(returnPoints[ptInd-1],pt[0]))
					returnPoints[ptInd++] = pt[0];
				break;
			case NSCurveToBezierPathElement:
				if (ptInd == 0 || !NSEqualPoints(returnPoints[ptInd-1],pt[0]))
					returnPoints[ptInd++] = pt[0];
				if (ptInd == 0 || !NSEqualPoints(returnPoints[ptInd-1],pt[1]))
					returnPoints[ptInd++] = pt[1];
				if (ptInd == 0 || !NSEqualPoints(returnPoints[ptInd-1],pt[2]))
					returnPoints[ptInd++] = pt[2];
				break;
			case NSClosePathBezierPathElement:
				break;
		   }
		if (ptInd > 1)
		   {
		    *pt1 = returnPoints[0];
		    *pt2 = returnPoints[1];
			return YES;
		   }
	   }
	return NO;
   }

BOOL getLastTwoPoints(NSBezierPath *path,NSPoint *pt1,NSPoint *pt2)
   {
	int elCount = (int)[path elementCount];
	if (elCount < 2)
		return NO;
	NSPoint pt[3],returnPoints[3];
	int ptInd = 0;	
	for (int i = elCount - 1;i >= 0;i--)
	   {
		NSBezierPathElement elType = [path elementAtIndex:i associatedPoints:pt];
		switch(elType)
		   {
			case NSMoveToBezierPathElement:
			case NSLineToBezierPathElement:
				if (ptInd == 0 || !NSEqualPoints(returnPoints[ptInd-1],pt[0]))
					returnPoints[ptInd++] = pt[0];
				break;
			case NSCurveToBezierPathElement:
				if (ptInd == 0 || !NSEqualPoints(returnPoints[ptInd-1],pt[2]))
					returnPoints[ptInd++] = pt[2];
				if (ptInd == 0 || !NSEqualPoints(returnPoints[ptInd-1],pt[1]))
					returnPoints[ptInd++] = pt[1];
				if (ptInd == 0 || !NSEqualPoints(returnPoints[ptInd-1],pt[0]))
					returnPoints[ptInd++] = pt[0];
				break;
			case NSClosePathBezierPathElement:
				[path elementAtIndex:0 associatedPoints:pt];
				returnPoints[ptInd++] = pt[0];
				break;
		   }
		if (ptInd > 1)
		   {
		    *pt1 = returnPoints[0];
		    *pt2 = returnPoints[1];
			return YES;
		   }
	   }
	return NO;
   }

@implementation ACSDGraphic

@synthesize xScale,yScale,alpha,rotation,rotationPoint,addingPoint,actualAddingPoint,moveOffset,graphicMode,
selectionTimeStamp,layer,transform,parent,preOutlineStroke,preOutlineFill,
usesCache,bezierPathValid,displayBoundsValid,isMask,addingPoints,outlinePathValid,moving,opCancelled,
exposure,saturation,brightness,contrast,unsharpmaskRadius,unsharpmaskIntensity,gaussianBlurRadius,filterSettings;

+ (void) encodePoint:(NSPoint)pt coder:(NSCoder*)coder forKey:(NSString*)key
{
	[coder encodeDouble:pt.x forKey:[NSString stringWithFormat:@"%@x",key]];
	[coder encodeDouble:pt.y forKey:[NSString stringWithFormat:@"%@y",key]];
//	[coder encodeObject:[NSArray arrayWithObjects:[NSNumber numberWithFloat:pt.x],[NSNumber numberWithFloat:pt.y],nil]
//				 forKey:key];
}

+ (NSPoint) decodePointForKey:(NSString*)key coder:(NSCoder*)coder
{
	NSPoint pt;
	id o = [coder decodeObjectForKey:key];
	if (o)
	{
		pt.x = [[o objectAtIndex:0]doubleValue];
		pt.y = [[o objectAtIndex:1]doubleValue];
	}
	else
	{
		pt.x = [coder decodeDoubleForKey:[NSString stringWithFormat:@"%@x",key]];
		pt.y = [coder decodeDoubleForKey:[NSString stringWithFormat:@"%@y",key]];
	}
	return pt;
}

+ (void) encodeSize:(NSSize)sz coder:(NSCoder*)coder forKey:(NSString*)key
{
	[coder encodeDouble:sz.width forKey:[NSString stringWithFormat:@"%@w",key]];
	[coder encodeDouble:sz.height forKey:[NSString stringWithFormat:@"%@h",key]];
}

+ (NSSize) decodeSizeForKey:(NSString*)key coder:(NSCoder*)coder
{
	NSSize sz;
	sz.width = [coder decodeDoubleForKey:[NSString stringWithFormat:@"%@w",key]];
	sz.height = [coder decodeDoubleForKey:[NSString stringWithFormat:@"%@h",key]];
	return sz;
}

+ (void) encodeRect:(NSRect)r coder:(NSCoder*)coder forKey:(NSString*)key
{
/*	[coder encodeObject:[NSArray arrayWithObjects:
						 [NSNumber numberWithFloat:r.origin.x],
						 [NSNumber numberWithFloat:r.origin.y],
						 [NSNumber numberWithFloat:r.size.width],
						 [NSNumber numberWithFloat:r.size.height],
						 nil]
				 forKey:key];*/
	[ACSDGraphic encodePoint:r.origin coder:coder forKey:key];
	[ACSDGraphic encodeSize:r.size coder:coder forKey:key];
}

+ (NSRect) decodeRectForKey:(NSString*)key coder:(NSCoder*)coder
{
	NSRect r;
	id o = [coder decodeObjectForKey:key];
	if (o)
	{
		r.origin.x = [[o objectAtIndex:0]doubleValue];
		r.origin.y = [[o objectAtIndex:1]doubleValue];
		r.size.width = [[o objectAtIndex:2]doubleValue];
		r.size.height = [[o objectAtIndex:3]doubleValue];
	}
	else
	{
		r.origin = [ACSDGraphic decodePointForKey:key coder:coder];
		r.size = [ACSDGraphic decodeSizeForKey:key coder:coder];
	}
	return r;
}

+ (NSString*)nextNameForDocument:(ACSDrawDocument*)doc
{
    NSMutableDictionary *dict = [doc nameCounts];
	id val;
	int intVal;
	NSString *objName = [[self class]graphicTypeName];
	if ((val = [dict objectForKey:objName]) == nil)
		intVal = 0;
	else
	    intVal = [val intValue];
	intVal++;
	val = [NSNumber numberWithInt:intVal];
	[dict setObject:val forKey:objName];
	return [NSString stringWithFormat:@"%@%d",objName,intVal];
}

+ (NSString*)graphicTypeName
{
	return @"Object";
}

-(id)init
{
	if ((self = [super init]))
	{
		transform = nil;
		selectionTimeStamp = nil;
		shadowType = nil;
		manipulatingBounds = moving = NO;
		rotation = 0.0;
		xScale = yScale = 1.0;
		textPad = -1.0;
		alpha = 1.0;
		addingPoints = NO;
		displayBoundsValid = NO;
		currentDrawingDestination = nil;
		[self allocHandlePoints];
		connectors = [[NSMutableArray arrayWithCapacity:5]retain];
		deleted = NO;
        _tempSettings = [[NSMutableDictionary alloc]initWithCapacity:5];
        filterSettings = [[NSMutableDictionary alloc]initWithCapacity:5];
	}
	return self;
}

-(id)initWithName:(NSString*)n fill:(ACSDFill*)f stroke:(ACSDStroke*)str rect:(NSRect)b layer:(ACSDLayer*)l
{
	if ((self = [self init]))
	{
		self.name = n;
		[self setStroke:str];
		[self setFill:f];
		bounds = b;
		layer = l;
		usesCache = [self usuallyUsesCache];
		events = [[NSMutableDictionary dictionaryWithCapacity:2]retain];
		textLabel = [[ACSDLabel alloc]initWithGraphic:self];
	}
	return self;
}

-(id)initWithName:(NSString*)n fill:(ACSDFill*)f stroke:(ACSDStroke*)str rect:(NSRect)b layer:(ACSDLayer*)l
		   xScale:(float)xs yScale:(float)ys rotation:(float)rot shadowType:(ShadowType*)st label:(ACSDLabel*)lab alpha:(float)a
{
	if ((self = [self init]))
	{
		self.name = n;
		[self setStroke:str];
		[self setFill:f];
		bounds = b;
		layer = l;
		usesCache = [self usuallyUsesCache];
		events = [[NSMutableDictionary dictionaryWithCapacity:2]retain];
		[self setXScale:xs];
		[self setYScale:ys];
		rotationPoint = [self centrePoint];
		//[self setRotation:rot];
		rotation = rot;
		if (rotation != 0.0 || xScale != 1.0 || yScale != 1.0)
		{
			[self setRotationPoint:rotationPoint];
			[self computeTransform];
		}
		[self setShadowType:st];
		textLabel = [lab copy];
		[textLabel setGraphic:self];
		alpha = a;
	}
	return self;
}

-(void)dealloc
{
	self.name = nil;
	if (fill)
		[self setFill:nil];
	if (stroke)
		[self setStroke:nil];
	if (transform)
		[transform release];
	if (selectionTimeStamp)
		[selectionTimeStamp release];
	if (shadowType)
		[self setShadowType:nil];
	if (events)
		[events release];
	if (graphicCache)
		[graphicCache release];
	if (handlePoints)
		delete[] handlePoints;
	if (textLabel)
		[textLabel release];
	if (toolTip)
		[toolTip release];
	if (objectPdfData)
		[objectPdfData release];
	if (connectors)
		[connectors release];
	if (outlinePath)
		[outlinePath release];
	if (linkedObjects)
		[linkedObjects release];
	if (triggers)
		[triggers release];
    [filterSettings release];
    [_tempSettings release];
	self.sourcePath = nil;
    self.clipGraphic = nil;
	[super dealloc];
}

- (id)copyWithZone:(NSZone *)zone 
{
    /*ACSDGraphic *obj =  [[[self class] allocWithZone:zone] initWithName:[self name] fill:[self fill] stroke:[self stroke] rect:[self bounds]
																  layer:layer xScale:xScale yScale:yScale 
															   rotation:rotation shadowType:[self shadowType] label:textLabel alpha:alpha];*/
    ACSDGraphic *obj = [super copyWithZone:zone];
    obj.name = self.name;
    [obj setStroke:stroke];
    [obj setFill:fill];
    obj.bounds = bounds;
    obj.layer = layer;
    obj.usesCache = usesCache;
    //obj.events = [[NSMutableDictionary dictionaryWithCapacity:2]retain];
    [obj setXScale:xScale];
    [obj setYScale:yScale];
    obj.rotationPoint = [obj centrePoint];
    obj.rotation = rotation;
    if (rotation != 0.0 || xScale != 1.0 || yScale != 1.0)
    {
        [obj setRotationPoint:rotationPoint];
        [obj computeTransform];
    }
    [obj setShadowType:[self shadowType]];
    ACSDLabel *l = [textLabel copy];
    [obj setTextLabel:[l autorelease]];
    [l setGraphic:obj];
    obj.alpha = alpha;
    obj.hidden = self.hidden;
    obj.clipGraphic = self.clipGraphic;
    
	[obj setGraphicMode:graphicMode];
	[obj setToolTip:toolTip];
    [obj setIsMask:isMask];
	obj.filterSettings = [[filterSettings mutableCopy]autorelease];
	obj.sourcePath = self.sourcePath;
	obj.linkAlignmentFlags = self.linkAlignmentFlags;
	return obj;
}

-(void)mapCopiedObjectsFromDictionary:(NSDictionary*)map
   {
   }

-(BOOL)usuallyUsesCache
   {
	return YES;
   }

-(void)allocCacheWithMagnification:(float)mag
   {
	if (graphicCache)
		[graphicCache release];
	graphicCache = [[GraphicCache alloc]initWithWidth:[self bounds].size.width height:[self bounds].size.height];
	if (mag > 0.0)
		[graphicCache setMagnification:mag];
	[self readjustCache];
   }

-(void)freeCache
   {
	if (graphicCache)
	   {
		[graphicCache release];
		graphicCache = nil;
	   }
   }

-(void)allocHandlePoints
   {
	handlePoints = new NSPoint[8];
	noHandlePoints = 8;
   }

-(void)finishInit
   {
   }

- (void) encodeWithCoder:(NSCoder*)coder
{
	[super encodeWithCoder:coder];
	[coder encodeObject:[self name] forKey:@"ACSDGraphic_name"];
	[coder encodeConditionalObject:layer forKey:@"ACSDGraphic_layer"];
	[coder encodeConditionalObject:fill forKey:@"ACSDGraphic_fill"];
	[coder encodeConditionalObject:stroke forKey:@"ACSDGraphic_stroke"];
	[coder encodeConditionalObject:shadowType forKey:@"ACSDGraphic_shadowtype"];
	[ACSDGraphic encodeRect:bounds coder:coder forKey:@"ACSDGraphic_bounds"];
	[coder encodeFloat:rotation forKey:@"ACSDGraphic_rotation"];
	[coder encodeFloat:xScale forKey:@"ACSDGraphic_xScale"];
	[coder encodeFloat:yScale forKey:@"ACSDGraphic_yScale"];
	[ACSDGraphic encodePoint:rotationPoint coder:coder forKey:@"ACSDGraphic_rotationPoint"];
	[coder encodeObject:[self transform] forKey:@"ACSDGraphic_transform"];
	[coder encodeObject:[self events] forKey:@"ACSDGraphic_events"];
	[coder encodeObject:textLabel forKey:@"ACSDGraphic_label"];
	if (toolTip)
		[coder encodeObject:toolTip forKey:@"ACSDGraphic_toolTip"];
	[coder encodeFloat:alpha forKey:@"ACSDGraphic_alpha"];
    [coder encodeBool:isMask forKey:@"ACSDGraphic_Mask"];
    [coder encodeBool:self.hidden forKey:@"ACSDGraphic_hidden"];
	[coder encodeInt:graphicMode forKey:@"ACSDGraphic_graphicMode"];
    [coder encodeObject:[self link] forKey:@"ACSDGraphic_link"];
    [coder encodeObject:self.clipGraphic forKey:@"ACSDGraphic_clipGraphic"];
	if (linkedObjects)
		[coder encodeObject:linkedObjects forKey:@"ACSDGraphic_linkedObjects"];
	if (preOutlineFill)
		[coder encodeConditionalObject:preOutlineFill forKey:@"ACSDGraphic_preOutlineFill"];
	if (preOutlineStroke)
		[coder encodeConditionalObject:preOutlineStroke forKey:@"ACSDGraphic_preOutlineStroke"];
	if (triggers)
		[coder encodeObject:triggers forKey:@"ACSDGraphic_triggers"];
	if (filterSettings && [[filterSettings allKeys]count] > 0)
		[coder encodeObject:filterSettings forKey:@"ACSDGraphic_filterSettings"];
	if (_sourcePath)
		[coder encodeObject:_sourcePath forKey:@"ACSDImage_sourcepath"];
	if (self.linkAlignmentFlags != 0)
		[coder encodeInt:self.linkAlignmentFlags forKey:@"linkAlignmentFlags"];
}

- (id) initWithCoder:(NSCoder*)coder
{
	//	self = [self init];
	self = [super initWithCoder:coder];
	self.name = [coder decodeObjectForKey:@"ACSDGraphic_name"];
	layer = [coder decodeObjectForKey:@"ACSDGraphic_layer"];
	[self setFill:[coder decodeObjectForKey:@"ACSDGraphic_fill"]];
	[self setStroke:[coder decodeObjectForKey:@"ACSDGraphic_stroke"]];
	[self setShadowType:[coder decodeObjectForKey:@"ACSDGraphic_shadowtype"]];
	bounds = [ACSDGraphic decodeRectForKey:@"ACSDGraphic_bounds" coder:coder];
	rotation = [coder decodeFloatForKey:@"ACSDGraphic_rotation"];
	rotationPoint = [ACSDGraphic decodePointForKey:@"ACSDGraphic_rotationPoint" coder:coder];
	transform = [[coder decodeObjectForKey:@"ACSDGraphic_transform"]retain];
	if (rotation != 0.0 && !transform)
		[self computeTransform];
	xScale = [coder decodeFloatForKey:@"ACSDGraphic_xScale"];
	if (xScale == 0.0)
		xScale = 1.0;
	yScale = [coder decodeFloatForKey:@"ACSDGraphic_yScale"];
	if (yScale == 0.0)
		yScale = 1.0;
	if (!transform && (rotation != 0.0  || xScale != 1.0 || yScale != 1.0))
		[self computeTransform];
	usesCache = [self usuallyUsesCache];
	events = [[coder decodeObjectForKey:@"ACSDGraphic_events"]retain];
	//	manipulatingBounds = NO;
	textPad = -1.0;
	if ((textLabel = [[coder decodeObjectForKey:@"ACSDGraphic_label"]retain]) == nil)
		textLabel = [[ACSDLabel alloc]initWithGraphic:self];
	toolTip = [[coder decodeObjectForKey:@"ACSDGraphic_toolTip"]retain];
	if ([coder containsValueForKey:@"ACSDGraphic_alpha"])
		alpha = [coder decodeFloatForKey:@"ACSDGraphic_alpha"];
	else
		alpha = 1.0;
	addingPoints = NO;
	currentDrawingDestination = nil;
    isMask = [coder decodeBoolForKey:@"ACSDGraphic_Mask"];
    self.hidden = [coder decodeBoolForKey:@"ACSDGraphic_hidden"];
	graphicMode = (GraphicMode)[coder decodeIntForKey:@"ACSDGraphic_graphicMode"];
	link = [[coder decodeObjectForKey:@"ACSDGraphic_link"]retain];
	linkedObjects = [[coder decodeObjectForKey:@"ACSDGraphic_linkedObjects"]retain];
	[self setPreOutlineFill:[coder decodeObjectForKey:@"ACSDGraphic_preOutlineFill"]];
	[self setPreOutlineStroke:[coder decodeObjectForKey:@"ACSDGraphic_preOutlineStroke"]];
	triggers = [[coder decodeObjectForKey:@"ACSDGraphic_triggers"]retain];
	if (triggers)
		for (NSDictionary *t in triggers)
			[[t objectForKey:@"layer"]addTrigger:t];
	self.filterSettings = [coder decodeObjectForKey:@"ACSDGraphic_filterSettings"];
	if (filterSettings == nil)
		filterSettings = [[NSMutableDictionary alloc]initWithCapacity:5];
	self.sourcePath = [coder decodeObjectForKey:@"ACSDImage_sourcepath"];
	self.linkAlignmentFlags = [coder decodeIntForKey:@"linkAlignmentFlags"];
    self.clipGraphic = [coder decodeObjectForKey:@"ACSDGraphic_clipGraphic"];
	return self;
}

- (BOOL)isEqual:(id)anObject
   {
	return (self == anObject);
   }

- (NSUInteger)hash
   {
	return (NSUInteger)self;
   }

- (NSUndoManager*)undoManager
   {
    return [[layer document] undoManager];
   }

- (ACSDrawDocument*)document
   {
    return [layer document];
   }

-(ACSDFill*)fill
{
	return fill;
}

-(NSMutableArray*)triggers
{
	return triggers;
}

-(void)allocTriggers
{
	triggers = [[NSMutableArray arrayWithCapacity:3]retain];
}

-(NSSet*)usedFills
{
	NSMutableSet *fillSet = [NSMutableSet setWithCapacity:10];
	if (fill)
	{
		[fillSet addObject:fill];
		[fillSet unionSet:[fill usedFills]];
	}
	if (preOutlineFill)
	{
		[fillSet addObject:preOutlineFill];
		[fillSet unionSet:[preOutlineFill usedFills]];
	}
	if (stroke)
		[fillSet unionSet:[stroke usedFills]];
	return fillSet;
}

-(NSSet*)usedShadows
{
	NSMutableSet *shadowSet = [NSMutableSet setWithCapacity:10];
	if (shadowType)
		[shadowSet addObject:shadowType];
	if (fill)
		[shadowSet unionSet:[fill usedShadows]];
	if (stroke)
		[shadowSet unionSet:[stroke usedShadows]];
	return shadowSet;
}

-(NSSet*)usedStrokes
{
	NSMutableSet *strokeSet = [NSMutableSet setWithCapacity:10];
	if (fill)
		[strokeSet unionSet:[fill usedStrokes]];
	if (preOutlineFill)
		[strokeSet unionSet:[preOutlineFill usedStrokes]];
	if (stroke)
	{
		[strokeSet addObject:stroke];
		[strokeSet unionSet:[stroke usedStrokes]];
	}
	if (preOutlineStroke)
	{
		[strokeSet addObject:preOutlineStroke];
		[strokeSet unionSet:[preOutlineStroke usedStrokes]];
	}
	return strokeSet;
}

-(BOOL)graphicUsesStroke:(ACSDStroke*)str
{
	return (str == stroke) || (str == preOutlineStroke);
}

-(BOOL)graphicUsesFill:(ACSDFill*)f
{
	return (f == fill) || (f == preOutlineFill);
}

-(ACSDStroke*)stroke
   {
	return stroke;
   }

-(ACSDStroke*)graphicStroke
   {
	return [self stroke];
   }

-(NSRect)bounds
{
    return bounds;
}

-(NSRect)strictBounds
{
    return bounds;
}

-(NSRect)transformedBounds
{
    if (transform == nil)
    {
        NSRect b = bounds;
        if (b.size.width == 0.0)
            b.size.width = 0.001;
        if (b.size.height == 0.0)
            b.size.height = 0.001;
        return b;
    }
    return [[self transformedBezierPath]bounds];
}

-(NSRect)transformedStrictBounds
{
    return [self transformedBounds];
}


-(ACSDPath*)wholeFilledRect
   {
	float pad = 0.0;
	if (stroke && [stroke colour])
		pad = [stroke lineWidth] / 2.0;
	NSRect r = NSInsetRect([self bounds],-pad,-pad);
	NSBezierPath *p = [NSBezierPath bezierPathWithRect:r];
	if (transform)
		p = [transform transformBezierPath:p];
	if (moving)
		p = [[NSAffineTransform transformWithTranslateXBy:moveOffset.x yBy:moveOffset.y]transformBezierPath:p];
	return [ACSDPath pathWithPath:p];
   }

-(ACSDPath*)wholeOutline
   {
	if (fill && [fill colour])
		return [self convertToPath];
	return [[self convertToPath] outlineStroke];
   }

-(void)setDeleted:(BOOL)d
   {
	if (d == deleted)
		return;
	deleted = d;
	int inc = (deleted?-1:1);
	if (shadowType)
		[shadowType addToNonDeletedCount:inc];
	if (fill)
		[fill addToNonDeletedCount:inc];
	if (stroke)
		[stroke addToNonDeletedCount:inc];
   }

-(BOOL)deleted
   {
	return deleted;
   }

-(BOOL)canBeMask
   {
	return NO;
   }

-(NSRect)displayBounds
   {
	if (![self displayBoundsValid])
		[self computeDisplayBounds];
	if (moving)
		return(NSOffsetRect(displayBounds,moveOffset.x,moveOffset.y));
	return displayBounds;
   }

-(NSRect)viewableBounds
{
	return displayBounds;
}

-(NSMutableDictionary*)events
   {
	return events;
   }

-(NSTextStorage*)labelText
   {
    return [textLabel contents];
   }

-(ACSDLabel*)textLabel
   {
    return textLabel;
   }

-(void)setTextLabel:(ACSDLabel*)l
{
    if (l == textLabel)
        return;
    [textLabel release];
    textLabel = [l retain];
}
-(void)setGraphicName:(NSString*)n
   {
	if ([self.name isEqualToString:n])
		return;
	[[[self undoManager] prepareWithInvocationTarget:self] setGraphicName:[self name]];
	[self setName:n];
    [[NSNotificationCenter defaultCenter]postNotificationName:ACSDGraphicListChanged object:self];
    [[self undoManager] setActionName:@"Change Name"];
   }

-(void)setFill:(ACSDFill*)f
   {
	if (f == fill)
		return;
	if (fill)
	   {
		[fill removeGraphic:self];
		[fill release];
	   }
	fill = f;
	if (fill)
	   {
		[fill retain];
		[fill addGraphic:self];
	   }
   }

-(void)setAllFills:(ACSDFill*)f
   {
	[self setFill:f];
   }

-(void)setStroke:(ACSDStroke*)s
   {
	if (s == stroke)
		return;
	if (stroke)
	   {
		[stroke removeGraphic:self];
		[stroke release];
	   }
	stroke = s;
	if (stroke)
	   {
		[stroke retain];
		[stroke addGraphic:self];
	   }
   }

-(ShadowType*)shadowType
   {
	return shadowType;
   }

-(void)setShadowType:(ShadowType*)s
   {
	if (s == shadowType)
		return;
	if (shadowType)
	   {
		[shadowType removeGraphic:self];
		[shadowType release];
	   }
	shadowType = s;
	if (shadowType)
	   {
		[shadowType retain];
		[shadowType addGraphic:self];
	   }
   }

-(void)removeReferences
   {
	[self setShadowType:nil];
	[self setStroke:nil];
	[self setFill:nil];
   }

-(BOOL)setGraphicShadowType:(ShadowType*)s notify:(BOOL)notify
   {
	if (s == shadowType)
		return NO;
	[[[self undoManager] prepareWithInvocationTarget:self] setGraphicShadowType:[self shadowType]notify:YES];
	[self invalidateGraphicSizeChanged:NO shapeChanged:NO redraw:NO notify:NO];
	[self setShadowType:s];
	[self invalidateGraphicSizeChanged:YES shapeChanged:NO redraw:YES notify:notify];
	return YES;
   }

-(void)setBounds:(NSRect)r
   {
	bounds = r;
   }

-(void)createHandlePoints:(int)n
   {
	handlePoints = new NSPoint[n];
	noHandlePoints = n;
   }

- (void)resizeAdjustmentOldBounds:(NSRect)oldBounds newBounds:(NSRect)newBounds			//this is for anything that needs to change after the bounds have
   {																					//changed (during resize)
   }

-(void)preDelete
   {
	if (link)
		if ([link isKindOfClass:[ACSDLink class]])
			[ACSDLink uDeleteLinkForObject:self undoManager:[self undoManager]];
		else
			[self uSetLink:nil];
	if (linkedObjects)
	   {
        for (ACSDLink *l in [[linkedObjects copy]autorelease])
			[ACSDLink uDeleteFromFromObjectLink:l undoManager:[self undoManager]];
	   }
	[self setDeleted:YES];
   }

-(void)postUndelete
   {
	[self setDeleted:NO];
   }

-(void)setBoundsTo:(NSRect)newBounds from:(NSRect)oldBounds 
   {
    if (!NSEqualRects(newBounds, oldBounds))
	   {
		[self invalidateGraphicSizeChanged:NO shapeChanged:NO redraw:NO notify:NO];
        bounds = newBounds;
		[self resizeAdjustmentOldBounds:oldBounds newBounds:newBounds];
		[self invalidateGraphicSizeChanged:YES shapeChanged:YES redraw:YES notify:NO];
       }
   }

-(BOOL)setGraphicBoundsTo:(NSRect)newBounds from:(NSRect)oldBounds 
{
    if (NSEqualRects(newBounds, oldBounds))
		return NO;
	[self invalidateGraphicSizeChanged:NO shapeChanged:NO redraw:NO notify:NO];
	if (!manipulatingBounds)
		[[[self undoManager] prepareWithInvocationTarget:self] setGraphicBoundsTo:oldBounds from:newBounds];
	bounds = newBounds;
	rotationPoint = [self centrePoint];
	[self computeTransform];
	[self resizeAdjustmentOldBounds:oldBounds newBounds:newBounds];
	if (newBounds.size.width != oldBounds.size.width || newBounds.size.height != oldBounds.size.height)
	{
		[self invalidateGraphicSizeChanged:YES shapeChanged:YES redraw:YES notify:NO];
		[self invalidateConnectors];
	}
	else
		[self invalidateGraphicSizeChanged:YES shapeChanged:NO redraw:NO notify:NO];
	[self setDisplayBoundsValid:NO];
	[self postChangeOfBounds];
	return YES;
}

-(BOOL)setGraphicFill:(ACSDFill*)f notify:(BOOL)notify
   {
	if (f == [self fill])
		return NO;
	[[[self undoManager] prepareWithInvocationTarget:self] setGraphicFill:[self fill]notify:YES];
	[self invalidateGraphicSizeChanged:NO shapeChanged:NO redraw:NO notify:NO];
	[self setFill:f];
	[self invalidateGraphicSizeChanged:NO shapeChanged:NO redraw:YES notify:notify];
	return YES;
   }

-(BOOL)setGraphicLabelFlipped:(BOOL)fl notify:(BOOL)notify
   {
	[[[self undoManager] prepareWithInvocationTarget:self] setGraphicLabelFlipped:[[self textLabel]flipped]notify:YES];
	[self invalidateGraphicSizeChanged:NO shapeChanged:NO redraw:NO notify:NO];
	[textLabel setFlipped:fl];
	[self invalidateGraphicSizeChanged:YES shapeChanged:YES redraw:YES notify:notify];
	return YES;
   }

-(BOOL)setGraphicLabelText:(NSTextStorage*)tx notify:(BOOL)notify
   {
	[[[self undoManager] prepareWithInvocationTarget:self] setGraphicLabelText:[self labelText] notify:YES];
	[self invalidateGraphicSizeChanged:NO shapeChanged:NO redraw:NO notify:NO];
	[textLabel setLabel:tx];
	textPad = [textLabel paddingRequiredForPath:[self transformedBezierPath]];
	[self invalidateGraphicSizeChanged:YES shapeChanged:YES redraw:YES notify:notify];
	return YES;
   }

-(BOOL)setGraphicLabelVPos:(float)f notify:(BOOL)notify
   {
	[[[self undoManager] prepareWithInvocationTarget:self] setGraphicLabelVPos:[textLabel verticalPosition] notify:YES];
	[self invalidateGraphicSizeChanged:NO shapeChanged:NO redraw:NO notify:NO];
	[textLabel setVerticalPosition:f];
	textPad = [textLabel paddingRequiredForPath:[self transformedBezierPath]];
	[self invalidateGraphicSizeChanged:YES shapeChanged:YES redraw:YES notify:notify];
	return YES;
   }

-(BOOL)setGraphicLabelHPos:(float)f notify:(BOOL)notify
   {
	[[[self undoManager] prepareWithInvocationTarget:self] setGraphicLabelHPos:[textLabel horizontalPosition] notify:YES];
	[self invalidateGraphicSizeChanged:NO shapeChanged:NO redraw:NO notify:NO];
	[textLabel setHorizontalPosition:f];
	textPad = [textLabel paddingRequiredForPath:[self transformedBezierPath]];
	[self invalidateGraphicSizeChanged:YES shapeChanged:YES redraw:YES notify:notify];
	return YES;
   }

-(BOOL)setGraphicStroke:(ACSDStroke*)s notify:(BOOL)notify
   {
	if (s == [self stroke])
		return NO;
	[[[self undoManager] prepareWithInvocationTarget:self] setGraphicStroke:[self stroke]notify:YES];
	[self invalidateGraphicSizeChanged:NO shapeChanged:NO redraw:NO notify:NO];
	[self setStroke:s];
	[self invalidateGraphicSizeChanged:YES shapeChanged:NO redraw:YES notify:YES];
	return YES;
   }

-(NSComparisonResult)compareTimeStampWith:(id)obj
   {
	return [selectionTimeStamp compare:[obj selectionTimeStamp]];
   }

-(void)setGraphicTransform:(NSAffineTransform*)t
   {
	[[[self undoManager] prepareWithInvocationTarget:self] setGraphicTransform:transform];
	[self setTransform:t];
   }

-(BOOL)graphicCanDrawFill
   {
	return YES;
   }

-(BOOL)graphicCanDrawStroke
   {
	return YES;
   }

-(BOOL)visible
   {
	if (layer)
		return [layer visible] & !self.hidden;
	else
		return !self.hidden;
   }

-(BOOL)isEditable
   {
    return NO;
   }

-(BOOL)mayContainSubstitutions
   {
    return NO;
   }

-(BOOL)hasClosedPath
   {
	return YES;
   }

-(void)invalidateInView
   {
	[[[layer page]graphicViews]makeObjectsPerformSelector:@selector(invalidateGraphic:)withObject:self];
   }

-(void)invalidateGraphicSizeChanged:(BOOL)sizeChanged shapeChanged:(BOOL)shapeChanged redraw:(BOOL)redraw notify:(BOOL)notify
   {
	if (sizeChanged)
		[self setDisplayBoundsValid:NO];
	if (shapeChanged)
	   {
		[self setOutlinePathValid:NO];
		[self setBezierPathValid:NO];
	   }
	if (graphicCache && usesCache && sizeChanged)
		[self readjustCache];
	if (graphicCache && redraw)
		[graphicCache setValid:NO];
	[self invalidateInView];
	if (parent)
		[parent invalidateGraphicSizeChanged:sizeChanged shapeChanged:shapeChanged redraw:redraw notify:notify];
	if (notify)
		[[NSNotificationCenter defaultCenter] postNotificationName:ACSDGraphicDidChangeNotification object:self];
   }

-(void)setValue:(id)value forKey:(NSString *)key invalidateFlags:(NSInteger)invalFlags
{
	if (invalFlags)
		[self invalidateGraphicSizeChanged:NO shapeChanged:NO redraw:NO notify:NO];
	[self setValue:value forKey:key];
	if (invalFlags)
		[self invalidateGraphicSizeChanged:invalFlags & INVAL_FLAGS_SIZE_CHANGE	shapeChanged:INVAL_FLAGS_SHAPE_CHANGE redraw:INVAL_FLAGS_REDRAW notify:NO];
}

- (void)didChangeNeedRedraw:(BOOL)reDraw
   {
	if (graphicCache && reDraw)
		[graphicCache setValid:NO];
	[self invalidateInView];
    [[NSNotificationCenter defaultCenter] postNotificationName:ACSDGraphicDidChangeNotification object:self];
   }

-(void)tempMoveBy:(NSValue*)offsetV
   {
	NSPoint offset = [offsetV pointValue];
	[self invalidateInView];
	moveOffset = offset;
	[self invalidateInView];
   }

- (void)startMove
   {
	moving = YES;
	moveOffset.x = moveOffset.y = 0.0;
   }
    
- (void)stopMove:(NSNumber*)n
   {
	BOOL moved = [n boolValue];
	if (moved)
	   {
		moving = NO;
		if (moveOffset.x != 0.0 || moveOffset.y != 0.0)
			[self uMoveBy:moveOffset];
	   }
	else
	   {
		[self invalidateInView];
		moving = NO;
		[self invalidateInView];
	   }
	   moveOffset.x = moveOffset.y = 0.0;
   }
    
- (void)startBoundsManipulation
   {
    manipulatingBounds = YES;
    originalBounds = bounds;
   }

- (void)stopBoundsManipulation
   {
    if (manipulatingBounds)
	   {
        if (!NSEqualRects(originalBounds,bounds))
		   {
            manipulatingBounds = NO;
            [self setGraphicBoundsTo:bounds from:originalBounds];
           }
		else
			manipulatingBounds = NO;
       }
   }

-(void)computeHandlePoints
   {
	NSRect r = [self bounds];
	CGFloat x = r.origin.x;
	CGFloat y = r.origin.y;
	CGFloat incX = r.size.width / 2.0;
	CGFloat incY = r.size.height / 2.0;
	handlePoints[0].x = handlePoints[6].x = handlePoints[7].x = x;
	x += incX;
	handlePoints[1].x = handlePoints[5].x = x;
	x += incX;
	handlePoints[2].x = handlePoints[3].x = handlePoints[4].x = x;
	handlePoints[0].y = handlePoints[1].y = handlePoints[2].y = y;
	y += incY;
	handlePoints[3].y = handlePoints[7].y = y;
	y += incY;
	handlePoints[4].y = handlePoints[5].y = handlePoints[6].y = y;
   }
    
-(void)computeTransformedHandlePoints
   {
	[self computeHandlePoints];
	if (!transform)
		return;
	for (int i = 0;i < noHandlePoints;i++)
		handlePoints[i] = [transform transformPoint:handlePoints[i]];
   }
    
-(void)computeTransform
   {
	if (rotation == 0.0 && xScale == 1.0 && yScale == 1.0)
	   {
		[self setTransform:nil];
		return;
	   }
	NSAffineTransform *t = [NSAffineTransform transform];
	[t translateXBy:-rotationPoint.x yBy:-rotationPoint.y];
	NSAffineTransform *t2 = [NSAffineTransform transform];
	[t2 scaleXBy:xScale yBy:yScale];
	[t appendTransform:t2];
	t2 = [NSAffineTransform transform];
	[t2 rotateByDegrees:rotation];
	[t appendTransform:t2];
	t2 = [NSAffineTransform transform];
	[t2 translateXBy:rotationPoint.x yBy:rotationPoint.y];
	[t appendTransform:t2];
	[self setTransform:t];
   }
    
-(float)paddingRequired
   {
    float padding = ACSD_HALF_HANDLE_WIDTH;
    if (stroke)
	   {
        float sPad = [stroke paddingRequired];
        if (sPad > padding)
            padding = sPad;
       }
	if (textLabel && textPad < 0.0 && [textLabel contents] && [[textLabel contents]length] > 0)
		textPad = [textLabel paddingRequiredForPath:[self transformedBezierPath]];
	if (textPad > padding)
		padding = textPad;
    padding += 1.0;
	return padding;
   }

-(NSRect)controlPointBounds
{
	NSBezierPath *tp = [self transformedBezierPath];
	if ((!tp) || [tp isEmpty])
		return NSZeroRect;
	if ([tp elementCount] < 2)
	{
		NSPoint pts[3];
		NSBezierPathElement bzel = [tp elementAtIndex:0 associatedPoints:pts];
		if (bzel == NSMoveToBezierPathElement || bzel == NSLineToBezierPathElement || bzel == NSCurveToBezierPathElement)
		{
			NSRect r;
			r.origin = pts[0];
			r.size.width = r.size.height = 1.0;
			return r;
		}
		return NSZeroRect;
	}
	NSRect r = [tp controlPointBounds];
	if (graphicMode == GRAPHIC_MODE_OUTLINE)
		r = NSUnionRect([[self transformedOutlinePath]controlPointBounds],r);
	return r;
}

-(NSRect)displayBoundsSansShadow
   {
    float inset = -[self paddingRequired];
	NSRect r = [self controlPointBounds];
	if (r.size.width <= 0.0)
		r.size.width = 1.0;
	if (r.size.height <= 0.0)
		r.size.height = 1.0;
    return NSInsetRect(r, inset, inset);
   }
    
-(void)computeDisplayBounds
   {
    displayBounds = [self displayBoundsSansShadow];
	if (shadowType)
	   {
		NSRect r = displayBounds;
		r = NSOffsetRect(r,[shadowType xOffset],[shadowType yOffset]);
		float br = [shadowType blurRadius]/* * 3*/;
		r = NSInsetRect(r,-br,-br);
		displayBounds = NSUnionRect(displayBounds,r);
	   }
	if (handlePoints)
		[self computeTransformedHandlePoints];
	[self setDisplayBoundsValid:YES];
   }

-(NSSize)displayBoundsOffset
   {
	return point_offset([self displayBounds].origin,[self controlPointBounds].origin);
   }

- (double)magnification
   {
    if (graphicCache)
		return [graphicCache magnification];
	return 1.0;
   }

- (void)setMagnification:(double)mag
   {
    if (graphicCache)
		[graphicCache setMagnification:mag];
   }

-(NSPoint)centrePoint
   {
	NSPoint pt;
	NSRect r = [self bounds];
	pt.x = r.origin.x + r.size.width / 2.0;
	pt.y = r.origin.y + r.size.height / 2.0; 
	return pt;
   }

-(float)midX
{
	NSRect r = [self transformedBounds];
	return r.origin.x + r.size.width / 2.0;
}

-(float)midY
{
	NSRect r = [self transformedBounds];
	return r.origin.y + r.size.height / 2.0;
}

-(NSComparisonResult)compareUsingXPos:(ACSDGraphic*)g
{
	float myX = [self midX];
	float gX = [g midX];
	if (myX < gX)
		return NSOrderedAscending;
	if (myX > gX)
		return NSOrderedDescending;
	return NSOrderedSame;
}

-(NSComparisonResult)compareUsingYPos:(ACSDGraphic*)g
{
	float myY = [self midY];
	float gY = [g midY];
	if (myY < gY)
		return NSOrderedAscending;
	if (myY > gY)
		return NSOrderedDescending;
	return NSOrderedSame;
}

- (BOOL)setGraphicHidden:(BOOL)b
{
    if (b == self.hidden)
        return NO;
    [self invalidateInView];
    [[[self undoManager] prepareWithInvocationTarget:self] setGraphicHidden:self.hidden];
    [[NSNotificationCenter defaultCenter]postNotificationName:ACSDGraphicListChanged object:self];
    self.hidden = b;
    [self invalidateGraphicSizeChanged:NO shapeChanged:NO redraw:YES notify:NO];
    return YES;
}


- (void)setGraphicMask:(BOOL)b
   {
	if (b == isMask)
		return;
    [self invalidateInView];
	[[[self undoManager] prepareWithInvocationTarget:self] setGraphicMask:[self isMask]];
	[self setIsMask:b];
	[self invalidateGraphicSizeChanged:NO shapeChanged:NO redraw:YES notify:NO];
   }

- (void)setGraphicMaskObj:(id)n
   {
	BOOL b = [n boolValue];
	[self setGraphicMask:b];
   }

- (void)setGraphicAlpha:(float)f notify:(BOOL)notify
   {
	[[[self undoManager] prepareWithInvocationTarget:self] setGraphicAlpha:[self alpha] notify:YES];
	[self setAlpha:f];
	[self invalidateGraphicSizeChanged:NO shapeChanged:NO redraw:YES notify:notify];
   }

-(BOOL)hasAFilter
{
	return (exposure != 0.0 || saturation != 1.0 || brightness != 0.0 ||contrast != 1.0 
			|| (unsharpmaskRadius > 0.0 && unsharpmaskIntensity > 0.0) || gaussianBlurRadius > 0.0);
}

-(BOOL)setGraphicGaussianBlurRadius:(float)f notify:(BOOL)notify
{
	if (f == gaussianBlurRadius)
		return NO;
	[[[self undoManager] prepareWithInvocationTarget:self] setGraphicGaussianBlurRadius:[self gaussianBlurRadius] notify:YES];
	self.gaussianBlurRadius = f;
	[self invalidateGraphicSizeChanged:NO shapeChanged:NO redraw:YES notify:notify];
	return YES;
}

- (void)setGraphicExposure:(float)f notify:(BOOL)notify
{
	if (f == exposure)
		return;
	[self invalidateGraphicSizeChanged:NO shapeChanged:NO redraw:NO notify:notify];
	[[[self undoManager] prepareWithInvocationTarget:self] setGraphicExposure:[self exposure]notify:YES];
	[self setExposure:f];
	[self invalidateGraphicSizeChanged:NO shapeChanged:NO redraw:YES notify:notify];
}

- (BOOL)setGraphicSaturation:(float)f notify:(BOOL)notify
{
	if (f == saturation)
		return NO;
	[self invalidateGraphicSizeChanged:NO shapeChanged:NO redraw:NO notify:notify];
	[[[self undoManager] prepareWithInvocationTarget:self] setGraphicSaturation:[self saturation]notify:YES];
	[self setSaturation:f];
	[self invalidateGraphicSizeChanged:NO shapeChanged:NO redraw:YES notify:notify];
	return YES;
}
- (BOOL)setGraphicBrightness:(float)f notify:(BOOL)notify
{
	if (f == brightness)
		return NO;
	[self invalidateGraphicSizeChanged:NO shapeChanged:NO redraw:NO notify:notify];
	[[[self undoManager] prepareWithInvocationTarget:self] setGraphicBrightness:[self brightness]notify:YES];
	[self setBrightness:f];
	[self invalidateGraphicSizeChanged:NO shapeChanged:NO redraw:YES notify:notify];
	return YES;
}
- (BOOL)setGraphicContrast:(float)f notify:(BOOL)notify
{
	if (f == contrast)
		return NO;
	[self invalidateGraphicSizeChanged:NO shapeChanged:NO redraw:NO notify:notify];
	[[[self undoManager] prepareWithInvocationTarget:self] setGraphicContrast:[self contrast]notify:YES];
	[self setContrast:f];
	[self invalidateGraphicSizeChanged:NO shapeChanged:NO redraw:YES notify:notify];
	return YES;
}
- (BOOL)setGraphicUnsharpmaskIntensity:(float)f notify:(BOOL)notify
{
	if (f == unsharpmaskIntensity)
		return NO;
	[self invalidateGraphicSizeChanged:NO shapeChanged:NO redraw:NO notify:notify];
	[[[self undoManager] prepareWithInvocationTarget:self] setGraphicUnsharpmaskIntensity:[self unsharpmaskIntensity]notify:YES];
	[self setUnsharpmaskIntensity:f];
	[self invalidateGraphicSizeChanged:NO shapeChanged:NO redraw:YES notify:notify];
	return YES;
}
- (BOOL)setGraphicUnsharpmaskRadius:(float)f notify:(BOOL)notify
{
	if (f == unsharpmaskRadius)
		return NO;
	[self invalidateGraphicSizeChanged:NO shapeChanged:NO redraw:NO notify:notify];
	[[[self undoManager] prepareWithInvocationTarget:self] setGraphicUnsharpmaskRadius:[self unsharpmaskRadius]notify:YES];
	[self setUnsharpmaskRadius:f];
	[self invalidateGraphicSizeChanged:NO shapeChanged:NO redraw:YES notify:notify];
	return YES;
}

-(BOOL)setGraphicLevelsBlack:(float)newBlackLevel white:(float)newWhiteLevel grey:(float)newGreyLevel notify:(BOOL)notify
{
	float blackLevel = 0.0,whiteLevel = 1.0,greyLevel = 0.5;
	NSDictionary *d = [filterSettings objectForKey:@"ACSLevels"];
	if (d)
	{
		blackLevel = [[d objectForKey:@"blackLevel"]floatValue];
		whiteLevel = [[d objectForKey:@"whiteLevel"]floatValue];
		greyLevel = [[d objectForKey:@"greyLevel"]floatValue];
	}
	if (newBlackLevel == blackLevel && newWhiteLevel == whiteLevel && newGreyLevel == greyLevel)
		return NO;
	[self invalidateGraphicSizeChanged:NO shapeChanged:NO redraw:NO notify:notify];
	[[[self undoManager] prepareWithInvocationTarget:self] setGraphicLevelsBlack:blackLevel white:whiteLevel grey:greyLevel notify:YES];
	if (blackLevel == 0.0 && whiteLevel == 1.0 && greyLevel == 0.5)
		[filterSettings removeObjectForKey:@"ACSLevels"];
	else
		[filterSettings setObject:[NSDictionary dictionaryWithObjectsAndKeys:
								   [NSNumber numberWithFloat:newBlackLevel],@"blackLevel",
								   [NSNumber numberWithFloat:newWhiteLevel],@"whiteLevel",
								   [NSNumber numberWithFloat:newGreyLevel],@"greyLevel",
								   nil] forKey:@"ACSLevels"];
	[self invalidateGraphicSizeChanged:NO shapeChanged:NO redraw:YES notify:notify];
	return YES;
}

-(void)setToolTip:(NSString*)tip
   {
	if (toolTip == tip)
		return;
	if (toolTip)
		[toolTip release];
	if (tip && ![tip isEqualToString:@""])
		toolTip = [tip copy];
	else
		toolTip = nil;
   }

- (void)setGraphicToolTip:(NSString*)tip
{
    [[[self undoManager] prepareWithInvocationTarget:self] setGraphicToolTip:toolTip];
    [self setToolTip:tip];
}

- (BOOL)setGraphicSourcePath:(NSString*)sou
{
    if ([sou isEqualToString:self.sourcePath])
        return NO;
    [[[self undoManager] prepareWithInvocationTarget:self] setGraphicSourcePath:self.sourcePath];
    [self setSourcePath:sou];
    return YES;
}

-(NSString*)toolTip
   {
	if (toolTip)
		return toolTip;
	return @"";
   }

-(void)postSizePanelChangeId:(NSUInteger)changeid
{
	NSDictionary *userInfo = [NSDictionary dictionaryWithObject:[NSNumber numberWithInteger:changeid] forKey:@"param"];
	[[NSNotificationCenter defaultCenter] postNotificationName:ACSDSizePanelParamChangeNotification object:self userInfo:userInfo];
}

- (BOOL)setGraphicRotation:(float)rot notify:(BOOL)notify
{
	if (rot == rotation)
		return NO;
	[self invalidateGraphicSizeChanged:NO shapeChanged:NO redraw:NO notify:YES];
	[[[self undoManager] prepareWithInvocationTarget:self] setGraphicRotation:[self rotation]notify:YES];
	[self setRotation:rot];
	[self invalidateGraphicSizeChanged:YES shapeChanged:YES redraw:YES notify:YES];
	if (notify)
		[self postSizePanelChangeId:SC_ROTATION_CHANGE];
	return YES;
}

-(void)setRotation:(float)f
{
	if (f != rotation)
	{
		rotationPoint = [self centrePoint];
		rotation = f;
		[self computeTransform];
	}
}

-(void)setXScale:(float)f
{
	if (f != xScale)
	{
		rotationPoint = [self centrePoint];
		xScale = f;
		[self computeTransform];
	}
}

-(void)setYScale:(float)f
{
	if (f != yScale)
	{
		rotationPoint = [self centrePoint];
		yScale = f;
		[self computeTransform];
	}
}

- (BOOL)setGraphicXScale:(float)f notify:(BOOL)notify
{
	if (f == xScale)
		return NO;
	[self invalidateGraphicSizeChanged:NO shapeChanged:NO redraw:NO notify:notify];
	[[[self undoManager] prepareWithInvocationTarget:self] setGraphicXScale:[self xScale]notify:YES];
	[self setXScale:f];
	[self invalidateGraphicSizeChanged:YES shapeChanged:YES redraw:YES notify:notify];
	if (notify)
		[self postSizePanelChangeId:SC_SCALEX_CHANGE];
	return YES;
}

- (BOOL)setGraphicYScale:(float)f notify:(BOOL)notify
{
	if (f == yScale)
		return NO;
	[self invalidateGraphicSizeChanged:NO shapeChanged:NO redraw:NO notify:notify];
	[[[self undoManager] prepareWithInvocationTarget:self] setGraphicYScale:[self yScale]notify:YES];
	[self setYScale:f];
	[self invalidateGraphicSizeChanged:YES shapeChanged:YES redraw:YES notify:notify];
	if (notify)
		[self postSizePanelChangeId:SC_SCALEY_CHANGE];
	return YES;
}

- (void)setGraphicXScale:(float)fx yScale:(float)fy undo:(bool)undo
   {
	[self invalidateGraphicSizeChanged:NO shapeChanged:NO redraw:NO notify:NO];
	if (undo)
		[[[self undoManager] prepareWithInvocationTarget:self] setGraphicXScale:[self xScale] yScale:[self yScale] undo:YES];
	rotationPoint = [self centrePoint];
	[self setXScale:fx];
	[self setYScale:fy];
	[self computeTransform];
	[self invalidateGraphicSizeChanged:YES shapeChanged:NO redraw:YES notify:NO];
	[self postSizePanelChangeId:SC_SCALEX_CHANGE|SC_SCALEY_CHANGE];
   }

-(FlippableView*)setCurrentDrawingDestination:(FlippableView*)dest
{
    if (currentDrawingDestination == dest)
        return dest;
    FlippableView* temp = currentDrawingDestination;
    currentDrawingDestination = [dest retain];
    if (fill && [fill respondsToSelector:(@selector(setCurrentDrawingDestination:))])
        [(id)fill setCurrentDrawingDestination:dest];
    return [temp autorelease];
}

-(FlippableView*)currentDrawingDestination
   {
	if (currentDrawingDestination)
		return currentDrawingDestination;
	return nil;
//	return graphicView;
   }

float normalisedAngle(float ang)
{
	while (ang > 180.0)
		ang -= 360.0;
	while (ang < -180.0)
		ang += 360.0;
	return ang;
}
-(void)rotateByDegrees:(float)rotationAmount aroundPoint:(NSPoint)centre
   {
	NSAffineTransform *tf = [NSAffineTransform transform];
	NSAffineTransform *tf2 = [NSAffineTransform transform];
	NSAffineTransform *tf3 = [NSAffineTransform transform];
	[tf translateXBy:-centre.x yBy:-centre.y];
	[tf2 rotateByDegrees:rotationAmount];
	[tf3 translateXBy:centre.x yBy:centre.y];
	[tf appendTransform:tf2];
	[tf appendTransform:tf3];
	rotationPoint = [self centrePoint];
	NSPoint newCentrePoint = [tf transformPoint:rotationPoint];
	[self uMoveBy:NSMakePoint(newCentrePoint.x - rotationPoint.x,newCentrePoint.y - rotationPoint.y)];
	[self setGraphicRotation:normalisedAngle(rotationAmount+rotation) notify:YES];
   }

-(NSBezierPath*)outlinePath
   {
	if (!outlinePathValid)
	   {
		id g = self;
		g = [g convertToPath];
		[g setFill:preOutlineFill];
		[g setStroke:preOutlineStroke];
		g = [g outlineStroke];
		if (outlinePath)
			[outlinePath release];
		outlinePath = [[g bezierPath]retain];
		outlinePathValid = YES;
	   }
	return outlinePath;
   }

-(NSBezierPath*)transformedOutlinePath
   {
	if (!transform)
		return [self outlinePath];
	return [transform transformBezierPath:[self outlinePath]];
   }

-(NSInteger)totalElementCount:(NSBezierPath*)p
{
	return (NSInteger)[p elementCount];
}

-(ACSDFill*)chosenFillOptions:(NSMutableDictionary*)options
{
	ACSDFill *thisfill = fill;
	if (parent && [self.name hasPrefix:@"col"])
	{
		ACSDGroup *primoGenitor = [self primogenitor];
		if (primoGenitor && [primoGenitor fill] && primoGenitor.colourMode == COLOUR_MODE_SUB)
			thisfill = [primoGenitor fill];
	}
	ACSDFill *subfill = options[@"subfill"];
	if (subfill && [self.name hasPrefix:@"col"])
	{
		if ([options[@"subfill"] isKindOfClass:[ACSDGradient class]])
		{
			ACSDGradient *gr = (ACSDGradient*)options[@"subfill"];
			NSArray<GradientElement*> *grels = [gr gradientElements];
			NSString *nm = [self.name substringFromIndex:3];
			NSInteger i = [nm integerValue];
			if (i > 0 && i <= [grels count])
			{
				NSColor *c = [grels[i-1] colour];
				thisfill = [[ACSDFill alloc]initWithColour:c];
			}
		}
		else
		{
			if ([subfill colour])
				thisfill = options[@"subfill"];
		}
	}
	return thisfill;
}

- (void)drawObject:(NSRect)aRect view:(GraphicView*)gView options:(NSMutableDictionary*)options
{
    NSBezierPath *path;
    if (graphicMode == GRAPHIC_MODE_NORMAL)
        path = [self bezierPath];
    else
        path = [self outlinePath];
    if ([self totalElementCount:path] < 2)
        return;
    ACSDFill *thisfill = [self chosenFillOptions:options];
    if (thisfill)
        [thisfill fillPath:path];
    if ([stroke colour])
	   {
           [stroke strokePath:path];
           [[stroke colour]set];
           NSPoint pt1,pt2;
           ACSDLineEnding *le1 = [stroke lineStart];
           ACSDLineEnding *le2 = [stroke lineEnd];
           if (le1 && [le1 graphic] && getFirstTwoPoints(path,&pt1,&pt2))
               [le1 drawLineEndingAtPoint:pt1 angle:getAngleForPoints(pt1,pt2) lineWidth:[stroke lineWidth]];
           if (le2 && [le2 graphic] && getLastTwoPoints(path,&pt1,&pt2))
               [le2 drawLineEndingAtPoint:pt1 angle:getAngleForPoints(pt1,pt2) lineWidth:[stroke lineWidth]];
       }
    if (textLabel)
        [textLabel drawForPath:path];
}

-(ObjectPDFData*)objectPdfData
   {
	return objectPdfData;
   }

-(void)buildPDFData
   {
	if (!objectPdfData)
		objectPdfData = [[ObjectPDFData alloc]initWithObject:self];
//	if (fill)
//		[fill buildPDFData];
   }

-(void)freePDFData
   {
	if (objectPdfData)
	   {
		[objectPdfData release];
		objectPdfData = nil;
	   }
//	if (fill)
//		[fill freePDFData];
   }

-(BOOL)drawStrokeWithoutTransform
{
	return NO;
}

- (void)drawObjectWithEffect:(NSRect)aRect inView:(GraphicView*)gView useCache:(BOOL)useCache
			   options:(NSMutableDictionary*)options
   {
	[NSGraphicsContext saveGraphicsState];
	if (graphicCache && useCache)
	   {
		CGContextRef currentContext = (CGContextRef)[[NSGraphicsContext currentContext] graphicsPort];
		if (shadowType && [shadowType itsShadow])
			[[shadowType shadowWithScale:[[options objectForKey:@"scale"]floatValue]]set];
		CGContextBeginTransparencyLayer (currentContext, NULL);
		[NSGraphicsContext saveGraphicsState];
		[[NSAffineTransform transformWithTranslateXBy:[self displayBounds].origin.x yBy:[self displayBounds].origin.y] concat];
		NSRect s = [graphicCache imageBounds];
		[NSBezierPath clipRect:s];
		if ([graphicCache magnification] != 1.0)
		   {
			[[NSAffineTransform transformWithScaleBy:1.0/[graphicCache magnification]] concat];
		   }
		NSRect r = [graphicCache allocatedBounds];
		[graphicCache.bitmap drawInRect:r];
		[NSGraphicsContext restoreGraphicsState];
		if ([self drawStrokeWithoutTransform] && [stroke colour])
		{
			if (moving)
				[[NSAffineTransform transformWithTranslateXBy:moveOffset.x yBy:moveOffset.y] concat];
			[stroke strokePath:[self transformedBezierPath]];
		}
		CGContextEndTransparencyLayer (currentContext);
	   }
	else
	   {
		if (objectPdfData)
		   {
			NSImage *img = [[NSImage alloc]initWithData:[objectPdfData pdfData]];
			if (shadowType && [shadowType itsShadow])
				[[shadowType itsShadow]set];
			   NSRect r = NSZeroRect;
			   r.size = [img size];
			   [[img bestRepresentationForRect:r context:nil hints:nil]drawAtPoint:[objectPdfData offset]];	//the imagerep must be used instead of the image because the image one gives jaggies under magnification
			[img release];
		   }
		else
		   {
			if (moving)
				[[NSAffineTransform transformWithTranslateXBy:moveOffset.x yBy:moveOffset.y] concat];
			if (shadowType && [shadowType itsShadow])
				[[shadowType shadowWithScale:[[options objectForKey:@"scale"]floatValue]]set];
			CGContextRef currentContext = (CGContextRef)[[NSGraphicsContext currentContext] graphicsPort];
			CGContextBeginTransparencyLayer (currentContext, NULL);
			if (alpha < 1.0)
				CGContextSetAlpha(currentContext,alpha);
			CGContextBeginTransparencyLayer (currentContext, NULL);
			[NSGraphicsContext saveGraphicsState];
			if (transform)
				[transform concat];
			[self drawObject:aRect view:gView options:options];
			[NSGraphicsContext restoreGraphicsState];
			if ([self drawStrokeWithoutTransform] && [stroke colour])
				[stroke strokePath:[self transformedBezierPath]];				
			CGContextEndTransparencyLayer (currentContext);
			CGContextEndTransparencyLayer (currentContext);
		   }
	   }
	[NSGraphicsContext restoreGraphicsState];
   }

- (void)transformForCacheDrawing
   {
	if ([graphicCache magnification] != 1.0)
		[[NSAffineTransform transformWithScaleBy:[graphicCache magnification]]concat];
	if (![self displayBoundsValid])
		[self computeDisplayBounds];
//	[[NSAffineTransform transformWithTranslateXBy:-[self displayBounds].origin.x yBy:-[self displayBounds].origin.y]concat];
	[[NSAffineTransform transformWithTranslateXBy:-displayBounds.origin.x yBy:-displayBounds.origin.y]concat];
   }

- (void)drawInCache:(NSRect)aRect view:(GraphicView*)gView options:(NSMutableDictionary*)options
   {
	drawingToCache = YES;
	[NSGraphicsContext saveGraphicsState];
   [NSGraphicsContext setCurrentContext:[NSGraphicsContext graphicsContextWithBitmapImageRep:graphicCache.bitmap]];
	//[[graphicCache image]lockFocus];
	[[NSColor clearColor]set];
	NSRectFill([graphicCache magnifiedImageBounds]);
	[self transformForCacheDrawing];
    if (self.clipGraphic)
       [[self.clipGraphic bezierPath]addClip];
	FlippableView *temp = [self setCurrentDrawingDestination:(GraphicView*)[graphicCache image]];
	if (transform)
		[transform concat];
	CGContextRef currentContext = (CGContextRef)[[NSGraphicsContext currentContext] graphicsPort];
	if (alpha < 1.0)
		CGContextSetAlpha(currentContext,alpha);
	CGContextBeginTransparencyLayer (currentContext, NULL);
	[self drawObject:aRect view:gView options:options];
	CGContextEndTransparencyLayer (currentContext);
	[self setCurrentDrawingDestination:temp];
	[graphicCache setValid:YES];
	//[[graphicCache image]unlockFocus];
	drawingToCache = NO;
   [NSGraphicsContext restoreGraphicsState];
   }

- (void)draw:(NSRect)aRect inView:(GraphicView*)gView selected:(BOOL)isSelected isGuide:(BOOL)isGuide cacheDrawing:(BOOL)cacheDrawing
		options:(NSMutableDictionary*)options
   {
	if (![self visible])
		return;
	if (gView)
		[self setCurrentDrawingDestination:gView];
	if (usesCache && (graphicCache == nil) && cacheDrawing)
		[self allocCacheWithMagnification:[gView magnification]];
	if (graphicCache && cacheDrawing && !(([[[self layer]page]pageType] == PAGE_TYPE_MASTER) && [self mayContainSubstitutions]))
	   {
		[graphicCache checkAndSetMagnification:[gView magnification]];
		if (![graphicCache valid])
		   {
			[self drawInCache:aRect view:gView options:options];
		   }
		if ((!isGuide) || ([self isKindOfClass:[ACSDImage class]]))
			[self drawObjectWithEffect:aRect inView:gView useCache:YES options:options];
	   }
	else
    {
        if (self.clipGraphic)
            [[self.clipGraphic bezierPath]addClip];
		[self drawObjectWithEffect:aRect inView:gView useCache:NO options:options];
    }
   }

- (void)postChangeOfBounds
   {
	if (!layer)
		return;
	if ([[layer selectedGraphics]count] == 1)
	   {
		NSRect r = bounds;
		if (moving)
			r = NSOffsetRect(r,moveOffset.x,moveOffset.y);
		[ACSDGraphic postChangeOfBounds:r];
	   }
   }

- (void)moveBy:(NSPoint)vector
   {
	if (vector.x == 0.0 && vector.y == 0.0)
		return;
	if (layer)
		[self invalidateGraphicSizeChanged:NO shapeChanged:NO redraw:NO notify:NO];
	rotationPoint.x += vector.x;
	rotationPoint.y += vector.y;
	[self computeTransform];
	[self computeTransformedHandlePoints];
	bounds = NSOffsetRect([self bounds], vector.x, vector.y);
    if (self.clipGraphic)
        [self.clipGraphic moveBy:vector];
	if (layer)
	   {
		[self invalidateGraphicSizeChanged:YES shapeChanged:YES redraw:YES notify:NO];
		[self invalidateConnectors];
		[self postChangeOfBounds];
	   }
   }

- (void)uMoveBy:(NSPoint)vector
{
	NSPoint antiVector;
	antiVector.x = -vector.x;
	//antiVector.x *= xScale;
	antiVector.y = -vector.y;
	//antiVector.y *= yScale;
	[[[self undoManager] prepareWithInvocationTarget:self] uMoveBy:antiVector];
	[self moveBy:vector];
}

-(void)moveByValue:(NSValue*)val
   {
	[self moveBy:[val pointValue]];
   }

-(void)uMoveByValue:(NSValue*)val
   {
	[self uMoveBy:[val pointValue]];
   }

- (void)clearReferences
   {
	[self setFill:nil];
	[self setStroke:nil];
	[self setShadowType:nil];
   }

- (BOOL)setTop:(float)t
{
    NSRect b = [self bounds];
//	b.size.height = t - b.origin.y;
	b.origin.y += (t - NSMaxY(b));
	return [self setGraphicBoundsTo:b from:bounds];
}

- (BOOL)setHeight:(float)ht
{
    if (ht == bounds.size.height)
		return NO;
    NSRect b = [self bounds];
	b.size.height = ht;
	return [self setGraphicBoundsTo:b from:bounds];
}

- (BOOL)setRight:(float)r
{
    NSRect b = [self bounds];
//	b.size.width = r - b.origin.x;
	b.origin.x += (r - NSMaxX(b));
	return [self setGraphicBoundsTo:b from:bounds];
}

- (BOOL)setWidth:(float)w
{
    if (w == bounds.size.width)
		return NO;
    NSRect b = [self bounds];
	b.size.width = w;
	return [self setGraphicBoundsTo:b from:bounds];
}

- (BOOL)setX:(float)f
{
    if (f == bounds.origin.x)
        return NO;
    [self uMoveBy:NSMakePoint(f-[self bounds].origin.x,0.0)];
    return YES;
}

- (BOOL)setCentreX:(float)f
{
    if (f == NSMidX(bounds))
        return NO;
    [self uMoveBy:NSMakePoint(f-NSMidX([self bounds]),0.0)];
    return YES;
}

- (BOOL)setY:(float)f
{
	if (f == bounds.origin.y)
		return NO;
	[self uMoveBy:NSMakePoint(0.0,f-[self bounds].origin.y)];
	return YES;
}

- (BOOL)setCentreY:(float)f
{
    if (f == NSMidY(bounds))
        return NO;
    [self uMoveBy:NSMakePoint(0.0,f-NSMidY([self bounds]))];
    return YES;
}

- (void)flipHorizontally {
    // Some subclasses need to know.
    return;
}

- (void)flipVertically {
    // Some subclasses need to know.
    return;
}

- (void)flipH
   {
   }

- (void)flipV
   {
   }

+ (NSInteger)flipKnob:(NSInteger)knob horizontal:(BOOL)horizFlag
   {
    static BOOL initedFlips = NO;
    static int horizFlips[9];
    static int vertFlips[9];
    if (!initedFlips)
	   {
        horizFlips[UpperLeftKnob] = UpperRightKnob;
        horizFlips[UpperMiddleKnob] = UpperMiddleKnob;
        horizFlips[UpperRightKnob] = UpperLeftKnob;
        horizFlips[MiddleLeftKnob] = MiddleRightKnob;
        horizFlips[MiddleRightKnob] = MiddleLeftKnob;
        horizFlips[LowerLeftKnob] = LowerRightKnob;
        horizFlips[LowerMiddleKnob] = LowerMiddleKnob;
        horizFlips[LowerRightKnob] = LowerLeftKnob;
        
        vertFlips[UpperLeftKnob] = LowerLeftKnob;
        vertFlips[UpperMiddleKnob] = LowerMiddleKnob;
        vertFlips[UpperRightKnob] = LowerRightKnob;
        vertFlips[MiddleLeftKnob] = MiddleLeftKnob;
        vertFlips[MiddleRightKnob] = MiddleRightKnob;
        vertFlips[LowerLeftKnob] = UpperLeftKnob;
        vertFlips[LowerMiddleKnob] = UpperMiddleKnob;
        vertFlips[LowerRightKnob] = UpperRightKnob;
        initedFlips = YES;
       }
    if (horizFlag)
        return horizFlips[knob];
	 else
        return vertFlips[knob];
   }

BOOL upperKnob(NSInteger knob)
   {
	return ((knob == UpperLeftKnob) || (knob == UpperMiddleKnob) || (knob == UpperRightKnob));
   }

BOOL lowerKnob(NSInteger knob)
   {
	return ((knob == LowerLeftKnob) || (knob == LowerMiddleKnob) || (knob == LowerRightKnob));
   }

BOOL leftKnob(NSInteger knob)
   {
	return ((knob == UpperLeftKnob) || (knob == MiddleLeftKnob) || (knob == LowerLeftKnob)); 
   }

BOOL rightKnob(NSInteger knob)
   {
	return ((knob == UpperRightKnob) || (knob == MiddleRightKnob) || (knob == LowerRightKnob)); 
   }

#define MAGPROP(a) ((a) < 1.0)?(1.0/(a)):(a)

-(NSRect)constrainRect:(NSRect)newBounds usingKnob:(NSInteger)knob
   {
	if (originalBounds.size.height == 0.0 || originalBounds.size.width == 0.0)
		return newBounds;
	float newX = newBounds.origin.x,
		newY = newBounds.origin.y,
		newWidth = newBounds.size.width,
		newHeight = newBounds.size.height;
	float xProportion = newWidth / originalBounds.size.width;
	float yProportion = newHeight / originalBounds.size.height;
	float xx = MAGPROP(xProportion);
	float yy = MAGPROP(yProportion);
//	if (MAGPROP(yProportion) > MAGPROP(xProportion))
	if (yy > xx)
	   {
		newWidth = originalBounds.size.width * yProportion;
		if (leftKnob(knob))
			newX -=(newWidth - newBounds.size.width);
	   }
	else
	   {
		newHeight = originalBounds.size.height * xProportion;
		if (lowerKnob(knob))
			newY -=(newHeight - newBounds.size.height);
	   }
	return NSMakeRect(newX,newY,newWidth,newHeight);
   }

-(NSPoint)invertPoint:(NSPoint)point
   {
	if (transform)
	   {
		NSAffineTransform *t = [[[NSAffineTransform alloc]initWithTransform:transform]autorelease];
		[t invert];
		point = [t transformPoint:point];
	   }
	return point;
   }

-(NSPoint)invertOffset:(NSPoint)offset
   {
	if (transform)
	   {
		NSAffineTransform *t = [[[NSAffineTransform alloc]initWithTransform:transform]autorelease];
		NSPoint point = [t transformPoint:rotationPoint];
		point = NSMakePoint(point.x + offset.x,point.y + offset.y);
		[t invert];
		point = [t transformPoint:point];
		return NSMakePoint(point.x- rotationPoint.x,point.y- rotationPoint.y);
	   }
	return offset;
   }

- (KnobDescriptor)resizeByMovingKnob:(KnobDescriptor)kd toPoint:(NSPoint)point event:(NSEvent *)theEvent constrain:(BOOL)constrain aroundCentre:(BOOL)aroundCentre
{
    NSRect theBounds = originalBounds;
	float diff;
	if (transform)
		point = [self invertPoint:point];
    if (leftKnob(kd.knob))
	{
        // Adjust left edge
		diff = theBounds.origin.x - point.x;
        theBounds.size.width += diff;
		if (aroundCentre)
			theBounds.size.width += diff;
        theBounds.origin.x = point.x;
	}
	else if (rightKnob(kd.knob))
	{
        // Adjust right edge
		diff = point.x - NSMaxX(theBounds);
        theBounds.size.width += diff;
		if (aroundCentre)
		{
			theBounds.size.width += diff;
			theBounds.origin.x -= diff;
		}
	}
    if (theBounds.size.width < 0.0)
	{
//        kd.knob = [ACSDGraphic flipKnob:kd.knob horizontal:YES];
        theBounds.origin.x = NSMaxX(theBounds);
        theBounds.size.width = -theBounds.size.width;
		[self flipHorizontally];
	}
    if (upperKnob(kd.knob))
	{
        // Adjust top edge
		diff = point.y - NSMaxY(theBounds);
        theBounds.size.height += diff;
		if (aroundCentre)
		{
			theBounds.size.height += diff;
			theBounds.origin.y -= diff;
		}
	}
	else if (lowerKnob(kd.knob))
	{
        // Adjust bottom edge
		diff = theBounds.origin.y - point.y;
        theBounds.size.height += diff;
		if (aroundCentre)
			theBounds.size.height += diff;
        theBounds.origin.y = point.y;
	}
    if (theBounds.size.height < 0.0)
	{
//        kd.knob = [ACSDGraphic flipKnob:kd.knob horizontal:NO];
        theBounds.origin.y = NSMaxY(theBounds);
        theBounds.size.height = -theBounds.size.height;
        [self flipVertically];
	}
	if (constrain)
		theBounds = [self constrainRect:theBounds usingKnob:kd.knob];
    [self setGraphicBoundsTo:theBounds from:bounds];
    return kd;
}
/*
- (KnobDescriptor)resizeByMovingKnob:(KnobDescriptor)kd toPoint:(NSPoint)point event:(NSEvent *)theEvent constrain:(BOOL)constrain aroundCentre:(BOOL)aroundCentre
{
    NSRect theBounds = [self bounds];
	if (transform)
		point = [self invertPoint:point];
    if (leftKnob(kd.knob))
	{
        // Adjust left edge
        theBounds.size.width = NSMaxX(theBounds) - point.x;
        theBounds.origin.x = point.x;
	}
	else if (rightKnob(kd.knob))
	{
        // Adjust right edge
        theBounds.size.width = point.x - theBounds.origin.x;
	}
    if (theBounds.size.width < 0.0)
	{
        kd.knob = [ACSDGraphic flipKnob:kd.knob horizontal:YES];
        theBounds.size.width = -theBounds.size.width;
        theBounds.origin.x -= theBounds.size.width;
		[self flipHorizontally];
	}
    if (upperKnob(kd.knob))
	{
        // Adjust top edge
        theBounds.size.height = point.y - theBounds.origin.y;
	}
	else if (lowerKnob(kd.knob))
	{
        // Adjust bottom edge
        theBounds.size.height = NSMaxY(theBounds) - point.y;
        theBounds.origin.y = point.y;
	}
    if (theBounds.size.height < 0.0)
	{
        kd.knob = [ACSDGraphic flipKnob:kd.knob horizontal:NO];
        theBounds.size.height = -theBounds.size.height;
        theBounds.origin.y -= theBounds.size.height;
        [self flipVertically];
	}
	if (kd.knob == UpperMiddleKnob || kd.knob == LowerMiddleKnob)
	{
		theBounds.size.width = originalBounds.size.width;
		theBounds.origin.x = originalBounds.origin.x;
	}
	if (kd.knob == MiddleLeftKnob || kd.knob == MiddleRightKnob)
	{
		theBounds.size.height = originalBounds.size.height;
		theBounds.origin.y = originalBounds.origin.y;
	}
	if (constrain)
		theBounds = [self constrainRect:theBounds usingKnob:kd.knob];
    [self setGraphicBoundsTo:theBounds from:bounds];
    return kd;
}
*/
-(NSArray*)allKnobs
   {
	return [NSArray arrayWithObjects:
		[ConnectorAttachment connectorAttachmentWithKnob:KnobDescriptor(UpperLeftKnob) graphic:nil offset:NSMakePoint(NSMinX(bounds),NSMaxY(bounds)) distance:0],
		[ConnectorAttachment connectorAttachmentWithKnob:KnobDescriptor(UpperMiddleKnob) graphic:nil offset:NSMakePoint(NSMidX(bounds),NSMaxY(bounds)) distance:0],
		[ConnectorAttachment connectorAttachmentWithKnob:KnobDescriptor(UpperRightKnob) graphic:nil offset:NSMakePoint(NSMaxX(bounds),NSMaxY(bounds)) distance:0],
		[ConnectorAttachment connectorAttachmentWithKnob:KnobDescriptor(MiddleLeftKnob) graphic:nil offset:NSMakePoint(NSMinX(bounds),NSMidY(bounds)) distance:0],
		[ConnectorAttachment connectorAttachmentWithKnob:KnobDescriptor(MiddleRightKnob) graphic:nil offset:NSMakePoint(NSMaxX(bounds),NSMidY(bounds)) distance:0],
		[ConnectorAttachment connectorAttachmentWithKnob:KnobDescriptor(LowerLeftKnob) graphic:nil offset:NSMakePoint(NSMinX(bounds),NSMinY(bounds)) distance:0],
		[ConnectorAttachment connectorAttachmentWithKnob:KnobDescriptor(LowerMiddleKnob) graphic:nil offset:NSMakePoint(NSMidX(bounds),NSMinY(bounds)) distance:0],
		[ConnectorAttachment connectorAttachmentWithKnob:KnobDescriptor(LowerRightKnob) graphic:nil offset:NSMakePoint(NSMaxX(bounds),NSMinY(bounds)) distance:0],
		[ConnectorAttachment connectorAttachmentWithKnob:KnobDescriptor(centreKnob) graphic:nil offset:NSMakePoint(NSMidX(bounds),NSMidY(bounds)) distance:0],
		nil];
   }

-(KnobDescriptor)nearestKnobForPoint:(NSPoint)pt
   {
	NSArray *arr = [self allKnobs];
	float squaredDist = 10000*10000;
	KnobDescriptor minKnob = KnobDescriptor(NoKnob);
	for (unsigned i = 0;i < [arr count];i++)
	   {
		KnobDescriptor kd = [[arr objectAtIndex:i]knob];
		float kdist = squaredDistance(pt,[(ConnectorAttachment*)[arr objectAtIndex:i]offset]);
		if (kdist < squaredDist)
		   {
			squaredDist = kdist;
			minKnob = kd;
		   }
	   }
	return minKnob;
   }

-(NSPoint)pointForKnob:(const KnobDescriptor&)kd
   {
    float x,y;
	if (leftKnob(kd.knob))
		x = NSMinX(bounds);
	else if (rightKnob(kd.knob))
		x = NSMaxX(bounds);
	else
		x = NSMidX(bounds);
    if (upperKnob(kd.knob))
		y = NSMaxY(bounds);
	else if (lowerKnob(kd.knob))
		y = NSMinY(bounds);
	else
		y = NSMidY(bounds);
	return NSMakePoint(x,y);
   }

- (void)otherTrackKnobNotifiesView:(GraphicView*)gView
   {
   }

- (void)otherTrackKnobAdjustments
   {
   }

-(void) readjustCache
   {
	if (graphicCache && usesCache)
	   {
		[graphicCache resizeToWidth:[self displayBounds].size.width height:[self displayBounds].size.height];
		[graphicCache setValid:NO];
	   }
   }

-(BOOL)trackInit:(KnobDescriptor&)kd withEvent:(NSEvent *)theEvent inView:(GraphicView*)view ok:(BOOL*)success
{
	return NO;
}

-(void)trackMid:(KnobDescriptor&)kd withEvent:(NSEvent *)theEvent point:(NSPoint)point lastPoint:(NSPoint)lastPoint
	selectedGraphics:(NSSet*)selectedGraphics
{
	kd = [self resizeByMovingKnob:kd toPoint:point event:theEvent constrain:(([theEvent modifierFlags] & NSShiftKeyMask)!=0)
					 aroundCentre:(([theEvent modifierFlags] & NSAlternateKeyMask)!=0)];
}

/*- (BOOL)trackKnob:(KnobDescriptor&)kd withEvent:(NSEvent *)theEvent inView:(GraphicView*)view selectedGraphics:(NSSet*)selectedGraphics
{
	BOOL success;
	if ([self trackInit:kd withEvent:theEvent inView:view ok:&success])
		return success;
    NSPoint point = [view convertPoint:[theEvent locationInWindow] fromView:nil];
	NSPoint origPoint = point,lastPoint=origPoint;
	[[NSNotificationCenter defaultCenter] postNotificationName:ACSDShowCoordinatesNotification object:self
													  userInfo:[NSDictionary dictionaryWithObject:[NSNumber numberWithBool:YES] forKey:@"vis"]];
	BOOL can = NO,periodicStarted=NO;
    while (1)
	{
		if (can = opCancelled)
		{
			[self setOpCancelled:NO];
			break;
		}
        theEvent = [[view window] nextEventMatchingMask:(NSLeftMouseDraggedMask | NSLeftMouseUpMask | NSFlagsChangedMask | NSKeyDownMask | NSPeriodicMask)];
		if ([theEvent type] == NSKeyDown)
		{
			[view keyDown:theEvent];
			continue;
		}
        if ([theEvent type] == NSPeriodic)
		{
			[view scrollRectToVisible:RectFromPoint(point,30.0,[view magnification])];
			point = [view convertPoint:[[view window] mouseLocationOutsideOfEventStream] fromView:nil];
		}
		else
			if ([theEvent type] != NSFlagsChanged)
				point = [view convertPoint:[theEvent locationInWindow] fromView:nil];
		point.y = [view adjustHSmartGuide:point.y tool:1];
		point.x = [view adjustVSmartGuide:point.x tool:1];
		if ([self needsRestrictTo45] && ([theEvent modifierFlags] & NSShiftKeyMask))
			restrictTo45(origPoint,&point);
		[self invalidateGraphicSizeChanged:NO shapeChanged:NO redraw:NO notify:NO];
//        kd = [self resizeByMovingKnob:kd toPoint:point event:theEvent constrain:(([theEvent modifierFlags] & NSShiftKeyMask)!=0)
//						 aroundCentre:(([theEvent modifierFlags] & NSAlternateKeyMask)!=0)];
		[self trackMid:kd withEvent:theEvent point:point lastPoint:lastPoint selectedGraphics:selectedGraphics];
		[self otherTrackKnobAdjustments];
		[self invalidateGraphicSizeChanged:YES shapeChanged:YES redraw:YES notify:NO];
		lastPoint = point;
		[self postChangeOfBounds];
		[ACSDGraphic postChangeFromAnchorPoint:origPoint toPoint:point];
		[self setOutlinePathValid:NO];
		[self otherTrackKnobNotifiesView:view];
		periodicStarted = [view scrollIfNecessaryPoint:point periodicStarted:periodicStarted];
        if ([theEvent type] == NSLeftMouseUp)
            break;
	}
	if (periodicStarted)
		[NSEvent stopPeriodicEvents];
	[[NSNotificationCenter defaultCenter] postNotificationName:ACSDShowCoordinatesNotification object:self
													  userInfo:[NSDictionary dictionaryWithObject:[NSNumber numberWithBool:NO] forKey:@"vis"]];
    [[self undoManager] setActionName:@"Resize"];
	return !can;
}*/

- (NSRect)handleRect:(NSPoint)point magnification:(float)mag
   {
	return RectFromPoint(point,ACSD_HALF_HANDLE_WIDTH,mag);
   }

- (KnobDescriptor)knobUnderPoint:(NSPoint)point view:(GraphicView*)gView
   {
	for (int i = 0;i < noHandlePoints;i++)
		if (NSPointInRect(point,[self handleRect:handlePoints[i] magnification:[gView magnification]]))
			return KnobDescriptor(knobs[i]);
    return KnobDescriptor(NoKnob);
   }

-(NSInteger)nearestHandleToPoint:(NSPoint)pt maxDistance:(float)maxDistance xOffset:(float*)xOff yOffset:(float*)yOff
   {
	float minDistance = maxDistance + 1.0;
	int nearestHandle = -2;
	NSPoint nearestPoint={0.0,0.0};
	for (int i = 0;i < noHandlePoints;i++)
	   {
		float xx = pt.x - handlePoints[i].x;
		xx = xx * xx;
		float yy = pt.y - handlePoints[i].y;
		yy = yy * yy;
		float dist = sqrt(xx + yy);
		if (dist < minDistance)
		   {
			minDistance = dist;
			nearestHandle = i;
			nearestPoint = handlePoints[i];
		   }
	   }
	NSPoint cpt = [self centrePoint];
	float xx = pt.x - cpt.x;
	xx = xx * xx;
	float yy = pt.y - cpt.y;
	yy = yy * yy;
	float dist = sqrt(xx + yy);
	if (dist < minDistance)
	   {
		minDistance = dist;
		nearestHandle = -1;
		nearestPoint = cpt;
	   }
	if (minDistance > maxDistance)
		return -2;
	*xOff = nearestPoint.x - pt.x;
	*yOff = nearestPoint.y - pt.y;
	return nearestHandle;
   }

- (void)drawHandleAtPoint:(NSPoint)point magnification:(float)mag
   {
    NSRectFill([self handleRect:point magnification:mag]);
   }

- (void)drawCentrePointMagnification:(float)mag
   {
    NSPoint cp = [self centrePoint];
	if (transform)
		cp = [transform transformPoint:cp];
    NSRect r = [self handleRect:cp magnification:mag];
	[[NSColor cyanColor] set];
	[NSBezierPath setDefaultLineWidth:0.0];
	[NSBezierPath strokeLineFromPoint:r.origin toPoint:NSMakePoint(r.origin.x + r.size.width,r.origin.y + r.size.height)];
	[NSBezierPath strokeLineFromPoint:NSMakePoint(r.origin.x,r.origin.y + r.size.height) toPoint:NSMakePoint(r.origin.x + r.size.width,r.origin.y)];
   }

- (void)setHandleBitsForview:(GraphicView*)gView
{
	//[gView setHandleBitsH:0 v:0];
	for (int i = 0;i < noHandlePoints;i++)
		[gView setHandleBitsH:(int)handlePoints[i].x v:(int)handlePoints[i].y];
}

-(BOOL)uClearSelectedElements
   {
	return NO;
   }

-(BOOL)graphicCanMergePoints
   {
	return NO;
   }

- (void)drawOtherHandlesMagnification:(float)mag
   {
   }

-(NSColor*)setHandleColour:(BOOL)forGuide
{
    NSColor *col;
    if (forGuide)
        col = [[ACSDPrefsController sharedACSDPrefsController:nil] guideColour];
    else
        col = [[ACSDPrefsController sharedACSDPrefsController:nil] selectionColour];
    [col set];
    return col;
}

- (void)drawHandlesGuide:(BOOL)forGuide magnification:(float)mag options:(NSUInteger)options
   {
    if (noHandlePoints == 0 || !handlePoints)
		return;
//	if (NSEqualPoints(handlePoints[0],NSZeroPoint))
//		return;
	[NSGraphicsContext saveGraphicsState];
	[NSBezierPath setDefaultLineWidth:0.0];
	NSBezierPath *path = [NSBezierPath bezierPath];
	[self setHandleColour:forGuide];
	if (moving)
		[[NSAffineTransform transformWithTranslateXBy:moveOffset.x yBy:moveOffset.y] concat];
	[path moveToPoint:handlePoints[0]];
	for (int i = 1;i < noHandlePoints;i++)
	   {
		if (NSEqualPoints(handlePoints[i],NSZeroPoint))
			return;
		[path lineToPoint:handlePoints[i]];
	   }
	if ([self hasClosedPath])
		[path closePath];
	[path stroke];
	if (!forGuide)
	   {
		for (int i = 0;i < noHandlePoints;i++)
			[self drawHandleAtPoint:handlePoints[i]magnification:mag];
		[self drawCentrePointMagnification:mag];
		[self drawOtherHandlesMagnification:mag];
	   }
	[NSGraphicsContext restoreGraphicsState];
   }

- (void)addHandleRectsForView:(GraphicView*)view
{
	int selectedTool = [[ToolWindowController sharedToolWindowController:nil] currentTool];
	if (selectedTool != ACSD_ARROW_TOOL)
		return;
	NSRect visRect = [view visibleRect];
	for (int i = 0;i < noHandlePoints;i++)
	{
	    NSRect hR = [self handleRect:handlePoints[i] magnification:[view magnification]];
		if (NSIntersectsRect(hR, visRect))
			[view addCursorRect:hR cursor:[NSCursor cursorForKnob:knobs[i]]];
	}
}

- (NSBezierPath *)bezierPath
{
    return [NSBezierPath bezierPathWithRect:bounds];
}

- (NSBezierPath *)clipPath
{
	if ((fill && [fill colour]) || !(stroke && [stroke colour]))
		return [self transformedBezierPath];
	ACSDGraphic *newGraphic = [[self convertToPath]outlineStroke];
	return [newGraphic bezierPath];
}

- (ACSDPath*)convertToPath
{
	NSBezierPath *p = [self transformedBezierPath];
	if (!p)
		p = [NSBezierPath bezierPathWithRect:[self bounds]];
	ACSDPath *obj =  [[[ACSDPath alloc] initWithName:[self name] fill:[self fill] stroke:[self stroke] rect:[self bounds]
											   layer:nil bezierPath:p xScale:1 yScale:1 rotation:0 shadowType:shadowType label:textLabel alpha:alpha]autorelease];
	return obj;
}

- (NSBezierPath *)transformedBezierPath
{
	if (!transform)
		return [self bezierPath];
	return [transform transformBezierPath:[self bezierPath]];
}

- (BOOL)hasNonTransparentFillOrStroke
   {
//	if (fill && [fill colour] && [[fill colour]alphaComponent] > 0.0)
	if (fill && [fill canFill])
		return YES;
	return (stroke && [stroke colour] && [[stroke colour]alphaComponent] > 0.0);
   }

+(BOOL)testPath:(NSBezierPath*)path forHitPoint:(NSPoint)hitPoint threshold:(float)threshold
   {
	NSUInteger noElements = [path elementCount];
	NSPoint points[3],lastPoint={0.0,0.0};
	CGFloat dummy,dummy2;
	NSPoint dummyPt;
	for (NSUInteger i = 0;i < noElements;i++)
	   {
		NSBezierPathElement elementType = [path elementAtIndex:i associatedPoints:points];
		switch (elementType)
		   {
			case NSMoveToBezierPathElement:
				lastPoint = points[0];
				break;
			case NSLineToBezierPathElement:
				if (testLineSegmentHit(lastPoint,points[0],hitPoint,threshold))
					return YES;
				lastPoint = points[0];
				break;
			case NSCurveToBezierPathElement:
				if (testCurveHit(lastPoint,points[2],points[0],points[1],hitPoint,dummy,dummyPt,dummy2,threshold,2.0,0.0,1.0))
					return YES;
				lastPoint = points[2];
				break;
			case NSClosePathBezierPathElement:
				break;
		   }
	   }
	return NO;
   }

BOOL pathIntersectsWithRect(NSBezierPath *p,NSRect pathBounds,NSRect r,BOOL checkBottomLeft,BOOL checkTopLeft,BOOL checkTopRight,BOOL checkBottomRight)
   {
	if (r.size.width <= 0.5 || r.size.height <= 0.5)
		return NO;
	if ((checkTopLeft && [p containsPoint:top_left(r)]) || 
		(checkTopRight && [p containsPoint:top_right(r)]) ||
		(checkBottomLeft && [p containsPoint:bottom_left(r)]) ||
		(checkBottomRight && [p containsPoint:bottom_right(r)]))
		return YES;
	NSRect blRect,tlRect,trRect,brRect;
	quarter_rects(r,blRect,tlRect,trRect,brRect);
	return pathIntersectsWithRect(p,pathBounds,blRect,NO,YES,YES,YES)||pathIntersectsWithRect(p,pathBounds,tlRect,NO,NO,YES,NO)||
		pathIntersectsWithRect(p,pathBounds,trRect,NO,NO,NO,YES)||pathIntersectsWithRect(p,pathBounds,brRect,NO,NO,NO,NO);
   }


- (BOOL)intersectsWithRect:(NSRect)selectionRect    //used for selecting with rubberband
{
    NSBezierPath *p = [self transformedBezierPath];
    BOOL success = pathIntersectsWithRect(p,[p bounds],NSIntersectionRect([p bounds],selectionRect),YES,YES,YES,YES);
    if (success)
        return YES;
    if ([p bounds].size.height == 0 || [p bounds].size.width == 0)
    {
        return NSPointInRect(NSMakePoint(NSMinX([p bounds]),NSMinY([p bounds])), selectionRect) ||
        NSPointInRect(NSMakePoint(NSMinX([p bounds]),NSMaxY([p bounds])), selectionRect) ||
        NSPointInRect(NSMakePoint(NSMaxX([p bounds]),NSMinY([p bounds])), selectionRect) ||
        NSPointInRect(NSMakePoint(NSMaxX([p bounds]),NSMinY([p bounds])), selectionRect);
    }
    return NO;
}

- (BOOL)shapeUnderPoint:(NSPoint)point includeKnobs:(BOOL)includeKnobs view:(GraphicView*)vw
   {
	NSBezierPath *p = [self transformedBezierPath];
	if ([p containsPoint:point])
		return YES;
	if (includeKnobs && ([self knobUnderPoint:point view:vw].knob != NoKnob))
		return YES;
	return NO;
   }

- (BOOL)shapeUnderPointValue:(id)v
{
	NSPoint pt;
	BOOL includeKnobs = NO;
	GraphicView *vw = nil;
	if ([v isKindOfClass:[NSArray class]])
	{
		pt = [[v objectAtIndex:0]pointValue];
		includeKnobs = [[v objectAtIndex:1]boolValue];
		vw = (GraphicView*)[v objectAtIndex:2];
	}
	else
		pt = [v pointValue];
	return [self shapeUnderPoint:pt includeKnobs:includeKnobs view:vw];
}

-(void)drawHighlightRect:(NSRect)r colour:(NSColor*)col hotPoint:(NSPoint)hotPoint modifiers:(NSUInteger)modifiers
   {
	NSBezierPath *p = [self transformedBezierPath];
	[col set];
	[p setLineWidth:3];
	[p stroke];
   }

- (BOOL)hitTest:(NSPoint)point isSelected:(BOOL)isSelected view:(GraphicView*)gView
   {
    if (self.hidden)
        return NO;
	if (isSelected && ([self knobUnderPoint:point view:gView].knob != NoKnob))
        return YES;
    else if (graphicCache && ([self hasNonTransparentFillOrStroke]||([self isKindOfClass:[ACSDText class]])||(textLabel && [[textLabel contents]length]>0)))
	   {
		NSPoint tPt = point;
		tPt.x -= [self displayBounds].origin.x;
		tPt.y -= [self displayBounds].origin.y;
		tPt.x *= [graphicCache magnification];
		tPt.y *= [graphicCache magnification];
		NSRect r;
		r.origin = NSMakePoint(0.0,0.0);
		r.size = [[graphicCache image]size];
		if (NSPointInRect(tPt,r))
			   return [graphicCache hitTestX:tPt.x y:tPt.y];
		return NO;   
	   }
	else
	   {
        NSBezierPath *path = [self transformedBezierPath];
        if (path)
		   {
//            if ([path containsPoint:point])
//                return YES;
			if ([ACSDGraphic testPath:path forHitPoint:point threshold:4])
				return YES;
           }
		else
            if (NSPointInRect(point, [self bounds]))
                return YES;
	   }
	return NO;
   }

- (NSRect)rectFromAnchorPoint:(NSPoint)anchorPt movingPoint:(NSPoint)movingPt constrainedPoint:(NSPoint*)constrainedPoint 
			   dragFromCentre:(BOOL)centreDrag constrain:(BOOL)constrained 
   {
	NSPoint pt1 = anchorPt, pt2 = movingPt;
	if (constrained)
	   {
		float diffX = pt2.x - pt1.x;
		float diffY = pt2.y - pt1.y;
		float dist = MIN(fabs(diffX),fabs(diffY));
		pt2.x = pt1.x + dist * SIGN(diffX);
		pt2.y = pt1.y + dist * SIGN(diffY);
	   }
	if (centreDrag)
	   {
		pt1.x -= (pt2.x - pt1.x);
		pt1.y -= (pt2.y - pt1.y);
	   }
	*constrainedPoint = pt2;
	return rectFromPoints(pt1,pt2);
   }

+(void)postChangeOfBounds:(NSRect)b
   {
	NSDictionary *dict1 = [NSDictionary dictionaryWithObject:[NSValue valueWithRect:b] forKey:@"bounds"];
	[[NSNotificationCenter defaultCenter] postNotificationName:ACSDDimensionChangeNotification object:self userInfo:dict1];
   }

+(void)postChangeFromAnchorPoint:(NSPoint)anchorPoint toPoint:(NSPoint)point
{
	NSSize sz = NSMakeSize(point.x - anchorPoint.x,point.y - anchorPoint.y);
	NSDictionary *dict2 = [NSDictionary dictionaryWithObjectsAndKeys:[NSValue valueWithPoint:point],@"xy",
						   [NSValue valueWithSize:sz],@"dxdy",
						   [NSNumber numberWithFloat:angleForPoints(anchorPoint,point)],@"theta",
						   [NSNumber numberWithFloat:pointDistance(anchorPoint,point)],@"dist",
						   nil];
	dispatch_async(dispatch_get_main_queue(), ^{
		[[NSNotificationCenter defaultCenter] postNotificationName:ACSDMouseDidMoveNotification object:self userInfo:dict2];
	});
}

+(void)postShowCoordinates:(BOOL)show
   {
	[[NSNotificationCenter defaultCenter] postNotificationName:ACSDShowCoordinatesNotification object:self
													  userInfo:[NSDictionary dictionaryWithObject:[NSNumber numberWithBool:show] forKey:@"vis"]];
   }

-(void)createInit:(NSPoint)anchorPoint event:(NSEvent*)theEvent
{
    [self setBounds:NSMakeRect(anchorPoint.x, anchorPoint.y, 0.0, 0.0)];
}

-(void)createMid:(NSPoint)anchorPoint currentPoint:(NSPoint*)currPoint event:(NSEvent*)theEvent
{
	[self setBounds:[self rectFromAnchorPoint:anchorPoint movingPoint:*currPoint constrainedPoint:currPoint 
							   dragFromCentre:(([theEvent modifierFlags] & NSAlternateKeyMask)!=0)
									constrain:(([theEvent modifierFlags] & NSShiftKeyMask)!=0)]];
}

-(BOOL)createCleanUp:(BOOL)cancelled
{
    return (([self bounds].size.width > 0.0) || ([self bounds].size.height > 0.0)) && !cancelled;
}

-(BOOL)needsRestrictTo45
{
	return NO;
}

- (BOOL)createWithEvent:(NSEvent *)theEvent inView:(GraphicView *)view 
{
    NSPoint currPoint = [view convertPoint:[theEvent locationInWindow] fromView:nil];
	currPoint.y = [view adjustHSmartGuide:currPoint.y tool:1];
	currPoint.x = [view adjustVSmartGuide:currPoint.x tool:1];
	NSPoint anchorPoint = currPoint,lastPoint = anchorPoint;
	[self createInit:anchorPoint event:theEvent];
	[ACSDGraphic postShowCoordinates:YES];
	BOOL can = NO,periodicStarted=NO;
    while (1)
	{
		if (opCancelled)
		{
			[self setOpCancelled:NO];
			can = YES;
			break;
		}
        theEvent = [[view window] nextEventMatchingMask:(NSLeftMouseDraggedMask | NSLeftMouseUpMask | NSFlagsChangedMask | NSKeyDownMask | NSPeriodicMask)];
		if ([theEvent type] == NSKeyDown)
		{
			[view keyDown:theEvent];
			continue;
		}
        if ([theEvent type] == NSPeriodic)
		{
			[view scrollRectToVisible:RectFromPoint(currPoint,30.0,[view magnification])];
			currPoint = [view convertPoint:[[view window] mouseLocationOutsideOfEventStream] fromView:nil];
		}
		else if ([theEvent type] == NSFlagsChanged)
			currPoint = [view convertPoint:[[view window] mouseLocationOutsideOfEventStream] fromView:nil];
		else
			currPoint = [view convertPoint:[theEvent locationInWindow] fromView:nil];
		if ([self needsRestrictTo45] && ([theEvent modifierFlags] & NSShiftKeyMask))
			restrictTo45(anchorPoint,&currPoint);
		if (!NSEqualPoints(currPoint, lastPoint) || [theEvent type] == NSFlagsChanged)
		{
			currPoint.y = [view adjustHSmartGuide:currPoint.y tool:1];
			currPoint.x = [view adjustVSmartGuide:currPoint.x tool:1];
			[self invalidateGraphicSizeChanged:NO shapeChanged:NO redraw:NO notify:NO];
			[self createMid:anchorPoint currentPoint:&currPoint event:theEvent];
			[self invalidateGraphicSizeChanged:YES shapeChanged:YES redraw:YES notify:NO];
			[self postChangeOfBounds];
			[ACSDGraphic postChangeFromAnchorPoint:anchorPoint toPoint:currPoint];
			lastPoint = currPoint;
		}
		periodicStarted = [view scrollIfNecessaryPoint:currPoint periodicStarted:periodicStarted];
        if ([theEvent type] == NSLeftMouseUp)
            break;
	}
	if (periodicStarted)
		[NSEvent stopPeriodicEvents];
	[ACSDGraphic postShowCoordinates:NO];
	return [self createCleanUp:can];
}

- (BOOL)usesSimplePath
   {
    return YES;
   }

-(void)writeSVGDefs:(SVGWriter*)svgWriter
   {
	if ([fill isKindOfClass:[ACSDGradient class]])
		[svgWriter addGradient:@{@"gradient":fill,@"bounds":[NSValue valueWithRect:[self bounds]],@"index":@([svgWriter.gradients count])}];
    else if ([fill isKindOfClass:[ACSDPattern class]])
    {
        //[svgWriter addPattern:(ACSDPattern*)fill];
        ACSDPattern *pat = (ACSDPattern*)fill;
        pat.tempName = [NSString stringWithFormat:@"pat%d",(int)[svgWriter.patterns count]];
        [svgWriter addPattern:@{@"pattern":fill,@"bounds":[NSValue valueWithRect:[self strictBounds]],@"name":pat.tempName}];
    }
	if (shadowType && [shadowType itsShadow])
		[svgWriter addShadow:shadowType];
	if (stroke)
	   {
		if ([stroke lineStart] && [[stroke lineStart]graphic])
			[svgWriter addLineEnding:[stroke lineStart]];
		if ([stroke lineEnd] && [[stroke lineEnd]graphic])
			[svgWriter addLineEnding:[stroke lineEnd]];
	   }
   }

-(NSString*)svgTransform:(SVGWriter*)svgWriter
{
    if (rotation != 0.0)
    {
        NSPoint rpt = rotationPoint;
        float rot = rotation;
        if (svgWriter.shouldInvertSVGCoords)
        {
            rpt = [svgWriter.inversionTransform transformPoint:rpt];
            rot = -rotation;
        }
        return [NSString stringWithFormat:@" transform=\"rotate(%g %g %g)\" ",rot,rpt.x,rpt.y];
    }
    return @"";
}

-(void)writeSVGOtherAttributes:(SVGWriter*)svgWriter
{
    
}

-(NSString*)svgType
{
    return @"path";
}

-(NSString*)svgTypeSpecifics:(SVGWriter*)svgWriter boundingBox:(NSRect)bb
{
    NSBezierPath *p = [self bezierPath];
    if ([svgWriter shouldInvertSVGCoords])
    {
        p = [svgWriter.inversionTransform transformBezierPath:p];
    }
    return [NSString stringWithFormat:@"d=\"%@\" ",string_from_path(p)];
}

-(void)writeSVGData:(SVGWriter*)svgWriter
{
    [self writeSVGDefs:svgWriter];
    NSString *defId = nil;
    NSColor *patternBackColour = nil;
    if (fill && [fill isKindOfClass:[ACSDPattern class]] && (patternBackColour = [((ACSDPattern*)fill)backgroundColour]))
    {
        if ([patternBackColour alphaComponent] > 0.0)
            defId = [NSString stringWithFormat:@"D_%d",self.objectKey];
    }
    if (defId)
    {
        NSMutableString *defstr = [[NSMutableString alloc]init];
        [defstr appendFormat:@"<%@ id=\"%@\" %@",[self svgType],defId,[self svgTransform:svgWriter]];
        [defstr appendString:[self svgTypeSpecifics:svgWriter boundingBox:NSZeroRect]];
        [defstr appendString:@" />\n"];
        [svgWriter addOtherDefString:defstr];
        [[svgWriter contents]appendFormat:@"%@<use id=\"%@f\" xlink:href=\"#%@\" ",[svgWriter indentString],self.name,defId];
        if ([svgWriter clipPathName])
            [[svgWriter contents]appendFormat:@"clip-path=\"url(#%@)\" ",[svgWriter clipPathName]];
        [[svgWriter contents]appendFormat:@"fill=\"%@\"",string_from_nscolor(patternBackColour)];
        if ([patternBackColour alphaComponent] < 1.0)
                [[svgWriter contents]appendFormat:@"fill-opacity=\"%g\" ",[patternBackColour alphaComponent]];
        [[svgWriter contents]appendString:@" />\n"];
        [[svgWriter contents]appendFormat:@"%@<use id=\"%@\" xlink:href=\"#%@\" ",[svgWriter indentString],self.name,defId];
    }
    else
    {
        [[svgWriter contents]appendFormat:@"%@<%@ id=\"%@\" %@",[svgWriter indentString],[self svgType],self.name,[self svgTransform:svgWriter]];
        //if ([svgWriter clipPathName])
            //[[svgWriter contents]appendFormat:@"clip-path=\"url(#%@)\" ",[svgWriter clipPathName]];
        if (self.clipGraphic)
        {
            [svgWriter setClipPathName:[NSString stringWithFormat:@"clip%ld",(NSUInteger)self]];
            NSMutableString *defstr = [NSMutableString stringWithFormat:@"\t<clipPath id=\"%@\" >\n",[svgWriter clipPathName]];
            [defstr appendFormat:@"\t\t<%@ id=\"%@\" %@/>\n",[self.clipGraphic svgType],self.clipGraphic.name,[self.clipGraphic svgTypeSpecifics:svgWriter boundingBox:NSZeroRect]];
            [defstr appendString:@"\t</clipPath>\n"];
            [svgWriter addOtherDefString:defstr];
            [[svgWriter contents]appendFormat:@"clip-path=\"url(#%@)\" ",[svgWriter clipPathName]];
        }
        [[svgWriter contents]appendString:[self svgTypeSpecifics:svgWriter boundingBox:NSZeroRect]];
    }
    if (stroke)
	   {
           [stroke writeSVGData:svgWriter];
           if ([stroke lineStart] && [[stroke lineStart]graphic])
               [[svgWriter contents]appendFormat:@"marker-start=\"url(#markerS%d)\" ",[[stroke lineStart]objectKey]];
           if ([stroke lineEnd] && [[stroke lineEnd]graphic])
               [[svgWriter contents]appendFormat:@"marker-end=\"url(#markerE%d)\" ",[[stroke lineEnd]objectKey]];
       }
    if (fill)
        [fill writeSVGData:svgWriter];
    if (shadowType)
        [shadowType writeSVGData:svgWriter];
    if (self.hidden)
        [[svgWriter contents] appendString:@"visibility=\"hidden\" "];
    if (self.alpha != 1.0)
        [[svgWriter contents] appendFormat:@"opacity=\"%g\" ",self.alpha];
    [self writeSVGOtherAttributes:svgWriter];
    [[svgWriter contents]appendString:@" />\n"];
    if (textLabel)
        [textLabel writeSVGData:svgWriter];
}

-(void)writeCanvasGraphic:(CanvasWriter*)canvasWriter
{
	if (transform)
	{
		NSAffineTransformStruct t = [transform transformStruct];
		[[canvasWriter contents]appendFormat:@"ctx.transform(%g,%g,%g,%g,%g,%g);\n",t.m11, t.m12, t.m21, t.m22, t.tX, t.tY];
	}
	[[canvasWriter contents]appendString:@"ctx.beginPath();\n"];
	NSBezierPath *tbp = [self bezierPath];
//	NSBezierPath *tbp = [self transformedBezierPath];
	[[canvasWriter contents]appendFormat:@"%@\n",canvas_string_from_path(tbp)];
	[[canvasWriter contents]appendString:@"ctx.save();\n"];
	if (shadowType)
		[[canvasWriter contents]appendFormat:@"%@\n",[shadowType canvasData:canvasWriter]];
	BOOL restored = NO;
	if (fill)
	{
		[canvasWriter setObject:tbp forKey:@"path"];
		[[canvasWriter contents]appendFormat:@"%@\n",[fill canvasData:canvasWriter]];
		if ([fill canFill])
		{
			[[canvasWriter contents]appendString:@"ctx.fill();\n"];
			[[canvasWriter contents]appendString:@"ctx.restore();\n"];
			restored = YES;
		}
	}
	if (stroke && [stroke colour])
	{
		[[canvasWriter contents]appendFormat:@"%@\n",[stroke canvasData:canvasWriter]];
		[[canvasWriter contents]appendString:@"ctx.stroke();\n"];
		NSPoint pt1,pt2;
		ACSDLineEnding *le1 = [stroke lineStart];
		ACSDLineEnding *le2 = [stroke lineEnd];
		[[canvasWriter contents]appendFormat:@"ctx.fillStyle=\"%@\";",rgba_from_nscolor([stroke colour])];
		if (le1 && [le1 graphic] && getFirstTwoPoints([self bezierPath],&pt1,&pt2))
			[le1 canvas:canvasWriter dataForLineEndingAtPoint:pt1 angle:getAngleForPoints(pt1,pt2) lineWidth:[stroke lineWidth]];
		if (le2 && [le2 graphic] && getLastTwoPoints([self bezierPath],&pt1,&pt2))
			[le2 canvas:canvasWriter dataForLineEndingAtPoint:pt1 angle:getAngleForPoints(pt1,pt2) lineWidth:[stroke lineWidth]];
	}
	if (!restored)
		[[canvasWriter contents]appendString:@"ctx.restore();\n"];
}

-(void)writeCanvasData:(CanvasWriter*)canvasWriter
{
	[[canvasWriter contents]appendString:@"ctx.save();\n"];
	[self writeCanvasGraphic:canvasWriter];
	[[canvasWriter contents]appendString:@"ctx.restore();\n"];
   }

-(BOOL)isSameAs:(id)obj
   {
	if ([self class] != [obj class])
		return NO;
	ACSDGraphic *g = obj;
	if (![self.name isEqualToString:[g name]])
		return NO;
	if ((fill == nil)!= ([g fill] == nil))
		return NO;
	if (fill && !([fill isSameAs:[g fill]]))
		return NO;
	if ((stroke == nil)!= ([g stroke] == nil))
		return NO;
	if (stroke && !([stroke isSameAs:[g stroke]]))
		return NO;
	if (!NSEqualRects([self bounds],[g bounds]))
		return NO;
	return YES;
   }

-(NSSet*)subObjects
   {
	return [NSSet set];
   }

-(BOOL)isTextObject
   {
	return NO;
   }

-(NSSet*)allTheObjects
   {
	return [NSMutableSet setWithObject:self];
   }
   
-(void)addConnector:(ACSDConnector*)c
   {
	[connectors addObject:c];
   }

-(void)removeConnector:(ACSDConnector*)c
   {
	[connectors removeObjectIdenticalTo:c];
   }

-(void)invalidateConnectors
   {
	[connectors makeObjectsPerformSelector:@selector(reformConnector)];
   }

-(id)link
   {
	return link;
   }

-(void)setAbsoluteLink:(NSURL*)url
   {
   }

-(void)setLink:(id)l
   {
	if (l == link)
		return;
	if (link)
		[link release];
	if (l)
		[l retain];
	link = l;
   }

-(void)uSetLink:(id)l
   {
	if (link && [link respondsToSelector:@selector(removeFromLinkedObjects)])
		[link removeFromLinkedObjects];
//	[[[self undoManager] prepareWithInvocationTarget:self] uSetLink:link];
	[self setLink:l];
   }


-(void)uRemoveLinkedObject:(id)obj
   {
	if (!linkedObjects)
		return;
//	[[[self undoManager] prepareWithInvocationTarget:self] uAddLinkedObject:obj];
	[linkedObjects removeObject:obj];
   }

-(void)uAddLinkedObject:(id)obj
   {
	if (!linkedObjects)
		linkedObjects = [[NSMutableSet alloc]initWithCapacity:3];
//	[[[self undoManager] prepareWithInvocationTarget:self] uRemoveLinkedObject:obj];
	[linkedObjects addObject:obj];
   }

-(BOOL)uDeleteAttributeAtIndex:(NSInteger)idx notify:(BOOL)notif
{
    NSArray *arr = self.attributes[idx];
    [[[self undoManager] prepareWithInvocationTarget:self] uInsertAttributeName:arr[0]value:arr[1] atIndex:idx notify:YES];
    [self.attributes removeObjectAtIndex:idx];
	if (notif)
		[[NSNotificationCenter defaultCenter]postNotificationName:ACSDGraphicAttributeChanged object:self];
    return YES;
}

-(BOOL)uInsertAttributeName:(NSString*)nm value:(NSString*)val atIndex:(NSInteger)idx notify:(BOOL)notif
{
    [[[self undoManager] prepareWithInvocationTarget:self] uDeleteAttributeAtIndex:idx notify:YES];
    if (self.attributes == nil)
        self.attributes = [NSMutableArray arrayWithCapacity:6];
    [self.attributes insertObject:@[nm,val] atIndex:idx];
	if (notif)
		[[NSNotificationCenter defaultCenter]postNotificationName:ACSDGraphicAttributeChanged object:self];
    return YES;
}

-(BOOL)uSetAttributeName:(NSString*)nm atIndex:(NSInteger)idx notify:(BOOL)notif
{
    NSArray *arr = self.attributes[idx];
    [[[self undoManager] prepareWithInvocationTarget:self] uSetAttributeName:arr[0] atIndex:idx notify:YES];
    [self.attributes replaceObjectAtIndex:idx withObject:@[nm,arr[1]]];
	if (notif)
		[[NSNotificationCenter defaultCenter]postNotificationName:ACSDGraphicAttributeChanged object:self];
    return YES;
}

-(BOOL)uSetAttributeValue:(NSString*)val atIndex:(NSInteger)idx notify:(BOOL)notif
{
    NSArray *arr = self.attributes[idx];
    [[[self undoManager] prepareWithInvocationTarget:self] uSetAttributeValue:arr[1] atIndex:idx notify:YES];
    [self.attributes replaceObjectAtIndex:idx withObject:@[arr[0],val]];
	if (notif)
		[[NSNotificationCenter defaultCenter]postNotificationName:ACSDGraphicAttributeChanged object:self];
    return YES;
}

-(BOOL)uSetAttributeValue:(NSString*)val forName:(NSString*)nme notify:(BOOL)notif
{
	NSInteger idx = 0;
	for (NSArray *arr in self.attributes)
	{
		if ([arr[0] isEqual:nme])
		{
			[self uSetAttributeValue:val atIndex:idx notify:notif];
			return YES;
		}
		idx++;
	}
	idx = [self.attributes count];
	[self uInsertAttributeName:nme value:val atIndex:idx notify:notif];
	return YES;
}

-(BOOL)uDeleteAttributeForName:(NSString*)nme notify:(BOOL)notif
{
	for (NSInteger idx = [self.attributes count] - 1;idx >= 0;idx--)
	{
		NSArray *arr = self.attributes[idx];
		if ([arr[0] isEqual:nme])
			return [self uDeleteAttributeAtIndex:idx notify:notif];
	}
	return NO;
}

-(void)uSetAttributes:(NSMutableArray*)arr
{
    [[[self undoManager] prepareWithInvocationTarget:self] uSetAttributes:self.attributes];
    self.attributes = arr;
    [[NSNotificationCenter defaultCenter]postNotificationName:ACSDGraphicDidChangeNotification object:self];
}

-(void)uSetGraphicMode:(GraphicMode)gm
   {
	if (gm == graphicMode)
		return;
	[[[self undoManager] prepareWithInvocationTarget:self] uSetGraphicMode:graphicMode];
	graphicMode = gm;
	if (graphicMode == GRAPHIC_MODE_OUTLINE)
	   {
		[self setPreOutlineStroke:stroke];
		[self setPreOutlineFill:fill];
		[self setStroke:nil];
		[self setOutlinePathValid:NO];
	   }
	else
	   {
		[self setStroke:preOutlineStroke];
		[self setFill:preOutlineFill];
	   }
	[self invalidateGraphicSizeChanged:YES shapeChanged:YES redraw:YES notify:NO];
   }

-(BOOL)isOrContainsImage
   {
	return NO;
   }


-(NSImage*)graphicImageFromPageImage:(NSImage*)pageImage
   {
	NSRect b = NSIntegralRect([self displayBounds]);
	NSImage *im = [[[NSImage alloc]initWithSize:b.size]autorelease];
	[im lockFocus];
	[pageImage drawInRect:NSMakeRect(0,0,b.size.width,b.size.height) fromRect:b operation:NSCompositeSourceOver fraction:1.0];
	[im unlockFocus];
	return im;
   }

-(NSImage*)scaledImage
   {
	NSRect b = NSIntegralRect([self displayBounds]);
	NSImage *im = [[[NSImage alloc]initWithSize:b.size]autorelease];
	[im lockFocus];
	[[shadowType itsShadow]set];
	[graphicCache.bitmap drawInRect:[graphicCache allocatedBounds]];
	[im unlockFocus];
	return im;
   }

NSString *imageNameForOptions(NSDictionary* options)
   {
	return [NSString stringWithFormat:@"img_%d_%d",[[options objectForKey:@"pageNo"]intValue],[[options objectForKey:@"imageNo"]intValue]];
   }

NSString *htmlDirectoryNameForOptions(NSMutableDictionary *options,NSString *dirType)
   {
	NSError *err;
	NSString *pathName = [options objectForKey:dirType];
	if (![[NSFileManager defaultManager]fileExistsAtPath:pathName])
		if (![[NSFileManager defaultManager] createDirectoryAtPath:pathName withIntermediateDirectories:NO attributes:nil error:&err])
			show_error_alert([NSString stringWithFormat:@"Error creating directory: %@; %@",pathName,[err localizedDescription]]);
	return pathName;
   }

-(BOOL)writeSVGImageOptions:(NSMutableDictionary*)options
   {
	SVGWriter *svgWriter = [[[SVGWriter alloc]initWithSize:[self displayBounds].size document:nil page:nil]autorelease];
	[svgWriter createDataForGraphic:self];
	NSString *fileName = [imageNameForOptions(options) stringByAppendingPathExtension:@"svg"];
	NSString *pathName = htmlDirectoryNameForOptions(options,@"smallimages");
	pathName = [pathName stringByAppendingPathComponent:fileName];
	return ([[svgWriter fullString] writeToFile:pathName atomically:YES encoding:NSUnicodeStringEncoding error:nil]);
   }

-(NSString*)writeCanvasImageOptions:(NSMutableDictionary*)options
   {
	NSString *identifier = imageNameForOptions(options);
	NSMutableArray *fNames = [options objectForKey:@"canvasScriptNames"];
	[fNames addObject:identifier];
	CanvasWriter *canvasWriter = [[[CanvasWriter alloc]initWithBounds:[self displayBounds]identifier:identifier]autorelease];
	[canvasWriter createDataForGraphic:self];
	return [canvasWriter contents];
   }

-(BOOL)writeImageFromPageImageOptions:(NSMutableDictionary*)options
   {
	NSString *imageSuffix,*imageType;
	imageSuffix = [[options objectForKey:@"htmlSettings"]objectForKey:@"imageSuffix"];
	imageType = [[options objectForKey:@"htmlSettings"]objectForKey:@"imageType"];
	NSImage *im;
	if ([imageSuffix isEqualToString:@"png"])
		im = [self scaledImage];
	else
		im = [self graphicImageFromPageImage:[options objectForKey:@"pageImage"]];
	NSData *imData = [im TIFFRepresentation];
	CGImageSourceRef cgImageSource = CGImageSourceCreateWithData((CFDataRef)imData,NULL);
	CGImageRef cgImageref = CGImageSourceCreateImageAtIndex(cgImageSource,0,NULL);
	CFRelease(cgImageSource);
	NSString *fileName = [imageNameForOptions(options) stringByAppendingPathExtension:imageSuffix];
	NSString *pathName = htmlDirectoryNameForOptions(options,@"smallimages");
	pathName = [pathName stringByAppendingPathComponent:fileName];
	NSURL *url = [NSURL fileURLWithPath:pathName];
	CGImageDestinationRef cgImageDest = CGImageDestinationCreateWithURL((CFURLRef)url,(CFStringRef)imageType,1,NULL);
	if (!cgImageDest)
	{
		CGImageRelease(cgImageref);
		return show_error_alert([NSString stringWithFormat:@"Error creating image destination: %@",[url description]]);
	}
	CGImageDestinationAddImage(cgImageDest,cgImageref,NULL);
	CGImageDestinationFinalize(cgImageDest);
	CFRelease(cgImageDest);
	CGImageRelease(cgImageref);
	return YES;
   }

-(BOOL)processClickThrough:(NSMutableDictionary*)options size:(NSSize*)finalSize
   {
	return NO;
   }	

-(NSString*) stringFromURL:(NSURL*)url options:(NSMutableDictionary*)options
   {
	NSString *str = [url description];
	if ([str isEqualToString:@"nextpage"])
		return [NSString stringWithFormat:@"%@_%d.html",[options objectForKey:@"dTitle"],[[options objectForKey:@"pageNo"]intValue]+1];
	else if ([str isEqualToString:@"prevpage"])
		return [NSString stringWithFormat:@"%@_%d.html",[options objectForKey:@"dTitle"],[[options objectForKey:@"pageNo"]intValue]-1];
	else if ([str isEqualToString:@"firstpage"])
		return [NSString stringWithFormat:@"%@_1.html",[options objectForKey:@"dTitle"]];
	return str;
   }

-(id)checkLink:(ACSDLink*)l overflow:(BOOL*)overflow
   {
	return self;
   }

-(NSString*)anchorStringForObject:(id)obj link:(ACSDLink*)lnk options:(NSMutableDictionary*)options
   {
	if ([obj isKindOfClass:[ACSDPage class]])
		return [NSString stringWithFormat:@"%@_%ld.html",[options objectForKey:@"dTitle"],[obj pageNo]];
	else
	   {
		NSString *pref;
		if ([layer page] == [[(ACSDGraphic*)obj layer]page])
			pref = @"";
		else
			pref = [NSString stringWithFormat:@"%@_%ld.html",[options objectForKey:@"dTitle"],[[[(ACSDGraphic*)obj layer] page]pageNo]];
		pref = [NSString stringWithFormat:@"%@#%@",pref,[lnk anchorNameForToObject]];
		return pref;
	   }
   }

-(NSString*)link:(id)l urlStringOptions:(NSMutableDictionary*)options
   {
	if (!l)
		return nil;
	if ([l isKindOfClass:[NSURL class]])
		return [self stringFromURL:l options:options];
	if ([l isKindOfClass:[ACSDLink class]])
		return [self anchorStringForObject:[l toObject] link:l options:options];
	return nil;
   }

-(NSString*)linkUrlStringOptions:(NSMutableDictionary*)options
   {
	return [self link:link urlStringOptions:options];
   }

-(void)processHTMLTriggers:(NSMutableString*)bodyString
{
	if (triggers)
		for (NSDictionary *t in triggers)
		{
			int j = [[t objectForKey:@"event"]intValue];
			NSString *temp;
			if ([[t objectForKey:@"action"]intValue] == TRIGGER_SHOW)
				temp = @"visible";
			else
				temp = @"hidden";
			[bodyString appendFormat:@"on%@=\"document.getElementById('%@').style.visibility='%@'\" ",
			 triggerEventStrings[j],[(ACSDLayer*)[t objectForKey:@"layer"]name],temp];
		}
}	

-(int)htmlVectorModeOptions:(NSMutableDictionary*)options
{
	if ([self isMemberOfClass:[ACSDImage class]])
		return VECTOR_GRAPHICS_BITMAP;
	else
		return [[[options objectForKey:@"htmlSettings"]objectForKey:@"vectorGraphicsType"]intValue];
}

-(void)processHTMLOptions:(NSMutableDictionary*)options
{
	int vectorMode = [self htmlVectorModeOptions:options];
	if (vectorMode == VECTOR_GRAPHICS_BITMAP)
		[self writeImageFromPageImageOptions:options];
	else if (vectorMode == VECTOR_GRAPHICS_SVG)
		[self writeSVGImageOptions:options];
	else /* canvas */
		[[options objectForKey:@"canvasScriptString"]appendString:[self writeCanvasImageOptions:options]];
	NSMutableDictionary *htmlSettings = [options objectForKey:@"htmlSettings"];
	BOOL clickThrough = [[htmlSettings objectForKey:@"clickThrough"]boolValue];
	NSMutableString *cssString = [options objectForKey:@"cssString"];
	NSMutableString *ieString = [options objectForKey:@"ieString"];
	NSString *objName = imageNameForOptions(options);
	NSSize sz = [[[layer page] document]documentSize];
	NSRect b = NSIntegralRect([self displayBounds]);
	[cssString appendFormat:@"\t\t\t#%@ {position: absolute; top: %dpx; left: %dpx; height: %dpx; width: %dpx; padding: 0px; margin: 0px; z-index: 1;",
	 objName,(int)(sz.height-NSMaxY(b)),(int)(NSMinX(b)),(int)b.size.height,(int)b.size.width];
	[cssString appendString:@"}\n"];
	NSMutableString *bodyString = [options objectForKey:@"bodyString"];
	[bodyString appendFormat:@"\t\t<div id=\"%@\"",objName];
	[self processHTMLTriggers:bodyString];
	[bodyString appendString:@">\n\t\t\t"];
	bool ieCompatibility = [[options objectForKey:@"ieCompatibility"]boolValue];
	bool ieCompatImage = ieCompatibility && [self isKindOfClass:[ACSDImage class]];
	if (linkedObjects && ([linkedObjects count] > 0))
		[bodyString appendFormat:@"<a name=\"%lx\">",(NSUInteger)self];
	else if (ieCompatibility && (clickThrough || (link != nil)))
		[bodyString appendFormat:@"<a id=\"i%@\">",objName];
	if (vectorMode == VECTOR_GRAPHICS_SVG)
		[bodyString appendFormat:@"<object border=\"0\" height=\"%d\" width=\"%d\" src=\"smallimages/%@.%@\"/>",
		 (int)b.size.height,(int)b.size.width,objName,@"svg"];
	else if (vectorMode == VECTOR_GRAPHICS_BITMAP)
	{
		[bodyString appendFormat:@"<img border=\"0\" height=\"%d\" width=\"%d\" ",(int)b.size.height,(int)b.size.width];
		if (toolTip && ieCompatImage)
			[bodyString appendFormat:@"title=\"%@\" ",toolTip];
		[bodyString appendFormat:@"src=\"smallimages/%@.%@\"/>",objName,[[options objectForKey:@"htmlSettings"]objectForKey:@"imageSuffix"]];
		if (ieCompatImage && clickThrough && (link == nil))
			[ieString appendFormat:@"\t\t\tdocument.all.i%@.href=\'largeimages/%@.%@\';\n",objName,
			 objName,[[options objectForKey:@"htmlSettings"]objectForKey:@"imageSuffix"]];
	}
	else
	{
		[bodyString appendFormat:@"<canvas id=\"c_%@\" height=\"%d\" width=\"%d\" >\n\tCanvas not supported\n</canvas>\n",objName,(int)b.size.height,(int)b.size.width];
	}
	if ((linkedObjects && ([linkedObjects count] > 0))||(ieCompatibility && (clickThrough || (link != nil))))
		[bodyString appendString:@"</a>"];
	[bodyString appendString:@"\n\t\t</div>\n"];
	if (link)
	{
		NSString *urlString = [self linkUrlStringOptions:options];
		b = NSIntegralRect([self transformedBounds]);
		[cssString appendFormat:@"\t\t\t#%@a {position: absolute; top: %dpx; left: %dpx; height: %dpx; width: %dpx; padding: 0px; margin: 0px; z-index: 2;cursor:pointer}\n",
		 objName,(int)(sz.height-NSMaxY(b)),(int)(NSMinX(b)),(int)b.size.height,(int)b.size.width];
		//		[bodyString appendFormat:@"\t\t<div id=\"%@a\" onclick=\"javascript:golink('%@')\"></div>",objName,urlString];
		[bodyString appendFormat:@"\t\t<div id=\"%@a\" onclick=\"window.location.href='%@'\"></div>\n",objName,urlString];
		if (ieCompatibility)
			[ieString appendFormat:@"\t\t\tdocument.all.i%@.href=\'%@\';\n",objName,urlString];
	}
	else
	{
		NSSize finalSize;
		if([self processClickThrough:options size:&finalSize])
		{
			b = NSIntegralRect([self transformedBounds]);
			[cssString appendFormat:@"\t\t\t#%@a {position: absolute; top: %dpx; left: %dpx; height: %dpx; width: %dpx; padding: 0px; margin: 0px; z-index: 2;cursor:pointer}\n",
			 objName,(int)(sz.height-NSMaxY(b)),(int)(NSMinX(b)),(int)b.size.height,(int)b.size.width];
			[bodyString appendFormat:@"\t\t<div id=\"%@a\" ",objName];
			if (toolTip)
				[bodyString appendFormat:@"title=\"%@\" ",toolTip];
			[bodyString appendFormat:@"onclick=\"javascript:show_wind(\'%@\',\'%@\',%g,%g,\'%@\')\"></div>\n",
			 objName,[@"largeimages" stringByAppendingPathComponent:[objName stringByAppendingPathExtension:@"jpg"]],finalSize.width,finalSize.height,[self name]];
		}
	}
	int i = [[options objectForKey:@"imageNo"]intValue];
	[options setObject:[NSNumber numberWithInt:i+1] forKey:@"imageNo"];
}

-(NSImage*)imageForDrag
{
	if (graphicCache)
		return [graphicCache image];
	return nil;
}

-(void)moveWithinBoundsOfView:(NSView*)view
   {
	float deltaX = 0.0,deltaY = 0.0;
	NSRect f = [view bounds];
	if (bounds.origin.x > NSMaxX(f))
		deltaX = NSMaxX(bounds) - NSMaxX(f) + 20;
	if (bounds.origin.y > NSMaxY(f))
		deltaY = NSMaxY(bounds) - NSMaxY(f) + 20;
	[self moveBy:NSMakePoint(-deltaX,-deltaY)];
   }

-(BOOL)doesTextFlow
   {
	return NO;
   }

-(void)updateForStyle:(ACSDStyle*)style oldAttributes:(NSDictionary*)oldAttrs
   {
   }

-(void)addLinksForPDFContext:(CGContextRef) context
   {
	if (link)
	   {
		if ([link isKindOfClass:[NSURL class]])
			CGPDFContextSetURLForRect(context,(CFURLRef)link,CGRectFromNSRect([self transformedBounds]));
		else if ([link isKindOfClass:[ACSDLink class]])
			CGPDFContextSetDestinationForRect(context,(CFStringRef)[link anchorNameForToObject],CGRectFromNSRect([self transformedBounds]));
	   }
	if (linkedObjects && [linkedObjects count] > 0)
	   {
		NSRect r = [self transformedBounds];
		CGPDFContextAddDestinationAtPoint(context,(CFStringRef)[ACSDLink anchorNameForObject:self],CGPointMake(NSMidX(r),NSMidY(r)));
	   }
   }

-(void)invalidateTextFlower
   {
   }

-(NSBezierPath*)pathTextGetPath
{
	return [self transformedBezierPath];
}

#define PS_FORMAT  0
#define CSV_FORMAT  1

-(NSString*)pathTextForPath:(NSBezierPath*)p format:(int)format
{
	NSUInteger ct = [p elementCount];
	if (ct < 2)
		return @"";
	NSString *moveFormat = @"[moveto %g %g]\n";
	NSString *lineFormat = @"[lineto %g %g]\n";
	NSString *curveFormat = @"[curveto %g %g %g %g %g %g]\n";
	NSString *lineCSVFormat = @"<pathelement>%g,%g,%g,%g</pathelement>\n";
	NSString *curveCSVFormat = @"<pathelement>%g,%g,%g,%g,%g,%g,%g,%g</pathelement>\n";
	NSMutableString *pathString = [NSMutableString stringWithCapacity:ct * 10];
	NSPoint firstPoint = NSMakePoint(0.0,0.0),lastPoint = firstPoint;
	NSRect r = [p bounds];
	[pathString appendFormat:@"\n\n//Bounds: %g,%g,%g,%g\n\n",r.origin.x,r.origin.y,r.size.width,r.size.height];
	BOOL closed = NO;
	for (int i = 0;i < ct;i++)
	{
		NSPoint pt[3];
		NSBezierPathElement el = [p elementAtIndex:i associatedPoints:pt];
		switch (el)
		{
			case NSMoveToBezierPathElement:
				if (format == PS_FORMAT)
					[pathString appendFormat:moveFormat,pt[0].x,pt[0].y];
				firstPoint = lastPoint = pt[0];
				break;
			case NSLineToBezierPathElement:
				if (format == PS_FORMAT)
					[pathString appendFormat:lineFormat,pt[0].x,pt[0].y];
				else
					[pathString appendFormat:lineCSVFormat,lastPoint.x,lastPoint.y,pt[0].x,pt[0].y];
				lastPoint = pt[0];
				break;
			case NSCurveToBezierPathElement:
				if (format == PS_FORMAT)
					[pathString appendFormat:curveFormat,pt[2].x,pt[2].y,pt[0].x,pt[0].y,pt[1].x,pt[1].y];
				else
					[pathString appendFormat:curveCSVFormat,lastPoint.x,lastPoint.y,pt[0].x,pt[0].y,pt[1].x,pt[1].y,pt[2].x,pt[2].y];
				lastPoint = pt[2];
				break;
			case NSClosePathBezierPathElement:
				[pathString appendString:@"[close]\n"];
				closed = YES;
				break;
		}
	}
	if (!closed && NSEqualPoints(firstPoint,lastPoint))
		[pathString appendString:@"[close]\n"];
	return pathString;
}

/*-(NSString*)pathTextInvertY:(BOOL)invertY
{
	NSBezierPath *p = [[[self pathTextGetPath]copy]autorelease];
	int format = PS_FORMAT;
	if (invertY)
	{
		float h = [self document].documentSize.height;
		NSAffineTransform *t = [NSAffineTransform transformWithTranslateXBy:0 yBy:h];
		[t scaleXBy:1.0 yBy:-1];
		[p transformUsingAffineTransform:t];
		format = CSV_FORMAT;
	}
	return [self pathTextForPath:p format:format];
}*/

-(NSString*)pathTextInvertY:(BOOL)invertY
{
	NSBezierPath *p = [[[self pathTextGetPath]copy]autorelease];
	int format = PS_FORMAT;
	NSString *returnString;
	NSSize sz = [self document].documentSize;
	if (invertY)
	{
		float h = sz.height;
		NSAffineTransform *t = [NSAffineTransform transformWithTranslateXBy:0 yBy:h];
		[t scaleXBy:1.0 yBy:-1];
		[p transformUsingAffineTransform:t];
		format = CSV_FORMAT;
	}
	returnString = [self pathTextForPath:p format:format];
	NSAffineTransform *t = [NSAffineTransform transformWithScaleXBy:1/sz.width yBy:1/sz.height];
	[p transformUsingAffineTransform:t];
	return [NSString stringWithFormat:@"%@\n--\n%@",returnString,[self pathTextForPath:p format:format]];
}


-(BOOL)addTrigger:(NSDictionary*)t
{
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

-(void)permanentScale:(float)sc transform:(NSAffineTransform*)t
{
	NSRect r = [t transformRect:[self bounds]];
	[self setGraphicBoundsTo:r from:[self bounds]];
}

-(NSString*)xmlAttributes:(NSMutableDictionary*)options
{
	NSMutableString *attrString = [NSMutableString stringWithCapacity:100];
	int docx = [[options objectForKey:xmlDocWidth]intValue];
	int docy = [[options objectForKey:xmlDocHeight]intValue];
	NSPoint pt = [self centrePoint];
	[attrString appendFormat:@" x=%g y=%g",pt.x,pt.y];
	float x = pt.x / docx;
	float y = pt.y / docy;
	[attrString appendFormat:@" relx=%g rely=%g",x,y];
	if (xScale != 1.0)
		[attrString appendFormat:@" scalex=%g",xScale];
	if (yScale != 1.0)
		[attrString appendFormat:@" scaley=%g",yScale];
	if (rotation != 0.0)
		[attrString appendFormat:@" rotation=%g",rotation];
	return attrString;
}

-(NSString*)graphicXML:(NSMutableDictionary*)options
{
	NSMutableString *graphicString = [NSMutableString stringWithCapacity:100];
	NSString *indent = [options objectForKey:xmlIndent];
	NSString *classname = [[NSStringFromClass([self class])substringFromIndex:4]lowercaseString];
	[graphicString appendFormat:@"%@<%@ name=\"%@\"",indent,classname,self.name];
	[graphicString appendFormat:@"%@ >\n",[self xmlAttributes:options]];
	[graphicString appendFormat:@"%@</%@>\n",indent,classname];
	[options setObject:indent forKey:xmlIndent];
	return graphicString;
}

-(NSRect)parentRect:(NSMutableDictionary*)options
{
    NSRect r = NSMakeRect(0, 0, [[options objectForKey:xmlDocWidth]intValue],[[options objectForKey:xmlDocHeight]intValue]);
    if (self.link != nil)
    {
        if ([self.link isKindOfClass:[ACSDLink class]])
        {
            ACSDLink *l = self.link;
            if ([l.toObject isKindOfClass:[ACSDGraphic class]])
            {
                ACSDGraphic *g = l.toObject;
                r = [g transformedBounds];
            }
        }
    }
    return r;
}

-(NSString*)graphicAttributesXML:(NSMutableDictionary*)options
{
	NSMutableString *attrString = [NSMutableString stringWithCapacity:100];
	int docHeight = [[options objectForKey:xmlDocHeight]intValue];
    NSRect r = [self parentRect:options];
    NSPoint pt = [self centrePoint];
	if (self.linkAlignmentFlags != 0)
	{
		int vert = (self.linkAlignmentFlags >> 2) & 0x3;
        vert = (vert + 1) % 3;
		int horiz = self.linkAlignmentFlags & 0x3;
        horiz = (horiz + 1) % 3;
		[attrString appendFormat:@" anchor=\"%g,%g\"",0.5 * horiz,0.5 * vert];
        NSRect b = [self transformedBounds];
		if (vert == 0)
			pt.y = NSMaxY(b);
		else if (vert == 2)
			pt.y = NSMinY(b);
		if (horiz == 0)
			pt.x = NSMinX(b);
		else if (horiz == 2)
			pt.x = NSMaxX(b);
	}
	NSPoint invpt = InvertedPoint(pt,docHeight);
	NSRect invrect = InvertedRect(r, docHeight);
	NSPoint relpt = RelativePointInRect(invpt.x, invpt.y, invrect);
	[attrString appendFormat:@" pos=\"%g,%g\"",relpt.x,relpt.y];
	NSString *source;
	if (self.sourcePath)
		source = [[self.sourcePath lastPathComponent]stringByDeletingPathExtension];
	else
		source = self.name;
	if (self.link && [self.link respondsToSelector:@selector(toObject)] && [[self.link toObject]isKindOfClass:[ACSDGraphic class]])
		[attrString appendFormat:@" parent=\"%@\"",[(ACSDGraphic*)[self.link toObject] name]];
	[attrString appendFormat:@" src=\"%@\"",source];
	if (xScale != 1.0)
		[attrString appendFormat:@" scalex=\"%g\"",xScale];
	if (yScale != 1.0 || xScale != 1.0)
		[attrString appendFormat:@" scaley=\"%g\"",yScale];
	if (rotation != 0.0)
		[attrString appendFormat:@" rotation=\"%g\"",rotation];
    if (fill)
    {
        if ([fill isKindOfClass:[ACSDGradient class]])
        {
            [attrString appendFormat:@" fill=\"url(#%@)\" ",[(ACSDGradient*)fill svgName:[self document]]];
        }
        else if ([fill isKindOfClass:[ACSDPattern class]])
        {
            [attrString appendFormat:@" fill=\"url(#%@)\" ",[(ACSDPattern*)fill svgName:[self document]]];
        }
		else if (fill.colour)
		{
			CGFloat r,g,b,a;
            [[fill.colour colorUsingColorSpaceName:NSDeviceRGBColorSpace device:nil]getRed:&r green:&g blue:&b alpha:&a];
            //[[fill.colour colorUsingColorSpaceName:NSCalibratedRGBColorSpace device:nil]getRed:&r green:&g blue:&b alpha:&a];
			if (a > 0.0)
			{
				r *= 255;
				g *= 255;
				b *= 255;
				[attrString appendFormat:@" fill=\"%d,%d,%d\"",(int)roundf(r),(int)roundf(g),(int)roundf(b)];
				if (a < 1.0)
					[attrString appendFormat:@" fillopacity=\"%g\"",a];
			}
		}
    }
    if (stroke && stroke.colour && stroke.lineWidth > 0.0)
    {
        CGFloat r,g,b,a;
        [[stroke.colour colorUsingColorSpaceName:NSDeviceRGBColorSpace device:nil]getRed:&r green:&g blue:&b alpha:&a];
        if (a > 0.0)
        {
            r *= 255;
            g *= 255;
            b *= 255;
            [attrString appendFormat:@" stroke=\"%d,%d,%d\"",(int)roundf(r),(int)roundf(g),(int)roundf(b)];
            if (a < 1.0)
                [attrString appendFormat:@" strokeopacity=\"%g\"",a];
            [attrString appendFormat:@" strokewidth=\"%g\"",stroke.lineWidth];
			if (stroke.lineCap)
			{
				NSArray *caps = @[@"butt",@"round",@"square"];
				[attrString appendFormat:@" linecap=\"%@\"",caps[stroke.lineCap]];
			}
			if (stroke.lineJoin)
			{
				NSArray *caps = @[@"miter",@"round",@"bevel"];
				[attrString appendFormat:@" linejoin=\"%@\"",caps[stroke.lineJoin]];
			}
            if (stroke.dashes && [stroke.dashes count] > 0)
            {
                if (stroke.dashPhase != 0)
                    [attrString appendFormat:@" stroke-dashoffset=\"%g\"",stroke.dashPhase];
                [attrString appendFormat:@" stroke-dasharray=\"%g",[stroke.dashes[0]floatValue]];
                for (int i = 1;i < [stroke.dashes count];i++)
                    [attrString appendFormat:@",%g",[stroke.dashes[i]floatValue]];
                [attrString appendString:@"\""];
            }
        }
    }
    if (shadowType && shadowType.colour)
    {
        CGFloat r,g,b,a;
        [[shadowType.colour colorUsingColorSpaceName:NSDeviceRGBColorSpace device:nil]getRed:&r green:&g blue:&b alpha:&a];
        if (a > 0.0)
        {
            r *= 255;
            g *= 255;
            b *= 255;
            [attrString appendFormat:@" shadowcolour=\"%d,%d,%d\"",(int)roundf(r),(int)roundf(g),(int)roundf(b)];
            if (a < 1.0)
                [attrString appendFormat:@" shadowopacity=\"%g\"",a];
            [attrString appendFormat:@" shadowradius=\"%g\"",shadowType.blurRadius];
            [attrString appendFormat:@" shadowxoffset=\"%g\"",shadowType.xOffset];
            [attrString appendFormat:@" shadowyoffset=\"%g\"",-shadowType.yOffset];
        }
    }
	if (isMask)
		[attrString appendString:@" hasmask=\"true\""];
    float zpos = [options[@"layerzidx"]floatValue] + [self.tempSettings[@"gzidx"]floatValue]/1000.0;
    [attrString appendFormat:@" zpos=\"%g\"",zpos];
    if (self.hidden)
        [attrString appendString:@" hidden=\"true\""];
    if (self.alpha != 1.0)
        [attrString appendFormat:@" opacity=\"%g\"",self.alpha];
    for (NSArray *attrs in self.attributes)
        [attrString appendFormat:@" %@=\"%@\"",attrs[0],attrs[1]];
	return attrString;
}

-(NSString*)xmlEventTypeName
{
	return [[[self class]graphicTypeName]lowercaseString];
}

-(NSString*)graphicXMLForEvent:(NSMutableDictionary*)options
{
	NSMutableString *graphicString = [NSMutableString stringWithCapacity:100];
	NSString *indent = [options objectForKey:xmlIndent];
    if ([self.fill isKindOfClass:[ACSDGradient class]])
        [graphicString appendString:[((ACSDGradient*)self.fill)graphicXMLForEvent:options]];
    else if ([self.fill isKindOfClass:[ACSDPattern class]])
        [graphicString appendString:[((ACSDPattern*)self.fill)graphicXMLForEvent:options]];
	[graphicString appendFormat:@"%@<%@ id=\"%@\"",indent,[self xmlEventTypeName],self.name];
	[graphicString appendFormat:@"%@ />\n",[self graphicAttributesXML:options]];
	[options setObject:indent forKey:xmlIndent];
	return graphicString;
}

-(NSPoint)positionRelativeToRect:(NSRect)rect
{
    NSPoint pt = [self centrePoint];
    pt.x -= rect.origin.x;
    pt.y -= rect.origin.y;
    pt.x = pt.x / rect.size.width;
    pt.y = pt.y /rect.size.height;
    return pt;
}

-(void)setPosition:(NSPoint)pt
{
    NSPoint p2 = [self centrePoint];
	[self uMoveBy:diff_points(pt, p2)];

}

-(ACSDGroup*)primogenitor
{
    ACSDGraphic *dad = self;
    while (dad.parent != nil)
        dad = dad.parent;
    return (dad == self)?nil:((ACSDGroup*)dad);
}

-(NSMutableSet*)linkedObjects
{
    return linkedObjects;
}

-(int)zDepth
{
	return 1;
}

-(NSArray*)indexPathFromAncestor:(ACSDGroup*)anc array:(NSArray*)inArray
{
	if (parent == nil)
		return nil;
	NSInteger idx = [parent.graphics indexOfObjectIdenticalTo:self];
	inArray = [@[@(idx)] arrayByAddingObjectsFromArray:inArray];
	if (parent == anc)
		return inArray;
	return [parent indexPathFromAncestor:anc array:inArray];
}

-(NSArray*)indexPathFromAncestor:(ACSDGroup*)anc
{
	return [self indexPathFromAncestor:anc array:@[]];
}
@end
