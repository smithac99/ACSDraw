#import "GradientControl.h"
#import "GradientElement.h"
#import "GradientRulerView.h"

GradientElement* gradientElementForMarker(NSRulerMarker* m);
NSColor* colourForMarker(NSRulerMarker* m);

@implementation GradientControl

-(NSRect)patternBounds
   {
	NSRect r = [self bounds];
	r.origin.x += margin;
	r.size.width -= (2 * margin);
	return r;
   }

- (void)drawRect:(NSRect)aRect
   {
	if (gradient)
		[gradient fillPath:[NSBezierPath bezierPathWithRect:[self patternBounds]]angle:0];
   }

-(void)setup
   {
	[NSScrollView setRulerViewClass:[GradientRulerView class]];
	[[self enclosingScrollView]setHasHorizontalRuler:YES];
	[[self enclosingScrollView]setRulersVisible:YES];
	rulerView = [[self enclosingScrollView]horizontalRulerView];
	[rulerView setClientView:self];
	margin = [[NSImage imageNamed:@"gradientmarker"]size].width / 2;
	float fw = [self bounds].size.width - margin - margin;
	[NSRulerView registerUnitWithName:@"Width" abbreviation:@"w" unitToPointsConversionFactor:fw 
						  stepUpCycle:[NSArray arrayWithObjects:[NSNumber numberWithFloat:2.0],nil] 
						stepDownCycle:[NSArray arrayWithObjects:[NSNumber numberWithFloat:0.5],[NSNumber numberWithFloat:0.25],nil]
		];
	[rulerView setMeasurementUnits:@"Width"];
	[rulerView setOriginOffset:margin];
//	[rulerView setRuleThickness:8];
   }

GradientElement* gradientElementForMarker(NSRulerMarker* m)
   {
	NSValue *v = (NSValue*)[m representedObject];
	GradientElement *ge = (GradientElement*)[v nonretainedObjectValue];
	return ge;
   }

NSColor* colourForMarker(NSRulerMarker* m)
   {
	return [gradientElementForMarker(m) colour];
   }

-(void)selectRulerMarker:(NSRulerMarker*)m
   {
	if (selectedRulerMarker == m)
		return;
	if (selectedRulerMarker)
	   {
		[selectedRulerMarker setImage:[NSImage imageNamed:@"gradientmarker"]];
		[rulerView setNeedsDisplay:YES];
	   }
	selectedRulerMarker = m;
	[selectedRulerMarker setImage:[NSImage imageNamed:@"gradientmarkerselb"]];
	[gradientColourWell setColor:colourForMarker(m)];
   }

-(void)doRemovables
   {
	BOOL removable = [[rulerView markers]count] > 2;
	for (unsigned i = 0;i < [[rulerView markers]count];i++)
		[[[rulerView markers]objectAtIndex:i]setRemovable:removable];
   }

-(void)setupMarkers
{
	[rulerView setMarkers:nil];
	selectedRulerMarker = nil;
	if (!gradient)
		return;
	NSArray *arr = [gradient gradientElements];
	float vWidth = [self bounds].size.width - 2 * margin;
	NSImage *im = [NSImage imageNamed:@"gradientmarker"];
	for (unsigned i = 0;i < [arr count];i++)
	{
		GradientElement *ge = [arr objectAtIndex:i];
		NSRulerMarker *marker = [[NSRulerMarker alloc]initWithRulerView:rulerView
														 markerLocation:[ge position] * vWidth + margin
																  image:im
															imageOrigin:NSMakePoint([im size].width/2,0)];
		[marker setMovable:YES];
		[marker setRepresentedObject:[NSValue valueWithNonretainedObject:ge]];
		[rulerView addMarker:marker];
	}
	[self selectRulerMarker:[[rulerView markers]objectAtIndex:0]];
	[self doRemovables];
	[gradientAngleSlider setFloatValue:[gradient angle]];
	[gradientAngleTextField setFloatValue:[gradient angle]];
}

- (IBAction)gradientAngleSliderHit:(id)sender
   {
	if ([sender floatValue] != [gradient angle])
	   {
		[gradient setAngle:[sender floatValue]];
		[gradientAngleTextField setFloatValue:[gradient angle]];
		[gradientDisplay setNeedsDisplay:YES];
	   }
   }

- (IBAction)gradientAngleTextFieldHit:(id)sender
   {
	if ([sender floatValue] != [gradient angle])
	   {
		float angle = [sender floatValue];
		if (angle < 0.0)
			angle += 360.0;
		else if (angle > 360.0)
			angle = angle - ((int)(angle / 360) * 360);
		[gradient setAngle:angle];
		[gradientAngleSlider setFloatValue:angle];
		[gradientDisplay setNeedsDisplay:YES];
	   }
   }

- (IBAction)gradientWellHit:(id)sender
   {
    NSColor *colour = [sender color];
	if (!selectedRulerMarker)
		return;
	GradientElement *ge = gradientElementForMarker(selectedRulerMarker);
	if (![colour isEqual:[ge colour]])
	   {
        [ge setColour:colour];
		[self setNeedsDisplay:YES];
		[gradientDisplay setNeedsDisplay:YES];
		[gradient invalidateGraphicsRefreshCache:YES];
       }
   }


-(void)setGradient:(ACSDGradient*)g
   {
	if (g == gradient)
		return;
	gradient = g;
	[self setupMarkers];
   }

- (BOOL)rulerView:(NSRulerView *)aRulerView shouldMoveMarker:(NSRulerMarker *)aMarker
   {
	[self selectRulerMarker:aMarker];
	return YES;
   }

- (void)rulerView:(NSRulerView *)aRulerView handleMouseDown:(NSEvent *)theEvent
   {
	NSPoint curPoint = [self convertPoint:[theEvent locationInWindow] fromView:nil];
	NSImage *im = [NSImage imageNamed:@"gradientmarkersel"];
	NSRulerMarker *m = [[NSRulerMarker alloc]initWithRulerView:aRulerView markerLocation:curPoint.x 
														 image:im 
												   imageOrigin:NSMakePoint([im size].width/2,0)];
	[aRulerView trackMarker:m withMouseEvent:theEvent];
   }


- (BOOL)rulerView:(NSRulerView *)aRulerView shouldAddMarker:(NSRulerMarker *)aMarker
   {
	return YES;
   }

- (void)rulerView:(NSRulerView *)aRulerView didRemoveMarker:(NSRulerMarker *)aMarker
   {
	NSRulerMarker *m;
	if ([[rulerView markers]count] > 0)
		m = [[rulerView markers]objectAtIndex:0];
	else 
		m = nil;
	[self selectRulerMarker:m];
	GradientElement *ge = gradientElementForMarker(aMarker);
	[[gradient gradientElements]removeObjectIdenticalTo:ge];
	[self setNeedsDisplay:YES];
	[gradientDisplay setNeedsDisplay:YES];
   }

- (void)rulerView:(NSRulerView *)aRulerView didAddMarker:(NSRulerMarker *)aMarker
   {
	float pos = ([aMarker markerLocation]-margin)/([self bounds].size.width - margin - margin);
	GradientElement *ge = [[GradientElement alloc]initWithPosition:pos colour:[gradient shadingColourForPosition:pos]];
	[aMarker setRepresentedObject:[NSValue valueWithNonretainedObject:ge]];
	[gradient addGradientElementAndOrder:ge];
		[self selectRulerMarker:aMarker];
	[self doRemovables];
	[self setNeedsDisplay:YES];
	[gradientDisplay setNeedsDisplay:YES];
   }

- (void)rulerView:(NSRulerView *)aRulerView didMoveMarker:(NSRulerMarker *)aMarker
   {
	[gradientElementForMarker(aMarker) setPosition:([aMarker markerLocation]-margin)/([self bounds].size.width - margin - margin)];
	[[gradient gradientElements]sortUsingSelector:@selector(comparePositionWith:)];
	[self setNeedsDisplay:YES];
	[gradientDisplay setNeedsDisplay:YES];
	[gradient invalidateGraphicsRefreshCache:YES];
   }

- (CGFloat)rulerView:(NSRulerView *)aRulerView willMoveMarker:(NSRulerMarker *)aMarker toLocation:(CGFloat)location
   {
	CGFloat loc = location;
	if (loc < margin)
		return margin;
	if (loc > NSMaxX([self bounds]) - margin)
		return NSMaxX([self bounds]) - margin;
	return loc;
   }

- (BOOL)acceptsFirstMouse:(NSEvent *)theEvent
{
	return YES;
}



@end
