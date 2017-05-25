//
//  ACSDConnector.mm
//  ACSDraw
//
//  Created by alan on 30/04/06.
//  Copyright 2006 Alan C Smith. All rights reserved.
//

#import "ACSDConnector.h"
#import "GraphicView.h"
#import "ConnectorAttachment.h"
#import "ArrayAdditions.h"
#import "geometry.h"
#import "ACSDPath.h"
#import "SizeController.h"


@implementation ACSDConnector

+ (NSString*)graphicTypeName
   {
	return @"Connector";
   }

-(id)initWithName:(NSString*)n fill:(ACSDFill*)f stroke:(ACSDStroke*)str rect:(NSRect)r layer:(ACSDLayer*)l
		  graphic:(ACSDGraphic*)g knobDescriptor:(const KnobDescriptor&)kd offset:(NSPoint)os distance:(float)d
   {
    if (self = [super initWithName:n fill:nil stroke:str rect:r layer:l])
	   {
		elbow = NO_ELBOW;
		self.fromGraphics = [NSMutableArray arrayWithCapacity:10];
		self.toGraphics = [NSMutableArray arrayWithCapacity:10];
		[self setFromGraphic:g knob:kd offset:os distance:d];
		[self generateBezierPath];
	   }
	return self;
   }

-(id)initWithName:(NSString*)n fill:(ACSDFill*)f stroke:(ACSDStroke*)str rect:(NSRect)r layer:(ACSDLayer*)l
		   xScale:(float)xs yScale:(float)ys rotation:(float)rot shadowType:(ShadowType*)st label:(ACSDLabel*)lab alpha:(float)a
		  graphic:(ACSDGraphic*)g knobDescriptor:(const KnobDescriptor&)kd offset:(NSPoint)os distance:(float)d
   {
    if (self = [super initWithName:n fill:f stroke:str rect:r layer:l xScale:xs yScale:ys rotation:rot shadowType:st label:lab alpha:a])
	   {
		elbow = NO_ELBOW;
		self.fromGraphics = [NSMutableArray arrayWithCapacity:10];
		self.toGraphics = [NSMutableArray arrayWithCapacity:10];
		[self setFromGraphic:g knob:kd offset:os distance:d];
		[self generateBezierPath];
	   }
	return self;
   }
- (id)copyWithZone:(NSZone *)zone 
   {
//    id obj = [[[self class] allocWithZone:zone] initWithName:[self name] fill:[self fill] stroke:[self stroke] rect:[self bounds]
//														view:[self graphicView] layer:layer xScale:xScale yScale:yScale rotation:rotation shadowType:[self shadowType] label:textLabel
//													   alpha:alpha
//												fromGraphics:[fromGraphics copiedObjects] toGraphics:[toGraphics copiedObjects]elbow:elbow];
	id obj = [super copyWithZone:zone];
	[obj setElbow:elbow];
	[obj setFromGraphics:[self.fromGraphics mutableCopy]];
	[obj setToGraphics:[self.toGraphics mutableCopy]];
	[obj generateBezierPath];
	return obj;
   }

-(void)mapCopiedObjectsFromDictionary:(NSDictionary*)map
   {
	if ([self.fromGraphics count] > 0)
	   {
		ConnectorAttachment *ca = [self.fromGraphics objectAtIndex:0];
		ACSDGraphic *newGraphic = [map objectForKey:[NSValue valueWithNonretainedObject:[ca graphic]]];
		if (newGraphic)
			[self setFromGraphic:newGraphic knob:[ca knob] offset:[ca offset] distance:0.0];
	   }
	if ([self.toGraphics count] > 0)
	   {
		ConnectorAttachment *ca = [self.toGraphics objectAtIndex:0];
		ACSDGraphic *newGraphic = [map objectForKey:[NSValue valueWithNonretainedObject:[ca graphic]]];
		if (newGraphic)
			[self setToGraphic:newGraphic knob:[ca knob] offset:[ca offset] distance:0.0];
	   }
   }

-(void)allocHandlePoints
   {
	handlePoints = new NSPoint[2];
	noHandlePoints = 2;
   }

-(BOOL)hasClosedPath
   {
	return NO;
   }


- (void) encodeWithCoder:(NSCoder*)coder
   {
	[super encodeWithCoder:coder];
	[coder encodeInt:elbow forKey:@"ACSDConnector_elbow"];
	[coder encodeObject:self.fromGraphics forKey:@"ACSDConnector_fromGraphics"];
	[coder encodeObject:self.toGraphics forKey:@"ACSDConnector_toGraphics"];
   }

- (id) initWithCoder:(NSCoder*)coder
   {
	self = [super initWithCoder:coder];
	elbow = [coder decodeIntForKey:@"ACSDConnector_elbow"];
	self.fromGraphics = [coder decodeObjectForKey:@"ACSDConnector_fromGraphics"];
	self.toGraphics = [coder decodeObjectForKey:@"ACSDConnector_toGraphics"];
	[self.fromGraphics makeObjectsPerformSelector:@selector(addConnector:) withObject:self];
	[self.toGraphics makeObjectsPerformSelector:@selector(addConnector:) withObject:self];
	handlePoints = new NSPoint[2];
	noHandlePoints = 2;
	bezierPath = [NSBezierPath bezierPath];
	[self generateBezierPath];
	return self;
   }

-(int)elbow
   {
	return elbow;
   }

-(void)setElbow:(int)e
   {
	elbow = e;
   }

-(NSPoint)toPt
   {
	if ([self.toGraphics count] == 0)
		return NSZeroPoint;
	ConnectorAttachment *ca = [self.toGraphics objectAtIndex:0];
	if ([ca graphic] == nil)
		return [ca offset];
	return offset_point([[ca graphic]pointForKnob:[ca knob]],[ca offset]);
   }

-(NSPoint)fromPt
   {
	if ([self.fromGraphics count] == 0)
		return NSZeroPoint;
	ConnectorAttachment *ca = [self.fromGraphics objectAtIndex:0];
	if ([ca graphic] == nil)
		return [ca offset];
	return offset_point([[ca graphic]pointForKnob:[ca knob]],[ca offset]);
   }

-(ACSDGraphic*)fromGraphic
   {
	if ([self.fromGraphics count] > 0)
		return [[self.fromGraphics objectAtIndex:0]graphic];
	return nil;
   }

-(ACSDGraphic*)toGraphic
   {
	if ([self.toGraphics count] > 0)
		return [[self.toGraphics objectAtIndex:0]graphic];
	return nil;
   }

-(void)setFromGraphic:(ACSDGraphic*)g knob:(const KnobDescriptor&)kd offset:(NSPoint)pt distance:(float)d
   {
	[self.fromGraphics makeObjectsPerformSelector:@selector(removeConnector:)withObject:self];
	[self.fromGraphics removeAllObjects];
	[self.fromGraphics addObject:[ConnectorAttachment connectorAttachmentWithKnob:kd graphic:g offset:pt distance:d]];
	[self.fromGraphics makeObjectsPerformSelector:@selector(addConnector:)withObject:self];
   }

-(void)setToGraphic:(ACSDGraphic*)g knob:(const KnobDescriptor&)kd offset:(NSPoint)pt distance:(float)d
   {
	[self.toGraphics makeObjectsPerformSelector:@selector(removeConnector:)withObject:self];
	[self.toGraphics removeAllObjects];
	[self.toGraphics addObject:[ConnectorAttachment connectorAttachmentWithKnob:kd graphic:g offset:pt distance:d]];
	[self.toGraphics makeObjectsPerformSelector:@selector(addConnector:)withObject:self];
   }

-(void)preDelete
   {
	[self.fromGraphics makeObjectsPerformSelector:@selector(removeConnector:)withObject:self];
	[self.toGraphics makeObjectsPerformSelector:@selector(removeConnector:)withObject:self];
   }

-(void)postUndelete
   {
	[self.fromGraphics makeObjectsPerformSelector:@selector(addConnector:)withObject:self];
	[self.toGraphics makeObjectsPerformSelector:@selector(addConnector:)withObject:self];
   }

- (void)generateBezierPath
   {
	if (bezierPath)
		[bezierPath removeAllPoints];
	else
		bezierPath = [NSBezierPath bezierPath];
	NSPoint pt = [self fromPt];
	if (NSEqualPoints(pt,NSZeroPoint))
		return;
	[bezierPath moveToPoint:pt];
	pt = [self toPt];
	if (!NSEqualPoints(pt,NSZeroPoint))
		[bezierPath lineToPoint:pt];
   }

- (void)moveBy:(NSPoint)vector
   {
   }

- (void)uMoveBy:(NSPoint)vector
   {
   }

-(void)computeHandlePoints
   {
	handlePoints[0] = [self fromPt];
	handlePoints[1] = [self toPt];
   }

- (BOOL)createWithEvent:(NSEvent *)theEvent inView:(GraphicView *)view 
   {
    NSPoint point = [view convertPoint:[theEvent locationInWindow] fromView:nil],actualPoint=NSZeroPoint;
    [self setBounds:rectFromPoints([self fromPt],[self toPt])];
	[view setHandleBitsH:(int)[self toPt].x v:(int)[self toPt].y];
	[[NSNotificationCenter defaultCenter] postNotificationName:ACSDShowCoordinatesNotification object:self
													  userInfo:[NSDictionary dictionaryWithObject:[NSNumber numberWithBool:YES] forKey:@"vis"]];
	ACSDGraphic *fromGraphic = [self fromGraphic];
	BOOL can = NO,periodicStarted=NO;
    while (1)
	   {
		if (opCancelled)
		   {
			[self setOpCancelled:NO];
			can = YES;
			break;
		   }
        theEvent = [[view window] nextEventMatchingMask:(NSLeftMouseDraggedMask | NSLeftMouseUpMask | NSKeyDownMask | NSPeriodicMask)];
		if ([theEvent type] == NSKeyDown)
		   {
			[view keyDown:theEvent];
			continue;
		   }		
        if ([theEvent type] == NSPeriodic)
		   {
			[view scrollRectToVisible:RectFromPoint(actualPoint,40.0,[view magnification])];
			actualPoint = [view convertPoint:[[view window] mouseLocationOutsideOfEventStream] fromView:nil];
		   }
		else
			actualPoint = [view convertPoint:[theEvent locationInWindow] fromView:nil];
		ACSDGraphic *toGraphic;
		if ((toGraphic = [view shapeUnderPoint:actualPoint extending:NO]) && (toGraphic != fromGraphic))
		   {
			KnobDescriptor kd = [toGraphic nearestKnobForPoint:actualPoint];
			NSPoint knobPoint = [toGraphic pointForKnob:kd];
			NSPoint os = diff_points(actualPoint,knobPoint);
			[self setToGraphic:toGraphic knob:kd offset:os distance:0.0];
		   }			
		else
			[self setToGraphic:nil knob:KnobDescriptor(NoKnob) offset:actualPoint distance:0.0];
		[self reformConnector];
		[self postChangeOfBounds];
		[ACSDGraphic postChangeFromAnchorPoint:[self fromPt] toPoint:[self toPt]];
		periodicStarted = [view scrollIfNecessaryPoint:point periodicStarted:periodicStarted];
        if ([theEvent type] == NSLeftMouseUp)
            break;
       }
	if (periodicStarted)
		[NSEvent stopPeriodicEvents];
	[[NSNotificationCenter defaultCenter] postNotificationName:ACSDShowCoordinatesNotification object:self
													  userInfo:[NSDictionary dictionaryWithObject:[NSNumber numberWithBool:NO] forKey:@"vis"]];
    NSRect theBounds = [self bounds];
    return ((theBounds.size.width > 0.0) || (theBounds.size.height > 0.0)) && !can;
   }

- (BOOL)trackDetachedKnob:(KnobDescriptor&)kd withEvent:(NSEvent *)theEvent view:(GraphicView*)view
   {
    //NSPoint point = [view convertPoint:[theEvent locationInWindow] fromView:nil]
	NSPoint actualPoint;
	[[NSNotificationCenter defaultCenter] postNotificationName:ACSDShowCoordinatesNotification object:self
													  userInfo:[NSDictionary dictionaryWithObject:[NSNumber numberWithBool:YES] forKey:@"vis"]];
	ACSDGraphic *constantGraphic;
	if (kd.knob == 0)
		constantGraphic = [self toGraphic];
	else
		constantGraphic = [self fromGraphic];
    while (1)
	   {
        theEvent = [[view window] nextEventMatchingMask:(NSLeftMouseDraggedMask | NSLeftMouseUpMask)];
		actualPoint = [view convertPoint:[theEvent locationInWindow] fromView:nil];
		ACSDGraphic *changingGraphic;
		if ((changingGraphic = [view shapeUnderPoint:actualPoint extending:NO]) && (changingGraphic != constantGraphic))
		   {
			KnobDescriptor k = [changingGraphic nearestKnobForPoint:actualPoint];
			NSPoint knobPoint = [changingGraphic pointForKnob:k];
			NSPoint os = diff_points(actualPoint,knobPoint);
			if (kd.knob == 0)
				[self setFromGraphic:changingGraphic knob:k offset:os distance:0.0];
			else
				[self setToGraphic:changingGraphic knob:k offset:os distance:0.0];
		   }			
		else
			if (kd.knob == 0)
				[self setFromGraphic:nil knob:KnobDescriptor(NoKnob) offset:actualPoint distance:0.0];
			else
				[self setToGraphic:nil knob:KnobDescriptor(NoKnob) offset:actualPoint distance:0.0];
		[self reformConnector];
		[self postChangeOfBounds];
		[ACSDGraphic postChangeFromAnchorPoint:[self fromPt] toPoint:[self toPt]];
        if ([theEvent type] == NSLeftMouseUp)
            break;
       }
	[[NSNotificationCenter defaultCenter] postNotificationName:ACSDShowCoordinatesNotification object:self
													  userInfo:[NSDictionary dictionaryWithObject:[NSNumber numberWithBool:NO] forKey:@"vis"]];
	return YES;
   }

-(BOOL)trackInit:(KnobDescriptor&)kd withEvent:(NSEvent *)theEvent inView:(GraphicView*)view ok:(BOOL*)success
{
	if ([theEvent modifierFlags] & NSCommandKeyMask)
	{
		NSPoint point = [view convertPoint:[theEvent locationInWindow] fromView:nil];
		if (kd.knob == 0)
			[self setFromGraphic:nil knob:KnobDescriptor(NoKnob) offset:point distance:0.0];
		else
			[self setToGraphic:nil knob:KnobDescriptor(NoKnob) offset:point distance:0.0];
		*success = [self trackDetachedKnob:kd withEvent:theEvent view:view];
		return YES;
	}
	return NO;
}
-(void)uMoveFromKnobFromPoint:(NSPoint)fp toPoint:(NSPoint)tp
   {
	[[[self undoManager] prepareWithInvocationTarget:self] uMoveFromKnobFromPoint:tp toPoint:fp];
	ConnectorAttachment *ca = [self.fromGraphics objectAtIndex:0];
	ACSDGraphic *g = [ca graphic];
	KnobDescriptor gk = [ca knob];
	NSPoint offset =  diff_points(tp,[g pointForKnob:gk]);
	[self setFromGraphic:g knob:gk offset:offset distance:0.0];
	[self reformConnector];
   }

-(void)uMoveToKnobFromPoint:(NSPoint)fp toPoint:(NSPoint)tp
   {
	[[[self undoManager] prepareWithInvocationTarget:self] uMoveToKnobFromPoint:tp toPoint:fp];
	ConnectorAttachment *ca = [self.toGraphics objectAtIndex:0];
	ACSDGraphic *g = [ca graphic];
	KnobDescriptor gk = [ca knob];
	NSPoint offset =  diff_points(tp,[g pointForKnob:gk]);
	[self setToGraphic:g knob:gk offset:offset distance:0.0];
	[self reformConnector];
   }

- (KnobDescriptor)resizeByMovingKnob:(KnobDescriptor)kd toPoint:(NSPoint)point event:(NSEvent *)theEvent constrain:(BOOL)constrain aroundCentre:(BOOL)aroundCentre
   {
	if (kd.knob == 0)	//from point
		[self uMoveFromKnobFromPoint:[self fromPt] toPoint:point];
	else
		[self uMoveToKnobFromPoint:[self toPt] toPoint:point];
	return kd;
   }

-(void)reformConnector
   {
	[self invalidateInView];
	[self invalidateGraphicSizeChanged:NO shapeChanged:NO redraw:NO notify:NO];
	[self generateBezierPath];
	[self setBounds:[[self bezierPath]bounds]];
	[self invalidateGraphicSizeChanged:YES shapeChanged:YES redraw:YES notify:NO];
	[self computeHandlePoints];
   }

- (BOOL)intersectsWithRect:(NSRect)selectionRect	//used for selecting with rubberband
   {
	if (transform == nil)
		return lineInRect(selectionRect,[self fromPt],[self toPt]);
	return [super intersectsWithRect:selectionRect];
   }

@end
