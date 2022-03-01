#import "PatternWindowController.h"
#import "ACSDPage.h"
#import "ACSDLayer.h"
#import "ACSDGroup.h"

@implementation PatternWindowController

- (id)initWithPattern:(ACSDPattern*)p;
{
	[NSScrollView setRulerViewClass:[GraphicRulerView class]];
	if (self = [super initWithWindowNibName:@"PatternWindow"])
	{
		[self setShouldCloseDocument:NO];
		pattern = p;
		undoManager = [[NSUndoManager alloc]init];
		temporaryPattern = nil;
	}
	return self;
}

- (GraphicView*)graphicView
{
	return graphicView;
}

- (NSUndoManager*)undoManager
{
	//	return [[self document]undoManager];
	return undoManager;
}

- (void)windowDidLoad
{
	[self setActionsDisabled:YES];
	pages = [NSMutableArray arrayWithCapacity:1];
	ACSDPage *p = [[ACSDPage alloc]initWithDocument:[self document]];
	[pages addObject:p];
	[[graphicView enclosingScrollView]setHasHorizontalRuler:YES];
	[[graphicView enclosingScrollView]setHasVerticalRuler:YES];
	[[graphicView enclosingScrollView]setRulersVisible:YES];
	horizontalRuler = (GraphicRulerView*)[[graphicView enclosingScrollView]horizontalRulerView];
	verticalRuler = (GraphicRulerView*)[[graphicView enclosingScrollView]verticalRulerView];
	[horizontalRuler setMeasurementUnits:@"Points"];
	[verticalRuler setMeasurementUnits:@"Points"];
	ACSDGraphic *g = [[pattern graphic]copy];
	NSPoint viewCentrePoint = [graphicView bounds].origin;
	viewCentrePoint.x += [graphicView bounds].size.width / 2;
	viewCentrePoint.y += [graphicView bounds].size.height / 2;
	NSPoint graphicCentrePoint = [g bounds].origin;
	graphicCentrePoint.x += [g bounds].size.width / 2;
	graphicCentrePoint.y += [g bounds].size.height / 2;
	float deltaX = viewCentrePoint.x - graphicCentrePoint.x;
	float deltaY = viewCentrePoint.y - graphicCentrePoint.y;
	[g moveBy:NSMakePoint(deltaX,deltaY)];
	NSRect patternRect =  NSOffsetRect([pattern patternBounds],deltaX,deltaY);
	[horizontalRuler setReservedThicknessForMarkers:0.0];
	[horizontalRuler setOriginOffset:patternRect.origin.x];
	[verticalRuler setOriginOffset:patternRect.origin.y];
	[horizontalRuler setDelegate:self];
	[verticalRuler setDelegate:self];
	NSImage *markerImage = [NSImage imageNamed:@"markersmall"];
	NSImage *markerImage90 = [NSImage imageNamed:@"markersmall90"];
	NSRulerMarker *horizMarker = [[NSRulerMarker alloc]initWithRulerView:horizontalRuler 
														  markerLocation:patternRect.origin.x + patternRect.size.width 
																   image:markerImage imageOrigin:NSMakePoint([markerImage size].width/2,10)];
	[horizMarker setMovable:YES];
	[[[graphicView enclosingScrollView]horizontalRulerView]setClientView:graphicView];
	[[[graphicView enclosingScrollView]horizontalRulerView]addMarker:horizMarker];
	NSRulerMarker *verticalMarker = [[NSRulerMarker alloc]initWithRulerView:verticalRuler 
															 markerLocation:patternRect.origin.y + patternRect.size.height
																	  image:markerImage90 imageOrigin:NSMakePoint(10,[markerImage90 size].height/2)];
	[verticalMarker setMovable:YES];
	[[[graphicView enclosingScrollView]verticalRulerView]setClientView:graphicView];
	[[[graphicView enclosingScrollView]verticalRulerView]addMarker:verticalMarker];
	[[p currentLayer]addGraphic:g];
	verticalOriginLine = [[SnapLine alloc]initWithGraphicView:graphicView orientation:SNAPLINE_VERTICAL];
	[verticalOriginLine setVisible:YES];
	[verticalOriginLine setLocation:patternRect.origin.x];
	horizontalOriginLine = [[SnapLine alloc]initWithGraphicView:graphicView orientation:SNAPLINE_HORIZONTAL];
	[horizontalOriginLine setVisible:YES];
	[horizontalOriginLine setLocation:patternRect.origin.y];
	verticalLimitLine = [[SnapLine alloc]initWithGraphicView:graphicView orientation:SNAPLINE_VERTICAL];
	[verticalLimitLine setVisible:YES];
	[verticalLimitLine setLocation:NSMaxX(patternRect)];
	horizontalLimitLine = [[SnapLine alloc]initWithGraphicView:graphicView orientation:SNAPLINE_HORIZONTAL];
	[horizontalLimitLine setVisible:YES];
	[horizontalLimitLine setLocation:NSMaxY(patternRect)];
	[graphicView setDocumentBased:NO];
	[graphicView setPages:pages];
	[graphicView setDefaultStroke:[[[self document]strokes]objectAtIndex:1]];
	[graphicView setDefaultFill:[[[self document]fills]objectAtIndex:1]];
	[graphicView setPostsBoundsChangedNotifications:YES];
	[graphicView setPostsFrameChangedNotifications:YES];
	//	[graphicView setFrameSize:[[self document] documentSize]];
	//	if ([[self document]fileName])
	//		[[self window] setFrameUsingName:[[self document]fileName]];
	//	[self adjustWindowSize];
	//    [graphicView setNeedsDisplay:YES];
	[[self window]setAcceptsMouseMovedEvents:YES];
	[offsetText setFloatValue:[pattern offset]];
	[offsetSlider setFloatValue:[pattern offset]];
	[scaleText setFloatValue:[pattern scale]];
	[scaleSlider setFloatValue:log10([pattern scale])];
	[xSpacingText setFloatValue:[pattern xSpacing]];
	[xSpacingSlider setFloatValue:([pattern xSpacing])];
	[ySpacingText setFloatValue:[pattern ySpacing]];
	[ySpacingSlider setFloatValue:([pattern ySpacing])];
	[offsetTypeRBMatrix selectCellAtRow:0 column:[pattern offsetMode]];
	[opacityText setFloatValue:[pattern alpha]];
	[opacitySlider setFloatValue:[pattern alpha]];
    [originXText setFloatValue:pattern.patternOrigin.x];
    [originYText setFloatValue:pattern.patternOrigin.y];
	[backgroundColourWell setColor:[pattern backgroundColour]];
	[layoutPopUp selectItemAtIndex:[pattern layoutMode]];
    self.displayClip = pattern.clip;
    self.displayRotation = pattern.rotation;
	[graphicView resizeHandleBits];
	[self setActionsDisabled:NO];
}

- (NSUndoManager *)windowWillReturnUndoManager:(NSWindow*)sender
{
	return [self undoManager];
}

- (NSString*)windowTitleForDocumentDisplayName:(NSString*)fileName
{
	NSMutableString *name = [NSMutableString stringWithCapacity:30];
	[name appendString:fileName];
	[name appendString:NSLocalizedString(@" - Edit Pattern",@"")];
	return name;
}

- (void)adjustWindowSize
{
	NSScrollView *scrollView = [graphicView enclosingScrollView];
	NSSize frameS = [NSScrollView frameSizeForContentSize:[graphicView frame].size horizontalScrollerClass:[NSScroller class] verticalScrollerClass:[NSScroller class] borderType:[scrollView borderType] controlSize:NSRegularControlSize scrollerStyle:[[scrollView horizontalScroller]scrollerStyle]];
/*	NSSize frameS = [NSScrollView frameSizeForContentSize:([graphicView frame].size)
									hasHorizontalScroller:[scrollView hasHorizontalScroller]
									  hasVerticalScroller: [scrollView hasVerticalScroller]
											   borderType:[scrollView borderType]];*/
	NSRect frameR = NSMakeRect(0.0,0.0,frameS.width,frameS.height);
	frameR = [NSWindow frameRectForContentRect:frameR styleMask:[[graphicView window]styleMask]];
	[[graphicView window]setMaxSize:frameR.size];
	NSClipView *cv = [scrollView contentView];
	NSRect clipBounds = [cv bounds];
	NSRect frame = [graphicView frame];
	if ((frame.size.width < clipBounds.size.width) || (frame.size.height < clipBounds.size.height))
		[[self window]zoom:self];
}

-(void)uSetXSpacing:(float)v text:(BOOL)text slider:(BOOL)slider
{
	if ([[self temporaryPattern] xSpacing] != v)
		[[[self undoManager] prepareWithInvocationTarget:self] uSetXSpacing:[temporaryPattern xSpacing]text:YES slider:YES];
	if (text)
		[xSpacingText setFloatValue:v];
	if (slider)
	{
		//float scale10 = log10(v);
		//[spacingSlider setFloatValue:scale10];
		[xSpacingSlider setFloatValue:v];
	}
	[[self temporaryPattern] setXSpacing:v];
	[patternPreview setNeedsDisplay:YES];
	[[self undoManager]setActionName:@"Change X Spacing"];
}

-(void)uSetYSpacing:(float)v text:(BOOL)text slider:(BOOL)slider
{
	if ([[self temporaryPattern] ySpacing] != v)
		[[[self undoManager] prepareWithInvocationTarget:self] uSetYSpacing:[temporaryPattern ySpacing]text:YES slider:YES];
	if (text)
		[ySpacingText setFloatValue:v];
	if (slider)
	{
		//float scale10 = log10(v);
		//[spacingSlider setFloatValue:scale10];
		[ySpacingSlider setFloatValue:v];
	}
	[[self temporaryPattern] setYSpacing:v];
	[patternPreview setNeedsDisplay:YES];
	[[self undoManager]setActionName:@"Change Y Spacing"];
}


- (IBAction)xSpacingSliderHit:(id)sender
{
	if (actionsDisabled)
		return;
	[self setActionsDisabled:YES];
	float spacing = [sender floatValue];
	//float spacing = pow(10,spacing10);
	[self uSetXSpacing:spacing text:YES slider:NO];
	[self setActionsDisabled:NO];
}

- (IBAction)ySpacingSliderHit:(id)sender
{
	if (actionsDisabled)
		return;
	[self setActionsDisabled:YES];
	float spacing = [sender floatValue];
	//float spacing = pow(10,spacing10);
	[self uSetYSpacing:spacing text:YES slider:NO];
	[self setActionsDisabled:NO];
}

- (IBAction)xSpacingTextHit:(id)sender
{
	if (actionsDisabled)
		return;
	[self setActionsDisabled:YES];
	float spacing = [sender floatValue];
	[self uSetXSpacing:spacing text:NO slider:YES];
	[self setActionsDisabled:NO];
}

- (IBAction)ySpacingTextHit:(id)sender
{
	if (actionsDisabled)
		return;
	[self setActionsDisabled:YES];
	float spacing = [sender floatValue];
	[self uSetYSpacing:spacing text:NO slider:YES];
	[self setActionsDisabled:NO];
}

-(void)uSetPatternMode:(int)m updateControl:(BOOL)updateControl
{
	if ([[self temporaryPattern] mode] != m)
		[[[self undoManager] prepareWithInvocationTarget:self] uSetPatternMode:[temporaryPattern mode]updateControl:YES];
	[[self temporaryPattern] setMode:m];
	if (updateControl)
		[patternModeRBMatrix selectCellAtRow:0 column:m];
	[patternPreview setNeedsDisplay:YES];
	[[self undoManager]setActionName:@"Change Pattern Mode"];
}

- (IBAction)patternModeRBMatrixHit:(id)sender
{
	[self uSetPatternMode:(int)[patternModeRBMatrix selectedColumn]updateControl:NO];
}

-(void)uSetOffsetMode:(int)m updateControl:(BOOL)updateControl
{
	if ([[self temporaryPattern] offsetMode] != m)
		[[[self undoManager] prepareWithInvocationTarget:self] uSetOffsetMode:[temporaryPattern offsetMode]updateControl:YES];
	[[self temporaryPattern] setOffsetMode:m];
	if (updateControl)
		[offsetTypeRBMatrix selectCellAtRow:0 column:m];
	[patternPreview setNeedsDisplay:YES];
	[[self undoManager]setActionName:@"Change Offset Mode"];
}

- (IBAction)offsetTypeRBMatrixHit:(id)sender
{
	[self uSetOffsetMode:(int)[offsetTypeRBMatrix selectedColumn]updateControl:NO];
}

-(void)uSetClip:(BOOL)b
{
	if ([[self temporaryPattern] clip] != b)
		[[[self undoManager] prepareWithInvocationTarget:self] uSetClip:[temporaryPattern clip]];
	[[self temporaryPattern] setClip:b];
	if (b != self.displayClip)
		self.displayClip = b;
	[patternPreview setNeedsDisplay:YES];
	[[self undoManager]setActionName:@"Change Clip"];
}

-(void)setDisplayClip:(BOOL)displayClip
{
	if (actionsDisabled)
		return;
	[self setActionsDisabled:YES];
	if (displayClip != self.displayClip)
		_displayClip = displayClip;
	[self uSetClip:displayClip];
	[self setActionsDisabled:NO];
}

-(void)uSetUseCentrePattern:(BOOL)b
{
	if ([[self temporaryPattern] usePatternCentre] != b)
		[[[self undoManager] prepareWithInvocationTarget:self] uSetUseCentrePattern:[temporaryPattern usePatternCentre]];
	[[self temporaryPattern] setUsePatternCentre:b];
	if (b != self.displayUsePatternCentre)
		self.displayUsePatternCentre = b;
	[patternPreview setNeedsDisplay:YES];
	[[self undoManager]setActionName:@"Change Use Pattern Centre"];
}

-(void)setDisplayUsePatternCentre:(BOOL)b
{
	if (actionsDisabled)
		return;
	[self setActionsDisabled:YES];
	if (b != self.displayUsePatternCentre)
		_displayUsePatternCentre = b;
	[self uSetUseCentrePattern:b];
	[self setActionsDisabled:NO];
}


-(void)uSetRotation:(float)rot
{
	if ([[self temporaryPattern] rotation] != rot)
		[[[self undoManager] prepareWithInvocationTarget:self] uSetRotation:[temporaryPattern rotation]];
	[[self temporaryPattern] setRotation:rot];
	if (rot != self.displayRotation)
		self.displayRotation = rot;
	[patternPreview setNeedsDisplay:YES];
	[[self undoManager]setActionName:@"Change Rotation"];
}

-(void)setDisplayRotation:(float)displayRotation
{
	if (actionsDisabled)
		return;
	[self setActionsDisabled:YES];
	if (displayRotation != self.displayRotation)
		_displayRotation = displayRotation;
	[self uSetRotation:displayRotation];
	[self setActionsDisabled:NO];
}

-(void)uSetOpacity:(float)v text:(BOOL)text slider:(BOOL)slider
{
	if ([[self temporaryPattern] alpha] != v)
		[[[self undoManager] prepareWithInvocationTarget:self] uSetOpacity:[temporaryPattern alpha]text:YES slider:YES];
	if (text)
		[opacityText setFloatValue:v];
	if (slider)
		[opacitySlider setFloatValue:v];
	[[self temporaryPattern] setAlpha:v];
	[patternPreview setNeedsDisplay:YES];	
	[[self undoManager]setActionName:@"Change Opacity"];
}

- (IBAction)opacitySliderHit:(id)sender
{
	if (actionsDisabled)
		return;
	[self setActionsDisabled:YES];
	[self uSetOpacity:[sender floatValue] text:YES slider:NO];
	[self setActionsDisabled:NO];
}

- (IBAction)opacityTextHit:(id)sender
{
	if (actionsDisabled)
		return;
	[self setActionsDisabled:YES];
	[self uSetOpacity:[sender floatValue] text:NO slider:YES];
	[self setActionsDisabled:NO];
}


-(void)uSetOffset:(float)v text:(BOOL)text slider:(BOOL)slider
{
	if ([[self temporaryPattern] offset] != v)
		[[[self undoManager] prepareWithInvocationTarget:self] uSetOffset:[temporaryPattern offset]text:YES slider:YES];
	if (text)
		[offsetText setFloatValue:v];
	if (slider)
		[offsetSlider setFloatValue:v];
	[[self temporaryPattern] setOffset:v];
	[patternPreview setNeedsDisplay:YES];	
	[[self undoManager]setActionName:@"Change Offset"];
}

- (IBAction)offsetSliderHit:(id)sender
{
	if (actionsDisabled)
		return;
	[self setActionsDisabled:YES];
	[self uSetOffset:[sender floatValue] text:YES slider:NO];
	[self setActionsDisabled:NO];
}

- (IBAction)offsetTextHit:(id)sender
{
	if (actionsDisabled)
		return;
	[self setActionsDisabled:YES];
	[self uSetOffset:[sender floatValue] text:NO slider:YES];
	[self setActionsDisabled:NO];
}

-(void)uSetOriginX:(float)v text:(BOOL)text
{
    NSPoint pt = [[self temporaryPattern] patternOrigin];
    if (pt.x != v)
        [[[self undoManager] prepareWithInvocationTarget:self] uSetOriginX:pt.x text:YES];
    if (text)
        [originXText setFloatValue:v];
    pt.x = v;
    [[self temporaryPattern] setPatternOrigin:pt];
    [patternPreview setNeedsDisplay:YES];
    [[self undoManager]setActionName:@"Change X Origin"];
}

- (IBAction)originXTextHit:(id)sender
{
    if (actionsDisabled)
        return;
    [self setActionsDisabled:YES];
    float ox = [sender floatValue];
    [self uSetOriginX:ox text:YES];
    [self setActionsDisabled:NO];
}

-(void)uSetOriginY:(float)v text:(BOOL)text
{
    NSPoint pt = [[self temporaryPattern] patternOrigin];
    if (pt.y != v)
        [[[self undoManager] prepareWithInvocationTarget:self] uSetOriginY:pt.y text:YES];
    if (text)
        [originYText setFloatValue:v];
    pt.y = v;
    [[self temporaryPattern] setPatternOrigin:pt];
    [patternPreview setNeedsDisplay:YES];
    [[self undoManager]setActionName:@"Change Y Origin"];
}

- (IBAction)originYTextHit:(id)sender
{
    if (actionsDisabled)
        return;
    [self setActionsDisabled:YES];
    float oy = [sender floatValue];
    [self uSetOriginY:oy text:YES];
    [self setActionsDisabled:NO];
}

-(BOOL)uSetLayoutMode:(int)md
{
    if (md != [self temporaryPattern].layoutMode)
    {
        [[[self undoManager] prepareWithInvocationTarget:self] uSetLayoutMode:[self temporaryPattern].layoutMode];
        [self temporaryPattern].layoutMode = md;
        [patternPreview setNeedsDisplay:YES];
        return YES;
    }
    return NO;
}

- (IBAction)layoutModePopUpHit:(id)sender
{
    if (actionsDisabled)
        return;
    [self setActionsDisabled:YES];
    NSPopUpButton *pu = sender;
    [self uSetLayoutMode:(int)[pu indexOfSelectedItem]];
    [self setActionsDisabled:NO];
    [[self undoManager]setActionName:@"Change Layout Mode"];
}

-(void)uSetScale:(float)v text:(BOOL)text slider:(BOOL)slider
{
	if ([[self temporaryPattern] scale] != v)
		[[[self undoManager] prepareWithInvocationTarget:self] uSetScale:[temporaryPattern scale]text:YES slider:YES];
	if (text)
		[scaleText setFloatValue:v];
	if (slider)
	{
		float scale10 = log10(v);
		[scaleSlider setFloatValue:scale10];
	}
	[[self temporaryPattern] setScale:v];
	[patternPreview setNeedsDisplay:YES];	
	[[self undoManager]setActionName:@"Change Scale"];
}

- (IBAction)scaleSliderHit:(id)sender
{
	if (actionsDisabled)
		return;
	[self setActionsDisabled:YES];
	float scale10 = [sender floatValue];
	float scale = pow(10,scale10);
	[self uSetScale:scale text:YES slider:NO];
	[self setActionsDisabled:NO];
}

- (IBAction)scaleTextHit:(id)sender
{
	if (actionsDisabled)
		return;
	[self setActionsDisabled:YES];
	float scale = [sender floatValue];
	[self uSetScale:scale text:NO slider:YES];
	[self setActionsDisabled:NO];
}

-(BOOL)uSetBackgroundColour:(NSColor*)col
{
	if ([col isEqual:[[self temporaryPattern]backgroundColour]])
		return NO;
	[[[self undoManager] prepareWithInvocationTarget:self] uSetBackgroundColour:[temporaryPattern backgroundColour]];
	[[self temporaryPattern] setBackgroundColour:col];
	[patternPreview setNeedsDisplay:YES];
	return YES;
}

-(IBAction)backgroundColourWellHit:(id)sender
{
	if (actionsDisabled)
		return;
	if ([self uSetBackgroundColour:[sender color]])
		[[self undoManager]setActionName:@"Change Background Colour"];
}

- (IBAction)updateHit:(id)sender
{
    [[scaleSlider window]makeFirstResponder:nil];
	ACSDPattern *pat = [self temporaryPattern];
	[pattern changeGraphic:[pat graphic] view:nil];
	[pattern changeScale:[pat scale] view:nil];
	[pattern changeXSpacing:[pat xSpacing] view:nil];
	[pattern changeYSpacing:[pat ySpacing] view:nil];
	[pattern changeOffset:[pat offset]view:nil];
	[pattern setAlpha:[pat alpha]];
	[pattern setMode:[pat mode]];
	[pattern changeClip:[pat clip]view:nil];
	[pattern changeRotation:[pat rotation]view:nil];
	[pattern changeOffsetMode:[pat offsetMode]view:nil];
	[pattern setPatternBounds:[pat patternBounds]];
	[pattern setPdfImageRep:[pat pdfImageRep]];
	[pattern setPdfOffset:[pat pdfOffset]];
	[pattern setBackgroundColour:[pat backgroundColour]];
    [pattern setPatternOrigin:[pat patternOrigin]];
	[pattern setLayoutMode:[pat layoutMode]];
	pattern.usePatternCentre = pat.usePatternCentre;
	[[NSNotificationCenter defaultCenter] postNotificationName:ACSDFillAdded object:self];
	[[self undoManager]removeAllActions];
}

- (void)graphicsUpdated
{
	[patternPreview setNeedsDisplay:YES];
	[self setTemporaryPattern:nil];
}

-(void)setTemporaryPattern:(ACSDPattern*)p
{
	if (temporaryPattern == p)
		return;
	temporaryPattern = p;
}

-(ACSDPattern*)temporaryPattern
{
	if (temporaryPattern)
		return temporaryPattern;
	temporaryPattern = [self tempPattern];
	return temporaryPattern;
}

-(ACSDPattern*)updatedTemporaryPattern
{
	ACSDPattern *temp = [self temporaryPattern];
	[temp setScale:[scaleText floatValue]];
	[temp setXSpacing:[xSpacingText floatValue]];
	[temp setYSpacing:[ySpacingText floatValue]];
	[temp setOffset:[offsetText floatValue]];
	[temp setOffsetMode:(int)[offsetTypeRBMatrix selectedColumn]];
	return temp;
}


-(ACSDPattern*)tempPattern
{
	ACSDLayer *layer = [[[pages objectAtIndex:0]layers]objectAtIndex:1];
	if (!layer)
		return nil;
	NSArray *graphics = [layer graphics];
	if (!graphics)
		return nil;
	ACSDGraphic *g;
	NSInteger ct = [graphics count];
	if (ct == 0)
		return nil;
	[[self undoManager] disableUndoRegistration];
	if (ct == 1)
	{
		g = [[graphics objectAtIndex:0]copy];
		[g setLayer:nil];
	}
	else
	{
		NSMutableArray *arr = [NSMutableArray arrayWithCapacity:ct];
		for (int i = 0;i < ct;i++)
			[arr addObject:[[graphics objectAtIndex:i]copy]];
		g = [[ACSDGroup alloc]initWithName:@"patgroup" graphics:arr  layer:nil];
	}
	float xOffset = [horizontalRuler originOffset];
	float yOffset = [verticalRuler originOffset];
	NSRect pBounds = NSMakeRect(xOffset,yOffset,[verticalLimitLine location] - xOffset,[horizontalLimitLine location] - yOffset);
	ACSDPattern *pat = [ACSDPattern patternWithGraphic:g scale:[scaleText floatValue] 
											  xSpacing:[xSpacingText floatValue] ySpacing:[ySpacingText floatValue] offset:[offsetText floatValue]
											offsetMode:(int)[offsetTypeRBMatrix selectedColumn] alpha:1.0 
												  mode:(int)[patternModeRBMatrix selectedColumn] 
										 patternBounds:pBounds];
    pat.backgroundColour = pattern.backgroundColour;
    pat.clip = pattern.clip;
    pat.rotation = pattern.rotation;
	pat.layoutMode = pattern.layoutMode;
	[[self undoManager] enableUndoRegistration];
	return pat;
}

-(void)uMoveHorizontalRulerToOffset:(float)f moveRuler:(BOOL)move
{
	[[[self undoManager] prepareWithInvocationTarget:self] uMoveHorizontalRulerToOffset:[verticalOriginLine location]moveRuler:YES];
	[graphicView setNeedsDisplayInRect:[verticalOriginLine rectForDisplay]];
	[verticalOriginLine setLocation:f];
	[graphicView setNeedsDisplayInRect:[verticalOriginLine rectForDisplay]];
	if (move)
		[horizontalRuler setOriginOffset:f];	
	[[self temporaryPattern] setPatternBounds:NSMakeRect([horizontalRuler originOffset],[verticalRuler originOffset],
														 [verticalLimitLine location] - [horizontalRuler originOffset],
														 [horizontalLimitLine location] - [verticalRuler originOffset])];
	[patternPreview setNeedsDisplay:YES];	
}

-(void)horizontalRulerMovedToOffset:(float)f
{
	[self uMoveHorizontalRulerToOffset:f moveRuler:NO];
	[[self undoManager]setActionName:@"Move Horizontal Ruler"];
}

-(void)uMoveVerticalRulerToOffset:(float)f moveRuler:(BOOL)move
{
	[[[self undoManager] prepareWithInvocationTarget:self] uMoveVerticalRulerToOffset:[horizontalOriginLine location]moveRuler:YES];
	[graphicView setNeedsDisplayInRect:[horizontalOriginLine rectForDisplay]];
	[horizontalOriginLine setLocation:f];
	[graphicView setNeedsDisplayInRect:[horizontalOriginLine rectForDisplay]];
	if (move)
		[verticalRuler setOriginOffset:f];	
	[[self temporaryPattern] setPatternBounds:NSMakeRect([horizontalRuler originOffset],[verticalRuler originOffset],
														 [verticalLimitLine location] - [horizontalRuler originOffset],
														 [horizontalLimitLine location] - [verticalRuler originOffset])];
	[patternPreview setNeedsDisplay:YES];	
}

-(void)verticalRulerMovedToOffset:(float)f
{
	[self uMoveVerticalRulerToOffset:f moveRuler:NO];
	[[self undoManager]setActionName:@"Move Vertical Ruler"];
}

- (void)setActionsDisabled:(BOOL)disabled
{
	actionsDisabled = disabled;
}

- (BOOL)actionsDisabled
{
    return actionsDisabled;
}

- (BOOL)rulerView:(NSRulerView *)aRulerView shouldMoveMarker:(NSRulerMarker *)aMarker
{
	return YES;
}

-(void)uMoveHorizontalMarkerToOffset:(float)f moveMarker:(BOOL)move
{
	[[[self undoManager] prepareWithInvocationTarget:self] uMoveHorizontalMarkerToOffset:[verticalLimitLine location]moveMarker:YES];
	[graphicView setNeedsDisplayInRect:[verticalLimitLine rectForDisplay]];
	[verticalLimitLine setLocation:f];
	[graphicView setNeedsDisplayInRect:[verticalLimitLine rectForDisplay]];
	if (move)
		[[[horizontalRuler markers]objectAtIndex:0]setMarkerLocation:f];
	[horizontalRuler setNeedsDisplay:YES];
	[[self temporaryPattern] setPatternBounds:NSMakeRect([horizontalRuler originOffset],[verticalRuler originOffset],
														 [verticalLimitLine location] - [horizontalRuler originOffset],
														 [horizontalLimitLine location] - [verticalRuler originOffset])];
	[patternPreview setNeedsDisplay:YES];	
}	

-(void)uMoveVerticalMarkerToOffset:(float)f moveMarker:(BOOL)move
{
	[[[self undoManager] prepareWithInvocationTarget:self] uMoveVerticalMarkerToOffset:[horizontalLimitLine location]moveMarker:YES];
	[graphicView setNeedsDisplayInRect:[horizontalLimitLine rectForDisplay]];
	[horizontalLimitLine setLocation:f];
	[graphicView setNeedsDisplayInRect:[horizontalLimitLine rectForDisplay]];
	if (move)
		[[[verticalRuler markers]objectAtIndex:0]setMarkerLocation:f];
	[verticalRuler setNeedsDisplay:YES];
	[[self temporaryPattern] setPatternBounds:NSMakeRect([horizontalRuler originOffset],[verticalRuler originOffset],
														 [verticalLimitLine location] - [horizontalRuler originOffset],
														 [horizontalLimitLine location] - [verticalRuler originOffset])];
	[patternPreview setNeedsDisplay:YES];	
}	

- (void)rulerView:(NSRulerView *)aRulerView didMoveMarker:(NSRulerMarker *)aMarker
{
	float loc = [aMarker markerLocation];
	if (aMarker == [[horizontalRuler markers]objectAtIndex:0])
	{
		[self uMoveHorizontalMarkerToOffset:loc moveMarker:NO];
		[[self undoManager]setActionName:@"Move Horizontal Limit Line"];
	}
	else
	{
		[self uMoveVerticalMarkerToOffset:loc moveMarker:NO];
		[[self undoManager]setActionName:@"Move Vertical Limit Line"];
	}
}

-(id)representedObject
{
	return pattern;
}

-(BOOL)dirty
{
	return [[self undoManager]canUndo];
}

- (BOOL)windowShouldClose:(id)sender
{
	if ([self dirty])
	{
		NSInteger response = [[NSAlert alertWithMessageText:@"Some changes have not been applied" 
										defaultButton:@"Continue" alternateButton:@"Cancel" otherButton:nil 
							informativeTextWithFormat:@"- to continue without applying them, click Continue"]runModal];
		if (response == NSAlertAlternateReturn)
			return NO;
	}
	return YES;
}

-(void)otherDrawing:(NSRect)r
{
	[verticalOriginLine drawRect:r];
	[horizontalOriginLine drawRect:r];
	[verticalLimitLine drawRect:r];
	[horizontalLimitLine drawRect:r];
}

@end
