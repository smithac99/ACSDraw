#import "LineEndingWindowController.h"
#import "GraphicView.h"
#import "ACSDrawDocument.h"
#import "ACSDPage.h"
#import "GraphicRulerView.h"
#import "ACSDGraphic.h"
#import "ACSDGroup.h"
#import "ACSDLine.h"

@implementation LineEndingWindowController

- (id)initWithLineEnding:(ACSDLineEnding*)le;
   {
	[NSScrollView setRulerViewClass:[GraphicRulerView class]];
	if (self = [super initWithWindowNibName:@"LineEndingWindow"])
	   {
		[self setShouldCloseDocument:NO];
		lineEnding = le;
		undoManager = [[NSUndoManager alloc]init];
	   }
	return self;
   }

- (GraphicView*)graphicView
   {
	return graphicView;
   }

- (NSUndoManager*)undoManager
   {
	return undoManager;
   }

- (void)windowDidLoad
   {
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
	ACSDGraphic *g = [[lineEnding graphic]copy];
	NSPoint viewCentrePoint = [graphicView bounds].origin;
	viewCentrePoint.x += [graphicView bounds].size.width / 2;
	viewCentrePoint.y += [graphicView bounds].size.height / 2;
	NSPoint graphicCentrePoint = [g bounds].origin;
	graphicCentrePoint.x += [g bounds].size.width / 2;
	graphicCentrePoint.y += [g bounds].size.height / 2;
	float deltaX = viewCentrePoint.x - graphicCentrePoint.x;
	float deltaY = viewCentrePoint.y - graphicCentrePoint.y;
	[g moveBy:NSMakePoint(deltaX,deltaY)];
	[horizontalRuler setOriginOffset:deltaX];
	[verticalRuler setOriginOffset:deltaY];
	[horizontalRuler setDelegate:self];
	[verticalRuler setDelegate:self];
	[[p currentLayer]addGraphic:g];
	verticalGuideLine = [[SnapLine alloc]initWithGraphicView:graphicView orientation:SNAPLINE_VERTICAL];
	[verticalGuideLine setVisible:YES];
	[verticalGuideLine setLocation:deltaX];
	horizontalGuideLine = [[SnapLine alloc]initWithGraphicView:graphicView orientation:SNAPLINE_HORIZONTAL];
	[horizontalGuideLine setVisible:YES];
	[horizontalGuideLine setLocation:deltaY];
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
	[offsetText setFloatValue:[lineEnding offset]];
	[scaleText setFloatValue:[lineEnding scale]];
	[aspectText setFloatValue:[lineEnding aspect]];
	if ([[g fill]useCurrent])
		[fillTypeRBMatrix selectCellAtRow:1 column:0];
	else
		[fillTypeRBMatrix selectCellAtRow:0 column:0];
	[graphicView resizeHandleBits];
   }

- (NSUndoManager *)windowWillReturnUndoManager:(NSWindow*)sender
   {
	return [self undoManager];
   }

- (NSString*)windowTitleForDocumentDisplayName:(NSString*)fileName
   {
	NSMutableString *name = [NSMutableString stringWithCapacity:30];
	[name appendString:fileName];
	[name appendString:NSLocalizedString(@" - Edit Line Ending",@"")];
	return name;
   }

- (void)adjustWindowSize
   {
	NSScrollView *scrollView = [graphicView enclosingScrollView];
       NSSize frameS = [NSScrollView frameSizeForContentSize:[graphicView frame].size horizontalScrollerClass:[NSScroller class] verticalScrollerClass:[NSScroller class] borderType:[scrollView borderType] controlSize:NSControlSizeRegular scrollerStyle:[[scrollView horizontalScroller]scrollerStyle]];
	/*NSSize frameS = [NSScrollView frameSizeForContentSize:([graphicView frame].size)
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

- (NSSlider*)zoomSlider
   {
	return zoomSlider;
   }

- (IBAction)zoomSliderHit:(id)sender
   {
	[lineEndPreview setNeedsDisplay:YES];	
   }

-(void)uSetScale:(float)v text:(BOOL)text slider:(BOOL)slider
   {
	if ([[self temporaryLineEnding] scale] != v)
		[[[self undoManager] prepareWithInvocationTarget:self] uSetScale:[temporaryLineEnding scale]text:YES slider:YES];
	if (text)
		[scaleText setFloatValue:v];
	if (slider)
	   {
		float scale10 = log10(v);
		[scaleSlider setFloatValue:scale10];
	   }
	[[self temporaryLineEnding] setScale:v];
	[lineEndPreview setNeedsDisplay:YES];	
	[[self undoManager]setActionName:@"Change Scale"];
   }


- (IBAction)scaleTextHit:(id)sender
   {
	float scale = [sender floatValue];
	[self uSetScale:scale text:NO slider:YES];
   }

- (IBAction)scaleSliderHit:(id)sender
   {
	float scale10 = [sender floatValue];
	float scale = pow(10,scale10);
	[self uSetScale:scale text:YES slider:NO];
   }

-(void)uSetAspect:(float)v text:(BOOL)text slider:(BOOL)slider
   {
	if ([[self temporaryLineEnding] aspect] != v)
		[[[self undoManager] prepareWithInvocationTarget:self] uSetAspect:[temporaryLineEnding aspect]text:YES slider:YES];
	if (text)
		[aspectText setFloatValue:v];
	if (slider)
	   {
		float aspect10 = log10(v);
		[aspectSlider setFloatValue:aspect10];
	   }
	[[self temporaryLineEnding] setAspect:v];
	[lineEndPreview setNeedsDisplay:YES];	
	[[self undoManager]setActionName:@"Change Aspect"];
   }


- (IBAction)aspectTextHit:(id)sender
   {
	float aspect = [sender floatValue];
	[self uSetAspect:aspect text:NO slider:YES];
   }

- (IBAction)aspectSliderHit:(id)sender
   {
	float aspect10 = [sender floatValue];
	float aspect = pow(10,aspect10);
	[self uSetAspect:aspect text:YES slider:NO];
   }

-(void)uSetOffset:(float)v text:(BOOL)text slider:(BOOL)slider
   {
	if ([[self temporaryLineEnding] offset] != v)
		[[[self undoManager] prepareWithInvocationTarget:self] uSetOffset:[temporaryLineEnding offset]text:YES slider:YES];
	if (text)
		[offsetText setFloatValue:v];
	if (slider)
	   {
		float offset10 = log10(v);
		[offsetSlider setFloatValue:offset10];
	   }
	[[self temporaryLineEnding] setOffset:v];
	[lineEndPreview setNeedsDisplay:YES];	
	[[self undoManager]setActionName:@"Change Offset"];
   }

- (IBAction)offsetTextHit:(id)sender
   {
	float offset = [sender floatValue];
	[self uSetOffset:offset text:NO slider:YES];
   }

- (IBAction)offsetSliderHit:(id)sender
   {
	float offset10 = [sender floatValue];
	float offset = pow(10,offset10);
	[self uSetOffset:offset text:YES slider:NO];
   }

- (IBAction)updateHit:(id)sender
   {
	ACSDLineEnding *le = [self tempLineEnding];
	[lineEnding setGraphic:[le graphic]];
	[lineEnding setScale:[le scale]];
	[lineEnding setAspect:[le aspect]];
	[lineEnding setOffset:[le offset]];
	[[NSNotificationCenter defaultCenter] postNotificationName:ACSDRefreshLineEndingsNotification object:self];
	[[self undoManager]removeAllActions];
   }

-(void)uSetFillType:(int)f updateControl:(BOOL)updateControl
   {
	[[[self undoManager] prepareWithInvocationTarget:self] uSetFillType:(f + 1)%2 updateControl:YES];
	if (updateControl)
		[fillTypeRBMatrix selectCellAtRow:f column:0];
	if ([fillTypeRBMatrix selectedRow] == 1)		//fill uses parent
		[[[self temporaryLineEnding]graphic] setAllFills:[ACSDFill parentFill]];
	else
		[self setTemporaryLineEnding:nil];
	[lineEndPreview setNeedsDisplay:YES];	
	[[self undoManager]setActionName:@"Change Fill Type"];
   }

- (IBAction)fillTypeRBMatrixHit:(id)sender
   {
	[self uSetFillType:(int)[fillTypeRBMatrix selectedRow]updateControl:NO];
   }

- (void)graphicsUpdated
   {
	[self setTemporaryLineEnding:nil];
	[lineEndPreview setNeedsDisplay:YES];
   }

-(void)setTemporaryLineEnding:(ACSDLineEnding*)p
   {
	if (temporaryLineEnding == p)
		return;
	temporaryLineEnding = p;
   }

-(ACSDLineEnding*)temporaryLineEnding
   {
	if (!temporaryLineEnding)
		temporaryLineEnding = [self tempLineEnding];
	return temporaryLineEnding;
   }

-(ACSDLineEnding*)tempLineEnding
   {
	NSArray *graphics = [((ACSDLayer*)[[[pages objectAtIndex:0]layers]objectAtIndex:1])graphics];
	if (!graphics)
		return nil;
	ACSDGraphic *g;
	NSInteger ct = [graphics count];
	if (ct == 0)
		return nil;
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
		g = [[ACSDGroup alloc]initWithName:@"legroup" graphics:arr layer:nil];
	   }
	if ([fillTypeRBMatrix selectedRow] == 1)		//fill uses parent
		[g setAllFills:[ACSDFill parentFill]];
	float xOffset = -[horizontalRuler originOffset];
	float yOffset = -[verticalRuler originOffset];
	[g moveBy:NSMakePoint(xOffset,yOffset)];
	ACSDLineEnding *le = [ACSDLineEnding lineEndingWithGraphic:g scale:[scaleText floatValue] aspect:[aspectText floatValue] offset:[offsetText floatValue]];
	return le;
   }

-(void)uMoveHorizontalRulerToOffset:(float)f moveRuler:(BOOL)move
   {
	[[[self undoManager] prepareWithInvocationTarget:self] uMoveHorizontalRulerToOffset:[verticalGuideLine location]moveRuler:YES];
	[graphicView setNeedsDisplayInRect:[verticalGuideLine rectForDisplay]];
	[verticalGuideLine setLocation:f];
	[graphicView setNeedsDisplayInRect:[verticalGuideLine rectForDisplay]];
	if (move)
		[horizontalRuler setOriginOffset:f];	
	[self setTemporaryLineEnding:nil];
	[lineEndPreview setNeedsDisplay:YES];	
   }

-(void)horizontalRulerMovedToOffset:(float)f
   {
	[self uMoveHorizontalRulerToOffset:f moveRuler:NO];
	[[self undoManager]setActionName:@"Move Horizontal Ruler"];
   }

-(void)uMoveVerticalRulerToOffset:(float)f moveRuler:(BOOL)move
   {
	[[[self undoManager] prepareWithInvocationTarget:self] uMoveVerticalRulerToOffset:[horizontalGuideLine location]moveRuler:YES];
	[graphicView setNeedsDisplayInRect:[horizontalGuideLine rectForDisplay]];
	[horizontalGuideLine setLocation:f];
	[graphicView setNeedsDisplayInRect:[horizontalGuideLine rectForDisplay]];
	if (move)
		[verticalRuler setOriginOffset:f];	
	[self setTemporaryLineEnding:nil];
	[lineEndPreview setNeedsDisplay:YES];	
   }

-(void)verticalRulerMovedToOffset:(float)f
   {
	[self uMoveVerticalRulerToOffset:f moveRuler:NO];
	[[self undoManager]setActionName:@"Move Vertical Ruler"];
   }

-(id)representedObject
   {
	return lineEnding;
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
	[verticalGuideLine drawRect:r];
	[horizontalGuideLine drawRect:r];
   }

 
@end
