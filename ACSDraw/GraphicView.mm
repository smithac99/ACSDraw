#import "GraphicView.h"
#import "ACSDGraphic.h"
#import "ACSDLayer.h"
#import "ACSDPage.h"
#import "ACSDFill.h"
#import "ACSDGradient.h"
#import "ACSDStroke.h"
#import "ACSDRect.h"
#import "ACSDMatrix.h"
#import "ACSDGrid.h"
#import "ACSDCircle.h"
#import "ACSDLine.h"
#import "ToolWindowController.h"
#import "ACSDCursor.h"
#import "ACSDText.h"
#import "ACSDPattern.h"
#import "ACSDGroup.h"
#import "ACSDPath.h"
#import "ACSDSubPath.h"
#import "ACSDImage.h"
#import "ACSDrawDefs.h"
#import "ACSDLineEnding.h"
#import "PositionalObject.h"
#import "SelectionSet.h"
#import "ACSDPathElement.h"
#import "MainWindowController.h"
#import "ShadowType.h"
#import "ACSDPrefsController.h"
#import "IPolygon.h"
#import "ISegElement.h"
#import "LineEndingWindowController.h"
#import "InvocationHolder.h"
#import "AffineTransformAdditions.h"
#import "PatternWindowController.h"
#import "SnapLine.h"
#import "AppDelegate.h"
#import "ArrayAdditions.h"
#import "geometry.h"
#import "ACSDConnector.h"
#import "ACSDPolygon.h"
#import "ObjectAdditions.h"
#import "ConditionalObject.h"
#import "HighLightLayer.h"
#import "ACSDLink.h"
#import "ACSDTextView.h"
#import "ACSDStyle.h"
#import "ArchiveDelegate.h"
#import "ACSDFreeHand.h"
#import "TextSubstitution.h"
#import "PalletteViewController.h"
#import "StrokesController.h"
#import "ShadowsController.h"
#import "FillsController.h"
#import "SizeController.h"
#import "MarkerView.h"
#import "HTMLAccumulator.h"
#import "gSubPath.h"
#import "GraphicView+GraphicViewAdditions.h"
#import "AnimationsController.h"
#import "ACSDDocImage.h"
#import "NSView+Additions.h"
#import "SelectedElement.h"

#define MINN(a,b) ((a)<(b))?(a):(b)

NSString *ACSDCancelOpNotification = @"ACSDCancelOp";

NSString *ACSDGraphicViewTextSelectionDidChangeNotification = @"ACSDGraphicViewtextSelectionDidChange";
NSString *ACSDGraphicViewSelectionDidChangeNotification = @"ACSDGraphicViewSelectionDidChange";
NSString *ACSDDocumentDidChangeNotification = @"ACSDDocumentDidChange";
NSString *ACSDMouseDidMoveNotification = @"ACSDMouseDidMove";
NSString *ACSDExposureChangedNotification = @"ACSDExposureChanged";
NSString *ACSDDimensionChangeNotification = @"ACSDDimensionChange";
NSString *ACSDSizePanelParamChangeNotification = @"ACSDSizePanelParamChange";
NSString *ACSDFillAdded = @"ACSDFillAdded";
NSString *ACSDRefreshLineEndingsNotification = @"ACSDRefreshLineEndings";
NSString *ACSDPageChanged = @"ACSDPageChanged";
NSString *ACSDLayerSelectionChanged = @"ACSDLayerSelectionChanged";
NSString *ACSDGraphicListChanged = @"ACSDGraphicListChanged";
NSString *ACSDGraphicAttributeChanged = @"ACSDGraphicAttributeChanged";
NSString *ACSDCurrentLayerChanged = @"ACSDCurrentLayerChanged";
NSString *ACSDRefreshShadowsNotification = @"ACSDRefreshShadows";
NSString *ACSDRefreshStrokesNotification = @"ACSDRefreshStrokes";
NSString *ACSDrawGraphicPasteboardType = @"ACSDrawGraphic";
NSString *ACSDrawGraphicRefPasteboardType = @"ACSDrawGraphicRef";
NSString *ACSDrawAttributePasteboardType = @"ACSDrawAttribute";

static NSInteger sortPositionalObjects(id obj1,id obj2,void *context);
NSInteger findSame(id obj,NSArray *arr);

@implementation GraphicView

@synthesize documentBased,editorInUse,showSelection,
cursorMode,defaultMatrixRows,defaultMatrixColumns,defaultPolygonSides,
rotationPoint,currentPageInd,
creatingGraphic,creatingPath,editingGraphic,defaultFill,defaultStroke;

- (id)initWithFrame:(NSRect)frameRect
   {
	if ((self = [super initWithFrame:frameRect]))
	   {
		rubberbandRect = NSZeroRect;
		rubberbandGraphics = nil;
		creatingGraphic = nil;
		creatingPath = nil;
		layoutManager = nil;
		[self setFlipped:NO];
		cursorMode = GV_MODE_NONE;
		snapSize = [[ACSDPrefsController sharedACSDPrefsController:nil]snapSize];
		hotSpotSize = [[ACSDPrefsController sharedACSDPrefsController:nil]hotSpotSize];
		[self setSelectionColour:[[ACSDPrefsController sharedACSDPrefsController:nil]selectionColour]];
		[self setGuideColour:[[ACSDPrefsController sharedACSDPrefsController:nil]guideColour]];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(selectedToolDidChange:)
			name:ACSDSelectedToolDidChangeNotification object:[ToolWindowController sharedToolWindowController:nil]];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(snapButtonDidChange:)
			name:ACSDSnapButtonDidChangeNotification object:[ToolWindowController sharedToolWindowController:nil]];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(boundsChanged:)
			name:NSViewBoundsDidChangeNotification object:self];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(guideColourChanged:)
			name:ACSDGuideColourDidChangeNotification object:[ACSDPrefsController sharedACSDPrefsController:nil]];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(selectionColourChanged:)
			name:ACSDSelectionColourDidChangeNotification object:[ACSDPrefsController sharedACSDPrefsController:nil]];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(snapSizeChanged:)
			name:ACSDSnapSizeDidChangeNotification object:[ACSDPrefsController sharedACSDPrefsController:nil]];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(hotSpotSizeChanged:)
			name:ACSDHotSpotSizeDidChangeNotification object:[ACSDPrefsController sharedACSDPrefsController:nil]];
		[self snapButtonDidChange:nil];
		editor = nil;
		editorInUse = NO;
		spaceDown = NO;
		magnification = 1.0;
		verticalHandleBits = NULL;
		horizontalHandleBits = NULL;
		defaultMatrixRows = 2;
		defaultMatrixColumns = 2;
		defaultPolygonSides = 3;
		snapSize = 2;
		snapHOffsets = new char[(int)([self bounds].size.width)];
		snapVOffsets = new char[(int)([self bounds].size.height)];
		cacheDrawing = YES;
		repeatQueue = [[NSMutableArray alloc]initWithCapacity:5];
		repeatingAction = NO;
		handleShadow = [[NSShadow alloc]init];
		[handleShadow setShadowBlurRadius:2];
		highLightLayer = [[HighLightLayer alloc]initWithGraphicView:self];
		drawGrid = NO;
	   }
	return self;
   }

-(void)dealloc
{
    [self endEditing];
	[[self selectedGraphics] removeAllObjects];
	[[NSNotificationCenter defaultCenter] postNotificationName:ACSDGraphicViewSelectionDidChangeNotification object:self];
	[pages release];
	[defaultFill release];
	[defaultStroke release];
	[layoutManager release];
	[editor release];
	[repeatQueue release];
	if (verticalHandleBits)
		delete[] verticalHandleBits;
	if (horizontalHandleBits)
		delete[] horizontalHandleBits;
	if (snapHOffsets)
		delete[] snapHOffsets;
	if (snapVOffsets)
		delete[] snapVOffsets;
	[handleShadow release];
	[highLightLayer release];
	[_polygonSheet release];
	self.savedEyeClick = nil;
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[super dealloc];
}

-(void) setPages:(NSMutableArray*)list
   {
	if (pages == list)
		return;
	if (pages)
		[pages release];
	pages = [list retain];
	[self adjustPageNumbersFromIndex:0];
	[self resolveMasters];
	[self setCurrentPageIndex:0 force:YES withUndo:NO];
   }

-(ACSDPage*)currentPage
   {
	return [pages objectAtIndex:currentPageInd];
   }

- (NSMutableArray*)layers
   {
    return [[self currentPage]layers];
   }

-(HighLightLayer*)highLightLayer
   {
	return highLightLayer;
   }

- (ACSDLayer*)currentEditableLayer
{
    ACSDPage *p = [self currentPage];
    NSInteger idx = [p currentLayerInd];
    if (idx >= 0 && idx < [[p layers]count])
        return [p layers][idx];
    return nil;
}

-(CGContextRef)drawingToPDF
   {
	return drawingToPDF;
   }

-(void)setDrawingToPDF:(CGContextRef)d
   {
	drawingToPDF = d;
   }

- (BOOL)cacheOn
   {
	return cacheDrawing;
   }

- (float)magnification
   {
	return magnification;
   }

- (NSMutableArray*)pages
   {
	return pages;
   }

- (void)setCurrentPageIndex:(NSInteger)i force:(BOOL)force
{
	if ((i == currentPageInd && !force) || i < 0)
		return;
	[self endEditing];
	[[pages objectAtIndex:currentPageInd]removeGraphicView:self];
	currentPageInd = i;
	[[pages objectAtIndex:currentPageInd]addGraphicView:self];
	[[NSNotificationCenter defaultCenter] postNotificationName:ACSDPageChanged object:self userInfo:nil];
	[self setNeedsDisplay:YES];
    [markerView setNeedsDisplay:YES];
	[[[self window]windowController]synchronizeWindowTitleWithDocumentName];
}

- (void)setCurrentPageIndex:(NSInteger)i force:(BOOL)force withUndo:(BOOL)withUndo
{
	if (i == currentPageInd && !force)
		return;
	[self endEditing];
	if (withUndo)
    {
        [[self undoManager]setActionIsDiscardable:YES];
		[[[self undoManager] prepareWithInvocationTarget:self] setCurrentPageIndex:currentPageInd force:force withUndo:YES];
    }
	[self setCurrentPageIndex:i force:force];
	self.savedEyeClick = nil;
}

- (NSColor*)backgroundColour
   {
	return [[self document]backgroundColour];
   }

- (ACSDrawDocument*)document
   {
	return [[[self window]windowController]document];
   }

- (NSTextView*)editor
   {
	if (editor)
		return editor;
    editor = [[ACSDTextView allocWithZone:NULL] initWithFrame:NSMakeRect(0.0, 0.0, 100.0, 100.0) textContainer:nil];
    [editor setTextContainerInset:NSMakeSize(0.0, 0.0)];
    [editor setDrawsBackground:NO];
    [editor setAllowsUndo:YES];
    return editor;
   }

- (void)startEditingGraphic:(ACSDGraphic*)graphic withEvent:(NSEvent*)event
   {
    [graphic startEditingWithEvent:event inView:self];
   }

- (void)endEditing
   {
    if (editingGraphic)
	   {
        [editingGraphic endEditingInView:self];
        editingGraphic = nil;
       }
   }


- (BOOL)textView:(NSTextView *)aTextView doCommandBySelector:(SEL)aSelector
   {
	return NO;
   }

-(NSArray*)layersWithName:(NSString*)nm
{
    NSMutableArray *layers = [NSMutableArray arrayWithCapacity:20];
    for (ACSDPage *p in pages)
        for (ACSDLayer *l in p.layers)
            if ([l.name isEqual:nm])
                [layers addObject:l];
    return layers;
}

-(void)setLayer:(ACSDLayer*)l visible:(BOOL)vis
{
    [[[self undoManager] prepareWithInvocationTarget:self] setLayer:l visible:!vis];
	[[NSNotificationCenter defaultCenter] postNotificationName:ACSDLayerSelectionChanged object:self];
	[l setLayerVisible:vis];
}

-(void)hideLayersWithName:(NSString*)nm
{
    NSArray *ls = [[self layersWithName:nm]objectsWhichRespond:NO toSelector:@selector(visible)];
    if ([ls count] > 0)
    {
        for (ACSDLayer *l in ls)
            [self setLayer:l visible:NO];
        [[NSNotificationCenter defaultCenter] postNotificationName:ACSDCurrentLayerChanged object:self];
        [[self undoManager] setActionName:[NSString stringWithFormat:@"Hide Layers: %@",nm]];
    }
}

-(void)uSelectGraphics:(NSArray*)gs forLayer:(ACSDLayer*)l
{
    [[[self undoManager] prepareWithInvocationTarget:self] uSelectGraphics:[[l selectedGraphics]allObjects] forLayer:l];
    [[l selectedGraphics]removeAllObjects];
    [[l selectedGraphics]addObjectsFromArray:gs];
}

-(void)uSetCurrentLayer:(ACSDLayer*)l forPage:(ACSDPage*)page
{
    [[[self undoManager] prepareWithInvocationTarget:self] uSetCurrentLayer:[page currentLayer]forPage:page];
    [page setCurrentLayer:l];
}

-(BOOL)setCurrentLayer:(ACSDLayer*)l forPage:(ACSDPage*)page
{
    if ([page currentLayer] == l)
        return NO;
    if (page == [self currentPage])
    {
        NSInteger idx = [[self layers]indexOfObject:l];
        [self setCurrentEditableLayerIndex:idx force:NO select:YES withUndo:YES];
    }
    else
    {
        [self uSelectGraphics:[NSArray array] forLayer:[page currentLayer]];
        [self uSetCurrentLayer:l forPage:page];
        [self uSelectGraphics:[l graphics] forLayer:l];
    }
    return YES;
}

-(void)selectLayersWithName:(NSString*)nm
{
    BOOL changed = NO;
    for (ACSDPage *p in pages)
        for (ACSDLayer *l in p.layers)
        {
            if ([[l name] isEqualToString:nm])
            {
                changed = [self setCurrentLayer:l forPage:p] || changed;
                break;
            }
        }
    if (changed)
        [[self undoManager]setActionName:[NSString stringWithFormat:@"select Layers: %@",nm]];
}

- (void)setCurrentEditableLayerIndex:(NSInteger)i force:(BOOL)force select:(BOOL)sel withUndo:(BOOL)withUndo
{
    NSInteger oldLayerInd = [[self currentPage] currentLayerInd];
    if ((i ==  oldLayerInd)&& (!force))
        return;
    [[self undoManager]setActionIsDiscardable:YES];
    if (sel)
        [self clearSelection];
    if ([[self currentEditableLayer]isGuideLayer])
        [self setNeedsDisplay:YES];
    if (withUndo)
        [[[self undoManager] prepareWithInvocationTarget:self] setCurrentEditableLayerIndex:[[self currentPage] currentLayerInd]force:YES select:sel withUndo:YES];
    [[self currentPage]setCurrentLayerInd:i];
    if (sel && [[self currentEditableLayer]editable])
        [self selectGraphics:[[self currentEditableLayer] graphics]];
    [[NSNotificationCenter defaultCenter] postNotificationName:ACSDCurrentLayerChanged object:self];
    [self reCalcHandleBitsIgnoreSelected:NO];
}

-(void)uSetSelectionForLayer:(ACSDLayer*)l toObjects:(NSArray*)arr
{
    [[[self undoManager] prepareWithInvocationTarget:self] uSetSelectionForLayer:l toObjects:[[l selectedGraphics]allObjects]];
    [[l selectedGraphics]removeAllObjects];
    [[l selectedGraphics]addObjectsFromArray:arr];
    [self setNeedsDisplay];
    [markerView setNeedsDisplay:YES];
}

- (id)selectedGraphics
   {
	ACSDLayer *l;
	if ((l = [self currentEditableLayer]))
		return [l selectedGraphics];
	return nil;
   }

- (BOOL)graphicIsSelected:(ACSDGraphic*)graphic
   {
	return [[self selectedGraphics] containsObject:graphic];
   }

- (void)setCurrentEditableLayer:(ACSDLayer*)l
   {
	[[self currentPage]setCurrentLayer:l];
	[[NSNotificationCenter defaultCenter] postNotificationName:ACSDCurrentLayerChanged object:self];
   }
	
- (BOOL)selectGraphic:(ACSDGraphic *)graphic
{
    if ([self graphicIsSelected:graphic])
        return NO;
    else
	   {
           //[[self undoManager]setActionIsDiscardable:YES];
           [[[self undoManager] prepareWithInvocationTarget:self] deselectGraphic:graphic];
           if ([self currentEditableLayer] != [graphic layer])
               [self setCurrentEditableLayer:[graphic layer]];
           [[self selectedGraphics] addObject:graphic];
           [graphic invalidateInView];
           [[self window] invalidateCursorRectsForView:self];
           [[NSNotificationCenter defaultCenter] postNotificationName:ACSDGraphicViewSelectionDidChangeNotification object:self];
           if (cursorMode == GV_ROTATION_AWAITING_SELECTION)
               cursorMode = GV_ROTATION_AWAITING_CLICK;
           return YES;
       }
}

- (BOOL)deselectGraphic:(ACSDGraphic *)graphic
{
    if ([self graphicIsSelected:graphic])
	   {
           //[[self undoManager]setActionIsDiscardable:YES];
           [[[self undoManager] prepareWithInvocationTarget:self] selectGraphic:graphic];
           [[self selectedGraphics] removeObject:graphic];
           [graphic invalidateInView];
           [[self window] invalidateCursorRectsForView:self];
           [[NSNotificationCenter defaultCenter] postNotificationName:ACSDGraphicViewSelectionDidChangeNotification object:self];
           return YES;
       }
    return NO;
}

- (BOOL)deselectGraphics:(NSArray*)elementArray
{
	BOOL selectionDidChange = NO;
	for (ACSDGraphic *g in elementArray)
		selectionDidChange = [self deselectGraphic:g] || selectionDidChange;
	if (selectionDidChange)
        [[NSNotificationCenter defaultCenter] postNotificationName:ACSDGraphicViewSelectionDidChangeNotification object:self];
	return selectionDidChange;
}

- (void)setNeedsDisplay
   {
	[self setNeedsDisplay:YES];
   }

- (void)swapElementsAtPosition1:(NSInteger)pos1 position2:(NSInteger)pos2
   {
	[[[self undoManager] prepareWithInvocationTarget:self] swapElementsAtPosition1:pos2 position2:pos1];
	NSMutableArray *graphics = [[self currentEditableLayer] graphics];
	ACSDGraphic *o1 = [graphics objectAtIndex:pos1];
	ACSDGraphic *o2 = [graphics objectAtIndex:pos2];
	[o1 invalidateInView];
	[o2 invalidateInView];
	[graphics replaceObjectAtIndex:pos1 withObject:o2];
	[graphics replaceObjectAtIndex:pos2 withObject:o1];
	[o1 invalidateInView];
	[o2 invalidateInView];
   }

- (void)deletePageAtIndex:(NSInteger)index
   {
	ACSDPage *page = [pages objectAtIndex:index];
	[[[self undoManager] prepareWithInvocationTarget:self] addPage:page atIndex:index];
	[page deRegisterWithDocument:[self document]];
	if (index < (signed)[pages count] - 1)
		[self setCurrentPageIndex:index force:YES withUndo:NO];
	else
		[self setCurrentPageIndex:index - 1 force:YES withUndo:NO];
	[pages removeObjectAtIndex:index];
	[self adjustPageNumbersFromIndex:index];
    [[NSNotificationCenter defaultCenter] postNotificationName:ACSDPageChanged object:self userInfo:nil];
   }

-(void)sortOutMastersForPageAtIndex:(NSInteger)ind
   {
	ACSDPage *page = [pages objectAtIndex:ind];
	if (!([page useMasterType] == USE_MASTER_DEFAULT))
		return;
	BOOL done = NO;
	for (NSInteger i = ind;i >= 0 && !done;i--)
	   {
		ACSDPage *p = [pages objectAtIndex:i];
		if ([p pageType] == PAGE_TYPE_MASTER)
			if (([p masterType] == MASTER_TYPE_ALL)
				|| (([p masterType] == MASTER_TYPE_ODD) && ([page pageNo] & 1))
				|| (([p masterType] == MASTER_TYPE_EVEN) && !([page pageNo] & 1)))
			   {
				done = YES;
				[page uSetMaster:p];
				[p uAddSlave:page];
			   }
	   }
   }

- (void)addPage:(ACSDPage*)page atIndex:(NSInteger)index
{
	[[[self undoManager] prepareWithInvocationTarget:self] deletePageAtIndex:index];
	[pages insertObject:page atIndex:index];
	[page registerWithDocument:[self document]];
	[self adjustPageNumbersFromIndex:index];
	[self sortOutMastersForPageAtIndex:index];
	[self setCurrentPageIndex:index force:YES withUndo:NO];
	[[NSNotificationCenter defaultCenter] postNotificationName:ACSDPageChanged object:self userInfo:nil];
}

- (void)deleteLayerAtIndex:(NSInteger)index
{
	NSMutableArray *layers = [[self currentPage]layers];
	ACSDLayer *layer = [layers objectAtIndex:index];
	[[[self undoManager] prepareWithInvocationTarget:self] addLayer:layer atIndex:index];
	[layers removeObjectAtIndex:index];
	if (layer == [self currentEditableLayer])
		if (index < (signed)[layers count] - 1)
			[self setCurrentEditableLayerIndex:index force:NO select:NO withUndo:YES];
		else
			[self setCurrentEditableLayerIndex:index - 1 force:NO select:NO withUndo:YES];
	[[NSNotificationCenter defaultCenter] postNotificationName:ACSDCurrentLayerChanged object:self];
	self.savedEyeClick = nil;
}

- (void)addLayer:(ACSDLayer*)layer atIndex:(NSInteger)index
{
	[[[self undoManager] prepareWithInvocationTarget:self] deleteLayerAtIndex:index];
	[[[self currentPage]layers] insertObject:layer atIndex:index];
	[layer setPage:[self currentPage]];
	self.savedEyeClick = nil;
	[[NSNotificationCenter defaultCenter] postNotificationName:ACSDCurrentLayerChanged object:self];
}

-(void)renumberPagesFromIndex:(NSInteger)fromInd
   {
	NSInteger pageInd;
	if (fromInd == 0)
		pageInd = 1;
	else
		pageInd = [[pages objectAtIndex:fromInd - 1]pageNo] + 1;
	for (NSInteger i = fromInd,ct = [pages count];i < ct;i++)
	   {
		ACSDPage *page = [pages objectAtIndex:i];
		[page setPageNo:pageInd];
		pageInd++;
	   }
   }

- (void)deleteCurrentPage
   {
	[self deletePageAtIndex:currentPageInd];
	[[self undoManager] setActionName:@"Delete Page"];	
   }

- (NSUInteger)movePageFromIndex:(NSUInteger)fromInd toIndex:(NSUInteger)toInd
{
	if (fromInd == toInd)
		return toInd;
	if (fromInd < toInd)
	{
		[[[self undoManager] prepareWithInvocationTarget:self] movePageFromIndex:toInd-1 toIndex:fromInd];
		[pages insertObject:[pages objectAtIndex:fromInd] atIndex:toInd];
		[pages removeObjectAtIndex:fromInd];
//		currentPageInd = toInd - 1;
		[self setCurrentPageIndex:toInd-1 force:NO];
		[self renumberPagesFromIndex:fromInd];
	}
	else
	{
		[[[self undoManager] prepareWithInvocationTarget:self] movePageFromIndex:toInd toIndex:fromInd+1];
		id obj = [[pages objectAtIndex:fromInd]retain];
		[pages removeObjectAtIndex:fromInd];
		[pages insertObject:obj atIndex:toInd];
		[obj release];
//		currentPageInd = toInd;
		[self setCurrentPageIndex:toInd force:NO];
		[self renumberPagesFromIndex:toInd];
	}
	[self resolveMasters];
	[self setNeedsDisplay:YES];
	[[self undoManager] setActionName:@"Move Page"];	
	return currentPageInd;
}

-(void)uMoveLayerAtIndex:(NSInteger)fromInd page:(ACSDPage*)fromPage toIndex:(NSInteger)toInd page:(ACSDPage*)toPage
{
    if (fromPage == toPage && fromInd == toInd)
        return;
    [[[self undoManager] prepareWithInvocationTarget:self] uMoveLayerAtIndex:toInd page:toPage toIndex:fromInd page:fromPage];
    ACSDLayer *l = [fromPage layers][fromInd];
    [[toPage layers]insertObject:l atIndex:toInd];
    [[fromPage layers]removeObjectAtIndex:fromInd];
    [l setPage:toPage];
    [self setNeedsDisplay:YES];
}

- (NSInteger)moveLayerFromIndex:(NSInteger)fromInd toIndex:(NSInteger)toInd
{
	if (fromInd == toInd)
		return toInd;
	NSMutableArray *layers = [self layers];
	if (fromInd < toInd)
	{
		[[[self undoManager] prepareWithInvocationTarget:self] moveLayerFromIndex:toInd-1 toIndex:fromInd];
		[layers insertObject:[layers objectAtIndex:fromInd] atIndex:toInd];
		[layers removeObjectAtIndex:fromInd];
		[[self currentPage]setCurrentLayerInd:toInd - 1];
	}
	else
	{
		[[[self undoManager] prepareWithInvocationTarget:self] moveLayerFromIndex:toInd toIndex:fromInd+1];
		id obj = [[layers objectAtIndex:fromInd]retain];
		[layers removeObjectAtIndex:fromInd];
		[layers insertObject:obj atIndex:toInd];
		[obj release];
		[[self currentPage]setCurrentLayerInd:toInd];
	}
	[self setNeedsDisplay:YES];
	[[NSNotificationCenter defaultCenter] postNotificationName:ACSDCurrentLayerChanged object:self];
	[[self undoManager] setActionName:@"Move Layer"];	
	self.savedEyeClick = nil;
	return [[self currentPage] currentLayerInd];
}

-(void)uRemoveTrigger:(NSMutableDictionary*)t fromLayer:(ACSDLayer*)l
{
	[[[self undoManager] prepareWithInvocationTarget:self] uAddTrigger:t toLayer:l];
	[l removeTrigger:t];
	[t removeObjectForKey:@"layer"];
}

-(void)uAddTrigger:(NSMutableDictionary*)t toLayer:(ACSDLayer*)l
{
	[[[self undoManager] prepareWithInvocationTarget:self] uRemoveTrigger:t fromLayer:l];
	[l addTrigger:t];
	[t setObject:l forKey:@"layer"];
}

-(void)uAddTrigger:(NSMutableDictionary*)t toGraphic:(ACSDGraphic*)g
{
	[[[self undoManager] prepareWithInvocationTarget:self] uRemoveTrigger:t fromGraphic:g];
	[g addTrigger:t];
	[t setObject:g forKey:@"graphic"];
}

-(void)uRemoveTrigger:(NSMutableDictionary*)t fromGraphic:(ACSDGraphic*)g
{
	[[[self undoManager] prepareWithInvocationTarget:self] uAddTrigger:t toGraphic:g];
	[g removeTrigger:t];
	[t removeObjectForKey:@"graphic"];
}

- (void)insertLayer:(ACSDLayer*)l atIndex:(NSInteger)ind
   {
	[[[self undoManager] prepareWithInvocationTarget:self] deleteCurrentLayer];
	[[self layers] insertObject:l atIndex:ind];
	[self setCurrentEditableLayerIndex:ind force:YES select:NO withUndo:NO];
	   [[NSNotificationCenter defaultCenter] postNotificationName:ACSDCurrentLayerChanged object:self];
//	[[NSNotificationCenter defaultCenter] postNotificationName:ACSDPageChanged object:self userInfo:nil];
	[self setNeedsDisplay:YES];
   }

- (void)deleteCurrentLayer
   {
	NSInteger ind = [[self currentPage]currentLayerInd];
	[[[self undoManager] prepareWithInvocationTarget:self] insertLayer:[self currentEditableLayer] atIndex:ind];
	NSArray *triggers = [[self currentEditableLayer]triggers];
	if (triggers)
		for (NSInteger i = [triggers count] - 1;i >= 0;i--)
		{
			NSMutableDictionary *t = [triggers objectAtIndex:i];
			[self uRemoveTrigger:t fromLayer:[self currentEditableLayer]];
			[self uRemoveTrigger:t fromGraphic:[t objectForKey:@"graphic"]];
		}
	[[self layers] removeObjectAtIndex:ind];
	if (ind >= (int)[[self layers] count])
		ind--;
	[[self currentPage]setCurrentLayerInd:ind];
	[self setCurrentEditableLayerIndex:ind force:YES select:NO withUndo:NO];
//	[[NSNotificationCenter defaultCenter] postNotificationName:ACSDPageChanged object:self userInfo:nil];
	   [[NSNotificationCenter defaultCenter] postNotificationName:ACSDCurrentLayerChanged object:self];
	[self setNeedsDisplay:YES];
	[[self undoManager] setActionName:@"Delete Layer"];	
   }

-(void)moveGraphicsFromLayer:(ACSDLayer*) fromLayer atIndexes:(NSIndexSet*)fromIxs toLayer:(ACSDLayer*)toLayer atIndexes:(NSIndexSet*)toIxs
{
    [[[self undoManager] prepareWithInvocationTarget:self] moveGraphicsFromLayer:toLayer atIndexes:toIxs toLayer:fromLayer atIndexes:fromIxs];
    NSMutableArray *fromIndexes = [NSMutableArray array];
    [fromIxs enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
        [fromIndexes addObject:@(idx)];
    }];
    NSMutableArray *toIndexes = [NSMutableArray array];
    [toIxs enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
        [toIndexes addObject:@(idx)];
    }];
    NSMutableArray *gs = [NSMutableArray array];
    for (NSInteger i = [fromIndexes count]-1;i >= 0;i--)
    {
        NSInteger fi = [fromIndexes[i]integerValue];
        ACSDGraphic *g = [fromLayer graphics][fi];
        [gs addObject:@[g,toIndexes[i]]];
        [fromLayer removeGraphicAtIndex:fi];
    }
    for (NSArray *arr in [gs reverseObjectEnumerator])
    {
        ACSDGraphic *g = arr[0];
        NSInteger idx = [arr[1] integerValue];
        [toLayer addGraphic:g atIndex:idx];
    }
}

- (void)moveSelectedGraphicsToLayer:(NSInteger)toInd
   {
	NSInteger fromInd = [[self currentPage]currentLayerInd];
	if (fromInd == toInd)
		return;
	[[[self undoManager] prepareWithInvocationTarget:self] moveSelectedGraphicsToLayer:fromInd];
	NSArray *gArray = [[self selectedGraphics] allObjects];
	[[[self layers]objectAtIndex:fromInd]removeGraphics:gArray];
	[[[self layers]objectAtIndex:toInd]addGraphics:gArray];
	[[self selectedGraphics]removeAllObjects];
	[[self currentPage]setCurrentLayerInd:toInd];
	[[[self currentEditableLayer]selectedGraphics]addObjectsFromArray:gArray];
	[self setNeedsDisplay:YES];
   }

- (void)adjustPageNumbersFromIndex:(NSInteger)index
   {
	int pageNo = 1;
	for (unsigned i = 0;i < [pages count];i++)
	   {
		ACSDPage *page = [pages objectAtIndex:i];
		if ([page pageType]== PAGE_TYPE_NORMAL)
		   {
			[page setPageNo:pageNo];
			pageNo++;
		   }
	   }
   }
	
- (void)addNewPageAtIndex:(NSInteger)index
{
	[self addPage:[[[ACSDPage alloc]initWithDocument:[self document]]autorelease]atIndex:index];
	[[self undoManager] setActionName:@"Add Page"];
}

/*NSString *IncrementString(NSString *s)
{
    if ([s length] == 0)
        return s;
    unichar uc = [s characterAtIndex:[s length] - 1];
    if ([[NSCharacterSet decimalDigitCharacterSet]characterIsMember:uc])
    {
        int tot = [[s substringFromIndex:[s length]-1]intValue] + 1;
        return [NSString stringWithFormat:@"%@%d",[s substringToIndex:[s length] - 1],tot];
    }
    if ([[NSCharacterSet letterCharacterSet]characterIsMember:uc])
    {
        if (uc == 'z')
            return [s stringByAppendingString:@"a"];
        else if (uc == 'Z')
            return [s stringByAppendingString:@"A"];
        else
        {
            uc++;
            return [NSString stringWithFormat:@"%@%C",[s substringToIndex:[s length] - 1],uc];
        }
    }
    return s;
}*/

-(void)duplicatePageAtIndex:(NSInteger)index
{
    ACSDPage *p = [[pages[index]copy]autorelease];
    [p setPageTitle:IncrementString([pages[index]pageTitle])];
	[self addPage:p atIndex:index+1];
	[[self undoManager] setActionName:@"Duplicate Page"];
}

-(IBAction)duplicatePage:(id)sender
{
	if (currentPageInd >= 0)
		[self duplicatePageAtIndex:currentPageInd];
}

- (void)addNewLayerAtIndex:(NSInteger)index
   {
	[self addLayer:[[[ACSDLayer alloc]initWithName:[[self currentPage] nextLayerName]isGuideLayer:NO]autorelease]
		atIndex:index];
	[self setCurrentEditableLayerIndex:index force:NO select:YES withUndo:YES];
	[[self undoManager] setActionName:@"Add Layer"];
   }

-(void)setDefaultMastersForMasterPage:(ACSDPage*)masterPage fromIndex:(NSInteger)ind
   {
	BOOL oddFound = NO,evenFound = NO;
	for (NSInteger i = ind,ct = [pages count];i < ct && (!oddFound) && (!evenFound);i++)
	   {
		ACSDPage *p = [pages objectAtIndex:i];
		if ([p pageType] == PAGE_TYPE_MASTER && ![p inactive])
		   {
			if ([p masterType] == MASTER_TYPE_ALL)
				oddFound = evenFound = YES;
			else if ([p masterType] == MASTER_TYPE_ODD)
				oddFound = YES;
			else if ([p masterType] == MASTER_TYPE_EVEN)
				evenFound = YES;
		   }
		if ([p useMasterType] == USE_MASTER_DEFAULT)
			if (([masterPage masterType] == MASTER_TYPE_ALL)
				|| (([masterPage masterType] == MASTER_TYPE_ODD) && ([p pageNo] & 1))
				|| (([masterPage masterType] == MASTER_TYPE_EVEN) && !([p pageNo] & 1)))
			   {
				[p uSetMaster:masterPage];
				[masterPage uAddSlave:p];
			   }
	   }
   }

-(void)resolveMasters
{
	ACSDPage *oddMaster=nil,*evenMaster=nil;
	for (NSInteger i = 0,ct = [pages count];i < ct;i++)
	{
		ACSDPage *p = [pages objectAtIndex:i];
		if ([p pageType] == PAGE_TYPE_MASTER)
		{
			[p allocSlaves];
			[[p slaves]removeAllObjects];
		}
		if ([p useMasterType] == USE_MASTER_DEFAULT || [p useMasterType] == USE_MASTER_NONE)
		{
			[p allocMasters];
			[[p masters]removeAllObjects];
			if ([p useMasterType] == USE_MASTER_DEFAULT)
			{
				if ([p pageType] == PAGE_TYPE_MASTER)
				{
					if ([p masterType] == MASTER_TYPE_ALL)
					{
						if (oddMaster)
						{
							[[p masters]addObject:oddMaster];
							[[oddMaster slaves]addObject:p];
						}
						if (evenMaster && (oddMaster != evenMaster))
						{
							[[p masters]addObject:evenMaster];
							[[evenMaster slaves]addObject:p];
						}
					}
					else if ([p masterType] == MASTER_TYPE_ODD)
					{
						if (oddMaster)
						{
							[[p masters]addObject:oddMaster];
							[[oddMaster slaves]addObject:p];
						}
					}
					else if ([p masterType] == MASTER_TYPE_EVEN)
					{
						if (evenMaster)
						{
							[[p masters]addObject:evenMaster];
							[[evenMaster slaves]addObject:p];
						}
					}
				}
				else
				{
					if (([p pageNo] & 1) && oddMaster)
					{
						[[p masters]addObject:oddMaster];
						[[oddMaster slaves]addObject:p];
					}
					else if (!([p pageNo] & 1) && evenMaster)
					{
						[[p masters]addObject:evenMaster];
						[[evenMaster slaves]addObject:p];
					}
				}
			}
		}
		if ([p pageType] == PAGE_TYPE_MASTER && ![p inactive])
		{
			if ([p masterType] == MASTER_TYPE_ALL)
				oddMaster = evenMaster = p;
			else if ([p masterType] == MASTER_TYPE_ODD)
				oddMaster = p;
			else if ([p masterType] == MASTER_TYPE_EVEN)
				evenMaster = p;
		}
	}
}

-(BOOL)uSetLayer:(ACSDLayer*)l zPosOffset:(float)f
{
    if (l == nil || l.zPosOffset == f)
        return NO;
    [[[self undoManager] prepareWithInvocationTarget:self] uSetLayer:l zPosOffset:l.zPosOffset];
    l.zPosOffset = f;
    [[NSNotificationCenter defaultCenter] postNotificationName:ACSDCurrentLayerChanged object:self userInfo:nil];
    return YES;
}

-(void)setCurrentLayerZPosOffset:(float)f
{
    if ([self uSetLayer:[self currentEditableLayer] zPosOffset:f])
        [[self undoManager] setActionName:@"Set Layer zPos offset"];
    
}

-(BOOL)uSetLayer:(ACSDLayer*)l exportable:(BOOL)b
{
	if (l == nil || l.exportable == b)
		return NO;
	[[[self undoManager] prepareWithInvocationTarget:self] uSetLayer:l exportable:l.exportable];
	l.exportable = b;
	[[NSNotificationCenter defaultCenter] postNotificationName:ACSDCurrentLayerChanged object:self userInfo:nil];
	return YES;
}

-(void)setCurrentLayerExportable:(BOOL)b
{
	if ([self uSetLayer:[self currentEditableLayer] exportable:b])
		[[self undoManager] setActionName:@"Set Layer Exportable"];
	
}
-(BOOL)uSetMasterType:(int)mType
{
	if (mType == [[self currentPage]masterType])
		return NO;
	ACSDPage *page = [self currentPage];
	[[[self undoManager] prepareWithInvocationTarget:self] uSetMasterType:[page masterType]];
	[page setMasterType:mType];
	[self resolveMasters];
	[[NSNotificationCenter defaultCenter] postNotificationName:ACSDPageChanged object:self userInfo:nil];
	return YES;
}

-(void)setMasterType:(int)mType
   {
	if ([self uSetMasterType:mType])
		[[self undoManager] setActionName:@"Set Master Type"];
   }

-(BOOL)uSetUseMaster:(int)mType
   {
	if (mType == [[self currentPage]useMasterType])
		return NO;
	ACSDPage *page = [self currentPage];
	[[[self undoManager] prepareWithInvocationTarget:self] uSetUseMaster:[page useMasterType]];
	[page setUseMasterType:mType];
	[self resolveMasters];
	[[NSNotificationCenter defaultCenter] postNotificationName:ACSDPageChanged object:self userInfo:nil];
	return YES;
   }

-(void)setUseMaster:(int)mType
   {
	if ([self uSetUseMaster:mType])
		[[self undoManager] setActionName:@"Set Master Use"];
   }

-(BOOL)uSetPageInactive:(BOOL)ia
{
	if (ia == [[self currentPage]inactive])
		return NO;
	[[[self undoManager] prepareWithInvocationTarget:self] uSetPageInactive:[[self currentPage]inactive]];
	[[self currentPage]setInactive:ia];
	return YES;
}

-(void)setPageInactive:(BOOL)ia
   {
	if ([self uSetPageInactive:ia])
	if (ia)
		[[self undoManager] setActionName:@"Set Page Inactive"];
	else
		[[self undoManager] setActionName:@"Set Page Active"];
	int pType = [[self currentPage]pageType];
	if (pType == PAGE_TYPE_MASTER)
		if (ia)
		   {
			for (ACSDPage *p in pages)
				[p uRemoveMaster:[self currentPage]];
		   }
/*		else
		{
//			[self setDefaultMastersForMasterPage:[self currentPage] fromIndex:currentPageInd+1];
	    }*/
		[self resolveMasters];
   }


-(BOOL)uSetPageType:(int)pType
   {
	if (pType == [[self currentPage]pageType])
		return NO;
	ACSDPage *page = [self currentPage];
	int uType;
	if (pType == PAGE_TYPE_MASTER)
	   {
		uType = PAGE_TYPE_NORMAL;
		if ([page name] == nil)
			[page setName:@"Master"];
	   }
	else
		uType = PAGE_TYPE_MASTER;
	[[[self undoManager] prepareWithInvocationTarget:self] uSetPageType:uType];
	[page setPageType:pType];
	[self adjustPageNumbersFromIndex:currentPageInd];
	if (pType == PAGE_TYPE_MASTER)
	   {
		[self setDefaultMastersForMasterPage:page fromIndex:currentPageInd+1];
	   }
	else
	   {
		for (ACSDPage *p in pages)
			[p uRemoveMaster:page];
	   }
	[[NSNotificationCenter defaultCenter] postNotificationName:ACSDPageChanged object:self userInfo:nil];
	return YES;
   }

-(void)setPageType:(int)pType
   {
	if ([self uSetPageType:pType])
		if (pType == PAGE_TYPE_MASTER)
			[[self undoManager] setActionName:@"Set Master Page"];
		else
			[[self undoManager] setActionName:@"Unset Master Page"];
   }

- (BOOL)clearSelection
{
    NSArray *elementArray = [[self selectedGraphics] allObjects];
    NSInteger ct = [elementArray count];
    if (ct > 0)
	   {
           for (int i = 0;i < ct;i++)
           {
               ACSDGraphic *curGraphic = [elementArray objectAtIndex:i];
               [curGraphic uClearSelectedElements];
               [curGraphic invalidateInView];
           }
           [[self undoManager]setActionIsDiscardable:YES];
           [[[self undoManager] prepareWithInvocationTarget:self] selectGraphics:elementArray];
           [self deselectGraphics:elementArray];
           [[self window] invalidateCursorRectsForView:self];
           [[NSNotificationCenter defaultCenter] postNotificationName:ACSDGraphicViewSelectionDidChangeNotification object:self];
           return YES;
       }
    return NO;
}

-(void)toggleLockingForLayer:(ACSDLayer*)l
{
	if (l == [self currentEditableLayer])
		[self clearSelection];
	[[[self undoManager] prepareWithInvocationTarget:self] toggleLockingForLayer:l];
	[l setEditable:![l editable]];
	[[NSNotificationCenter defaultCenter] postNotificationName:ACSDLayerSelectionChanged object:self];
}

-(void)toggleVisibilityForLayer:(ACSDLayer*)l modifierFlags:(NSUInteger)modifierFlags
{
//	if (l == [self currentEditableLayer])
//		[self clearSelection];
	if ((modifierFlags & NSAlternateKeyMask)!=0)
	{
		if ([l visible])
		{
			if (self.savedEyeClick != nil)
			{
				ACSDLayer *savedLayer = self.savedEyeClick[0];
				if (savedLayer == l)
				{
					NSArray *visibleLayers = self.savedEyeClick[1];
					for (ACSDLayer *ly in visibleLayers)
					{
						[self setLayer:ly visible:YES];
					}
					self.savedEyeClick = nil;
					return;
				}
			}
			else
			{
				NSMutableArray *visibleLayers = [NSMutableArray array];
				for (ACSDLayer *ly in [self layers])
				{
					if (ly != l && [ly visible])
					{
						[self setLayer:ly visible:NO];
						[visibleLayers addObject:ly];
					}
				}
				if (![l visible])
					[self setLayer:l visible:YES];
				self.savedEyeClick = @[l,visibleLayers];
				return;
			}
		}
	}
	[self setLayer:l visible:![l visible]];
}

NSInteger sortPositionalObjects(id obj1,id obj2,void *context)
   {
	PositionalObject *o1,*o2;
	o1 = obj1;
	o2 = obj2;
	if ([o1 position] < [o2 position])
		return NSOrderedAscending;
	if ([o1 position] > [o2 position])
		return NSOrderedDescending;
	return NSOrderedSame;
   }

- (void)insertselectedGraphics:(NSMutableArray*)poArray
   {
	[[[self undoManager] prepareWithInvocationTarget:self] deleteSelectedGraphics];
	for (PositionalObject *po in poArray)
	   {
		ACSDGraphic *curGraphic = [po object];
		[[[self currentEditableLayer] graphics]insertObject:curGraphic atIndex:[po position]];
        [[self selectedGraphics] addObject:curGraphic];
        [curGraphic invalidateInView];
	   }
	[[self window] invalidateCursorRectsForView:self];
    [[NSNotificationCenter defaultCenter] postNotificationName:ACSDGraphicViewSelectionDidChangeNotification object:self];
   }

- (void)insertArchivedElements:(NSData*)data
   {
	NSMutableArray *poArray = [NSKeyedUnarchiver unarchiveObjectWithData:data];
	[self insertselectedGraphics:poArray];
   }

- (void)insertGraphic:(ACSDGraphic*)graphic atIndex:(NSInteger)i
{
    [[[self undoManager] prepareWithInvocationTarget:self] deleteGraphicAtIndex:i];
    [[[self currentEditableLayer] graphics]insertObject:graphic atIndex:i];
    [self selectGraphic:graphic];
    //[[self selectedGraphics] addObject:graphic];
    [graphic registerWithDocument:[self document]];
    [graphic postUndelete];
    [graphic invalidateInView];
    [[self window] invalidateCursorRectsForView:self];
    [[NSNotificationCenter defaultCenter] postNotificationName:ACSDGraphicViewSelectionDidChangeNotification object:self];
    [[NSNotificationCenter defaultCenter]postNotificationName:ACSDGraphicListChanged object:self];
}

-(void)uSetGraphics:(NSMutableArray*)gs forLayer:(ACSDLayer*)l      //assumes this is just a different ordering
{
    [[[self undoManager] prepareWithInvocationTarget:self] uSetGraphics:[l graphics]forLayer:l];
    [l setGraphics:gs];
    [self setNeedsDisplay:YES];
    [[NSNotificationCenter defaultCenter]postNotificationName:ACSDGraphicListChanged object:self];
}

- (void)addElement:(ACSDGraphic*)graphic
   {
	[self insertGraphic:graphic atIndex:[[[self currentEditableLayer]graphics] count]];
//	[[self document]registerObject:graphic];
   }

- (NSArray*)selectedGraphicsSortedByTimestamp
{
    NSArray *selectedGraphics = [[self selectedGraphics] allObjects];
    if ([selectedGraphics count] < 2)
        return selectedGraphics;
    return [selectedGraphics sortedArrayUsingSelector:@selector(compareTimeStampWith:)];
}

-(NSArray*)verticalSpacesForGraphics:(NSArray*)graphics inset:(int)inset
{
    NSMutableIndexSet *ixs = [NSMutableIndexSet indexSetWithIndexesInRange:NSMakeRange(0, [self frame].size.width)];
    for (ACSDGraphic *g in graphics)
    {
        NSRect b = [g transformedBounds];
        b = NSInsetRect(b, inset, inset);
        int st = NSMinX(b);
        int en = NSMaxX(b);
        [ixs removeIndexesInRange:NSMakeRange(st, en - st)];
    }
    NSMutableArray *arr = [NSMutableArray array];
    [ixs enumerateRangesUsingBlock:^(NSRange range, BOOL *stop) {
        [arr addObject:@(range.location + range.length / 2)];
    }];
    return arr;
}

-(NSArray*)horizontalSpacesForGraphics:(NSArray*)graphics inset:(int)inset
{
    NSMutableIndexSet *ixs = [NSMutableIndexSet indexSetWithIndexesInRange:NSMakeRange(0, [self frame].size.height)];
    for (ACSDGraphic *g in graphics)
    {
        NSRect b = [g transformedBounds];
        b = NSInsetRect(b, inset, inset);
        int st = NSMinY(b);
        int en = NSMaxY(b);
        [ixs removeIndexesInRange:NSMakeRange(st, en - st + 1)];
    }
    NSMutableArray *arr = [NSMutableArray array];
    [ixs enumerateRangesUsingBlock:^(NSRange range, BOOL *stop) {
        [arr addObject:@(range.location + range.length / 2)];
    }];
    return arr;
}

-(NSArray*)rowColumnGraphics:(NSArray*)graphics
{
    NSMutableArray *arr = [NSMutableArray array];
    int ct = ceil(sqrt([graphics count]));
    NSArray *vs = @[];
    NSArray *hs = @[];
    for (int i = 0;i < 3;i++)
    {
        vs = [self verticalSpacesForGraphics:graphics inset:i*10];
        hs = [self horizontalSpacesForGraphics:graphics inset:i*10];
        if ([vs count] >= ct || [hs count] >= ct)
            break;
    }
    for (ACSDGraphic *g in graphics)
    {
        int cx = [g centrePoint].x;
        int colidx = 0;
        for (NSNumber *n in vs)
        {
            if (cx < [n intValue])
            {
                break;
            }
            colidx++;
        }
        int cy = [g centrePoint].y;
        int rowidx = 0;
        for (NSNumber *n in hs)
        {
            if (cy < [n intValue])
            {
                break;
            }
            rowidx++;
        }
        [arr addObject:@[g,@(colidx),@(rowidx)]];
    }
    return arr;
}

static NSComparisonResult ord(int i1,int i2,BOOL asc)
{
    int j1,j2;
    if (asc)
    {
        j1 = i1;
        j2 = i2;
    }
    else
    {
        j1 = i2;
        j2 = i1;
    }
    if (j1 < j2)
        return NSOrderedAscending;
    if (j2 < j1)
        return NSOrderedDescending;
    return NSOrderedSame;
}

static NSComparisonResult orderstuff(int i1,int i2,BOOL asci,int j1,int j2,BOOL ascj)
{
    if (i1 == i2)
        return ord(j1, j2, ascj);
    return ord(i1,i2,asci);
}

- (NSArray*)selectedGraphicsSortedByRowColumnRowFirst:(BOOL)rowFirst rowAsc:(BOOL)rowAsc colAsc:(BOOL)colAsc
{
    NSArray *selectedGraphics = [[self selectedGraphics] allObjects];
    if ([selectedGraphics count] < 2)
        return selectedGraphics;
    NSArray *triples = [self rowColumnGraphics:selectedGraphics];
    triples = [triples sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
        int col1 = [obj1[1]intValue],col2 = [obj2[1]intValue];
        int row1 = [obj1[2]intValue],row2 = [obj2[2]intValue];
        if (rowFirst)
        {
            return orderstuff(col1, col2, colAsc, row1, row2, rowAsc);
            /*if (col1 < col2)
                return NSOrderedAscending;
            if (col1 > col2)
                return NSOrderedDescending;
            if (row1 < row2)
                return NSOrderedAscending;
            if (row1 > row2)
                return NSOrderedDescending;
            return NSOrderedSame;*/
        }
        else
        {
            return orderstuff(row1, row2, rowAsc, col1, col2, colAsc);
            /*if (row1 < row2)
                return NSOrderedAscending;
            if (row1 > row2)
                return NSOrderedDescending;
            if (col1 < col2)
                return NSOrderedAscending;
            if (col1 > col2)
                return NSOrderedDescending;
            return NSOrderedSame;*/
        }
    }];
    NSMutableArray *arr = [NSMutableArray array];
    for (NSArray *t in triples)
        [arr addObject:t[0]];
    return arr;
}

- (NSArray*)sortedSelectedGraphics
   {
	NSInteger selectedCount = [[self selectedGraphics]count];
	if (selectedCount == 1)
		return [[self selectedGraphics] allObjects];
	else
	   {
		NSMutableArray *sortedSelectedGraphics = [NSMutableArray arrayWithCapacity:selectedCount];
		NSArray *allElements = [[self currentEditableLayer] graphics];
		for (ACSDGraphic *curGraphic in allElements)
		   {
			if ([self graphicIsSelected:curGraphic])
				[sortedSelectedGraphics addObject:curGraphic];
		   }
		return sortedSelectedGraphics;
	   }
   }

-(NSIndexSet*)indexesOfSelectedGraphics
{
	NSMutableIndexSet *ixs = [[[NSMutableIndexSet alloc]init]autorelease];
    NSArray *elementArray = [[self selectedGraphics] allObjects];
	for (ACSDGraphic *curGraphic in elementArray)
	{
		NSInteger pos = [[[self currentEditableLayer] graphics]indexOfObjectIdenticalTo:curGraphic];
		[ixs addIndex:pos];
	}
	return ixs;
}

- (NSMutableArray*)sortedPositionalObjects
{
    NSArray *elementArray = [[self selectedGraphics] allObjects];
	NSMutableArray *positionalObjects = [NSMutableArray arrayWithCapacity:[elementArray count]];
	for (ACSDGraphic *curGraphic in elementArray)
	{
		NSUInteger pos = [[[self currentEditableLayer] graphics]indexOfObjectIdenticalTo:curGraphic];
		[positionalObjects addObject:[[[PositionalObject alloc]initWithPosition:pos object:curGraphic]autorelease]];
	}
	[positionalObjects sortUsingFunction:sortPositionalObjects context:NULL];
	return positionalObjects;
}

- (void)uRefreshElement:(ACSDGraphic*)g
   {
	[[[self undoManager] prepareWithInvocationTarget:self] uRefreshElement:g];
	[g invalidateInView];
	if ([g layer] == [self currentEditableLayer])
		[[self window] invalidateCursorRectsForView:self];
   }

- (void)uDeleteGraphic:(ACSDGraphic*)g
   {
	ACSDLayer *l = [g layer];
	NSUInteger i = [[l graphics]indexOfObjectIdenticalTo:g];
	if (!l || i == NSNotFound)
		return;
	[g invalidateInView];
	[g preDelete];
	[[[self undoManager] prepareWithInvocationTarget:self] uInsertGraphic:g intoLayer:l atIndex:i];
	[[l graphics]removeObjectAtIndex:i];
	[[self document] deRegisterObject:g];
	if (l == [self currentEditableLayer])
	   {
		[[self window] invalidateCursorRectsForView:self];
		[[self selectedGraphics]removeObject:g];
	   }
    [[NSNotificationCenter defaultCenter]postNotificationName:ACSDGraphicListChanged object:self];
   }

- (void)uInsertGraphic:(ACSDGraphic*)g intoLayer:(ACSDLayer*) l atIndex:(NSInteger)i
   {
	[[[self undoManager] prepareWithInvocationTarget:self] uDeleteGraphic:g];
	[[l graphics]insertObject:g atIndex:i];
	[[self document]registerObject:g];
	[g setLayer:l];
	[g postUndelete];
	[g invalidateInView];
	if (l == [self currentEditableLayer])
		[[self window] invalidateCursorRectsForView:self];
    [[NSNotificationCenter defaultCenter]postNotificationName:ACSDGraphicListChanged object:self];
   }

- (void)deleteGraphicAtIndex:(NSInteger)i
   {
	ACSDGraphic *g = [[[self currentEditableLayer] graphics]objectAtIndex:i];
	[g preDelete];
	[[[self undoManager] prepareWithInvocationTarget:self] insertGraphic:g atIndex:i];
	[[[self currentEditableLayer] graphics]removeObjectAtIndex:i];
	[g invalidateInView];
	[g deRegisterWithDocument:[self document]];
    [[NSNotificationCenter defaultCenter]postNotificationName:ACSDGraphicListChanged object:self];
   }

- (void)deleteGraphic:(ACSDGraphic*)g
   {
	NSUInteger pos = [[[self currentEditableLayer]graphics]indexOfObjectIdenticalTo:g];
	[self deleteGraphicAtIndex:pos];
   }

- (void)deleteSelectedGraphics
   {
	if (creatingPath)
	   {
		[creatingPath invalidateInView];
		[creatingPath setAddingPoints:NO];
		creatingPath = nil;
	   }
	NSInteger ct = [[self selectedGraphics] count];
    if (ct > 0)
	   {
		NSArray *objectsToDelete = [self sortedSelectedGraphics];
		for (NSInteger i = [objectsToDelete count] - 1;i >= 0;i--)
		{
			[self deselectGraphic:[objectsToDelete objectAtIndex:i]];
			[self uDeleteGraphic:[objectsToDelete objectAtIndex:i]];
		}
		[self emptyRepeatQueue];
       }
   }

- (BOOL)selectGraphics:(NSArray*)elementArray
   {
	BOOL selectionDidChange = NO;
	for (ACSDGraphic *g in elementArray)
		selectionDidChange = [self selectGraphic:g] || selectionDidChange;
	if (selectionDidChange)
        [[NSNotificationCenter defaultCenter] postNotificationName:ACSDGraphicViewSelectionDidChangeNotification object:self];
	return selectionDidChange;
   }

- (void)uInsertIntoCurrentLayerGraphic:(ACSDGraphic*)graphic atIndex:(NSInteger)i
   {
	[[[self undoManager] prepareWithInvocationTarget:self] uRemoveFromCurrentLayerGraphicAtIndex:i];
	[[[self currentEditableLayer] graphics]insertObject:graphic atIndex:i];
//	[[self selectedGraphics] addObject:graphic];
	[graphic invalidateInView];
	[graphic setParent:nil];
	[[self window] invalidateCursorRectsForView:self];
    [[NSNotificationCenter defaultCenter] postNotificationName:ACSDGraphicViewSelectionDidChangeNotification object:self];
   }


-(void)uRemoveFromCurrentLayerGraphicAtIndex:(NSInteger)i
   {
	ACSDGraphic *g = [[[self currentEditableLayer] graphics]objectAtIndex:i];
	[[[self undoManager] prepareWithInvocationTarget:self] uInsertIntoCurrentLayerGraphic:g atIndex:i];
	[[[self currentEditableLayer] graphics]removeObjectAtIndex:i];
	[g invalidateInView];
   }
   
- (void)removeFromCurrentLayerGraphic:(ACSDGraphic*)g
   {
	NSUInteger pos = [[[self currentEditableLayer]graphics]indexOfObjectIdenticalTo:g];
	[self uRemoveFromCurrentLayerGraphicAtIndex:pos];
   }

- (void)removeSelectedGraphicsFromCurrentLayer
   {
	if (creatingPath)
	   {
		[creatingPath invalidateInView];
		[creatingPath setAddingPoints:NO];
		creatingPath = nil;
	   }
	NSInteger ct = [[self selectedGraphics] count];
    if (ct > 0)
	   {
		NSArray *objectsToRemove = [self sortedSelectedGraphics];
		[self clearSelection];
		for (NSInteger i = ct - 1;i >= 0;i--)
            [self removeFromCurrentLayerGraphic:[objectsToRemove objectAtIndex:i]];
		[self emptyRepeatQueue];
       }
   }

- (ACSDGraphic*)graphicUnderPoint:(NSPoint)point extending:(BOOL)extending
   {
	if (extending)
	   {
		ACSDLayer *layer = [self currentEditableLayer];
		if ([layer visible] && [layer editable])
		   {
			NSMutableArray *graphics = [layer graphics];
			NSInteger ct = [graphics count];
			for (NSInteger j = ct - 1;j >= 0; j--)
			   {
				ACSDGraphic *curGraphic = [graphics objectAtIndex:j];
				if ([self mouse:point inRect:[curGraphic displayBounds]] && [curGraphic hitTest:point isSelected:[self graphicIsSelected:curGraphic]view:self])
					return curGraphic;
			   }
		   }
	   }
	else
	   {
		for (ACSDLayer *layer in [[self currentPage] layers])
		   {
			if ([layer visible] && [layer editable] && (layer == [self currentEditableLayer] || ![layer isGuideLayer]))
			   {
				for (ACSDGraphic *curGraphic in [[layer graphics]reverseObjectEnumerator])
					if ([self mouse:point inRect:[curGraphic displayBounds]] && [curGraphic hitTest:point isSelected:[self graphicIsSelected:curGraphic]view:self])
						return curGraphic;
			   }
		   }
	   }
	return nil;
   }

- (ACSDGraphic*)masterGraphicUnderPoint:(NSPoint)point
{
	for (ACSDPage *p in [[self currentPage]masters])
		for (ACSDLayer *layer in [p layers])
		{
			if ([layer visible] && ![layer isGuideLayer])
			{
				for (ACSDGraphic *curGraphic in [[layer graphics]reverseObjectEnumerator])
					if ([self mouse:point inRect:[curGraphic displayBounds]] && [curGraphic hitTest:point isSelected:NO view:self])
						return curGraphic;
			}
		}
	return nil;
}

- (ACSDGraphic*)shapeUnderPoint:(NSPoint)point extending:(BOOL)extending
{
	if (extending)
	{
		ACSDLayer *layer = [self currentEditableLayer];
		if ([layer visible])
			return [[layer graphics]lastObjectWhichRespondsYesToSelector:@selector(shapeUnderPointValue:) withObject:[NSValue valueWithPoint:point]];
	}
	else
	{
		for (ACSDLayer *layer in [[self currentPage] layers])
		{
			if ([layer visible] && [layer editable] && (layer == [self currentEditableLayer] || ![layer isGuideLayer]))
			{
				NSMutableArray *graphics = [layer graphics];
				ACSDGraphic *graphic;
				if ((graphic = [graphics lastObjectWhichRespondsYesToSelector:@selector(shapeUnderPointValue:) withObject:[NSValue valueWithPoint:point]]))
					return graphic;
			}
		}
	}
	return nil;
}

-(ACSDGraphic*)selectedShapeUnderPoint:(NSPoint)pt
   {
	return [[self sortedSelectedGraphics] lastObjectWhichRespondsYesToSelector:@selector(shapeUnderPointValue:) 
																	withObject:[NSArray arrayWithObjects:[NSValue valueWithPoint:pt],[NSNumber numberWithBool:YES],self,nil]];
   }

- (ACSDGraphic*)selectedGraphicUnderPoint:(NSPoint)point
   {
	NSArray *selectedgraphics = [self sortedSelectedGraphics];
    NSEnumerator *objEnum = [selectedgraphics objectEnumerator];
    ACSDGraphic *curGraphic;
    while ((curGraphic = [objEnum nextObject]) != nil) 
		if ([self mouse:point inRect:[curGraphic displayBounds]] && [curGraphic hitTest:point isSelected:YES view:self])
			return curGraphic;
	return nil;
   }

- (NSSet *)graphicsIntersectingRect:(NSRect)rect
   {
	NSMutableSet *result = [NSMutableSet set];
	if ([self currentEditableLayer] && [[self currentEditableLayer] editable])
	   {
		for (ACSDGraphic *curGraphic in [[self currentEditableLayer] graphics])
			if ([curGraphic intersectsWithRect:rect])
				[result addObject:curGraphic];
	   }
    return result;
   }

- (void)invalidateGraphic:(ACSDGraphic*)graphic
{
	NSRect db = [graphic displayBounds];
	[self setNeedsDisplayInRect:db];
/*	if (magnification != 1.0)
	{
		NSAffineTransform *transform = [NSAffineTransform transformWithScaleBy:magnification];
		db = [transform transformRect:db];
	}*/
	[markerView setNeedsDisplayInRect:db];
	if ([[[self window]windowController]respondsToSelector:@selector(graphicsUpdated)])
		[(id)[[self window]windowController] graphicsUpdated];
}

- (void)invalidateGraphics:(NSArray *)graphics
   {
	[graphics makeObjectsPerformSelector:@selector(invalidateInView)];
   }

- (void) refreshLayer:(int)l
   {
	[self clearSelection];
	[[self currentPage] setCurrentLayerInd:l];
	[self selectGraphics:[[self currentEditableLayer] graphics]];
	[self reCalcHandleBitsIgnoreSelected:NO];
   }

-(void)selectGraphicsInCurrentLayerFromSet:(NSSet*)gset
{
	[self clearSelection];
	NSMutableArray *arr = [NSMutableArray arrayWithCapacity:[gset count] + 1];
	ACSDLayer *l = [self currentEditableLayer];
	for (ACSDGraphic *g in gset)
		if ([g layer] == l)
			[arr addObject:g];
	if ([arr count] > 0)
	{
		[self selectGraphics:arr];
		[[self undoManager]setActionName:@"Select Graphics"];
	}
}

-(void)selectGraphicsInCurrentLayerFromIndexSeto:(NSIndexSet*)ixs
{
    [self clearSelection];
    ACSDLayer *l = [self currentEditableLayer];
    NSArray *graphics = [l graphics];
    NSArray *objs = [graphics objectsAtIndexes:ixs];
    if ([objs count] > 0)
    {
        [self selectGraphics:objs];
        [[self undoManager]setActionName:@"Select Graphics"];
    }
}

-(void)selectGraphicsInCurrentLayerFromIndexSet:(NSIndexSet*)ixs
{
    ACSDLayer *l = [self currentEditableLayer];
    NSArray *graphics = [l graphics];
    NSSet *alreadySelected = [self selectedGraphics];
    NSSet *objs = [NSSet setWithArray:[graphics objectsAtIndexes:ixs]];
	BOOL changed = NO;
	for (ACSDGraphic *g in graphics)
	{
		if ([objs containsObject:g] && ![alreadySelected containsObject:g])
			changed = [self selectGraphic:g] || changed;
		else if (![objs containsObject:g] && [alreadySelected containsObject:g])
			changed = [self deselectGraphic:g] || changed;
	}
	if (changed)
		[[self undoManager]setActionName:([objs count] == 0)?@"Deselect Graphics":@"Select Graphics"];
}

- (void)drawNonCachedRect:(NSRect)aRect
   {
   }

- (void)beginDocument
   {
	[super beginDocument];
    NSPrintInfo *printInfo = [[self document] printInfo];
//	NSDictionary *dict = [printInfo dictionary];
	NSSize pSize = [printInfo paperSize];
	NSRect pageBounds = [printInfo imageablePageBounds];
	pSize = pageBounds.size;
	[printInfo setLeftMargin:0];
	[printInfo setTopMargin:0];
	[printInfo setRightMargin:0];
	[printInfo setBottomMargin:0];
//	pSize.height -= ([printInfo topMargin] + [printInfo bottomMargin]);
//	pSize.width -= ([printInfo leftMargin] + [printInfo rightMargin]);
/*	[printInfo setLeftMargin:pageBounds.origin.x];
	[printInfo setTopMargin:pageBounds.origin.y];
	[printInfo setRightMargin:pageBounds.origin.x];
	[printInfo setBottomMargin:pageBounds.origin.y];
	if ([self bounds].size.height > pSize.height || [self bounds].size.width > pSize.width)
	   {
		float hRatio = [self bounds].size.height / pSize.height;
		float wRatio = [self bounds].size.width / pSize.width;
		float ratio = fmax(hRatio,wRatio);
		[dict setValue:[NSNumber numberWithFloat:1.0/ratio] forKey:NSPrintScalingFactor];
	   }*/
	[printInfo setHorizontallyCentered:YES];
	[printInfo setVerticallyCentered:YES];
   }

- (BOOL)printing
   {
	return [[[self window]windowController]printing];
   }

- (BOOL)isOpaque
{
	ACSDPage *page = [self currentPage];
	if ([[page backgroundColour]alphaComponent] < 1.0 && [[[page document]backgroundColour]alphaComponent] < 1.0)
		return NO;
	return YES;
}

-(void)drawBackgroundInRect:(NSRect)aRect page:(ACSDPage*)page
{
	NSColor *pageCol = [page backgroundColour];
    if ([pageCol alphaComponent] < 1.0)
	{
		[[[page document]backgroundColour]set];
		[NSBezierPath fillRect:aRect];
		for (ACSDPage *master in [page masters])
		{
			[[master backgroundColour]set];
			[NSBezierPath fillRect:aRect];
		}
	}
	if ([pageCol alphaComponent] > 0.0)
	{
		[pageCol set];
		[NSBezierPath fillRect:aRect];
	}
}

-(void)drawPage:(ACSDPage*)page rect:(NSRect)aRect drawingToScreen:(BOOL)drawingToScreen drawMarkers:(BOOL)drawMarkers drawingToPDF:(CGContextRef)drPDF
  substitutions:(NSMutableDictionary*)substitutions options:(NSDictionary*)options
{
    float overrideScale = [[options objectForKey:@"overrideScale"]floatValue];
    BOOL selectionOnly = [[options objectForKey:@"selectionOnly"]boolValue];
	drawingToPDF = drPDF;
	if ([page pageType] == PAGE_TYPE_NORMAL)
		[substitutions setObject:[NSNumber numberWithInteger:[page pageNo]]forKey:[NSNumber numberWithInt:TEXT_SUBSTITUTION_CURRENT_PAGE]];
    if (!selectionOnly)
    {
        [self drawBackgroundInRect:aRect page:page];
        if ([page masters])
        {
            int pno = [[substitutions objectForKey:[NSNumber numberWithInt:TEXT_SUBSTITUTION_CURRENT_PAGE]]intValue];
            for (ACSDPage *mp in [page masters])
            {
                if (([mp masterType] == MASTER_TYPE_ALL) || ([mp masterType] == MASTER_TYPE_ODD && (pno &1)) || ([mp masterType] == MASTER_TYPE_EVEN && !(pno &1)))
                    [self drawPage:mp rect:aRect drawingToScreen:drawingToScreen drawMarkers:drawMarkers drawingToPDF:drPDF substitutions:substitutions options:options];
            }
        }
    }
	NSMutableDictionary *goptions = [[[NSMutableDictionary alloc]initWithCapacity:5]autorelease];
	[goptions setObject:substitutions forKey:@"substitutions"];
	if (overrideScale != 0.0)
		[goptions setObject:[NSNumber numberWithFloat:overrideScale] forKey:@"scale"];
	else
		[goptions setObject:[NSNumber numberWithFloat:magnification] forKey:@"scale"];
	for (ACSDLayer *layer in [[page layers]reverseObjectEnumerator])
	{
		if ([layer visible] && !(!drawMarkers && [layer isGuideLayer]))
		{
			for (ACSDGraphic *curGraphic in [layer graphics])
			{
				NSRect displayBounds = [curGraphic displayBounds];
				if (NSIntersectsRect(aRect, displayBounds))
				{
					BOOL inRubberBandGraphics = rubberbandGraphics && [rubberbandGraphics containsObject:curGraphic];
					BOOL graphicIsSelected = [self graphicIsSelected:curGraphic];
					BOOL selected = (graphicIsSelected && !(rubberbandIsDeselecting && inRubberBandGraphics)) ||
					(!graphicIsSelected && (!rubberbandIsDeselecting && inRubberBandGraphics));
					if ((selected || !selectionOnly) && (!drawingToScreen || drawMarkers || ![curGraphic isKindOfClass:[ACSDText class]] ||
						[(ACSDText*)curGraphic htmlMustBeDoneAsImage]))
						[curGraphic draw:aRect inView:self selected:(drawMarkers && selected && showSelection) 
								 isGuide:([layer isGuideLayer] && !(layer == [self currentEditableLayer])) && drawMarkers 
							cacheDrawing:drawingToScreen options:goptions];
				}
			}
		}
	}
	if (drawMarkers)
	{
		if ([highLightLayer targetObject])
			[highLightLayer drawRect:aRect hotPoint:[self convertPoint:[[self window] mouseLocationOutsideOfEventStream] fromView:nil]];
		if (drawGrid)
		{
			[NSGraphicsContext saveGraphicsState];
			[NSBezierPath setDefaultLineWidth:0.0];
			[[NSColor cyanColor] set];
			float ltop=NSMaxY([self bounds]),lbottom=0.0,lleft=0.0,lright=NSMaxX([self bounds]);
			float sx = rotationPoint.x,sy = rotationPoint.y;
			[NSBezierPath strokeLineFromPoint:NSMakePoint(lleft,sy) toPoint:NSMakePoint(lright,sy)];
			[NSBezierPath strokeLineFromPoint:NSMakePoint(sx,lbottom) toPoint:NSMakePoint(sx,ltop)];
			[NSGraphicsContext restoreGraphicsState];
		}
	}
}

-(void)setDrawGrid:(BOOL)g
{
	drawGrid = g;
}

- (void)drawRect:(NSRect)aRect
{
	float sc;
	NSMutableDictionary *substitutions = [NSMutableDictionary dictionaryWithCapacity:5];
	BOOL drawingToScreen = [NSGraphicsContext currentContextDrawingToScreen];
	CGContextSetFillColorSpace((CGContextRef)[[NSGraphicsContext currentContext]graphicsPort],getRGBColorSpace());
	CGContextSetStrokeColorSpace((CGContextRef)[[NSGraphicsContext currentContext]graphicsPort],getRGBColorSpace());
	ACSDPage *page;
	if (drawingToScreen)
	{
		page = [self currentPage];
	}
	else
	{
		NSInteger pageNo = [[NSPrintOperation currentOperation]currentPage];
		if (pageNo == 0)
			page = [self currentPage];
		else
			page = [pages objectAtIndex:pageNo - 1];
		if ([self printing])
		{
			NSPrintInfo *printInfo = [[self document] printInfo];
			NSDictionary *dict = [printInfo dictionary];
			sc = [[dict valueForKey:NSPrintScalingFactor]floatValue];
			if (sc < 1.0)
			{
				NSRect pageBounds = [printInfo imageablePageBounds];
				[[NSAffineTransform transformWithTranslateXBy:pageBounds.origin.x yBy:pageBounds.origin.y]concat];
				[[NSAffineTransform transformWithScaleXBy:sc yBy:sc]concat];
				aRect = [self bounds];
			}
		}
	}
	//	[substitutions setObject:[NSNumber numberWithInt:[page pageNo]]forKey:[NSNumber numberWithInt:TEXT_SUBSTITUTION_CURRENT_PAGE]];
	[self drawPage:page rect:aRect drawingToScreen:drawingToScreen drawMarkers:drawingToScreen drawingToPDF:nil substitutions:substitutions options:nil];
    if (creatingGraphic)
	{
        NSRect displayBounds = [creatingGraphic displayBounds];
        if (NSIntersectsRect(aRect, displayBounds))
		{
			NSMutableDictionary *options = [NSMutableDictionary dictionaryWithCapacity:5];
			[options setObject:substitutions forKey:@"substitutions"];
			[options setObject:[NSNumber numberWithFloat:magnification] forKey:@"scale"];
            [creatingGraphic draw:aRect inView:self selected:YES isGuide:[[creatingGraphic layer] isGuideLayer] cacheDrawing:[self cacheOn] options:options];
		}
	}
	if (!drawingToScreen)
		return;
    if (!NSEqualRects(rubberbandRect, NSZeroRect))
	{
		[[NSColor cyanColor] set];
		[NSBezierPath setDefaultLineWidth:1.0 / magnification];
		NSFrameRect(rubberbandRect);
	}
	if ([[[self window]windowController] respondsToSelector:@selector(otherDrawing:)])
		[(id)[[self window]windowController] otherDrawing:aRect];
}

-(NSShadow*)handleShadow
   {
	if (magnification == 1.0)
		return handleShadow;
	else
	   {
		NSShadow *scaledShadow = [[[NSShadow alloc]init]autorelease];
		NSSize sz = [handleShadow shadowOffset];
		sz.width = sz.width * magnification;
		sz.height = sz.height * magnification;
		[scaledShadow setShadowOffset:sz];
		[scaledShadow setShadowBlurRadius:[handleShadow shadowBlurRadius] * magnification];
		[scaledShadow setShadowColor:[handleShadow shadowColor]];
		return scaledShadow;
	   }
   }

-(void)createConnectorWithEvent:(NSEvent *)theEvent
   {
    NSPoint curPoint = [self convertPoint:[theEvent locationInWindow] fromView:nil];
    ACSDGraphic *graphic = [self graphicUnderPoint:curPoint extending:NO];
	if (!graphic)
		return;
	KnobDescriptor kd = [graphic nearestKnobForPoint:curPoint];
	if (kd.knob == NoKnob)
		return;
	NSPoint knobPoint = [graphic pointForKnob:kd];
	[[NSNotificationCenter defaultCenter] postNotificationName:ACSDShowCoordinatesNotification object:self
													  userInfo:[NSDictionary dictionaryWithObject:[NSNumber numberWithBool:YES] forKey:@"vis"]];
	creatingGraphic = [[ACSDConnector alloc] initWithName:[ACSDConnector nextNameForDocument:[self document]]
						fill:nil stroke:[self defaultStroke] rect:NSZeroRect layer:[self currentEditableLayer]
												  graphic:graphic knobDescriptor:kd offset:diff_points(curPoint,knobPoint) distance:0.0];
	[self selectGraphic:creatingGraphic];
    if ([creatingGraphic createWithEvent:theEvent inView:self])
        [[[self currentEditableLayer] graphics] addObject:[[self document]registerObject:creatingGraphic]];
	[[[self undoManager] prepareWithInvocationTarget:self] deleteSelectedGraphics];
    [[self undoManager] setActionName:[NSString stringWithFormat:@"Create %@",[[ACSDConnector class] graphicTypeName]]];
    [[self window] invalidateCursorRectsForView:self];
	[self reCalcHandleBitsIgnoreSelected:NO];
    [creatingGraphic release];
	creatingGraphic = nil;
	
   }

- (BOOL)createAGraphic:(ACSDGraphic*)g withEvent:(NSEvent *)theEvent 
{
    NSPoint currPoint = [self convertPoint:[theEvent locationInWindow] fromView:nil];
	currPoint.y = [self adjustHSmartGuide:currPoint.y tool:1];
	currPoint.x = [self adjustVSmartGuide:currPoint.x tool:1];
	NSPoint anchorPoint = currPoint,lastPoint = anchorPoint;
	[g createInit:anchorPoint event:theEvent];
    [g setShadowType:[self defaultShadow]];
	[ACSDGraphic postShowCoordinates:YES];
	BOOL can = NO,periodicStarted=NO;
    while (1)
	{
		if ([g opCancelled])
		{
			[g setOpCancelled:NO];
			can = YES;
			break;
		}
        theEvent = [[self window] nextEventMatchingMask:(NSLeftMouseDraggedMask | NSLeftMouseUpMask | NSFlagsChangedMask | NSKeyDownMask | NSPeriodicMask)];
		if ([theEvent type] == NSKeyDown)
		{
			[self keyDown:theEvent];
			continue;
		}
        if ([theEvent type] == NSPeriodic)
		{
			[self scrollRectToVisible:RectFromPoint(currPoint,30.0,[self magnification])];
			currPoint = [self convertPoint:[[self window] mouseLocationOutsideOfEventStream] fromView:nil];
		}
		else if ([theEvent type] == NSFlagsChanged)
			currPoint = [self convertPoint:[[self window] mouseLocationOutsideOfEventStream] fromView:nil];
		else
			currPoint = [self convertPoint:[theEvent locationInWindow] fromView:nil];
		if ([g needsRestrictTo45] && ([theEvent modifierFlags] & NSShiftKeyMask))
			restrictTo45(anchorPoint,&currPoint);
		if (!NSEqualPoints(currPoint, lastPoint) || [theEvent type] == NSFlagsChanged)
		{
			currPoint.y = [self adjustHSmartGuide:currPoint.y tool:1];
			currPoint.x = [self adjustVSmartGuide:currPoint.x tool:1];
			[g invalidateGraphicSizeChanged:NO shapeChanged:NO redraw:NO notify:NO];
			[g createMid:anchorPoint currentPoint:&currPoint event:theEvent];
			[g invalidateGraphicSizeChanged:YES shapeChanged:YES redraw:YES notify:NO];
			[g postChangeOfBounds];
			[ACSDGraphic postChangeFromAnchorPoint:anchorPoint toPoint:currPoint];
			lastPoint = currPoint;
		}
		periodicStarted = [self scrollIfNecessaryPoint:currPoint periodicStarted:periodicStarted];
        if ([theEvent type] == NSLeftMouseUp)
            break;
	}
	if (periodicStarted)
		[NSEvent stopPeriodicEvents];
	if (![[g class]isEqual:[ACSDPath class]])
		[ACSDGraphic postShowCoordinates:NO];
	return [g createCleanUp:can];
}

- (void)createGraphic:(int)graphicType withEvent:(NSEvent *)theEvent 
   {
	if (graphicType == ACSD_CONNECTOR_TOOL)
	   {
		[self createConnectorWithEvent:theEvent];
		return;
	   }
	Class theClass;
	switch (graphicType)
	   {
		case ACSD_RECT_TOOL:
			theClass = [ACSDRect class];
			break;
		case ACSD_CIRCLE_TOOL:
			theClass = [ACSDCircle class];
			break;
		case ACSD_TEXT_TOOL:
			theClass = [ACSDText class];
			break;
		case ACSD_LINE_TOOL:
			theClass = [ACSDLine class];
			break;
		case ACSD_PEN_TOOL:
			theClass = [ACSDPath class];
			break;
		case ACSD_GRID_TOOL:
			theClass = [ACSDGrid class];
			break;
		case ACSD_POLYGON_TOOL:
			theClass = [ACSDPolygon class];
			break;
		case ACSD_FREEHAND_TOOL:
			theClass = [ACSDFreeHand class];
			break;
		default:
			theClass = nil;
	   }
	[[NSNotificationCenter defaultCenter] postNotificationName:ACSDShowCoordinatesNotification object:self
		userInfo:[NSDictionary dictionaryWithObject:[NSNumber numberWithBool:YES] forKey:@"vis"]];
	if (theClass == [ACSDPolygon class])
	   {
		NSPoint pt = [self convertPoint:[theEvent locationInWindow] fromView:nil];
		creatingGraphic = [[ACSDPolygon alloc] initWithName:[theClass nextNameForDocument:[self document]]
													fill:[self defaultFill] stroke:[self defaultStroke] rect:NSZeroRect layer:[self currentEditableLayer]
												 noSides:defaultPolygonSides pt0:pt pt1:pt];
	   }
	else
		creatingGraphic = [[theClass alloc] initWithName:[theClass nextNameForDocument:[self document]]
													fill:[self defaultFill] stroke:[self defaultStroke] rect:NSZeroRect layer:[self currentEditableLayer]];
	//[creatingGraphic setShadowType:[self defaultShadow]];
	if ([self createAGraphic:creatingGraphic withEvent:theEvent])
//    if ([creatingGraphic createWithEvent:theEvent inView:self])
	   {
        [creatingGraphic setShadowType:[self defaultShadow]];
        [[[self currentEditableLayer] graphics] addObject:[[self document]registerObject:creatingGraphic]];
		[self selectGraphic:creatingGraphic];
        if ([creatingGraphic isEditable])
            [self startEditingGraphic:creatingGraphic withEvent:nil ];
		if ([creatingGraphic isKindOfClass:[ACSDPath class]])
		   {
			creatingPath = creatingGraphic;
			[creatingPath setAddingPoints:YES];
		   }
		[[[self undoManager] prepareWithInvocationTarget:self] deleteSelectedGraphics];
		[[self undoManager] setActionName:[NSString stringWithFormat:@"Create %@",[theClass graphicTypeName]]];
	   }
	else
	   {
		[creatingGraphic invalidateInView];
		[creatingGraphic removeReferences];
	   }
    [[self window] invalidateCursorRectsForView:self];
	[self reCalcHandleBitsIgnoreSelected:NO];
    [creatingGraphic release];
	creatingGraphic = nil;
    [[NSNotificationCenter defaultCenter]postNotificationName:ACSDGraphicListChanged object:self];
   }

-(void)addGraphic:(ACSDGraphic*)g
   {
	[self clearSelection];
	[[[self currentEditableLayer] graphics] addObject:[[self document]registerObject:g]];
	[self selectGraphic:g];
	[[[self undoManager] prepareWithInvocationTarget:self] deleteSelectedGraphics];
   }

- (void)createDocImage:(ACSDrawDocument*)adoc name:(NSString*)name location:(NSPoint*)loc fileName:(NSString*)fileName
{
	NSSize iSize = [adoc documentSize];
	NSSize vSize = [self bounds].size;
	float ratio = 1.0;
	if (iSize.width > vSize.width || iSize.height > vSize.height)
	{
		float wRatio = 0.9 * vSize.width / iSize.width;
		float hRatio = 0.9 * vSize.height / iSize.height;
		ratio = (wRatio < hRatio)?wRatio:hRatio;
	}
	NSPoint location;
	if (loc)
		location = *loc;
	else
		location = NSMakePoint(floor((vSize.width - iSize.width*ratio)/2.0),floor((vSize.height - iSize.height*ratio)/2.0));
	NSRect r = NSMakeRect(location.x - floor(iSize.width/2.0),location.y-floor(iSize.height/2.0),iSize.width,iSize.height);
	ACSDDocImage *image = [[ACSDDocImage alloc]initWithName:name fill:nil stroke:nil rect:r layer:[self currentEditableLayer] drawDoc:adoc];
	image.sourcePath = fileName;
	[image setGraphicXScale:ratio yScale:ratio undo:NO];
	[self clearSelection];
	[self selectGraphic:image];
    [self addGraphicToCurrentLayer:(ACSDGraphic*)[[self document]registerObject:image]];
	//[[[self currentEditableLayer] graphics] addObject:[[self document]registerObject:image]];
	[[[self undoManager] prepareWithInvocationTarget:self] deleteSelectedGraphics];
	[[self undoManager] setActionName:@"Import document"];
	[[self window] invalidateCursorRectsForView:self];
	[image release];
}

-(void)addGraphicToCurrentLayer:(ACSDGraphic*)g
{
    [[[self currentEditableLayer] graphics] addObject:g];
    [[NSNotificationCenter defaultCenter]postNotificationName:ACSDGraphicListChanged object:self];
}
- (void)createImage:(NSImage*)im name:(NSString*)name location:(NSPoint*)loc fileName:(NSString*)fileName
{
	NSSize iSize = [im size];
	NSSize vSize = [self bounds].size;
	float ratio = 1.0;
	if (iSize.width > vSize.width || iSize.height > vSize.height)
	{
		float wRatio = 0.9 * vSize.width / iSize.width;
		float hRatio = 0.9 * vSize.height / iSize.height;
		ratio = (wRatio < hRatio)?wRatio:hRatio;
	}
	NSPoint location;
	if (loc)
		location = *loc;
	else
		location = NSMakePoint(floor((vSize.width - iSize.width*ratio)/2.0),floor((vSize.height - iSize.height*ratio)/2.0));
	NSRect r = NSMakeRect(location.x - floor(iSize.width/2.0),location.y-floor(iSize.height/2.0),iSize.width,iSize.height);
	ACSDImage *image = [[ACSDImage alloc]initWithName:name
											fill:nil stroke:nil rect:r layer:[self currentEditableLayer] image:im];
	image.sourcePath = fileName;
	[image setGraphicXScale:ratio yScale:ratio undo:NO];
    [self clearSelection];
	[self selectGraphic:image];
    //[[[self currentEditableLayer] graphics] addObject:[[self document]registerObject:image]];
    [self addGraphicToCurrentLayer:(ACSDGraphic*)[[self document]registerObject:image]];
	[[[self undoManager] prepareWithInvocationTarget:self] deleteSelectedGraphics];
    [[self undoManager] setActionName:@"Import Picture"];
    [[self window] invalidateCursorRectsForView:self];
	[image release];
}

- (NSRect)boundsForGraphics:(NSArray *)graphics
   {
    NSRect rect = NSZeroRect;
    for (ACSDGraphic *g in graphics)
		rect = NSUnionRect(rect,[g bounds]);
    return rect;
   }

- (BOOL)verticalHandleAt:(int)v
   {
	int vPos = v / 32;
	int vBitPos = v % 32;
	return ((verticalHandleBits[vPos] & (1 << (31 - vBitPos))) != 0);
   }

- (BOOL)horizontalHandleAt:(int)h
{
	int hPos = h / 32;
	int hBitPos = h % 32;
	return ((horizontalHandleBits[hPos] & (1 << (31 - hBitPos))) != 0);
}

-(int)snapH:(int)h
{
	int dX = snapHOffsets[h];
	return h + dX;
}

-(int)snapV:(int)v
{
	int dY = snapVOffsets[v];
	return v + dY;
}

-(void)awakeFromNib
{
	showSelection = YES;
/*	mainCALayer = [CATiledLayer layer];
	mainCALayer.frame = [self bounds];
	[self setLayer:mainCALayer];
	[self setWantsLayer:YES];
	[mainCALayer setDelegate:self];
	[mainCALayer setNeedsDisplay];*/
}

- (float)adjustHSmartGuide:(float)y tool:(int)selectedTool
{
	BOOL needToDraw = selectedTool && snap;
	BOOL needHandle = [self verticalHandleAt:(int)y];
	[markerView.horizontalSnapLineLayer setHidden:!(needToDraw & needHandle)];
	if (markerView.horizontalSnapLineLayer.hidden)
		return y;
	float adjustedY = [self snapV:(int)y];
	markerView.horizontalSnapLineLayer.position = CGPointMake(0, adjustedY);
	return adjustedY;
}

- (float)adjustVSmartGuide:(float)x tool:(int)selectedTool
{
	BOOL needToDraw = selectedTool && snap;
	BOOL needHandle = [self horizontalHandleAt:(int)x];
	[markerView.verticalSnapLineLayer setHidden:!(needToDraw & needHandle)];
	if (markerView.verticalSnapLineLayer.hidden)
		return x;
	float adjustedX = [self snapH:(int)x];
	markerView.verticalSnapLineLayer.position = CGPointMake(adjustedX,0);
	return adjustedX;
}

- (void)mouseMoved:(NSEvent *)theEvent
   {
	NSPoint coord = [self convertPoint:[theEvent locationInWindow] fromView:nil];
	NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithObject:[NSValue valueWithPoint:coord] forKey:@"xy"];
    int selectedTool = [[ToolWindowController sharedToolWindowController:nil] currentTool];
	coord.y = [self adjustHSmartGuide:coord.y tool:selectedTool];
	coord.x = [self adjustVSmartGuide:coord.x tool:selectedTool];
	if ((selectedTool == ACSD_PEN_TOOL) && creatingPath)
	   {
		NSPoint lastPt;
		BOOL hasLastPoint = [((ACSDPath*)creatingPath) lastPoint:&lastPt];
		[creatingPath invalidateInView];
		[creatingPath setActualAddingPoint:coord];
		if ([theEvent modifierFlags] & NSShiftKeyMask)
		   {
			if (hasLastPoint)
				restrictTo45(lastPt,&coord);
		   }
		[creatingPath setAddingPoint:coord];
		[((ACSDPath*)creatingPath) constructAddingPointPath];
		[creatingPath invalidateGraphicSizeChanged:YES shapeChanged:YES redraw:YES notify:NO];
		if (hasLastPoint)
		   {
			NSSize sz = NSMakeSize(coord.x - lastPt.x,coord.y - lastPt.y);
			[dict setObject:[NSValue valueWithSize:sz] forKey:@"dxdy"];
			   [dict setObject: [NSNumber numberWithFloat:angleForPoints(lastPt,coord)] forKey:@"theta"];
			[dict setObject:[NSNumber numberWithFloat:pointDistance(coord,lastPt)] forKey:@"dist"];
		   }
	   }
	else if (cursorMode == GV_MODE_DOING_LINK)
	   {
		if (NSPointInRect(coord,[self visibleRect]))
		   {
			ACSDGraphic *g = [self graphicUnderPoint:coord extending:NO];
			   if (g == nil)
				   g = [self masterGraphicUnderPoint:coord];
			if (g &&  ([g isKindOfClass:[ACSDText class]] || (![[[self document]linkGraphics] containsObject:g])))
				[highLightLayer highLightObject:g modifiers:[theEvent modifierFlags]];
			else
				[highLightLayer highLightObject:self modifiers:[theEvent modifierFlags]];
		   }
		else
			[highLightLayer highLightObject:nil modifiers:[theEvent modifierFlags]];
	   }
	[[NSNotificationCenter defaultCenter] postNotificationName:ACSDMouseDidMoveNotification object:self userInfo:dict];
   }

- (BOOL)trackGraphic:(ACSDGraphic*)g knob:(KnobDescriptor&)kd withEvent:(NSEvent *)theEvent selectedGraphics:(NSSet*)selectedGraphics
{
	BOOL success;
	if ([g trackInit:kd withEvent:theEvent inView:self ok:&success])
		return success;
    NSPoint point = [self convertPoint:[theEvent locationInWindow] fromView:nil];
	NSPoint origPoint = point,lastPoint=origPoint;
	[[NSNotificationCenter defaultCenter] postNotificationName:ACSDShowCoordinatesNotification object:self
													  userInfo:[NSDictionary dictionaryWithObject:[NSNumber numberWithBool:YES] forKey:@"vis"]];
	BOOL can = NO,periodicStarted=NO;
    while (1)
	{
		if ((can = g.opCancelled))
		{
			[g setOpCancelled:NO];
			break;
		}
        theEvent = [[self window] nextEventMatchingMask:(NSLeftMouseDraggedMask | NSLeftMouseUpMask | NSFlagsChangedMask | NSKeyDownMask | NSPeriodicMask)];
		if ([theEvent type] == NSKeyDown)
		{
			[self keyDown:theEvent];
			continue;
		}
        if ([theEvent type] == NSPeriodic)
		{
			[self scrollRectToVisible:RectFromPoint(point,30.0,[self magnification])];
			point = [self convertPoint:[[self window] mouseLocationOutsideOfEventStream] fromView:nil];
		}
		else
			if ([theEvent type] != NSFlagsChanged)
				point = [self convertPoint:[theEvent locationInWindow] fromView:nil];
		point.y = [self adjustHSmartGuide:point.y tool:1];
		point.x = [self adjustVSmartGuide:point.x tool:1];
		//if ([g needsRestrictTo45] && ([theEvent modifierFlags] & NSShiftKeyMask))
		//	restrictTo45(origPoint,&point);
		[g invalidateGraphicSizeChanged:NO shapeChanged:NO redraw:NO notify:NO];
		[g trackMid:kd withEvent:theEvent point:point lastPoint:lastPoint selectedGraphics:selectedGraphics];
		[g otherTrackKnobAdjustments];
		[g invalidateGraphicSizeChanged:YES shapeChanged:YES redraw:YES notify:NO];
		lastPoint = point;
		[g postChangeOfBounds];
		[ACSDGraphic postChangeFromAnchorPoint:origPoint toPoint:point];
		[g setOutlinePathValid:NO];
		[g otherTrackKnobNotifiesView:self];
		periodicStarted = [self scrollIfNecessaryPoint:point periodicStarted:periodicStarted];
		[NSApp updateWindows];
        if ([theEvent type] == NSLeftMouseUp)
            break;
	}
	if (periodicStarted)
		[NSEvent stopPeriodicEvents];
	[[NSNotificationCenter defaultCenter] postNotificationName:ACSDShowCoordinatesNotification object:self
													  userInfo:[NSDictionary dictionaryWithObject:[NSNumber numberWithBool:NO] forKey:@"vis"]];
    [[self undoManager] setActionName:@"Resize"];
	return !can;
}

- (void)trackKnob:(KnobDescriptor&)kd ofGraphic:(ACSDGraphic *)graphic withEvent:(NSEvent *)theEvent
   {
	[graphic startBoundsManipulation];
	trackingGraphic = graphic;
	BOOL cancelled;
	if ([[ToolWindowController sharedToolWindowController:nil] currentTool] == ACSD_WHITE_ARROW_TOOL)
		cancelled = ![self trackGraphic:graphic knob:kd withEvent:theEvent selectedGraphics:[self selectedGraphics]];
	else
		cancelled = ![self trackGraphic:graphic knob:kd withEvent:theEvent selectedGraphics:nil];
	[graphic stopBoundsManipulation];
	trackingGraphic = nil;
	if (cancelled)
		[[self undoManager]undo];
    [[self window] invalidateCursorRectsForView:self];
   }

- (BOOL)rubberbandSelectWithEvent:(NSEvent *)theEvent
   {
    BOOL changed = NO;
	NSPoint origPoint, curPoint;
    rubberbandIsDeselecting = (([theEvent modifierFlags] & NSCommandKeyMask) ? YES : NO);
    origPoint = curPoint = [self convertPoint:[theEvent locationInWindow] fromView:nil];
    rubberbandRect = NSZeroRect;
	rubberbandGraphics = nil;
    while (1)
	   {
        theEvent = [[self window] nextEventMatchingMask:(NSLeftMouseDraggedMask | NSLeftMouseUpMask)];
        curPoint = [self convertPoint:[theEvent locationInWindow] fromView:nil];
        if (NSEqualPoints(origPoint, curPoint))
		   {
            if (!NSEqualRects(rubberbandRect, NSZeroRect))
			   {
                [self setNeedsDisplayInRect:rubberbandRect];
				[self invalidateGraphics:[rubberbandGraphics allObjects]];
               }
            rubberbandRect = NSZeroRect;
			if (rubberbandGraphics)
			   {
				[rubberbandGraphics release];
				rubberbandGraphics = nil;
			   }
           }
		else
		   {
            NSRect newRubberbandRect = rectFromPoints(origPoint, curPoint);
            if (!NSEqualRects(rubberbandRect, newRubberbandRect))
			   {
                [self setNeedsDisplayInRect:rubberbandRect];
				[self invalidateGraphics:[rubberbandGraphics allObjects]];
                rubberbandRect = newRubberbandRect;
                [rubberbandGraphics release];
                rubberbandGraphics = [[self graphicsIntersectingRect:rubberbandRect]retain];
                [self setNeedsDisplayInRect:rubberbandRect];
				[self invalidateGraphics:[rubberbandGraphics allObjects]];
               }
           }
        if ([theEvent type] == NSLeftMouseUp)
            break;
       }
    // Now select or deselect the rubberbanded graphics.
    NSEnumerator *objEnum = [rubberbandGraphics objectEnumerator];
    ACSDGraphic *curGraphic;
    while ((curGraphic = [objEnum nextObject]) != nil) 
	   {
        if (rubberbandIsDeselecting)
            [self deselectGraphic:curGraphic] || changed;
		else
            [self selectGraphic:curGraphic] || changed;
       }
    if (!NSEqualRects(rubberbandRect, NSZeroRect))
        [self setNeedsDisplayInRect:rubberbandRect];   
	rubberbandRect = NSZeroRect;
	if (rubberbandGraphics)
       {
		[rubberbandGraphics release];
		rubberbandGraphics = nil;
	   }
    [[self window] invalidateCursorRectsForView:self];
	return changed;
   }

-(void)moveSelectedGraphicsBy:(NSPoint)pt
   {
    NSArray *selGraphics = [[self selectedGraphics] allObjects];
	for (ACSDGraphic *graphic in selGraphics)
	   {
		[graphic invalidateInView];
		[[self currentEditableLayer]invalidateTextFlowersBehindGraphics:selGraphics];
		[graphic uMoveBy:NSMakePoint(pt.x,pt.y)];
		[graphic invalidateInView];
	   }
   }

-(void)moveToOrigin:(id)sender
{
    BOOL changed = NO;
    for (ACSDGraphic *g in [self selectedGraphics])
    {
        NSRect r = [g transformedBounds];
        if (r.origin.x != 0.0 || r.origin.y != 0.0)
        {
            changed = YES;
            [g invalidateInView];
            [[self currentEditableLayer]invalidateTextFlowersBehindGraphics:[NSArray arrayWithObject:g]];
            [g uMoveBy:NSMakePoint(-r.origin.x,-r.origin.y)];
            [g invalidateInView];
            
        }
    }
    if (changed)
        [[self undoManager]setActionName:@"Move to Origin"];
}

-(void)resetScale:(id)sender
{
    BOOL changed = NO;
    for (ACSDGraphic *g in [self selectedGraphics])
    {
        float xs = [g xScale];
        float ys = [g yScale];
        if (xs != 1.0 || ys != 1.0)
        {
            changed = YES;
            [g setGraphicXScale:1.0 yScale:1.0 undo:YES];
            
        }
    }
    if (changed)
        [[self undoManager]setActionName:@"Reset Scale"];
}

-(void)setUpDragWithEvent:(NSEvent*)theEvent graphicUnderMouse:(ACSDGraphic*)graphic
   {
    NSPasteboard *pboard;
    pboard = [NSPasteboard pasteboardWithName:NSDragPboard];
    [pboard declareTypes:[NSArray arrayWithObjects:ACSDrawGraphicRefPasteboardType,ACSDrawGraphicPasteboardType,nil]  owner:self];
	ACSDrawDocument *doc = [self document];
	NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:[NSData dataWithBytes:&doc length:sizeof(void*)],@"doc",
		[NSData dataWithBytes:&self length:sizeof(void*)],@"view",nil];
	[pboard setData:[NSKeyedArchiver archivedDataWithRootObject:dict] forType:ACSDrawGraphicRefPasteboardType];
	[self copySelectedGraphicsToPasteBoard:pboard draggedGraphic:graphic altDown:NO];
	NSRect b = [graphic displayBounds];
	dragGraphic = graphic;
    dragOffset = point_offset([self convertPoint:[[self window] mouseLocationOutsideOfEventStream] fromView:nil], b.origin);
    [self dragImage:[graphic imageForDrag] at:b.origin offset:dragOffset 
			  event:theEvent pasteboard:pboard source:self slideBack:YES];	
   }

- (unsigned long)draggingSourceOperationMaskForLocal:(BOOL)isLocal
   {
	return NSDragOperationMove|NSDragOperationCopy;
   }

- (NSDragOperation)draggingEntered:(id <NSDraggingInfo>)sender
   {
	NSString *tp = [[sender draggingPasteboard]availableTypeFromArray:[NSArray arrayWithObjects:ACSDrawGraphicRefPasteboardType,nil]];
	if (tp && [sender draggingSource] != nil)
	   {
		NSPasteboard *pboard = [sender draggingPasteboard];
		NSData *data = [pboard dataForType:ACSDrawGraphicRefPasteboardType];
		if (data)
		   {
			NSDictionary *dict = [NSKeyedUnarchiver unarchiveObjectWithData:data];
			ACSDrawDocument *doc;
			NSData *d = [dict objectForKey:@"doc"];
			[d getBytes:&doc];
			if (doc == [self document])
				return NSDragOperationMove;
		   }
	   }
	return NSDragOperationCopy;
   }

- (void)moveSelectedGraphicsFromPage:(ACSDPage*)pFrom toPage:(ACSDPage*)pTo
   {
	if (pFrom == pTo)
		return;
	[[[self undoManager] prepareWithInvocationTarget:self] moveSelectedGraphicsFromPage:pTo toPage:pFrom];
	NSArray *gArray = [[[pFrom currentLayer]selectedGraphics] allObjects];
	[gArray makeObjectsPerformSelector:@selector(invalidateInView)];
	[[pFrom currentLayer]removeGraphics:gArray];
	[[pTo currentLayer]addGraphics:gArray];
	[[[pFrom currentLayer] selectedGraphics]removeAllObjects];
	[[[pTo currentLayer]selectedGraphics]addObjectsFromArray:gArray];
	[gArray makeObjectsPerformSelector:@selector(invalidateInView)];
   }

- (BOOL)dragACSDrawObject:(id <NSDraggingInfo>)sender
   {
	NSData *data;
	NSDictionary *dict;
	NSPoint loc = [sender draggedImageLocation];
	if ([sender draggingSource] != nil)	//is in same application
	   {
		NSPasteboard *pboard = [sender draggingPasteboard];
		data = [pboard dataForType:ACSDrawGraphicRefPasteboardType];
		if (data)
		   {
			dict = [NSKeyedUnarchiver unarchiveObjectWithData:data];
			ACSDrawDocument *doc;
			NSData *d = [dict objectForKey:@"doc"];
			[d getBytes:&doc];
			if (doc == [self document])
			   {
				GraphicView *v; 
				d = [dict objectForKey:@"view"];
				[d getBytes:&v];
				[[self undoManager] setActionName:@"Move"];
				if ([self currentPage] != [v currentPage])
				   {
					[self clearSelection];
					[self moveSelectedGraphicsFromPage:[v currentPage] toPage:[self currentPage]];
				   }
				[[self selectedGraphics] makeObjectsPerformSelector:@selector(stopMove:)withObject:[NSNumber numberWithBool:NO]];
				ACSDGraphic *g = [[sender draggingSource]dragGraphic];
//				loc = offset_point(loc,neg_size([g displayBoundsOffset]));
				[self moveSelectedGraphicsBy:diff_points(loc,[g displayBounds].origin)];
				return YES;
			   }
		   }
	   }
	[self pasteFromPasteBoard:[sender draggingPasteboard] location:&loc];
	return YES;
   }

- (void)moveUp:(id)sender
{
    float amt = 1.0;
    if ([[self selectedGraphics] count] == 1)
    {
        ACSDGraphic *g = [[self selectedGraphics]anyObject];
        float bot = [g bounds].origin.y;
        float botr = ceilf(bot);
        if (botr > bot)
            amt = botr - bot;
    }
    NSPoint pt = NSMakePoint(0,amt);
    [self moveSelectedGraphicsBy:pt];
    [self addRepeatableAction:@selector(moveSelectedGraphicsBy:) name:@"Move" argument:&pt];
    [[self undoManager] setActionName:@"Move Up"];
}

- (void)moveDown:(id)sender
{
    float amt = 1.0;
    if ([[self selectedGraphics] count] == 1)
    {
        ACSDGraphic *g = [[self selectedGraphics]anyObject];
        float bot = [g bounds].origin.y;
        float botr = floorf(bot);
        if (bot > botr)
            amt = bot - botr;
    }
    NSPoint pt = NSMakePoint(0,-amt);
    [self moveSelectedGraphicsBy:pt];
    [self addRepeatableAction:@selector(moveSelectedGraphicsBy:) name:@"Move" argument:&pt];
    [[self undoManager] setActionName:@"Move Down"];
}

- (void)moveLeft:(id)sender
{
    float amt = 1.0;
    if ([[self selectedGraphics] count] == 1)
    {
        ACSDGraphic *g = [[self selectedGraphics]anyObject];
        float left = [g bounds].origin.x;
        float leftr = floorf(left);
        if (left > leftr)
            amt = left - leftr;
    }
    NSPoint pt = NSMakePoint(-amt,0);
    [self moveSelectedGraphicsBy:pt];
    [self addRepeatableAction:@selector(moveSelectedGraphicsBy:) name:@"Move" argument:&pt];
    [[self undoManager] setActionName:@"Move Left"];
}

- (void)moveRight:(id)sender
{
    float amt = 1.0;
    if ([[self selectedGraphics] count] == 1)
    {
        ACSDGraphic *g = [[self selectedGraphics]anyObject];
        float left = [g bounds].origin.x;
        float leftr = ceilf(left);
        if (leftr > left)
            amt = leftr - left;
    }
    NSPoint pt = NSMakePoint(amt,0);
    [self moveSelectedGraphicsBy:pt];
    [self addRepeatableAction:@selector(moveSelectedGraphicsBy:) name:@"Move" argument:&pt];
    [[self undoManager] setActionName:@"Move Right"];
}

-(void)moveToEndOfLine:(id)sender
{
    NSLog(@"here");
}

-(void)moveWordRight:(id)sender
{
    int selectedTool = [[ToolWindowController sharedToolWindowController:nil] currentTool];
    if (selectedTool == ACSD_WHITE_ARROW_TOOL)
    {
        SelectionSet *gs = [self selectedGraphics];
        if ([gs count] == 1)
        {
            ACSDGraphic *g = [[gs objects] anyObject];
            if ([g isKindOfClass:[ACSDPath class]])
            {
                ACSDPath *path = (ACSDPath*)g;
                if ([[path selectedElements]count] == 1)
                {
                    [path selectNextElement];
                    
                }
            }
        }
    }
}

-(void)moveWordLeft:(id)sender
{
    int selectedTool = [[ToolWindowController sharedToolWindowController:nil] currentTool];
    if (selectedTool == ACSD_WHITE_ARROW_TOOL)
    {
        SelectionSet *gs = [self selectedGraphics];
        if ([gs count] == 1)
        {
            ACSDGraphic *g = [[gs objects] anyObject];
            if ([g isKindOfClass:[ACSDPath class]])
            {
                ACSDPath *path = (ACSDPath*)g;
                if ([[path selectedElements]count] == 1)
                {
                    [path selectPrevElement];
                    
                }
            }
        }
    }
}

-(ACSDGraphic*)dragGraphic
   {
	return dragGraphic;
   }

- (BOOL)performDragOperation:(id <NSDraggingInfo>)sender
{
	NSString *tp = [[sender draggingPasteboard]availableTypeFromArray:[NSArray arrayWithObjects:ACSDrawGraphicRefPasteboardType,ACSDrawGraphicPasteboardType,nil]];
	if (tp != nil)
		return [self dragACSDrawObject:sender];
	//  NSPoint loc = [sender draggedImageLocation];
	NSPoint loc = [self convertPoint:[sender draggingLocation]fromView:nil];
	[self pasteFromPasteBoard:[sender draggingPasteboard] location:&loc];
    return YES;
}

- (void)draggedImage:(NSImage *)anImage endedAt:(NSPoint)aPoint operation:(NSDragOperation)operation
   {
//	dragGraphic = nil;
   }

-(BOOL)scrollIfNecessaryPoint:(NSPoint)point periodicStarted:(BOOL)periodicStarted
   {
	NSRect vr = NSInsetRect([self visibleRect],20.0,20.0);
	if (NSPointInRect(point,vr))
	   {
		if (periodicStarted)
		   {
			[NSEvent stopPeriodicEvents];
			periodicStarted = NO;
		   }
	   }
	else
	   {
		[self scrollRectToVisible:RectFromPoint(point,25.0,[self magnification])];
		if (!periodicStarted)
		   {
			[NSEvent startPeriodicEventsAfterDelay:0.3 withPeriod:0.5];
			periodicStarted = YES;
		   }
	   }
	return periodicStarted;
   }

- (IBAction)toggleShowSelection:(id)sender
{
	showSelection = !showSelection;
	[markerView setNeedsDisplay:YES];
}

- (IBAction)toggleShowPathDirection:(id)sender
{
	//showPathDirection = !showPathDirection;
    [[ACSDPrefsController sharedACSDPrefsController:nil]toggleShowPathDirection:nil];
	for (ACSDPage *p in [[self document] pages])
		for (ACSDLayer *l in [p layers])
			for (ACSDGraphic *g in [l graphics])
			{
				if ([g isKindOfClass:[ACSDPath class]])
				{
					//[g setDisplayBoundsValid:NO];
					[g invalidateGraphicSizeChanged:YES shapeChanged:NO redraw:YES notify:NO];
				}
			}
	[markerView setNeedsDisplay:YES];
}

- (void)moveSelectedGraphicsWithEvent:(NSEvent *)theEvent graphicUnderMouse:(ACSDGraphic*)graphic
{
    NSPoint lastPoint, curPoint,origPoint;
	//	NSEvent *mouseDownEvent = theEvent;
    NSArray *selGraphics = [[self selectedGraphics] allObjects];
    NSInteger ct;
    BOOL didMove = NO, isMoving = NO, cancelled = NO, periodicStarted = NO;
	BOOL knobsHidden = NO;
    ct = [selGraphics count];
    lastPoint = [self convertPoint:[theEvent locationInWindow] fromView:nil];
	origPoint = curPoint = lastPoint;
	BOOL snapping = (ct == 1) && snap;
	[self reCalcHandleBitsIgnoreSelected:YES];
	float snapXOffset,snapYOffset;
	if (snapping)
	{
		ACSDGraphic *graphic = [selGraphics objectAtIndex:0];
		NSInteger handle = [graphic nearestHandleToPoint:origPoint maxDistance:[[ACSDPrefsController sharedACSDPrefsController:nil]hotSpotSize] xOffset:&snapXOffset yOffset:&snapYOffset];
		if (handle < -1)
			snapping = NO;
	}
	[[NSNotificationCenter defaultCenter] postNotificationName:ACSDShowCoordinatesNotification object:self
													  userInfo:[NSDictionary dictionaryWithObject:[NSNumber numberWithBool:YES] forKey:@"vis"]];
    while (1)
	{
        theEvent = [[self window] nextEventMatchingMask:(NSLeftMouseDraggedMask | NSLeftMouseUpMask | NSKeyDownMask | NSPeriodicMask)];
        if ([theEvent type] == NSLeftMouseUp)
            break;
        if ([theEvent type] == NSKeyDown)
		{
			if ([[theEvent charactersIgnoringModifiers]isEqualToString:@"s"])
				[self toggleShowSelection:self];
			else
			{
				cancelled = YES;
				didMove = NO;
				break;
			}
		}
        if ([theEvent type] == NSPeriodic)
		{
			[self scrollRectToVisible:RectFromPoint(curPoint,30.0,magnification)];
			curPoint = [self convertPoint:[[self window] mouseLocationOutsideOfEventStream] fromView:nil];
		}
		else
			curPoint = [self convertPoint:[theEvent locationInWindow] fromView:nil];
		if ([theEvent modifierFlags] & NSShiftKeyMask)
			restrictTo45(origPoint,&curPoint);
		else if (snapping)
		{
		    NSPoint hotPoint;
			hotPoint.x = curPoint.x + snapXOffset;
			hotPoint.y = curPoint.y + snapYOffset;
			float xo = snapHOffsets[(int)hotPoint.x];
			float yo = snapVOffsets[(int)hotPoint.y];
			[self adjustHSmartGuide:hotPoint.y tool:1];
			[self adjustVSmartGuide:hotPoint.x tool:1];
			curPoint.x += xo;
			curPoint.y += yo;
		}
        if (!isMoving && ((fabs(curPoint.x - lastPoint.x) >= 2.0) || (fabs(curPoint.y - lastPoint.y) >= 2.0)))
		{
			isMoving = YES;
            knobsHidden = YES;
			[selGraphics makeObjectsPerformSelector:@selector(startMove)];
		}
        if (isMoving)
		{
            if (!NSEqualPoints(lastPoint, curPoint))
			{
				NSPoint dpt = NSMakePoint(curPoint.x - origPoint.x, curPoint.y - origPoint.y);
				didMove = YES;
				[selGraphics makeObjectsPerformSelector:@selector(tempMoveBy:)withObject:[NSValue valueWithPoint:dpt]];
				[selGraphics makeObjectsPerformSelector:@selector(invalidateTextFlower)];
				[[self currentEditableLayer]invalidateTextFlowersBehindGraphics:selGraphics];
				if (ct == 1)
					[[selGraphics objectAtIndex:0]postChangeOfBounds];
				periodicStarted = [self scrollIfNecessaryPoint:curPoint periodicStarted:periodicStarted];
				NSSize sz = NSMakeSize(curPoint.x - origPoint.x,curPoint.y - origPoint.y);
				NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:[NSValue valueWithPoint:curPoint],@"xy",
									  [NSValue valueWithSize:sz],@"dxdy",
									  [NSNumber numberWithFloat:angleForPoints(origPoint,curPoint)],@"theta",
									  [NSNumber numberWithFloat:pointDistance(origPoint,curPoint)],@"dist",
									  nil];
				[[NSNotificationCenter defaultCenter] postNotificationName:ACSDMouseDidMoveNotification object:self userInfo:dict];
			}
            lastPoint = curPoint;
		}
		NSRect b = [graphic displayBounds];
		if (!NSIntersectsRect(b,[self bounds]))
		{
			[self setUpDragWithEvent:theEvent graphicUnderMouse:graphic];
			cancelled = YES;
			didMove = NO;
			break;
		}
		[NSApp updateWindows];
	}
	if (periodicStarted)
		[NSEvent stopPeriodicEvents];
    if (isMoving)
	{
        knobsHidden = NO;
        //if ([[self undoManager]groupingLevel] == 0)
          //  [[self undoManager]beginUndoGrouping];
        [selGraphics makeObjectsPerformSelector:@selector(stopMove:)withObject:[NSNumber numberWithBool:!cancelled]];
		[[self currentEditableLayer]invalidateTextFlowersBehindGraphics:selGraphics];
        if (didMove)
		{
			NSPoint pt = NSMakePoint(curPoint.x - origPoint.x, curPoint.y - origPoint.y);
			[self addRepeatableAction:@selector(moveSelectedGraphicsBy:) name:@"Move" argument:&pt];
            [[self undoManager] setActionName:@"Move"];
			if (self.recordNextMove)
				[animationsController graphicsDidMove:selGraphics];
		}
	}
	self.recordNextMove = NO;
	[[NSNotificationCenter defaultCenter] postNotificationName:ACSDShowCoordinatesNotification object:self
													  userInfo:[NSDictionary dictionaryWithObject:[NSNumber numberWithBool:NO] forKey:@"vis"]];
    [[self window] invalidateCursorRectsForView:self];
}

- (void)splitAndTrackMouseWithEvent:(NSEvent *)theEvent
{
    NSPoint curPoint = [self convertPoint:[theEvent locationInWindow] fromView:nil];
	curPoint.y = [self adjustHSmartGuide:curPoint.y tool:1];
	curPoint.x = [self adjustVSmartGuide:curPoint.x tool:1];
    ACSDGraphic *graphic = [self selectedGraphicUnderPoint:curPoint];
    if (graphic && [graphic respondsToSelector:@selector(trackSplitKnob:withEvent:copy:inView:)])
	{
		KnobDescriptor kd = [graphic knobUnderPoint:curPoint view:self];
		if (kd.knob == NoKnob)
		{
			if (([theEvent modifierFlags] & NSCommandKeyMask)!=0)
				[((ACSDPath*)graphic) removePathElementWithEvent:theEvent inView:self];
			else if ([((ACSDPath*)graphic) splitPathWithEvent:theEvent copy:(([theEvent modifierFlags] & NSAlternateKeyMask)!=0) inView:self])
				[[self undoManager] setActionName:@"Add Point"];
		}
		else
		{
			[graphic startBoundsManipulation];
			ACSDPath *path = (ACSDPath*)graphic;
			ACSDSubPath *copysp = [[[[path subPaths] objectAtIndex:kd.subPath]copy]autorelease];
			[[[self undoManager] prepareWithInvocationTarget:path] uReplaceSubPathsInRange:NSMakeRange(kd.subPath,1)withSubPaths:[NSArray arrayWithObject:copysp]];
			[((ACSDPath*)graphic) trackSplitKnob:kd withEvent:theEvent copy:(([theEvent modifierFlags] & NSAlternateKeyMask)!=0) inView:self];
			[graphic stopBoundsManipulation];
			[[self window] invalidateCursorRectsForView:self];
			[[self undoManager] setActionName:@"Split Point"];
			return;
		}
	}
	else 
		while (1)
		{
			theEvent = [[self window] nextEventMatchingMask:(NSLeftMouseDraggedMask | NSLeftMouseUpMask)];
			if ([theEvent type] == NSLeftMouseUp)
				break;
		}
}

 - (void)goToGraphic:(ACSDGraphic*)g
   {
	[self clearSelection];
	ACSDLayer *layer = [g layer];
	ACSDPage *page = [layer page];
	if (page != [self currentPage])
	   {
		NSUInteger pageInd = [pages indexOfObjectIdenticalTo:page];
		[self setCurrentPageIndex:pageInd force:NO withUndo:YES];
		[[NSNotificationCenter defaultCenter] postNotificationName:ACSDPageChanged object:self userInfo:nil];
		[self setNeedsDisplay:YES];
	   }
	[self selectGraphic:g];
	[highLightLayer highLightObject:g times:5 interval:0.25];
   }

- (IBAction)showLink: (id)sender
{
    ACSDGraphic *g = [[[self selectedGraphics]allObjects]objectAtIndex:0];
    ACSDLink *l = [g link];
    if ([l respondsToSelector:@selector(toObject)])
    {
        [l checkToObj];
        id toObj = [l toObject];
        if (!toObj)
            return;
        ACSDPage *page = nil;
        if ([toObj isKindOfClass:[ACSDPage class]])
            page = toObj;
        else if ([toObj respondsToSelector:@selector(layer)])
                page = [[(ACSDGraphic*)toObj layer] page];
        else
            return;
        if (page != [self currentPage])
        {
            NSUInteger pageInd = [pages indexOfObjectIdenticalTo:page];
            [self setCurrentPageIndex:pageInd force:NO withUndo:YES];
            [[NSNotificationCenter defaultCenter] postNotificationName:ACSDPageChanged object:self userInfo:nil];
            [self setNeedsDisplay:YES];
        }
        if ([l anchorID] < 0)
            [highLightLayer highLightObject:toObj times:5 interval:0.25];
        else
            [highLightLayer highLightObject:l times:5 interval:0.25];
    }
}

-(id)linkForTextSelection
   {
	if (!editingGraphic)
		return nil;
	NSArray *arr = [editor selectedRanges];
	if ([arr count] == 0)
		return nil;
	NSRange r = [[arr objectAtIndex:0]rangeValue];
	id l = [(ACSDText*)editingGraphic linkForRange:r];
	if ([l isKindOfClass:[ACSDLink class]])
		return l;
	return nil;
   }

- (IBAction)showTextLink: (id)sender
   {
	ACSDLink *l = [self linkForTextSelection];
	if (!l)
		return;
	[l checkToObj];
	id toObj = [l toObject];
	if (!toObj)
		return;
    ACSDPage *page = nil;
    if ([toObj isKindOfClass:[ACSDPage class]])
        page = toObj;
    else
        page = [[(ACSDGraphic*)toObj layer] page];
	if (page != [self currentPage])
	   {
		NSUInteger pageInd = [pages indexOfObjectIdenticalTo:page];
		[self setCurrentPageIndex:pageInd force:NO withUndo:YES];
		[[NSNotificationCenter defaultCenter] postNotificationName:ACSDPageChanged object:self userInfo:nil];
		[self setNeedsDisplay:YES];
	   }
	if ([l anchorID] < 0)
		[highLightLayer highLightObject:toObj times:5 interval:0.25];
	else
		[highLightLayer highLightObject:l times:5 interval:0.25];
   }

- (void)pathSelectAndTrackMouseWithEvent:(NSEvent *)theEvent
   {
	NSPoint curPoint = [self convertPoint:[theEvent locationInWindow] fromView:nil];;
    BOOL extending = (([theEvent modifierFlags] & NSShiftKeyMask) ? YES : NO);
    ACSDGraphic *graphic = [self graphicUnderPoint:curPoint extending:extending];
	KnobDescriptor knobDescriptor = [graphic knobUnderPoint:curPoint view:self];
	if (knobDescriptor.knob != NoKnob)
	   {
		[self trackKnob:knobDescriptor ofGraphic:graphic withEvent:theEvent];
		return;
       }
    [[self window] invalidateCursorRectsForView:self];
   }

- (BOOL)rubberbandPathSelectWithEvent:(NSEvent *)theEvent
   {
	BOOL selectionChanged = [[[self selectedGraphics]allObjects]orMakeAllObjectsPerformSelector:@selector(uClearSelectedElements)];
	return selectionChanged;
   }

- (void)selectPathElementAndTrackMouseWithEvent:(NSEvent *)theEvent
   {
    BOOL selectionChanged=NO,isSelected=NO;
    BOOL extending = (([theEvent modifierFlags] & NSShiftKeyMask) ? YES : NO);
    BOOL altDown = (([theEvent modifierFlags] & NSAlternateKeyMask) ? YES : NO);
    NSPoint curPoint = [self convertPoint:[theEvent locationInWindow] fromView:nil];
    ACSDGraphic *graphic = [self graphicUnderPoint:curPoint extending:extending];
	if (!(graphic && [graphic isMemberOfClass:[ACSDPath class]]))
	   {
		[self rubberbandPathSelectWithEvent:theEvent];
		return;
	   }
	ACSDPath *path = (ACSDPath*)graphic;
	if ([self graphicIsSelected:path])
	   {
		KnobDescriptor knobDescriptor = [path knobOrLineUnderPoint:curPoint view:self];
		if (knobDescriptor.knob == NoKnob)
		   {
			[self rubberbandPathSelectWithEvent:theEvent];
			return;
		   }
		else
		   {
			BOOL knobIsSelected = [path knobIsSelected:knobDescriptor];
			if (extending)
			   {
				if (knobIsSelected)
					[path uDeselectElementFromKnob:knobDescriptor];
				else
				   {
					[path uSelectElementFromKnob:knobDescriptor extend:YES];
					isSelected = YES;
				   }
			   }
			else
			   {
				isSelected = YES;
				if (!knobIsSelected)
				   {
					selectionChanged = [[[self selectedGraphics]allObjects]orMakeAllObjectsPerformSelector:@selector(uClearSelectedElements)] || selectionChanged;
					[path uSelectElementFromKnob:knobDescriptor extend:YES];
				   }
				if (altDown && !knobDescriptor.isLine)
				   {
					[path uDeselectElementFromKnob:knobDescriptor];
					knobDescriptor = [(ACSDPath*)graphic uDuplicateKnob:knobDescriptor];
					[path uSelectElementFromKnob:knobDescriptor extend:extending];
				   }
			   }
		   }
		if (isSelected)
			[self trackKnob:knobDescriptor ofGraphic:graphic withEvent:theEvent];
	   }
   }

- (BOOL)layer1:(ACSDLayer*)l1 isInFrontOfLayer2:(ACSDLayer*)l2
   {
	if (l1 == l2)
		return NO;
    NSEnumerator *objEnum = [[[self currentPage]layers] objectEnumerator];
    ACSDLayer *l;
    while ((l = [objEnum nextObject]) != nil) 
		if (l == l1)
			return NO;
		else if (l == l2)
			return YES;
	return NO;
   }

- (BOOL)graphic1:(ACSDGraphic*)g1 isInFrontOfGraphic2:(ACSDGraphic*)g2
   {
	ACSDLayer *l1 = [g1 layer];
	ACSDLayer *l2 = [g2 layer];
	if (l1 != l2)
		return [self layer1:l1 isInFrontOfLayer2:l2];
    NSEnumerator *objEnum = [[[self currentEditableLayer] graphics] objectEnumerator];
    ACSDGraphic *g;
    while ((g = [objEnum nextObject]) != nil) 
		if (g == g1)
			return NO;
		else if (g == g2)
			return YES;
	return NO;
   }

-(ACSDGraphic*)frontmostGraphicOfG1:(ACSDGraphic*)g1 andG2:(ACSDGraphic*)g2
   {
	if (g1 == g2)
		return g1;
	if ([self graphic1:g1 isInFrontOfGraphic2:g2])
		return g1;
	return g2;
   }


- (void)autoFlowGraphic:(ACSDText*)textGraphic
   {
	if (currentPageInd == ((int)[pages count] - 1))
		[self addNewPageAtIndex:[pages count]];
	else
		[self setCurrentPageIndex:currentPageInd+1 force:YES withUndo:YES];
	ACSDText *newGraphic = [ACSDText dupAndFlowText:textGraphic];
	[newGraphic setName:[ACSDText nextNameForDocument:[self document]]];
	[newGraphic setLayer:[self currentEditableLayer]];
	[[[self currentEditableLayer] graphics] addObject:[[self document]registerObject:newGraphic]];
	[self selectGraphic:newGraphic];
	[self startEditingGraphic:newGraphic withEvent:nil ];
	[[[self undoManager] prepareWithInvocationTarget:self] deleteSelectedGraphics];
   }

-(void)selectGraphicWithName:(NSString*)nm
{
	if (nm == nil)
		return;
    BOOL selectionChanged=NO;
	[self clearSelection];
    NSRegularExpression *regexp = [NSRegularExpression regularExpressionWithPattern:nm options:NSRegularExpressionCaseInsensitive error:nil];
    if (regexp)
    {
        for (ACSDGraphic *g in [[self currentEditableLayer]graphics])
            //if ([[g name] isEqual:nm])
            if ([regexp numberOfMatchesInString:[g name] options:0 range:NSMakeRange(0, [[g name]length])] > 0)
                selectionChanged = [self selectGraphic:g]|| selectionChanged;
    }
    if (selectionChanged)
        [[self undoManager] setActionName:@"Change Selection"];
}

- (void)selectAndTrackMouseWithEvent:(NSEvent *)theEvent commandDown:(BOOL)commandDown
{
	NSPoint curPoint;
    ACSDGraphic *graphic = nil;
    BOOL isSelected,selectionChanged=NO;
    BOOL extending = (([theEvent modifierFlags] & NSShiftKeyMask) ? YES : NO);
	BOOL altDown = (([theEvent modifierFlags] & NSAlternateKeyMask) ? YES : NO);
    curPoint = [self convertPoint:[theEvent locationInWindow] fromView:nil];
	ACSDGraphic *selGraphic = [self selectedShapeUnderPoint:curPoint];
	ACSDGraphic *hitGraphic = [self graphicUnderPoint:curPoint extending:extending];
	if (selGraphic)
		graphic = selGraphic;
	else
		graphic = hitGraphic;
    isSelected = (graphic ? [self graphicIsSelected:graphic] : NO);
    if (!extending && !isSelected && !commandDown)
        selectionChanged = [self clearSelection] || selectionChanged;
    if (graphic)
	{
        // Add or remove this graphic from selection.
        if (extending)
		{
            if (isSelected)
			{
                selectionChanged = [self deselectGraphic:graphic] || selectionChanged;
                isSelected = NO;
			}
            else
			{
                selectionChanged = [self selectGraphic:graphic] || selectionChanged;
                isSelected = YES;
			}
		}
		else
		{
            if (isSelected)
			{
				KnobDescriptor knobDescriptor = [graphic knobUnderPoint:curPoint view:self];
				if (knobDescriptor.knob == nextTextKnob)
				{
					if ([(ACSDText*)graphic nextText])
						[self goToGraphic:[(ACSDText*)graphic nextText]];
					else if (altDown)
					{
						[self autoFlowGraphic:(ACSDText*)graphic];
					}
					else
					{
						[[self window] invalidateCursorRectsForView:self];
						cursorMode = GV_MODE_LINKING_TEXT_BLOCKS;
						linkingTextBlock = (ACSDText*)graphic;
					}
					return;
				}
				if (knobDescriptor.knob == previousTextKnob)
				{
					if ([(ACSDText*)graphic previousText])
						if (([theEvent modifierFlags] & NSCommandKeyMask))
							[self unlinkText:(ACSDText*)graphic];
						else
							[self goToGraphic:[(ACSDText*)graphic previousText]];
					return;
				}
                if (knobDescriptor.knob != NoKnob)
				{
                    [self trackKnob:knobDescriptor ofGraphic:graphic withEvent:theEvent];
                    return;
				}
			}
            selectionChanged = [self selectGraphic:graphic] || selectionChanged;
            isSelected = YES;
		}
		if (selectionChanged)
		{
			showSelection = YES;
			[[self undoManager] setActionName:@"Change Selection"];
		}
		if (altDown)
		{
			float arg = 0.0;
			NSDictionary *map = [self duplicateWithCascade:arg];
			[self emptyRepeatQueue];
			[self addRepeatableAction:@selector(duplicateWithCascade:) name:@"Duplicate" argument:&arg];
			graphic = [map objectForKey:[NSValue valueWithNonretainedObject:graphic]];
		}
	}
	else 
	{
        selectionChanged = [self rubberbandSelectWithEvent:theEvent] || selectionChanged;
		if (selectionChanged)
			[[self undoManager] setActionName:@"Change Selection"];
        return;
	}
    if (isSelected)
	{
        [[self undoManager] setActionName:@"Change Selection"];
        //if ([[self undoManager]groupingLevel] > 0)

          //  [[self undoManager]endUndoGrouping];
        //[[self undoManager]beginUndoGrouping];
        [self moveSelectedGraphicsWithEvent:theEvent graphicUnderMouse:graphic];
        return;
	}
    // If we got here then there must be nothing else to do.  Just track until mouseUp:.
    while (1)
	{
        theEvent = [[self window] nextEventMatchingMask:(NSLeftMouseDraggedMask | NSLeftMouseUpMask)];
        if ([theEvent type] == NSLeftMouseUp)
            break;
	}
    [[self window] invalidateCursorRectsForView:self];
}

- (void)adjustGradientWithPoint1:(NSPoint)pt1 point2:(NSPoint)pt2 
   {
	float dX = pt2.x - pt1.x;
	float dY = pt2.y - pt1.y;
	float hypotenuse = sqrt(dX * dX + dY * dY);
	float angle = DEGREES(asin(dY / hypotenuse));
	if (dX < 0)
		angle = 180.0 - angle;
	NSArray *selection = [self sortedSelectedGraphics];
	NSUInteger count = [selection count];
	if (count == 0)
	   {
		ACSDFill *currentFill = [[[PalletteViewController sharedPalletteViewController] fillController]currentFill];
		if (currentFill == nil)
			return;
		if (!([currentFill isKindOfClass:[ACSDGradient class]]))
			return;
		[(ACSDGradient*)currentFill setPreOffset:0.0 postOffset:0.0 angle:angle view:self];
		return;
	   }
   }

- (void)trackRotationWithEvent:(NSEvent *)theEvent 
   {
	NSPoint anglePoint = [self convertPoint:[theEvent locationInWindow] fromView:nil];
	float lastAngle = getAngleForPoints(rotationPoint,anglePoint);
	NSArray *selection = [[self selectedGraphics]allObjects];
	NSInteger ct = [selection count];
	if (([theEvent modifierFlags] & NSAlternateKeyMask)!=0)
	{
		drawGrid = YES;
		[self setNeedsDisplay:YES];
	}
	while (1)
	   {
		theEvent = [[self window] nextEventMatchingMask:(NSLeftMouseDraggedMask | NSLeftMouseUpMask | NSFlagsChangedMask)];
		if ([theEvent type] == NSFlagsChanged)
		{
			if ((([theEvent modifierFlags] & NSAlternateKeyMask)!=0)!= drawGrid)
			{
				drawGrid = !drawGrid;
				[self setNeedsDisplay:YES];
			}
		}
		else
		{
			anglePoint = [self convertPoint:[theEvent locationInWindow] fromView:nil];
			float angle = getAngleForPoints(rotationPoint,anglePoint);
			float incAngle = angle - lastAngle;
			if (incAngle != 0.0)
				for (int i = 0;i < ct;i++)
				   {
					ACSDGraphic *g = [selection objectAtIndex:i];
					[g invalidateInView];
					[g rotateByDegrees:incAngle aroundPoint:rotationPoint];
					[g invalidateInView];
					   [NSApp updateWindows];
				   }
			lastAngle = angle;
		}
		if ([theEvent type] == NSLeftMouseUp)
			break;
	   }
	if (drawGrid)
	{
		drawGrid = NO;
		[self setNeedsDisplay:YES];
	}
   }

- (void)trackGradientWithEvent:(NSEvent *)theEvent 
   {
	NSPoint anchorPoint = [self convertPoint:[theEvent locationInWindow] fromView:nil],dragPoint = anchorPoint;
	while (1)
	   {
		theEvent = [[self window] nextEventMatchingMask:(NSLeftMouseDraggedMask | NSLeftMouseUpMask)];
		dragPoint = [self convertPoint:[theEvent locationInWindow] fromView:nil];
		NSRect newRubberbandRect = rectFromPoints(anchorPoint, dragPoint);
		if (!NSEqualRects(rubberbandRect, newRubberbandRect))
		   {
			[self setNeedsDisplayInRect:rubberbandRect];
			rubberbandRect = newRubberbandRect;
			lineAnchorPoint = anchorPoint;
			lineDragPoint = dragPoint;
			rubberbandRect = NSInsetRect(rubberbandRect,-1,-1);
			[self setNeedsDisplayInRect:rubberbandRect];
		   }
		if ([theEvent type] == NSLeftMouseUp)
			break;
	   }	
	NSRect r = rubberbandRect;
	rubberbandRect = NSZeroRect;
	[self setNeedsDisplayInRect:r];
	if(r.size.width != 0.0 || r.size.height != 0.0)
		[self adjustGradientWithPoint1:anchorPoint point2:dragPoint];
   }

- (void)magnifyWithEvent:(NSEvent *)theEvent 
{
	NSRect frame = [self frame],b = [self bounds];
	NSSize scsz = [self scale];
	scsz = [markerView scale];
	NSPoint anchorPoint = [self convertPoint:[theEvent locationInWindow] fromView:nil],dragPoint = anchorPoint;
    if ([theEvent clickCount] > 1)
		magnification = 1.0;
	else
	{
		while (1)
		{
			theEvent = [[self window] nextEventMatchingMask:(NSLeftMouseDraggedMask | NSLeftMouseUpMask)];
			dragPoint = [self convertPoint:[theEvent locationInWindow] fromView:nil];
            NSRect newRubberbandRect = rectFromPoints(anchorPoint, dragPoint);
            if (!NSEqualRects(rubberbandRect, newRubberbandRect))
			{
                [self setNeedsDisplayInRect:rubberbandRect];
                rubberbandRect = newRubberbandRect;
                [self setNeedsDisplayInRect:rubberbandRect];
			}
			if ([theEvent type] == NSLeftMouseUp)
				break;
		}	
		NSRect dragRect = rectFromPoints(anchorPoint,dragPoint);
		if ((dragRect.size.width < 1.0) || (dragRect.size.height < 1.0))
		{
			if (([theEvent modifierFlags] & NSShiftKeyMask)!=0)
				magnification = magnification / 2.0;
			else
				magnification = magnification * 2.0;
		}
		else
		{
			float xRatio = b.size.width / dragRect.size.width;
			float yRatio = b.size.height / dragRect.size.height;
			magnification = MINN(xRatio,yRatio);
			anchorPoint.x = dragRect.origin.x + dragRect.size.width / 2.0;
			anchorPoint.y = dragRect.origin.y + dragRect.size.height / 2.0;
		}
	}
    NSClipView *cv = [[self enclosingScrollView]contentView];
	/*
	frame.size.width = b.size.width * magnification;
	frame.size.height = b.size.height * magnification;
	float xPosInFrame = anchorPoint.x / b.size.width * frame.size.width;  
	float yPosInFrame = anchorPoint.y / b.size.height * frame.size.height;
	NSRect clipBounds = [cv bounds];
	NSPoint mvPoint;
	mvPoint.x = xPosInFrame - clipBounds.size.width / 2.0;
	if (mvPoint.x < 0.0)
		mvPoint.x = 0.0;
	else if (mvPoint.x > (frame.size.width - clipBounds.size.width))
		mvPoint.x =(frame.size.width - clipBounds.size.width);
	mvPoint.y = yPosInFrame - clipBounds.size.height / 2.0;
	if (mvPoint.y < 0.0)
		mvPoint.y = 0.0;
	else if (mvPoint.y > (frame.size.height - clipBounds.size.height))
		mvPoint.y =(frame.size.height - clipBounds.size.height);
	[self setFrame:frame];
	[self setBounds:b];
    [markerView setFrame:[self bounds]];
	[cv scrollToPoint:mvPoint];*/
	[[self enclosingScrollView]setMagnification:magnification centeredAtPoint:anchorPoint];
    [[[self window]windowController] adjustWindowSize];
    [[self enclosingScrollView]reflectScrolledClipView:cv];

	[self setNeedsDisplayInRect:[self visibleRect]];
	scsz = [self scale];
	scsz = [markerView scale];
	markerView.layer.contentsScale = scsz.width;
	[markerView.layer setNeedsDisplay];
	rubberbandRect = NSZeroRect;
}

- (void)unlinkText:(ACSDText*)lText
   {
	if ([lText previousText] || [lText nextText])
	   {
//		[[[self undoManager] prepareWithInvocationTarget:self] linkText:lText toText:[lText previousText]];
		if (cursorMode == GV_MODE_LINKING_TEXT_BLOCKS)
			linkingTextBlock = [lText previousText];
		if ([lText uUnlinkText])
			[[self undoManager] setActionName:@"Unlink Text"];	
	   }
   }

- (void)linkText:(ACSDText*)lText toText:(ACSDText*)sText
   {
	if ([lText isKindOfClass:[ACSDText class]] && ![lText previousText] && ![lText nextText])
	   {
//		[[[self undoManager] prepareWithInvocationTarget:self] unlinkText:lText];
		if ([lText uLinkToText:sText])
		   {
			linkingTextBlock = lText;
			[self clearSelection];
			[self selectGraphic:lText];
			[[self undoManager] setActionName:@"Link Text"];	
			}
	   }	
   }

- (void)copyselectedGraphicsGivingNewSelection
   {
	NSArray *sortedSelectedGraphics = [self sortedSelectedGraphics];
	NSMutableArray *graphics = [[self currentEditableLayer] graphics];
	NSInteger nextPos = [graphics count];
	NSInteger count = [sortedSelectedGraphics count];
	for (int i = 0;i < count;i++)
		[graphics addObject:[[[sortedSelectedGraphics objectAtIndex:i]copy]autorelease]];
	count = [graphics count];
	[self clearSelection];
	for (NSInteger i = nextPos;i < count;i++)
	   {
		ACSDGraphic *graphic = [graphics objectAtIndex:i];
		[self selectGraphic:graphic];
	   }
	[[[self undoManager] prepareWithInvocationTarget:self] deleteSelectedGraphics];
   }

-(void)rotateselectedGraphicsWithDict:(NSDictionary*)dict
   {
	float rotation = [[dict objectForKey:@"rotation"]floatValue];
	if (rotation == 0.0)
		return;
	NSPoint rp = [[dict objectForKey:@"rotationPoint"]pointValue];
	[self addRepeatableAction:@selector(rotateselectedGraphicsWithDict:) name:@"Rotate" argument:&dict];
	NSArray *sortedSelectedGraphics = [self sortedSelectedGraphics];
	for (NSInteger i = 0,ct = [sortedSelectedGraphics count];i < ct;i++) 
		[[sortedSelectedGraphics objectAtIndex:i]rotateByDegrees:rotation aroundPoint:rp];
   }

- (IBAction)linkTo: (id)sender
   {
	[[self window] invalidateCursorRectsForView:self];
	[[self document] setLinkGraphics:[NSSet setWithSet:(NSSet*)[[self selectedGraphics]objects]]];
	[[self document] setLinkRanges:nil];
	cursorMode = GV_MODE_DOING_LINK;
   }

- (IBAction)linkTextTo: (id)sender
   {
	[self linkTo:sender];
	if (editingGraphic)
		[[self document] setLinkRanges:[editor selectedRanges]];
   }

-(void)uDeleteLink:(ACSDLink*)l oldLink:(ACSDLink*)oldL range:(NSValue*)textRange
   {
	[[[self undoManager] prepareWithInvocationTarget:self] uLinkFromObject:[l fromObject] range:textRange toObject:[l toObject] anchor:[l anchorID]];
	id fromObject = [l fromObject];
	id toObject = [l toObject];
	[l removeFromLinkedObjects];
	if (oldL)
    {
		if (textRange)
			[(ACSDText*)fromObject uSetLink:oldL forRange:[textRange rangeValue]];
		else
			[fromObject uSetLink:oldL];
        [toObject uAddLinkedObject:oldL];
    }
   }

-(ACSDLink*)uLinkFromObject:(id)fromObject range:(NSValue*)textRange toObject:(id)toObject anchor:(int)anchor
   {
	ACSDLink *l = [ACSDLink linkFrom:fromObject to:toObject anchorID:anchor];
	[[[self undoManager] prepareWithInvocationTarget:self] uDeleteLink:l oldLink:[fromObject link] range:textRange];
	if ([fromObject link])
		[[fromObject link]removeFromLinkedObjects];
	if (textRange)
		[(ACSDText*)fromObject uSetLink:l forRange:[textRange rangeValue]];
	else
		[fromObject uSetLink:l];
	[toObject uAddLinkedObject:l];
	return l;
   }

-(IBAction)removeLink:(id)sender
{
    for (ACSDGraphic *g in [self selectedGraphics])
    {
        if ([g link])
            [self uDeleteLink:g.link oldLink:nil range:nil];
    }
    [[self undoManager]setActionName:@"Remove Link"];
}

-(void)setLinkFromObjects:(NSSet*)fromObjects toObject:(id)toObject modifiers:(NSUInteger)modifiers
   {
	if (!(fromObjects && toObject))
		return;
	int anchorID = -1;
    NSEnumerator *fEnum = [fromObjects objectEnumerator];
	NSRange charRange = {0,0};
	if ([toObject isKindOfClass:[ACSDText class]] && ((modifiers & NSCommandKeyMask)==0))
	   {
		charRange = [toObject characterRangeUnderPoint:[self convertPoint:[[self window] mouseLocationOutsideOfEventStream] fromView:nil]];
		anchorID = [toObject assignAnchorForRange:charRange];
	   }
    ACSDGraphic *g;
	ACSDLink *l = nil;
    while ((g = [fEnum nextObject]) != nil)
	   {	
		NSArray *ranges = [[self document]linkRanges];
		if (ranges)
		   {
			for (unsigned i = 0;i < [ranges count];i++)
			   {
				NSRange r = [[ranges objectAtIndex:i]rangeValue];
				l = [ACSDLink uLinkFromObject:g range:r toObject:toObject anchor:anchorID substitutePageNo:NO changeAttributes:YES undoManager:[self  undoManager]];
			   }
		   }
		else
			l = [ACSDLink uLinkFromObject:g toObject:toObject anchor:anchorID substitutePageNo:NO changeAttributes:YES undoManager:[self undoManager]];
	   }
	if (anchorID < 0)
		[highLightLayer highLightObject:toObject times:5 interval:0.25];
	else
		[highLightLayer highLightObject:l times:5 interval:0.25];
    [[self undoManager] setActionName:@"Link"];
   }

-(IBAction)sizeToWidth:(id)sender
{
    float viewwidth = [self bounds].size.width;
    BOOL changed = NO;
    for (ACSDGraphic *g in [self selectedGraphics])
    {
        float w = [g bounds].size.width;
        float sc = viewwidth / w;
        changed = [g setGraphicXScale:sc notify:YES] || changed;
        changed = [g setGraphicYScale:sc notify:YES] || changed;
    }
    if (changed)
        [[self undoManager]setActionName:@"Scale to Width"];
}

- (IBAction)closePolygonSheet: (id)sender
   {
    int reply = (int)[sender tag];
	if (reply < 2)
	   {
		if (reply == 0)				//OK
			defaultPolygonSides = [polygonTextField intValue];
	   }
	[NSApp endSheet:_polygonSheet];
   }

- (void)polygonSheetDidEnd:(NSWindow *)sheet returnCode:(int)returnCode  contextInfo:(void  *)contextInfo
   {
	[_polygonSheet orderOut:self];
   }

- (void)showPolygonDialog
   {
	if (!_polygonSheet)
	{
		NSArray *topLevelObjects;
		[[NSBundle mainBundle] loadNibNamed:@"PolySides" owner:self topLevelObjects:&topLevelObjects];
	}
	[polygonTextField setIntValue:defaultPolygonSides];
    [NSApp beginSheet: _polygonSheet
	   modalForWindow: [self window]
		modalDelegate: self
	   didEndSelector: @selector(polygonSheetDidEnd:returnCode:contextInfo:)
		  contextInfo: nil];
   }

- (NSMenu *)menuForEvent:(NSEvent *)theEvent
   {
    NSPoint curPoint = [self convertPoint:[theEvent locationInWindow] fromView:nil];
	ACSDGraphic *selGraphic = [self selectedShapeUnderPoint:curPoint];
	if (!selGraphic)
		return nil;
	return [super menuForEvent:theEvent];
   }

-(void)processLinkToObj:(id)obj modifierFlags:(NSEventModifierFlags)modifierFlags
{
	[self setLinkFromObjects:[[self document]linkGraphics] toObject:obj modifiers:modifierFlags];
	[self cancelOperation:nil];
}

- (void)mouseDown:(NSEvent *)theEvent
   {
	if ((([theEvent modifierFlags] & NSAlternateKeyMask)!=0) && spaceDown)
	   {
		[self magnifyWithEvent:theEvent];
		return;
	   }
	NSPoint curPoint = [self convertPoint:[theEvent locationInWindow] fromView:nil];
    int selectedTool = [[ToolWindowController sharedToolWindowController:nil] currentTool];
	if (selectedTool || cursorMode)
		[self emptyRepeatQueue];
	if (cursorMode == GV_MODE_LINKING_TEXT_BLOCKS)
	   {
		ACSDGraphic *graphic = [self graphicUnderPoint:curPoint extending:NO];
		if (graphic && [graphic isKindOfClass:[ACSDText class]])
		{
			[self linkText:(ACSDText*)graphic toText:linkingTextBlock];
			[highLightLayer highLightObject:graphic times:3 interval:0.25];
		}
		return;
	   }
	else if (cursorMode == GV_MODE_DOING_LINK)
	   {
	    id obj = [highLightLayer targetObject];
		if (obj == self)
			obj = [self currentPage];
		   [self processLinkToObj:obj modifierFlags:[theEvent modifierFlags]];
		return;
	   }
	if (cursorMode == GV_ROTATION_AWAITING_CLICK)
	   {
		if (([theEvent modifierFlags] & NSCommandKeyMask)!=0)
		{
			[self selectAndTrackMouseWithEvent:theEvent commandDown:NO];
			return;
		}
		rotationPoint = curPoint;
		if (([theEvent modifierFlags] & NSAlternateKeyMask)==0)
			cursorMode = GV_ROTATION_AWAITING_ROTATE;
		else
		   {
			cursorMode = GV_ROTATION_SHOWING_DIALOG;
			[[[self window]windowController] showRotateDialog];
		   }
		[[self window] invalidateCursorRectsForView:self];
		return;
	   }
	if (cursorMode == GV_ROTATION_AWAITING_ROTATE)
	   {
		if (([theEvent modifierFlags] & NSCommandKeyMask)!=0)
		{
			[self selectAndTrackMouseWithEvent:theEvent commandDown:NO];
			cursorMode = GV_ROTATION_AWAITING_CLICK;
		}
		else
			[self trackRotationWithEvent:theEvent];
		return;
	   }
    if ([self editingGraphic])
        [self endEditing];
	if ((selectedTool == ACSD_POLYGON_TOOL) && (([theEvent modifierFlags] & NSAlternateKeyMask)!=0))
	   {
		[self showPolygonDialog];
		return;
	   }

	if ((selectedTool == ACSD_PEN_TOOL) && creatingPath)
	   {
		[(ACSDPath*)creatingPath trackAndAddPointWithEvent:theEvent inView:self];
		return;
	   }
	if (selectedTool == ACSD_WHITE_ARROW_TOOL)
	   {
		[self selectPathElementAndTrackMouseWithEvent:theEvent];
		return;
	   }
	if (selectedTool == ACSD_SPLIT_POINT_TOOL)
	   {
		[self splitAndTrackMouseWithEvent:theEvent];
		return;
	   }
    if ([theEvent clickCount] > 1) 
	   {
		[self emptyRepeatQueue];
        ACSDGraphic *graphic = [self graphicUnderPoint:curPoint extending:NO];
        if (graphic && [graphic isEditable])
		   {
            [self startEditingGraphic:graphic withEvent:theEvent];
            return;
           }
       }
    if (selectedTool)
	   {
		showSelection = YES;
        [self clearSelection];
        [self createGraphic:selectedTool withEvent:theEvent];
       }
	else
        [self selectAndTrackMouseWithEvent:theEvent commandDown:([theEvent modifierFlags] & NSCommandKeyMask)!=0];
   }

- (BOOL)acceptsFirstMouse:(NSEvent *)theEvent
   {
    return YES;
   }

- (void)snapButtonDidChange:(NSNotification *)notification
   {
	snap = ([[[ToolWindowController sharedToolWindowController:nil]snapButton]state] == NSOnState);
   }

- (void)selectedToolDidChange:(NSNotification *)notification
{
	if ([[ToolWindowController sharedToolWindowController:nil]previousTool] == ACSD_WHITE_ARROW_TOOL)
	{
		NSArray *selectedGraphics = [[self selectedGraphics]allObjects];
		for (ACSDGraphic *g in selectedGraphics)
		{
			if ([g isMemberOfClass:[ACSDPath class]])
			{
				ACSDPath *p = (ACSDPath*)g;
				if ([[p selectedElements] count] > 0)
				{
					[p clearSelectedElements];
					[p invalidateInView];
				}
			}
		}
	}
	if ([[ToolWindowController sharedToolWindowController:nil]currentTool] == ACSD_ROTATE_TOOL)
		if ([[self selectedGraphics] count] == 0)
			cursorMode = GV_ROTATION_AWAITING_SELECTION;
		else
			cursorMode = GV_ROTATION_AWAITING_CLICK;
		else
			cursorMode = GV_MODE_NONE;
    [[self window] invalidateCursorRectsForView:self];
	[self reCalcHandleBitsIgnoreSelected:NO];
	if (creatingPath)
	{
		[creatingPath setAddingPoints:NO];
		[creatingPath invalidateInView];
		[self setCreatingPath:nil];
	}
	[[NSNotificationCenter defaultCenter] postNotificationName:ACSDShowCoordinatesNotification object:self
													  userInfo:[NSDictionary dictionaryWithObject:[NSNumber numberWithBool:NO] forKey:@"vis"]];
}

- (void)setBitsH:(int)h offset:(int)o
   {
	int hPos = h / 32;
	int hBitPos = h % 32;
	horizontalHandleBits[hPos] |= (1 << (31 - hBitPos));
	snapHOffsets[h] = o;
   }

- (void)setBitsV:(int)v offset:(int)o
   {
	int vPos = v / 32;
	int vBitPos = v % 32;
	verticalHandleBits[vPos] |= (1 << (31 - vBitPos));
	snapVOffsets[v] = o;
   }

- (void)setHandleBitsH:(int)h v:(int)v
   {
	int temp;
	for (int i = -snapSize;i <= snapSize;i++)
		if ((temp = h + i) >= 0 && (temp < [self bounds].size.width)) 
			[self setBitsH:temp offset:-i];
	for (int i = -snapSize;i <= snapSize;i++)
		if ((temp = v + i) >= 0 && (temp < [self bounds].size.height)) 
			[self setBitsV:temp offset:-i];
   }

- (void)reCalcHandleBitsIgnoreSelected:(BOOL)ignoreSelected
{
	NSSize sz = [self bounds].size;
	int height = (int)sz.height;
	int width = (int)sz.width;
	for (int i = 0;i < height;i++)
		snapVOffsets[i] = 0;
	for (int i = 0;i < width;i++)
		snapHOffsets[i] = 0;
	int noVerticalBytes = (height + 31) / 32;
	int noHorizontalBytes = (width + 31) / 32;
	for (int i = 0;i < noVerticalBytes;i++)
		verticalHandleBits[i] = 0;
	for (int i = 0;i < noHorizontalBytes;i++)
		horizontalHandleBits[i] = 0;
	NSArray *graphics = [[self currentEditableLayer] graphics];
	NSInteger count = [graphics count];
	NSSet *selectedGraphics = nil;
	if (ignoreSelected)
		selectedGraphics = [self selectedGraphics];
	for (NSInteger i = 0;i < count;i++)
	{
		ACSDGraphic *graphic = [graphics objectAtIndex:i];
		if (!(ignoreSelected && [selectedGraphics containsObject:graphic]))
			[graphic setHandleBitsForview:self];
	}
	
	[self setHandleBitsH:width / 2 v:height / 2];

	if ([[self currentPage]guideLayer])
	{
		graphics = [[[self currentPage]guideLayer] graphics];
		count = [graphics count];
		for (int i = 0;i < count;i++)
		{
			ACSDGraphic *graphic = [graphics objectAtIndex:i];
			if (!(ignoreSelected && [selectedGraphics containsObject:graphic]))
				[graphic setHandleBitsForview:self];
		}
	}
}

- (void)resizeHandleBits
   {
	if (verticalHandleBits)
		delete[]verticalHandleBits;
	if (horizontalHandleBits)
		delete[]horizontalHandleBits;
	if (snapVOffsets)
		delete[]snapVOffsets;
	if (snapHOffsets)
		delete[]snapHOffsets;
	NSSize sz = [self bounds].size;
	int noVerticalBytes = ((int)sz.height + 31) / 32;
	int noHorizontalBytes = ((int)sz.width + 31) / 32;
	verticalHandleBits = new long[noVerticalBytes];
	horizontalHandleBits = new long[noHorizontalBytes];
	snapVOffsets = new char[(int)(sz.height)];
	snapHOffsets = new char[(int)(sz.width)];
	[self reCalcHandleBitsIgnoreSelected:NO];
   }

- (void)changePageTitle:(NSString*)t
{
	[[[self undoManager] prepareWithInvocationTarget:self] changePageTitle:[[self currentPage]pageTitle]];
	[[self currentPage]setPageTitle:t];
	[[[self document] windowControllers]makeObjectsPerformSelector:@selector(synchronizeWindowTitleWithDocumentName)];
	
	[[self undoManager] setActionName:@"Change Page Title"];
}

- (void)changeDocTitle:(NSString*)t
   {
	[[[self undoManager] prepareWithInvocationTarget:self] changeDocTitle:[[self document]docTitle]];
	[[self document]setDocTitle:t];
	[[self undoManager] setActionName:@"Change Title"];
   }

- (void)changeScriptURL:(NSString*)t
   {
	[[[self undoManager] prepareWithInvocationTarget:self] changeScriptURL:[[self document]scriptURL]];
	[[self document]setScriptURL:t];
	[[self undoManager] setActionName:@"Change Script URL"];
   }

- (void)changeAdditionalCSS:(NSString*)t
   {
	[[[self undoManager] prepareWithInvocationTarget:self] changeAdditionalCSS:[[self document]additionalCSS]];
	[[self document]setAdditionalCSS:t];
	[[self undoManager] setActionName:@"Change Additonal CSS"];
   }

/*- (void)changeDocumentSize:(NSSize)sz
{
	[[[self undoManager] prepareWithInvocationTarget:self] changeDocumentSize:[self bounds].size];
	[self setFrameSize:sz];
	[self setBoundsSize:sz];
	[[[self window]windowController] adjustWindowSize];
	[self resizeHandleBits];
	[[self document]setDocumentSize:sz];
	[self setNeedsDisplay:YES];
	[[NSNotificationCenter defaultCenter] postNotificationName:ACSDDocumentDidChangeNotification object:self];
}*/

- (void)changeDocumentSize:(NSSize)sz
{
	[[[self undoManager] prepareWithInvocationTarget:self] changeDocumentSize:[self bounds].size];
    magnification= 1.0;
    NSSize msz = sz;
    msz.width *= magnification;
    msz.height *= magnification;
	[self setFrameSize:msz];
	[self setBoundsSize:msz];
	[[[self window]windowController] adjustWindowSize];
	[self resizeHandleBits];
	[[self document]setDocumentSize:sz];
	[self setNeedsDisplay:YES];
	[[NSNotificationCenter defaultCenter] postNotificationName:ACSDDocumentDidChangeNotification object:self];
}

-(void)uSetStroke:(ACSDStroke*)st lineWidth:(float)lw
{
	[[[self undoManager] prepareWithInvocationTarget:self] uSetStroke:st lineWidth:[st lineWidth]];
	[st setLineWidth:lw];
}

-(void)uSetStroke:(ACSDStroke*)st dashes:(NSArray*)d
{
	[[[self undoManager] prepareWithInvocationTarget:self] uSetStroke:st dashes:[st dashes]];
	[st setDashes:d];
}

-(void)uSetStroke:(ACSDStroke*)st dashPhase:(float)dp
{
	[[[self undoManager] prepareWithInvocationTarget:self] uSetStroke:st dashPhase:[st dashPhase]];
	[st changeDashPhase:dp view:self];
}

-(NSSet*)selectedPathElements
{
    NSArray *arr = [[self selectedGraphics]allObjects];
    if ([arr count] != 1)
        return nil;
    ACSDGraphic *g = arr[0];
    if (![g isKindOfClass:[ACSDPath class]])
        return nil;
    ACSDPath *path = (id)g;
    NSSet *s = [path selectedElements];
    return s;
}

-(void)updateSelectedPointFromDictionary:(NSDictionary*)dict
{
    NSSet *els = [self selectedPathElements];
    if ([els count] != 1)
        return;
    ACSDPath *path = [[self selectedGraphics]allObjects][0];
    SelectedElement *se = [els anyObject];
    KnobDescriptor kd = [se knobDescriptor];
    ACSDSubPath *asp = [path subPaths][kd.subPath];
    ACSDPathElement *pe = [asp pathElements][kd.knob];
    ACSDPathElement *newpe = [pe copy];
    for (NSString *str in @[@"point",@"preControlPoint",@"postControlPoint",@"hasPreControlPoint",@"hasPostControlPoint"])
    {
        [newpe setValue:dict[str] forKey:str];
    }
    [path uReplacePathElementWithElement:newpe forKnob:kd];
    [[self undoManager]setActionName:@"Update Point"];
}

-(IBAction)editPoint:(id)sender
{
    NSSet *els = [self selectedPathElements];
    if ([els count] != 1)
        return;
    ACSDPath *path = [[self selectedGraphics]allObjects][0];
    SelectedElement *se = [els anyObject];
    KnobDescriptor kd = [se knobDescriptor];
    ACSDSubPath *asp = [path subPaths][kd.subPath];
    ACSDPathElement *pe = [asp pathElements][kd.knob];
    [(MainWindowController*)[[self window]windowController]showEditPointDialogForPathElement:pe];
}
- (void)scaleDocumentBy:(float)f
{
	NSSize currentsize = [self bounds].size;
	currentsize.width *= f;
	currentsize.height *=f;
	[self changeDocumentSize:currentsize];
    for (ACSDStroke *st in [[self document]strokes])
    {
        [self uSetStroke:st lineWidth:[st lineWidth]*f];
		if ([st dashes])
		{
			NSMutableArray *d = [NSMutableArray array];
			for (NSNumber *n in [st dashes])
				[d addObject:@([n floatValue]*f)];
			[self uSetStroke:st dashes:d];
		}
		if ([st dashPhase])
		{
			[self uSetStroke:st dashPhase:[st dashPhase]*f];
		}
    }
	for (ACSDPage *p in pages)
		[p permanentScale:f transform:[NSAffineTransform transformWithScaleBy:f]];
    [[self undoManager]setActionName:[NSString stringWithFormat:@"Scale Document by %g",f]];
}

-(void)moveAllObjectsBy:(NSPoint)vector
   {
	NSPoint antiVector = NSMakePoint(-vector.x,-vector.y);
	[[[self undoManager] prepareWithInvocationTarget:self] moveAllObjectsBy:antiVector];
	[pages makeObjectsPerformSelector:@selector(moveGraphicsByValue:) withObject:[NSValue valueWithPoint:vector]];
   }

- (void)changeDocumentSize:(NSSize)sz matrixRow:(int)row matrixColumn:(int)col
{
	float deltaX = sz.width - [self bounds].size.width,deltaY = sz.height - [self bounds].size.height;
	if(col == 1)
		deltaX /= 2.0;
	else if (col == 0)
		deltaX = 0.0;
	if(row == 1)
		deltaY /= 2.0;
	else if (row == 2)
		deltaY = 0.0;
	[self changeDocumentSize:sz];
	[[self undoManager] setActionName:@"Change Document Size"];
	if (deltaX != 0.0 || deltaY != 0.0)
		[self moveAllObjectsBy:NSMakePoint(deltaX,deltaY)];
}

- (void)changeDocumentWidth:(float)f
{
	[self changeDocumentSize:NSMakeSize(f,[self bounds].size.height)];
}

- (void)changeDocumentHeight:(float)f
{
	[self changeDocumentSize:NSMakeSize([self bounds].size.width,f)];
}

-(int)snapSize
   {
	return snapSize;
   }

- (NSColor*)guideColour
   {
	return guideColour;
   }

- (void)setGuideColour:(NSColor*)col
   {
    if (col == guideColour)
		return;
	if (guideColour)
		[guideColour release];
	guideColour = [col retain]; 
   }

- (void)setSelectionColour:(NSColor*)col
   {
    if (col == selectionColour)
		return;
	if (selectionColour)
		[selectionColour release];
	selectionColour = [col retain]; 
   }

- (void)boundsChanged:(NSNotification *)notification
   {
	[self resizeHandleBits];
   }

- (void)guideColourChanged:(NSNotification *)notification
{
	[self setGuideColour:[[notification userInfo]objectForKey:@"col"]];
}

- (void)selectionColourChanged:(NSNotification *)notification
{
    [self setSelectionColour:[[notification userInfo]objectForKey:@"col"]];
    [markerView setNeedsDisplay:YES];
    //[self setNeedsDisplay:YES];
}

- (void)snapSizeChanged:(NSNotification *)notification
{
	snapSize =[[[notification userInfo]objectForKey:@"n"]intValue];
	[self reCalcHandleBitsIgnoreSelected:NO];
}

- (void)hotSpotSizeChanged:(NSNotification *)notification
{
	hotSpotSize =[[[notification userInfo]objectForKey:@"n"]intValue];
}

- (void)resetCursorRects
{
	NSUInteger modifierFlags = [[[self window]currentEvent]modifierFlags];
	if ([[self document]linkGraphics])
		cursorMode = GV_MODE_DOING_LINK;
	if (cursorMode == GV_MODE_LINKING_TEXT_BLOCKS)
	{
		[self addCursorRect:[self visibleRect] cursor:[NSCursor chainCursor]];
		return;
	}
	if (cursorMode == GV_ROTATION_AWAITING_CLICK)
	{
		if ((modifierFlags & NSCommandKeyMask)!=0)
			[self addCursorRect:[self visibleRect] cursor:[NSCursor arrowCursor]];
		else
			[self addCursorRect:[self visibleRect] cursor:[NSCursor rotateCrossCursor]];
		return;
	}
	if (cursorMode == GV_ROTATION_AWAITING_ROTATE)
	{
		if ((modifierFlags & NSCommandKeyMask)!=0)
			[self addCursorRect:[self visibleRect] cursor:[NSCursor arrowCursor]];
		else
			[self addCursorRect:[self visibleRect] cursor:[NSCursor rotateCursor]];
		return;
	}
	if (cursorMode == GV_MODE_DOING_LINK)
	{
		[self addCursorRect:[self visibleRect] cursor:[NSCursor pointingHandCursor]];
		return;
	}
	if (((modifierFlags & NSAlternateKeyMask)!=0) && spaceDown)
	{
		if ((modifierFlags & NSShiftKeyMask)!=0)
			[self addCursorRect:[self visibleRect] cursor:[NSCursor magMinusCursor]];
		else
			[self addCursorRect:[self visibleRect] cursor:[NSCursor magPlusCursor]];
		return;
	}
    int selectedTool = [[ToolWindowController sharedToolWindowController:nil] currentTool];
    if (selectedTool == ACSD_WHITE_ARROW_TOOL)
	{
		if ((modifierFlags & NSAlternateKeyMask)==0)
			[self addCursorRect:[self visibleRect] cursor:[NSCursor whiteArrowCursor]];
		else
			[self addCursorRect:[self visibleRect] cursor:[NSCursor whiteArrowPlusCursor]];
		return;
	}
    if (selectedTool == ACSD_SPLIT_POINT_TOOL)
	{
		[self addCursorRect:[self visibleRect] cursor:[NSCursor splitCursor]];
		for (ACSDGraphic *graphic in [self selectedGraphics]) 
			[graphic addHandleRectsForView:self]; 
		return;
	}
    else if (selectedTool)
	{
		[self addCursorRect:[self visibleRect] cursor:[NSCursor crosshairCursor]];
		if (creatingPath)
			if ([[(ACSDPath*)creatingPath pathElements]count] > 1)
			{
			    NSRect r = [creatingPath handleRect:[[[(ACSDPath*)creatingPath pathElements]objectAtIndex:0]point] magnification:[self magnification]];
				[self addCursorRect:r cursor:[NSCursor closehairsCursor]];
			}
	}
	else
	{
		if ((modifierFlags & NSAlternateKeyMask)!=0)
			[self addCursorRect:[self visibleRect] cursor:[NSCursor arrowPlusCursor]];
		else
			[self addCursorRect:[self visibleRect] cursor:[NSCursor arrowCursor]];
		NSEnumerator *objEnum = [[self selectedGraphics] objectEnumerator];
		ACSDGraphic *curGraphic;
		while ((curGraphic = [objEnum nextObject]) != nil) 
			[curGraphic addHandleRectsForView:self]; 
	}
}

-(NSString*)repeatString
   {
	if ([repeatQueue count] == 0)
		return @"Repeat Action";
	NSMutableString *str = [NSMutableString stringWithCapacity:10];
	[str appendString:@"Repeat "];
	NSUInteger ct = [repeatQueue count];
	for (NSUInteger i = 0;i < ct && i < 5;i++)
	   {
		NSString *n = [((InvocationHolder*)[repeatQueue objectAtIndex:i])name];
		if (i > 0)
			[str appendString:@"+"];
		[str appendString:n];
	   }
	if (ct >= 5)
	   {
		NSString *s = [NSString stringWithFormat:@"%C",(unichar)0x2026];
		[str appendString:s];
	   }
	return str;
   }

-(void)addRepeatableAction:(SEL)selector name:(NSString*)n argument:(void*)arg
   {
	if (repeatingAction)
		return;
	NSMethodSignature *signature = [[self class]instanceMethodSignatureForSelector:selector];
	NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:signature];
	[invocation retainArguments];
	[invocation setSelector:selector];
	[invocation setArgument:arg atIndex:2];
	[repeatQueue addObject:[InvocationHolder holderForInvocation:invocation name:n]];
   }

-(void)emptyRepeatQueue
   {
	[repeatQueue removeAllObjects];
   }

- (void)repeatAction:(id)sender
   {
	repeatingAction = YES;
	for (unsigned i = 0;i < [repeatQueue count];i++)
	   {
		NSInvocation *inv = [[repeatQueue objectAtIndex:i]invocation];
		[inv setTarget:self];
		[inv invoke];
	   }
	repeatingAction = NO;
   }

- (NSLayoutManager*)layoutManager
   {
    if (!layoutManager)
	   {
        NSTextContainer *tc = [[NSTextContainer allocWithZone:NULL] initWithContainerSize:NSMakeSize(1.0e6, 1.0e6)];
        layoutManager = [[NSLayoutManager allocWithZone:NULL] init];
//        [tc setWidthTracksTextView:NO];
//        [tc setHeightTracksTextView:NO];
        [layoutManager addTextContainer:[tc autorelease]];
       }
    return layoutManager;
   }

-(void)repeatSelectedGraphicsRows:(NSInteger)rows cols:(NSInteger)cols xinc:(CGFloat)xinc yinc:(CGFloat)yinc rowOffset:(CGFloat)rowOffset
{
    if (rows <= 1 && cols <= 1)
        return;
    NSArray *sortedSelectedGraphics = [self sortedSelectedGraphics];
    int j = 1,i = 0;
    while (i < rows)
    {
        CGFloat thisRowOffset;
        if (i & 1)
            thisRowOffset = rowOffset;
        else
            thisRowOffset = 0;
        while (j < cols)
        {
            for (ACSDGraphic *g in sortedSelectedGraphics)
            {
                ACSDGraphic *newGraphic = [[g copy]autorelease];
                [newGraphic moveBy:NSMakePoint(j * xinc + thisRowOffset, i * yinc)];
                [newGraphic setName:[NSString stringWithFormat:@"%@ copy%d_%d",[g name],i,j]];
                [self addElement:newGraphic];
            }
            j++;
        }
        j = 0;
        i++;
    }
    [[self undoManager]setActionName:@"Repeat Copy"];
}

- (NSDictionary*)duplicateWithCascade:(float)cascadeAmount
{
	NSArray *sortedSelectedGraphics = [self sortedSelectedGraphics];
	NSMutableArray *graphics = [[self currentEditableLayer] graphics];
	NSInteger nextPos = [graphics count];
	NSInteger count = [sortedSelectedGraphics count];
	NSMutableDictionary *map = [NSMutableDictionary dictionaryWithCapacity:count];
	for (NSInteger i = 0;i < count;i++)
	{
		ACSDGraphic *oldGraphic = [sortedSelectedGraphics objectAtIndex:i];
		ACSDGraphic *newGraphic = [[oldGraphic copy]autorelease];
		[newGraphic setName:[NSString stringWithFormat:@"%@ copy",[oldGraphic name]]];
		[graphics addObject:[[self document]registerObject:newGraphic]];
		[map setObject:newGraphic forKey:[NSValue valueWithNonretainedObject:oldGraphic]];
	}
	count = [graphics count];
	for (NSValue *kv in [map allKeys])
	{
		ACSDGraphic *oldgraphic = [kv nonretainedObjectValue];
		if (oldgraphic.link)
		{
			ACSDGraphic *newgraphic = map[kv];
			id toobj = [oldgraphic.link toObject];
			NSValue *k = [NSValue valueWithNonretainedObject:toobj];
			id newtoobj = map[k];
			if (newtoobj == nil)
				newtoobj = toobj;
			ACSDLink *l = [ACSDLink linkFrom:newgraphic to:newtoobj];
			[newgraphic setLink:l];
			[newtoobj uAddLinkedObject:l];
		}
	}
	NSPoint delta = NSMakePoint(cascadeAmount,cascadeAmount);
	[self clearSelection];
	for (NSInteger i = nextPos;i < count;i++)
	{
		ACSDGraphic *graphic = [graphics objectAtIndex:i];
		[graphic mapCopiedObjectsFromDictionary:map];
		[graphic uMoveBy:delta];
		[self selectGraphic:graphic];
	}
	[[NSNotificationCenter defaultCenter]postNotificationName:ACSDGraphicListChanged object:self];
	[[[self undoManager] prepareWithInvocationTarget:self] deleteSelectedGraphics];
	[[self undoManager] setActionName:@"Duplicate"];
	return map;
}

- (void)duplicate:(id)sender
{
	float arg = PASTE_CASCADE_DELTA;
	[self duplicateWithCascade:arg];
	[self emptyRepeatQueue];
//	[self addRepeatableAction:@selector(duplicate:) name:@"Duplicate" argument:self];
	[self addRepeatableAction:@selector(duplicateWithCascade:) name:@"Duplicate" argument:&arg];
}

- (void)duplicateInPlace:(id)sender
{
	float arg = 0.0;
	[self duplicateWithCascade:arg];
	[self emptyRepeatQueue];
//	[self addRepeatableAction:@selector(duplicateInPlace:) name:@"Duplicate" argument:self];
	[self addRepeatableAction:@selector(duplicateWithCascade:) name:@"Duplicate" argument:&arg];
}

-(void)uUngroupGroupAtIndex:(NSInteger)gpind toGraphicsWithIndexSet:(NSIndexSet*)ixs
{
    NSMutableArray *layerGraphics = [[self currentEditableLayer] graphics];
	ACSDGroup *gp = layerGraphics[gpind];
	[gp invalidateInView];
	NSArray *graphics = [gp removeGraphics];
	[[self selectedGraphics] removeObject:gp];
	[gp preDelete];
	[layerGraphics removeObjectAtIndex:gpind];
	[gp deRegisterWithDocument:[self document]];
	int ind = 0;
	NSUInteger i = [ixs firstIndex];
	while (i != NSNotFound)
	{
        ACSDGraphic *g = graphics[ind];
		[layerGraphics insertObject:g atIndex:i];
		[self selectGraphic:g];
		i = [ixs indexGreaterThanIndex:i];
		ind++;
	}
    [[NSNotificationCenter defaultCenter]postNotificationName:ACSDGraphicListChanged object:self];
	[[[self undoManager] prepareWithInvocationTarget:self] uGroupGraphicsFromIndexSet:ixs intoGroup:gp atIndex:gpind];
}

-(void)uGroupGraphicsFromIndexSet:(NSIndexSet*)ixs intoGroup:(ACSDGroup*)gp atIndex:(NSInteger)ind
{
    [[[self currentEditableLayer] graphics] addObject:gp];
	[gp registerWithDocument:[self document]];
	NSMutableArray *arr = [NSMutableArray arrayWithCapacity:[ixs count]];
	NSUInteger i = [ixs firstIndex];
	while (i != NSNotFound)
	{
		[arr addObject:[[[self currentEditableLayer]graphics]objectAtIndex:i]];
		i = [ixs indexGreaterThanIndex:i];
	}
	i = [ixs lastIndex];
	while (i != NSNotFound)
	{
		[[self selectedGraphics] removeObject:[[[self currentEditableLayer]graphics]objectAtIndex:i]];
		[[[self currentEditableLayer] graphics]removeObjectAtIndex:i];
		i = [ixs indexLessThanIndex:i];
	}
	[gp setGraphics:arr];
	[[[self undoManager] prepareWithInvocationTarget:self] uUngroupGroupAtIndex:[[[self currentEditableLayer] graphics]indexOfObjectIdenticalTo:gp] toGraphicsWithIndexSet:ixs];
    [[self window] invalidateCursorRectsForView:self];
	[self reCalcHandleBitsIgnoreSelected:NO];
	[gp invalidateInView];
	[self selectGraphic:gp];
    [[NSNotificationCenter defaultCenter]postNotificationName:ACSDGraphicListChanged object:self];
}

- (void)group:(id)sender
   {
	NSIndexSet *ixs = [self indexesOfSelectedGraphics];
	ACSDGroup *group = [[ACSDGroup alloc]initWithName:[ACSDGroup nextNameForDocument:[self document]] graphics:[NSArray array]
		layer:[self currentEditableLayer]];
	[self uGroupGraphicsFromIndexSet:ixs intoGroup:group atIndex:[[[self currentEditableLayer] graphics]indexOfObjectIdenticalTo:group]];
	[group release];
	[[self undoManager] setActionName:@"Group"];
   }

- (void)ungroup:(id)sender
   {
	NSArray *lGraphics = [[self currentEditableLayer] graphics];
	NSIndexSet *ixs = [self indexesOfSelectedGraphics];
	NSUInteger i = [ixs lastIndex];
	while (i != NSNotFound)
	{
		ACSDGraphic *gr = [lGraphics objectAtIndex:i];
		if ([gr isMemberOfClass:[ACSDGroup class]])
		{
			ACSDGroup *gp = (ACSDGroup*)gr;
			[self uUngroupGroupAtIndex:i toGraphicsWithIndexSet:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(i,[[gp graphics]count])]];
		}
		i = [ixs indexLessThanIndex:i];
	}
	[[self undoManager] setActionName:@"Ungroup"];
   }

- (void)clear:(id)sender
   {
	BOOL changed = NO;
	if ([[ToolWindowController sharedToolWindowController:nil] currentTool] == ACSD_WHITE_ARROW_TOOL)
	   {
		for (ACSDGraphic *g in [[self selectedGraphics]allObjects])
		   {
			if ([g isMemberOfClass:[ACSDPath class]])
				changed =  [(ACSDPath*)g deleteSelectedElements] || changed;
		   }
	   }
	else
	   {
		changed = YES;
		[self deleteSelectedGraphics];
	   }
	if (changed)
		[[self undoManager] setActionName:@"Clear"];
   }

- (NSSet*)fillsUsedByElements:(NSArray*)elementArray
   {
	NSMutableSet *fillSet = [NSMutableSet setWithCapacity:10];
	for (unsigned i = 0;i < [elementArray count];i++)
	   {
		ACSDGraphic *g = [elementArray objectAtIndex:i];
		[fillSet unionSet:[g usedFills]];
	   }
	return fillSet;
   }

- (NSSet*)strokesUsedByElements:(NSArray*)elementArray
   {
	NSMutableSet *strokeSet = [NSMutableSet setWithCapacity:10];
	for (unsigned i = 0;i < [elementArray count];i++)
	   {
		ACSDGraphic *g = [elementArray objectAtIndex:i];
		[strokeSet unionSet:[g usedStrokes]];
	   }
	return strokeSet;
   }

- (NSSet*)shadowsUsedByElements:(NSArray*)elementArray
   {
	NSMutableSet *shadowSet = [NSMutableSet setWithCapacity:10];
	for (unsigned i = 0;i < [elementArray count];i++)
	   {
		ACSDGraphic *g = [elementArray objectAtIndex:i];
		[shadowSet unionSet:[g usedShadows]];
	   }
	return shadowSet;
   }

- (NSSet*)lineEndingsUsedByElements:(NSArray*)elementArray
   {
	NSMutableSet *lineEndingSet = [NSMutableSet setWithCapacity:10];
	for (unsigned i = 0;i < [elementArray count];i++)
	   {
		ACSDStroke *s = [elementArray objectAtIndex:i];
		if ([s lineStart])
			[lineEndingSet addObject:[s lineStart]];
		if ([s lineEnd])
			[lineEndingSet addObject:[s lineEnd]];
	   }
	return lineEndingSet;
   }

NSString *pbElementsKey = @"graphics";
NSString *pbStrokesKey = @"strokes";
NSString *pbFillsKey = @"fills";
NSString *pbShadowsKey = @"shadows";
NSString *pbLineEndingsKey = @"lineEndings";
NSString *pbLayerKey = @"layer";
NSString *positionKey = @"position";
NSString *dragGraphicKey = @"dragGraphic";

- (NSDictionary*)dictionaryFromLayer:(ACSDLayer*)layer position:(id)pos
{
	NSSet *strokeSet = [self strokesUsedByElements:[layer graphics]];
	return [NSDictionary dictionaryWithObjectsAndKeys:layer,pbLayerKey,
			strokeSet,pbStrokesKey,
			[self fillsUsedByElements:[layer graphics]],pbFillsKey,
			[self lineEndingsUsedByElements:[strokeSet allObjects]],pbLineEndingsKey,
			[self shadowsUsedByElements:[layer graphics]],pbShadowsKey,
			pos,positionKey,nil];
}

- (IBAction)setGraphicModeNormal:(id)sender
{
	for (ACSDGraphic *g in [[self selectedGraphics]allObjects])
		[g uSetGraphicMode:GRAPHIC_MODE_NORMAL];
	[[self undoManager] setActionName:[sender title]];
}

- (IBAction)setGraphicModeOutline:(id)sender
{
	for (ACSDGraphic *g in [[self selectedGraphics]allObjects])
		[g uSetGraphicMode:GRAPHIC_MODE_OUTLINE];
	[[self undoManager] setActionName:[sender title]];
}

-(void)copySelectedGraphicsToPasteBoard:(NSPasteboard*)pb draggedGraphic:(ACSDGraphic*)dg altDown:(BOOL)altDown
   {
	NSArray *graphics = [self sortedSelectedGraphics];
	NSSet *strokeSet = [self strokesUsedByElements:graphics];
	NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:graphics,pbElementsKey,
		strokeSet,pbStrokesKey,
		[self fillsUsedByElements:graphics],pbFillsKey,
		[self lineEndingsUsedByElements:[strokeSet allObjects]],pbLineEndingsKey,
		[self shadowsUsedByElements:graphics],pbShadowsKey,
		[ConditionalObject conditionalObject:dg],dragGraphicKey,
		nil];
	NSMutableData *mdat = [NSMutableData data];
	NSKeyedArchiver *archiver = [[[NSKeyedArchiver alloc] initForWritingWithMutableData:mdat]autorelease];
	[archiver setDelegate:[ArchiveDelegate archiveDelegateWithType:ARCHIVE_PASTEBOARD document:[self document]]];
	[archiver encodeObject:dict forKey:@"root"];
	[archiver encodeObject:[[self document]documentKey] forKey:@"docKey"];
	[archiver finishEncoding];
	[pb setData:mdat forType:ACSDrawGraphicPasteboardType];
	NSMutableString *ms = [NSMutableString stringWithCapacity:100];
	for (unsigned i = 0;i < [graphics count];i++)
		[ms appendString:[[graphics objectAtIndex:i]pathTextInvertY:altDown]];
	[pb setString:ms forType:NSStringPboardType];
   }

-(NSString*)liveCodeRelativeLocationStringForArray:(NSArray*)array
{
    if ([array count] > 1)
    {
        NSArray *last = [array lastObject];
        NSRect rect = [[last objectAtIndex:2]rectValue];
        NSArray *rest = [array subarrayWithRange:NSMakeRange(0, [array count] - 1)];
        return [self liveCodeLocationStringForArray:rest inRect:rect];
    }
    return @"";
}

-(NSString*)liveCodeLocationStringForArray:(NSArray*)array
{
    return [self liveCodeLocationStringForArray:array inRect:[self bounds]];
/*	NSMutableString *ms = [NSMutableString stringWithCapacity:200];
	[ms appendString:@"//\n//\n//    LiveCode Format\n//\n//\n"];
	float viewHeight = [self bounds].size.height;
	float viewWidth = [self bounds].size.width;
	for (NSArray *a in array)
	{
		NSString *gName = [a objectAtIndex:1];
		NSString *sourceName = [a objectAtIndex:0];
		NSRect rect = [[a objectAtIndex:2]rectValue];
		//		[ms appendString:[NSString stringWithFormat:@"    setImageSource \"%@\",\"%@\"\n",gName,sourceName]];
		float x = (rect.origin.x + (rect.size.width / 2));
		float y = viewHeight - (rect.origin.y + (rect.size.height / 2));
		[ms appendString:[NSString stringWithFormat:@"    //original location %g,%g;",x,y]];
		[ms appendString:[NSString stringWithFormat:@" original bounds %g,%g,%g,%g;",
						  rect.origin.x,rect.origin.y,rect.size.width,rect.size.height]];
		[ms appendString:[NSString stringWithFormat:@" ltrb %g,%g,%g,%g\n",
						  rect.origin.x/viewWidth,1-(rect.origin.y+rect.size.height)/viewHeight,(rect.origin.x+rect.size.width)/viewWidth,1-rect.origin.y/viewHeight]];
		x = x / viewWidth;
		y = y / viewHeight;
		[ms appendString:[NSString stringWithFormat:@"    loadImg \"%@\",\"%@\",(%g,%g)\n",gName,sourceName,x,y]];
		//		[ms appendString:[NSString stringWithFormat:@"    setImageLocation %g,%g\n",x,y]];
	}
	return ms;*/
}

-(NSString*)liveCodeLocationStringForArray:(NSArray*)array inRect:(NSRect)mainRect
{
	NSMutableString *ms = [NSMutableString stringWithCapacity:200];
	[ms appendString:@"//\n//\n//    LiveCode Format\n//\n//\n"];
	float rHeight = mainRect.size.height;
	float rWidth = mainRect.size.width;
	for (NSArray *a in array)
	{
		NSString *gName = [a objectAtIndex:1];
		NSString *sourceName = [a objectAtIndex:0];
		NSRect rect = [[a objectAtIndex:2]rectValue];
        rect.origin.x -= mainRect.origin.x;
        rect.origin.y -= mainRect.origin.y;
		float x = (rect.origin.x + (rect.size.width / 2));
		float y = rHeight - (rect.origin.y + (rect.size.height / 2));
		[ms appendString:[NSString stringWithFormat:@"    //original location %g,%g;",x,y]];
		[ms appendString:[NSString stringWithFormat:@" original bounds %g,%g,%g,%g;",
						  rect.origin.x,rect.origin.y,rect.size.width,rect.size.height]];
		[ms appendString:[NSString stringWithFormat:@" ltrb %g,%g,%g,%g\n",
						  rect.origin.x/rWidth,1-(rect.origin.y+rect.size.height)/rHeight,(rect.origin.x+rect.size.width)/rWidth,1-rect.origin.y/rHeight]];
		x = x / rWidth;
		y = y / rHeight;
		[ms appendString:[NSString stringWithFormat:@"    loadImg \"%@\",\"%@\",(%g,%g)\n",gName,sourceName,x,y]];
	}
	return ms;
}

-(NSString*)xCodeLocationStringForArray:(NSArray*)array
{
	NSMutableString *ms = [NSMutableString stringWithCapacity:200];
	[ms appendString:@"//\n//\n//    XCode Format\n//\n//\n"];
	float viewHeight = [self bounds].size.height;
	float viewWidth = [self bounds].size.width;
	for (NSArray *a in array)
	{
		NSString *gName = [[a objectAtIndex:1]stringByReplacingOccurrencesOfString:@" " withString:@"_"];
		unichar u = [gName characterAtIndex:0];
		if (isnumber(u))
			gName = [@"x" stringByAppendingString:gName];
		NSString *sourceName = [a objectAtIndex:0];
		NSRect rect = [[a objectAtIndex:2]rectValue];
		float x = (rect.origin.x + (rect.size.width / 2));
		rect.origin.y = viewHeight - NSMaxY(rect);
		float y = (rect.origin.y + (rect.size.height / 2));
		x = x / viewWidth;
		y = y / viewHeight;
		[ms appendString:[NSString stringWithFormat:@"//\n//\tBounds %g,%g,%g,%g\n//\n",
						  rect.origin.x / viewWidth,rect.origin.y / viewHeight,rect.size.width / viewWidth,rect.size.height / viewHeight]];
		[ms appendString:[NSString stringWithFormat:@"\tCALayer *%@ = [self createImageFromSource:@\"%@\" x:%g y:%g];\n",gName,sourceName,x,y]];
	}
	return ms;
}

-(NSArray*)locationArrayForGraphics:(NSArray*)graphics
{
	NSMutableDictionary *rootDict = [NSMutableDictionary dictionaryWithCapacity:10];
	NSMutableArray *nameArray = [NSMutableArray arrayWithCapacity:[graphics count]];
	NSMutableArray *resultArray = [NSMutableArray arrayWithCapacity:[graphics count]];
	for (ACSDGraphic *graphic in graphics)
	{
		NSString *gName = [graphic name];
		NSRange r = [gName rangeOfString:@" copy" options:NSAnchoredSearch|NSBackwardsSearch];
		while ([gName length] > 0 && r.length > 0)
		{
			gName = [gName substringWithRange:NSMakeRange(0, r.location)];
			r = [gName rangeOfString:@" copy" options:NSAnchoredSearch|NSBackwardsSearch];
		}
		id n = [rootDict objectForKey:gName];
		int ct;
		if (n == nil)
			ct = 0;
		else
			ct = [n intValue];
		ct ++;
		[rootDict setObject:[NSNumber numberWithInt:ct] forKey:gName];
		[nameArray addObject:[NSArray arrayWithObjects:[graphic name],gName,[NSValue valueWithRect:[graphic bounds]],nil]];
	}
	for (NSString *s in [rootDict allKeys])
		if ([[rootDict objectForKey:s]intValue] == 1)
			[rootDict removeObjectForKey:s];
		else
			[rootDict setObject:[NSNumber numberWithInt:0] forKey:s];
	for (NSArray *a in nameArray)
	{
		NSString *gName = [a objectAtIndex:1];
		NSString *sourceName = gName;
		id n = [rootDict objectForKey:gName];
		if (n)
		{
			int ct = [n intValue] + 1;
			[rootDict setObject:[NSNumber numberWithInt:ct] forKey:gName];
			gName = [NSString stringWithFormat:@"%@%d",gName,ct];
		}
		[resultArray addObject:[NSArray arrayWithObjects:sourceName,gName,[a objectAtIndex:2],nil]];
	}
	
	return resultArray;
}

-(IBAction)copyLocations:(id)sender
{
	if ([self currentEditableLayer] == nil || [[self selectedGraphics]count] == 0)
		return;
	NSPasteboard *pb = [NSPasteboard generalPasteboard];
    [pb declareTypes:[NSArray arrayWithObject:NSPasteboardTypeString] owner:nil];
	[pb clearContents];
	NSArray *arr = [self locationArrayForGraphics:[self selectedGraphicsSortedByTimestamp]];
	[pb writeObjects:[NSArray arrayWithObjects:
					  [self liveCodeLocationStringForArray:arr],
					  [self xCodeLocationStringForArray:arr],
					  nil]
	 ];
}

-(IBAction)copyARelB:(id)sender
{
	if ([self currentEditableLayer] == nil || [[self selectedGraphics]count] == 0)
		return;
	NSPasteboard *pb = [NSPasteboard generalPasteboard];
    [pb declareTypes:[NSArray arrayWithObject:NSPasteboardTypeString] owner:nil];
	[pb clearContents];
	NSArray *arr = [self locationArrayForGraphics:[self selectedGraphicsSortedByTimestamp]];
	[pb writeObjects:[NSArray arrayWithObjects:
					  [self liveCodeRelativeLocationStringForArray:arr],
					  nil]
	 ];
}

- (IBAction)copy:(id)sender
   {
	if (![self currentEditableLayer])
		return;
	if ([[self selectedGraphics]count] == 0)
		return;
    [[NSPasteboard generalPasteboard] declareTypes:[NSArray arrayWithObject:ACSDrawGraphicPasteboardType] owner:self];
	[self copySelectedGraphicsToPasteBoard:[NSPasteboard generalPasteboard]draggedGraphic:nil altDown:[sender isAlternate]];
   }

- (IBAction)selectAll:(id)sender
   {
	if ([self currentEditableLayer] && [[self currentEditableLayer]editable])
		if ([self selectGraphics:[[self currentEditableLayer] graphics]])
			[[self undoManager] setActionName:[sender title]];
   }

- (IBAction)selectNone:(id)sender
   {
	if ([self currentEditableLayer])
		[self clearSelection];
	[[self undoManager] setActionName:[sender title]];
   }

NSInteger findSame(id obj,NSArray *arr)
   {
	NSInteger ct = [arr count];
	for (NSInteger i = 0;i < ct;i++)
		if ([obj isSameAs:[arr objectAtIndex:i]])
			return i;
	return -1;
   }


-(void)reloadImages:(NSArray*)arr
{
    [self deselectGraphics:arr];
    for (ACSDGraphic *obj in arr)
	   {
           NSString *fileStr = [obj sourcePath];
           if (fileStr && [[NSFileManager defaultManager]fileExistsAtPath:fileStr])
           {
               ACSDGraphic *newobj = nil;
               NSString *extension = [[fileStr pathExtension]lowercaseString];
               NSRect r = [obj bounds];
               NSPoint pos = NSMakePoint(r.origin.x + r.size.width / 2,r.origin.y + r.size.height / 2);
               if ([extension isEqualTo:@"acsd"] || [extension isEqualTo:@"svg"])
               {
                   NSData *d = [NSData dataWithContentsOfFile:fileStr];
                   ACSDrawDocument *adoc = [[[ACSDrawDocument alloc]init]autorelease];
                   [adoc setFileURL:[NSURL fileURLWithPath:fileStr]];
                   [adoc readFromData:d ofType:extension error:nil];
                   r.size = [adoc documentSize];
                   r.origin.x = pos.x - r.size.width / 2;
                   r.origin.y = pos.y - r.size.height / 2;
                   newobj = [[ACSDDocImage alloc]initWithName:obj.name fill:obj.fill stroke:obj.stroke rect:r layer:[self currentEditableLayer] drawDoc:adoc];
               }
               else
               {
                   NSImage *im = nil;
                   if (!(im = ImageFromFile(fileStr)))
                       im = [[[NSImage alloc]initWithContentsOfFile:fileStr]autorelease];
                   if (im)
                   {
                       r.size = [im size];
                       r.origin.x = pos.x - r.size.width / 2;
                       r.origin.y = pos.y - r.size.height / 2;
                       newobj = [[ACSDImage alloc]initWithName:obj.name fill:obj.fill stroke:obj.stroke rect:r layer:[self currentEditableLayer] image:im];
                   }
               }
               if (newobj)
               {
                   newobj.attributes = [[obj.attributes mutableCopy]autorelease];
                   newobj.sourcePath = fileStr;
                   [newobj setXScale:[obj xScale]];
                   [newobj setYScale:[obj yScale]];
                   [newobj setAlpha:[obj alpha]];
                   [newobj setRotation:[obj rotation]];
                   [newobj setShadowType:[obj shadowType]];
                   newobj.hidden = obj.hidden;
                   newobj.linkAlignmentFlags = obj.linkAlignmentFlags;
                   NSInteger idx = [[[self currentEditableLayer] graphics]indexOfObjectIdenticalTo:obj];
                   if (obj.link && [obj.link isKindOfClass:[ACSDLink class]])
                   {
                       id toobj = [obj.link toObject];
                       [ACSDLink uLinkFromObject:newobj toObject:toobj anchor:[obj.link anchorID] substitutePageNo:[obj.link substitutePageNo] changeAttributes:[obj.link changeAttributes] undoManager:[self undoManager]];
                   }
                   for (ACSDLink *l in [[[obj linkedObjects] copy]autorelease])
                       [ACSDLink uLinkFromObject:[l toObject] toObject:newobj anchor:[l anchorID] substitutePageNo:[l substitutePageNo] changeAttributes:[l changeAttributes] undoManager:[self undoManager]];
                   [obj preDelete];
                   [[self document]registerObject:newobj];
                   [self replaceGraphicAtIndex:idx with:newobj];
                   [self selectGraphic:newobj];
               }
           }
       }
    [self setNeedsDisplay:YES];
}

-(IBAction)reloadImage:(id)sender
{
    NSArray *arr = [[self selectedGraphics]allObjects];
    if ([arr count] > 0)
    {
        [self reloadImages:arr];
        [[self undoManager]setActionName:@"Reload Images"];
    }
}

- (void)pasteFromPasteBoard:(NSPasteboard*)pBoard location:(NSPoint*)loc
{
	NSData *data = [pBoard dataForType:ACSDrawGraphicPasteboardType];
	if (!data)
	{
		NSImage *im;
		if ( [[pBoard types] containsObject:NSFilenamesPboardType] )
		{
			NSArray *files = [pBoard propertyListForType:NSFilenamesPboardType];
			for (unsigned i = 0;i < [files count];i++)
			{
				NSString *fileStr = [files objectAtIndex:i];
				NSString *extension = [[fileStr pathExtension]lowercaseString];
				if ([extension isEqualTo:@"acsd"] || [extension isEqualTo:@"svg"])
				{
					NSData *d = [NSData dataWithContentsOfFile:fileStr];
					ACSDrawDocument *adoc = [[[ACSDrawDocument alloc]init]autorelease];
					[adoc setFileURL:[NSURL fileURLWithPath:fileStr]];
					[adoc readFromData:d ofType:extension error:nil];
					[self createDocImage:adoc name:[[fileStr lastPathComponent]stringByDeletingPathExtension] location:loc fileName:fileStr];
				}
				else
				{
					if (!(im = ImageFromFile(fileStr)))
						im = [[[NSImage alloc]initWithContentsOfFile:fileStr]autorelease];
					if (im)
						[self createImage:im name:[[fileStr lastPathComponent]stringByDeletingPathExtension] location:loc fileName:fileStr];
				}
			}
			return;
		}
		if ((im = [[NSImage alloc]initWithPasteboard:pBoard]))
			[self createImage:[im autorelease] name:[ACSDImage nextNameForDocument:[self document]] location:loc fileName:nil];
		return;
	}
	NSDictionary *dict;
	NSKeyedUnarchiver *unarch = [[[NSKeyedUnarchiver alloc]initForReadingWithData:data]autorelease];
	[unarch setDelegate:[ArchiveDelegate archiveDelegateWithType:ARCHIVE_PASTEBOARD document:[self document]]];
	id docKey = [unarch decodeObjectForKey:@"docKey"];
	[(ArchiveDelegate*)[unarch delegate]setSameDocument:[docKey isEqual:[[self document]documentKey]]];
	id a = [unarch decodeObjectForKey:@"root"];
	if ([a isKindOfClass:[NSDictionary class]])
		dict = a;
	else
		return;
	if ([[(ArchiveDelegate*)[unarch delegate]newLineEndings]count] > 0)
	{
		[[[self document]lineEndings] addObjectsFromArray:[[(ArchiveDelegate*)[unarch delegate]newLineEndings]allObjects]];
		[[[PalletteViewController sharedPalletteViewController] strokeController]refreshLineEndings];
	}
	if ([[(ArchiveDelegate*)[unarch delegate]newStrokes]count] > 0)
	{
		[[[self document]strokes] addObjectsFromArray:[[(ArchiveDelegate*)[unarch delegate]newStrokes]allObjects]];
		[[[PalletteViewController sharedPalletteViewController] strokeController]refreshStrokes];
	}
	if ([[(ArchiveDelegate*)[unarch delegate]newFills]count] > 0)
	{
		[[[self document]fills] addObjectsFromArray:[[(ArchiveDelegate*)[unarch delegate]newFills]allObjects]];
		[[[PalletteViewController sharedPalletteViewController] fillController]addChange:FC_SOURCE_CHANGE];
	}
	if ([[(ArchiveDelegate*)[unarch delegate]newShadows]count] > 0)
	{
		[[[self document]shadows] addObjectsFromArray:[[(ArchiveDelegate*)[unarch delegate]newShadows]allObjects]];
		[[[PalletteViewController sharedPalletteViewController] shadowController]refreshShadows];
	}
	NSArray *pastedGraphics = [dict objectForKey:pbElementsKey];
	[self clearSelection];
	NSMutableSet *gSet = [NSMutableSet setWithCapacity:[pastedGraphics count]+5];
	for (unsigned i = 0;i < [pastedGraphics count];i++)
	{
		[gSet unionSet:[[pastedGraphics objectAtIndex:i]allTheObjects]];
	}
	NSArray *allGraphics = [gSet allObjects];
	[allGraphics makeObjectsPerformSelector:@selector(setLayer:)withObject:[self currentEditableLayer]];
	ACSDGraphic *drGraphic = [[dict objectForKey:dragGraphicKey]obj];
	if (drGraphic)
		[allGraphics makeObjectsPerformSelector:@selector(moveByValue:)withObject:[NSValue valueWithPoint:diff_points(*loc,[drGraphic displayBounds].origin)]];
	[pastedGraphics makeObjectsPerformSelector:@selector(moveWithinBoundsOfView:)withObject:self];
	[self performSelector:@selector(addElement:)withObjectsFromArray:pastedGraphics];
}

- (IBAction)paste:(id)sender
{
    [self pasteFromPasteBoard:[NSPasteboard generalPasteboard] location:NULL];
	[[self undoManager] setActionName:@"Paste"];
}

- (IBAction)pastePath:(id)sender
{
    NSPasteboard *pBoard = [NSPasteboard generalPasteboard];
    NSArray *arr = [pBoard readObjectsForClasses:[NSArray arrayWithObject:[NSString class]] options:nil];
    if ([arr count] > 0)
    {
        NSString *str = [arr objectAtIndex:0];
        NSBezierPath *bp = bezierPathFromSVGPath(str);
        ACSDPath *p = [[[ACSDPath alloc] initWithName:[ACSDPath nextNameForDocument:[self document]]
                                                                    fill:[self defaultFill] stroke:[self defaultStroke] rect:NSZeroRect layer:[self currentEditableLayer]
                       bezierPath:bp]autorelease];
        if (p)
        {
            [self clearSelection];
            [[[self currentEditableLayer] graphics] addObject:[[self document]registerObject:p]];
            [self selectGraphic:p];
            [[[self undoManager] prepareWithInvocationTarget:self] deleteSelectedGraphics];
            [[self undoManager] setActionName:@"Paste Puts"];
        }
    }

	//[[self undoManager] setActionName:@"Paste Path"];
}

- (IBAction)createStyleFromText:(id)sender
   {
	[[self undoManager] setActionName:@"Create Style"];
   }

- (NSInteger)oldestSelectedFrom:(NSArray*)graphics
   {
	NSDate *oldestTimeStamp = [NSDate date];
	NSInteger oldestInd = -1;
	NSInteger count = [graphics count];
	for (NSInteger i = 0;i < count;i++)
	   {
	    ACSDGraphic *graphic = [graphics objectAtIndex:i];
		if ([[graphic selectionTimeStamp]compare:oldestTimeStamp] == NSOrderedAscending)
		   {
			oldestInd = i;
			oldestTimeStamp = [graphic selectionTimeStamp];
		   }
	   }
	return oldestInd;
   }

-(void)accumHTML:(id)sender
{
	for (ACSDGraphic *g in [self selectedGraphics])
		[[HTMLAccumulator sharedHTMLAccumulator]addToQueue:[g name]];
	[[HTMLAccumulator sharedHTMLAccumulator]startQueue];
}

- (void)reversePath:(id)sender
   {
	NSArray *arr = [[self selectedGraphics]allObjects];
	if ([arr count] < 1)
		return;
	for (id obj in arr)
	   {
		if ([obj respondsToSelector:@selector(reversedSubPaths)])
		   {
			NSMutableArray *rSubPath = [obj reversedSubPaths];
			[self uRestoreSubPaths:rSubPath forPath:obj];
		   }
	   }
	[[self undoManager] setActionName:@"Reverse Path"];
   }

- (void)exportSelectedImage:(id)sender
{
	NSArray *arr = [[self selectedGraphics]allObjects];
	for (id obj in arr)
	{
		if ([obj isKindOfClass:[ACSDImage class]])
		{
			[[self document]exportAnImage:(ACSDImage*)obj];
		}
	}
}

- (void)mercatorPath:(id)sender
{
	NSArray *arr = [[self selectedGraphics]allObjects];
	if ([arr count] < 1)
		return;
	NSRect r = NSZeroRect;
	r.size = [[self document]documentSize];
	for (id obj in arr)
	{
		if ([obj respondsToSelector:@selector(mercatorSubPathsWithRect:)])
		{
			NSMutableArray *msps = [obj mercatorSubPathsWithRect:r];
			[self uRestoreSubPaths:msps forPath:obj];
		}
	}
	[[self undoManager] setActionName:@"Mercator Path"];
}

- (void)demercatorPath:(id)sender
{
	NSArray *arr = [[self selectedGraphics]allObjects];
	if ([arr count] < 1)
		return;
	NSRect r = NSZeroRect;
	r.size = [[self document]documentSize];
	for (id obj in arr)
	{
		if ([obj respondsToSelector:@selector(demercatorSubPathsWithRect:)])
		{
			NSMutableArray *msps = [obj demercatorSubPathsWithRect:r];
			[self uRestoreSubPaths:msps forPath:obj];
		}
	}
	[[self undoManager] setActionName:@"Demercator Path"];
}

- (NSMutableArray*)outlinesFromPathObjects:(NSMutableArray*)paths
   {
	NSMutableArray *resultArray = [NSMutableArray arrayWithCapacity:[paths count]];
	for (ACSDPath *obj in paths)
	   {
		if ([obj stroke])
			[resultArray addObject:[obj outlineStroke]];
	   }
	return resultArray;
   }

- (void)outlineStrokeCopy:(id)sender
{
	NSArray *arr = [self sortedSelectedGraphics];
	if ([arr count] < 1)
		return;
	NSMutableArray *pathArray = [self subPathsFromSelectedObjects:arr];
	NSMutableArray *outlineArray = [self outlinesFromPathObjects:pathArray];
	
	[self clearSelection];
	for (ACSDPath *g in outlineArray)
	{
		[self uInsertGraphic:g intoLayer:[self currentEditableLayer] atIndex:[[[self currentEditableLayer]graphics]count]];
		[g completeRebuild];
		[self selectGraphic:g];
	}
	[[self undoManager] setActionName:[sender title]];
}

- (void)outlineStroke:(id)sender
{
	NSArray *arr = [self sortedSelectedGraphics];
	if ([arr count] < 1)
		return;
	NSMutableArray *pathArray = [self subPathsFromSelectedObjects:arr];
	NSMutableArray *outlineArray = [self outlinesFromPathObjects:pathArray];
	
	[self deleteSelectedGraphics];
	for (ACSDPath *g in outlineArray)
	{
		[self uInsertGraphic:g intoLayer:[self currentEditableLayer] atIndex:[[[self currentEditableLayer]graphics]count]];
		[g completeRebuild];
		[self selectGraphic:g];
	}
	[[self undoManager] setActionName:[sender title]];
}

-(IBAction)outlineStrokeBuiltIn:(id)sender
{
    NSArray *arr = [self sortedSelectedGraphics];
    if ([arr count] < 1)
        return;
	[self clearSelection];
    for (ACSDGraphic *g in arr)
    {
        NSBezierPath *p = [g bezierPath];
        [p setLineWidth:[[g stroke]lineWidth]];
        [p setLineCapStyle:[[g stroke]lineCap]];
        [p setLineJoinStyle:[[g stroke]lineJoin]];
        NSBezierPath *outp = outlinedStrokePath(p);
        ACSDPath *newPath = [[[ACSDPath alloc]initWithName:[g name] fill:nil stroke:nil rect:[g bounds] layer:nil bezierPath:outp]autorelease];
        [self uInsertGraphic:newPath intoLayer:[self currentEditableLayer] atIndex:[[[self currentEditableLayer]graphics]count]];
        [newPath completeRebuild];
        [self selectGraphic:newPath];
    }
    [[self undoManager] setActionName:[sender title]];
}

- (void)uRestoreSubPaths:(NSMutableArray*)subPaths forPath:(ACSDPath*)path
   {
	[[[self undoManager] prepareWithInvocationTarget:self] uRestoreSubPaths:[path subPaths] forPath:path];
	[self invalidateGraphic:path];
	[path setSubPaths:subPaths];
	[path generatePath];
	[path completeRebuild];
   }

- (void)uFlipVertical:(id)obj
{
	[[[self undoManager] prepareWithInvocationTarget:self] uFlipVertical:obj];
	[obj flipV];
}

- (void)uFlipHorizontal:(id)obj
{
	[[[self undoManager] prepareWithInvocationTarget:self] uFlipHorizontal:obj];
	[obj flipH];
}

- (void)flipVertical:(id)sender
   {
	NSArray *arr = [[self selectedGraphics]allObjects];
	NSInteger ct = [arr count];
	if (ct < 1)
		return;
	for (id obj in arr)
	   {
		if ([obj respondsToSelector:@selector(flipV)])
		   {
			if ([obj respondsToSelector:@selector(uRestoreSubPaths:forPath:)])
			{
				[[[self undoManager] prepareWithInvocationTarget:self] uRestoreSubPaths:[obj subPaths] forPath:obj];
				[obj flipV];
			}
			else
				[self uFlipVertical:obj];
			if ([obj respondsToSelector:@selector(completeRebuild)])
				[obj completeRebuild];
		   }
	   }
	[[self undoManager] setActionName:@"Flip Vertical"];
   }

- (void)flipVerticalCopy:(id)sender
{
	NSArray *sortedSelectedGraphics = [self sortedSelectedGraphics];
	NSMutableArray *graphics = [[self currentEditableLayer] graphics];
	NSInteger ct = [sortedSelectedGraphics count];
	if (ct < 1)
		return;
	int affectedGraphics = 0;
	[self clearSelection];
	for (NSInteger i = 0;i < ct;i++)
	{
		ACSDGraphic *oldGraphic = [sortedSelectedGraphics objectAtIndex:i];
		if ([oldGraphic respondsToSelector:@selector(flipV)])
		{
			affectedGraphics++;
			ACSDGraphic *newGraphic = [oldGraphic copy];
			[graphics addObject:[[self document]registerObject:newGraphic]];
			[newGraphic flipV];
			if ([newGraphic respondsToSelector:@selector(completeRebuild)])
				[(id)newGraphic completeRebuild];
			[self selectGraphic:newGraphic];
		}
	}
	if (affectedGraphics > 0)
	{
		[[[self undoManager] prepareWithInvocationTarget:self] deleteSelectedGraphics];
		[[self undoManager] setActionName:@"Flip Vertical Copy"];
	}
}

- (void)flipHorizontal:(id)sender
   {
	NSArray *arr = [[self selectedGraphics]allObjects];
	NSInteger ct = [arr count];
	if (ct < 1)
		return;
	for (id obj in arr)
	   {
		if ([obj respondsToSelector:@selector(flipH)])
		   {
			if ([obj respondsToSelector:@selector(uRestoreSubPaths:forPath:)])
			{
				[[[self undoManager] prepareWithInvocationTarget:self] uRestoreSubPaths:[obj subPaths] forPath:obj];
				[obj flipH];
			}
			else
				[self uFlipHorizontal:obj];
			if ([obj respondsToSelector:@selector(completeRebuild)])
				[obj completeRebuild];
		   }
	   }
	[[self undoManager] setActionName:@"Flip Horizontal"];
   }

- (void)flipHorizontalCopy:(id)sender
{
	NSArray *sortedSelectedGraphics = [self sortedSelectedGraphics];
	NSMutableArray *graphics = [[self currentEditableLayer] graphics];
	NSInteger ct = [sortedSelectedGraphics count];
	if (ct < 1)
		return;
	int affectedGraphics = 0;
	[self clearSelection];
	for (NSInteger i = 0;i < ct;i++)
	   {
		ACSDGraphic *oldGraphic = [sortedSelectedGraphics objectAtIndex:i];
		if ([oldGraphic respondsToSelector:@selector(flipH)])
		{
			affectedGraphics++;
			ACSDGraphic *newGraphic = [oldGraphic copy];
			[graphics addObject:[[self document]registerObject:newGraphic]];
			[newGraphic flipH];
			if ([newGraphic respondsToSelector:@selector(completeRebuild)])
				[(id)newGraphic completeRebuild];
			[self selectGraphic:newGraphic];
		}
	   }
	if (affectedGraphics > 0)
	{
		[[[self undoManager] prepareWithInvocationTarget:self] deleteSelectedGraphics];
		[[self undoManager] setActionName:@"Flip Horizontal Copy"];
	}
}

- (void)uDeleteLastSubPath:(ACSDPath*)path
   {
	NSMutableArray *subPaths = [path subPaths];
	if ([subPaths count] == 0)
		return;
	id lastObj = [subPaths objectAtIndex:[subPaths count]-1];
	[[[self undoManager] prepareWithInvocationTarget:self] uAppendSubPath:lastObj toPath:path];
	[subPaths removeObjectAtIndex:[subPaths count]-1];
   }

- (void)uAppendSubPath:(id)subPath toPath:(ACSDPath*)path
   {
	NSMutableArray *subPaths = [path subPaths];
	[[[self undoManager] prepareWithInvocationTarget:self] uDeleteLastSubPath:path];
	[subPaths addObject:subPath];
   }

- (void)uRebuildPathUndo:(ACSDPath*)path
   {
	[[[self undoManager] prepareWithInvocationTarget:self] uRebuildPath:path];
   }

- (void)uRebuildPath:(ACSDPath*)path
   {
	[[[self undoManager] prepareWithInvocationTarget:self] uRebuildPathUndo:path];
	[path generatePath];
	[path recalcBounds];
	[path invalidateGraphicSizeChanged:YES shapeChanged:YES redraw:YES notify:NO];
	[[self window] invalidateCursorRectsForView:self];
   }

- (void)decomposeDelete:(BOOL)del
   {
	NSArray *arr = [self sortedSelectedGraphics];
	NSInteger objCount = [arr count];
	if (objCount == 0)
		return;
	[self clearSelection];
	for (NSInteger i = 0;i < objCount;i++)
	   {
		ACSDGraphic *g = [arr objectAtIndex:i];
		if ([g isKindOfClass:[ACSDPath class]])
		   {
			NSArray *subPathArray = [(ACSDPath*)g subPaths];
			NSInteger subPathCount = [subPathArray count];
			for (NSInteger j = 0;j < subPathCount;j++)
			   {
				NSMutableArray *pArray = [NSMutableArray arrayWithCapacity:1];
				[pArray addObject:[[[subPathArray objectAtIndex:j]copy]autorelease]];
				ACSDPath *h = [[[ACSDPath alloc]initWithName:[g name] fill:[g fill] stroke:[g stroke] rect:[g bounds] layer:[self currentEditableLayer] subPaths:pArray
													  xScale:[g xScale] yScale:[g yScale] rotation:[g rotation] shadowType:[g shadowType] label:nil alpha:[g alpha]]autorelease];
				[self addElement:h];
				[self selectGraphic:h];
			   }
			if (del)
				[self deleteGraphic:g];
		   }
	   }
	[[self undoManager] setActionName:@"Decompose"];
   }

- (void)decompose:(id)sender
   {
	[self decomposeDelete:YES];
   }

- (void)decomposeCopy:(id)sender
   {
	[self decomposeDelete:NO];
   }

- (void)combinePathsDelete:(BOOL)del
   {
	NSArray *arr = [self selectedGraphicsSortedByTimestamp];
	NSInteger ct = [arr count];
	if (ct < 2)
		return;
	[self clearSelection];
	ACSDGraphic *graphic = [arr objectAtIndex:0];
	ACSDPath *consumer;
	if ([graphic isMemberOfClass:[ACSDPath class]])
		consumer = [[graphic copy]autorelease];
	else
		consumer = [graphic convertToPath];
	[consumer setLayer:[graphic layer]];
	[consumer applyTransform];
	[self deleteGraphic:[arr objectAtIndex:0]];
	for (NSInteger i = 1;i < ct;i++)
	   {
		ACSDPath *g;
		graphic = [arr objectAtIndex:i];
		if ([graphic isMemberOfClass:[ACSDPath class]])
			g = [[graphic copy]autorelease];
		else
			g = [graphic convertToPath];
		[g applyTransform];
		for (NSInteger j = 0,ct = [[g subPaths] count];j < ct;j++)
		   {
			NSMutableArray *sp = [consumer subPaths];
			id ob = [[g subPaths]objectAtIndex:j];
			[sp addObject:ob];
		   }
//		[[consumer subPaths]addObjectsFromArray:[g subPaths]];
		if (del)
			[self deleteGraphic:[arr objectAtIndex:i]];
	   }
	[consumer generatePath];
	[consumer completeRebuild];
	[self addElement:consumer];
	[self selectGraphic:consumer];
	[[self undoManager] setActionName:@"Combine Paths"];
   }

- (void)combinePaths:(id)sender
   {
	[self combinePathsDelete:YES];
   }

- (void)combinePathsCopy:(id)sender
   {
	[self combinePathsDelete:NO];
   }

static ACSDGraphic *parg(ACSDGraphic *g)
{
    if (g.link == nil)
        return nil;
    if ([g.link respondsToSelector:@selector(toObject)])
    {
        ACSDGraphic *gl = [g.link toObject];
        if ([gl isKindOfClass:[ACSDGraphic class]])
            return gl;
    }
    return nil;
}
-(id)commonParent:(NSArray*)graphics
{
    if ([graphics count] == 0)
        return nil;
    ACSDGraphic *cp = parg(graphics[0]);
    if (cp == nil)
        return nil;
    for (ACSDGraphic *g in graphics)
        if (parg(g) != cp)
            return nil;
    return cp;
}

-(void)redoCursorStuff
{
    [[self window] invalidateCursorRectsForView:self];
    [self reCalcHandleBitsIgnoreSelected:NO];
}

- (void)centreHorizontally:(id)sender
{
    NSArray *objectsToMove = [[self selectedGraphics]allObjects];
    if ([objectsToMove count] == 0)
        return;
    NSRect r;
    ACSDGraphic *gpar = [self commonParent:objectsToMove];
    if (gpar == nil)
        r = [self bounds];
    else
        r = [gpar transformedBounds];
    ACSDGraphic *g = objectsToMove[0];
    NSRect gf = [g transformedBounds];
    float minx = NSMinX(gf);
    float maxx = NSMaxX(gf);
    for (ACSDGraphic *g in objectsToMove)
    {
        NSRect gf = [g transformedBounds];
        if (NSMinX(gf) < minx)
            minx = NSMinX(gf);
        if (NSMaxX(gf) > maxx)
            maxx = NSMaxX(gf);
    }
    float w = maxx - minx;
    float gap = (r.size.width - w) / 2;
    float dx = (r.origin.x + gap) - minx;
    for (ACSDGraphic *g in objectsToMove)
    {
        [g invalidateInView];
        [g uMoveBy:NSMakePoint(dx,0.0)];
        [g invalidateInView];
    }
    [self redoCursorStuff];
    [[self undoManager] setActionName:@"Centre Horizontally"];
}

- (void)centreVertically:(id)sender
{
    NSArray *objectsToMove = [[self selectedGraphics]allObjects];
    if ([objectsToMove count] == 0)
        return;
    NSRect r;
    ACSDGraphic *gpar = [self commonParent:objectsToMove];
    if (gpar == nil)
        r = [self bounds];
    else
        r = [gpar transformedBounds];
    ACSDGraphic *g = objectsToMove[0];
    NSRect gf = [g transformedBounds];
    float miny = NSMinY(gf);
    float maxy = NSMaxY(gf);
    for (ACSDGraphic *g in objectsToMove)
    {
        NSRect gf = [g transformedBounds];
        if (NSMinY(gf) < miny)
            miny = NSMinY(gf);
        if (NSMaxY(gf) > maxy)
            maxy = NSMaxY(gf);
    }
    float h = maxy - miny;
    float gap = (r.size.height - h) / 2;
    float dy = (r.origin.y + gap) - miny;
    for (ACSDGraphic *g in objectsToMove)
    {
        [g invalidateInView];
        [g uMoveBy:NSMakePoint(0.0,dy)];
        [g invalidateInView];
    }
    [self redoCursorStuff];
    [[self undoManager] setActionName:@"Centre Vertically"];
}

- (void)distributeHorizontally:(id)sender
{
	NSUInteger count = [[self selectedGraphics]count];
	if (count < 3)
		return;
	NSMutableArray *itemsToMove = [NSMutableArray arrayWithCapacity:count];
	[itemsToMove addObjectsFromArray:[[self selectedGraphics]allObjects]];
	[itemsToMove sortUsingSelector:@selector(compareUsingXPos:)];
	float leftX = [[itemsToMove objectAtIndex:0]midX];
	float rightX = [[itemsToMove objectAtIndex:(count-1)]midX];
	float increment = (rightX - leftX) / (count - 1);
	for (unsigned i = 1;i < count - 1;i++)
	   {
		float x = leftX + i * increment;
		ACSDGraphic *graphic = [itemsToMove objectAtIndex:i];
		float amountToMove = x - [graphic midX];
		[graphic invalidateInView];
		[graphic uMoveBy:NSMakePoint(amountToMove,0.0)];
		[graphic invalidateInView];
	   }
	[[self undoManager] setActionName:@"Distribute Horizontally"];
}

- (void)distributeVertically:(id)sender
{
	NSUInteger count = [[self selectedGraphics]count];
	if (count < 3)
		return;
	NSMutableArray *itemsToMove = [NSMutableArray arrayWithCapacity:count];
	[itemsToMove addObjectsFromArray:[[self selectedGraphics]allObjects]];
	[itemsToMove sortUsingSelector:@selector(compareUsingYPos:)];
	float bottomY = [[itemsToMove objectAtIndex:0]midY];
	float topY = [[itemsToMove objectAtIndex:(count-1)]midY];
	float increment = (topY - bottomY) / (count - 1);
	for (NSUInteger i = 1;i < count - 1;i++)
	   {
		float y = bottomY + i * increment;
		ACSDGraphic *graphic = [itemsToMove objectAtIndex:i];
		float amountToMove = y - [graphic midY];
		[graphic invalidateInView];
		[graphic uMoveBy:NSMakePoint(0.0,amountToMove)];
		[graphic invalidateInView];
	   }	
	[[self undoManager] setActionName:@"Distribute Vertically"];
}

- (void)alignVerticalCentres:(id)sender
{
	NSInteger count = [[self selectedGraphics]count];
	if (count < 2)
		return;
	NSMutableArray *itemsToMove = [NSMutableArray arrayWithCapacity:count];
	[itemsToMove addObjectsFromArray:[[self selectedGraphics]allObjects]];
	NSInteger oldestInd = [self oldestSelectedFrom:itemsToMove];
	ACSDGraphic *anchor = [itemsToMove objectAtIndex:oldestInd];
	[itemsToMove removeObjectAtIndex:oldestInd];
	count--;
	float centre = [anchor midY];
	for (NSInteger i = 0;i < count;i++)
	   {
	    ACSDGraphic *graphic = [itemsToMove objectAtIndex:i];
		float amountToMove = centre - [graphic midY];
		[graphic invalidateInView];
		[graphic uMoveBy:NSMakePoint(0.0,amountToMove)];
		[graphic invalidateInView];
	   }
	[[self undoManager] setActionName:@"Align VerticalCentres"];
}

- (void)alignHorizontalCentres:(id)sender
{
	NSInteger count = [[self selectedGraphics]count];
	if (count < 2)
		return;
	NSMutableArray *itemsToMove = [NSMutableArray arrayWithCapacity:count];
	[itemsToMove addObjectsFromArray:[[self selectedGraphics]allObjects]];
	NSInteger oldestInd = [self oldestSelectedFrom:itemsToMove];
	ACSDGraphic *anchor = [itemsToMove objectAtIndex:oldestInd];
	[itemsToMove removeObjectAtIndex:oldestInd];
	count--;
	float centre = [anchor midX];
	for (NSInteger i = 0;i < count;i++)
	   {
	    ACSDGraphic *graphic = [itemsToMove objectAtIndex:i];
		float amountToMove = centre - [graphic midX];
		[graphic invalidateInView];
		[graphic uMoveBy:NSMakePoint(amountToMove,0.0)];
		[graphic invalidateInView];
	   }
	[[self undoManager] setActionName:@"Align HorizontalCentres"];
}

- (void)alignLeftEdges:(id)sender
{
	NSInteger count = [[self selectedGraphics]count];
	if (count < 2)
		return;
	NSMutableArray *itemsToMove = [NSMutableArray arrayWithCapacity:count];
	[itemsToMove addObjectsFromArray:[[self selectedGraphics]allObjects]];
	NSInteger oldestInd = [self oldestSelectedFrom:itemsToMove];
	ACSDGraphic *anchor = [itemsToMove objectAtIndex:oldestInd];
	[itemsToMove removeObjectAtIndex:oldestInd];
	count--;
	float leftEdge = [anchor transformedBounds].origin.x;
	for (NSInteger i = 0;i < count;i++)
	{
	    ACSDGraphic *graphic = [itemsToMove objectAtIndex:i];
		float amountToMove = leftEdge - [graphic transformedBounds].origin.x;
		[graphic invalidateInView];
		[graphic uMoveBy:NSMakePoint(amountToMove,0.0)];
		[graphic invalidateInView];
	}
	[[self undoManager] setActionName:@"Align Left Edges"];
}

- (void)alignRightEdges:(id)sender
{
	NSInteger count = [[self selectedGraphics]count];
	if (count < 2)
		return;
	NSMutableArray *itemsToMove = [NSMutableArray arrayWithCapacity:count];
	[itemsToMove addObjectsFromArray:[[self selectedGraphics]allObjects]];
	NSInteger oldestInd = [self oldestSelectedFrom:itemsToMove];
	ACSDGraphic *anchor = [itemsToMove objectAtIndex:oldestInd];
	[itemsToMove removeObjectAtIndex:oldestInd];
	count--;
	float rightEdge = [anchor transformedBounds].origin.x + [anchor transformedBounds].size.width;
	for (int i = 0;i < count;i++)
	{
	    ACSDGraphic *graphic = [itemsToMove objectAtIndex:i];
		float amountToMove = rightEdge - ([graphic transformedBounds].origin.x + [graphic transformedBounds].size.width);
		[graphic invalidateInView];
		[graphic uMoveBy:NSMakePoint(amountToMove,0.0)];
		[graphic invalidateInView];
	}
	[[self undoManager] setActionName:@"Align Right Edges"];
}

- (void)alignTopEdges:(id)sender
{
	NSInteger count = [[self selectedGraphics]count];
	if (count < 2)
		return;
	NSMutableArray *itemsToMove = [NSMutableArray arrayWithCapacity:count];
	[itemsToMove addObjectsFromArray:[[self selectedGraphics]allObjects]];
	NSInteger oldestInd = [self oldestSelectedFrom:itemsToMove];
	ACSDGraphic *anchor = [itemsToMove objectAtIndex:oldestInd];
	[itemsToMove removeObjectAtIndex:oldestInd];
	count--;
	float topEdge = [anchor transformedBounds].origin.y  + [anchor transformedBounds].size.height;
	for (NSInteger i = 0;i < count;i++)
	{
	    ACSDGraphic *graphic = [itemsToMove objectAtIndex:i];
		float amountToMove = topEdge - ([graphic transformedBounds].origin.y + [graphic transformedBounds].size.height);
		[graphic invalidateInView];
		[graphic uMoveBy:NSMakePoint(0.0,amountToMove)];
		[graphic invalidateInView];
	}
	[[self undoManager] setActionName:@"Align Top Edges"];
}

- (void)alignBottomEdges:(id)sender
{
	NSInteger count = [[self selectedGraphics]count];
	if (count < 2)
		return;
	NSMutableArray *itemsToMove = [NSMutableArray arrayWithCapacity:count];
	[itemsToMove addObjectsFromArray:[[self selectedGraphics]allObjects]];
	NSInteger oldestInd = [self oldestSelectedFrom:itemsToMove];
	ACSDGraphic *anchor = [itemsToMove objectAtIndex:oldestInd];
	[itemsToMove removeObjectAtIndex:oldestInd];
	count--;
	float bottomEdge = [anchor transformedBounds].origin.y;
	for (NSInteger i = 0;i < count;i++)
	{
	    ACSDGraphic *graphic = [itemsToMove objectAtIndex:i];
		float amountToMove = bottomEdge - [graphic transformedBounds].origin.y;
		[graphic invalidateInView];
		[graphic uMoveBy:NSMakePoint(0.0,amountToMove)];
		[graphic invalidateInView];
	}
	[[self undoManager] setActionName:@"Align Bottom Edges"];
}

- (void)deleteForward:(id)sender
{
    [self clear:sender];
}

- (void)deleteBackward:(id)sender
{
    [self clear:sender];
}

- (void)bringForward:(id)sender
{
    NSMutableArray *positionalObjects = [self sortedPositionalObjects];
    NSInteger i,ct = [positionalObjects count],allCt = [[[self currentEditableLayer] graphics]count];
    for (i = ct - 1;i >= 0 && ([(PositionalObject*)[positionalObjects objectAtIndex:i]position] == (allCt - (ct - i)));i--)
        ;
    for (;i >= 0;i--)
    {
        NSInteger pos = [(PositionalObject*)[positionalObjects objectAtIndex:i]position];
        [self swapElementsAtPosition1:pos position2:(NSInteger)pos+1];
    }
    [[NSNotificationCenter defaultCenter]postNotificationName:ACSDGraphicListChanged object:self];
    [[self undoManager] setActionName:[sender title]];
}

- (void)sendBackward:(id)sender
{
    NSMutableArray *positionalObjects = [self sortedPositionalObjects];
    NSInteger i,ct = [positionalObjects count];
    for (i = 0;i < ct && ([(PositionalObject*)[positionalObjects objectAtIndex:i]position] == i);i++)
        ;
    for (;i < ct;i++)
	   {
           NSInteger pos = [(PositionalObject*)[positionalObjects objectAtIndex:i]position];
           [self swapElementsAtPosition1:pos position2:(NSInteger)pos - 1];
       }
    [[NSNotificationCenter defaultCenter]postNotificationName:ACSDGraphicListChanged object:self];
    [[self undoManager] setActionName:[sender title]];
}

- (void)moveElementFromPosition:(NSInteger)pos1 toPosition:(NSInteger) pos2
   {
	[[[self undoManager] prepareWithInvocationTarget:self] moveElementFromPosition:pos2 toPosition:pos1];
	ACSDGraphic *obj = [[[self currentEditableLayer] graphics]objectAtIndex:pos1];
	[[[self currentEditableLayer] graphics]removeObjectAtIndex:pos1];
	[[[self currentEditableLayer] graphics]insertObject:obj atIndex:pos2];
	[obj invalidateInView];
   }

- (void)sendToBack:(id)sender
   {
	NSMutableArray *positionalObjects = [self sortedPositionalObjects];
	NSInteger ct = [positionalObjects count],i;
	for (i = 0;i < ct && ([(PositionalObject*)[positionalObjects objectAtIndex:i]position] == i);i++)
		;
	NSInteger j = i;
	for (;i < ct;i++,j++)
	   {
		NSInteger pos = [(PositionalObject*)[positionalObjects objectAtIndex:i]position];
		[self moveElementFromPosition:pos toPosition:j];
	   }
    [[NSNotificationCenter defaultCenter]postNotificationName:ACSDGraphicListChanged object:self];
	[[self undoManager] setActionName:[sender title]];
   }

- (void)bringToFront:(id)sender
   {
	NSMutableArray *positionalObjects = [self sortedPositionalObjects];
	NSInteger i,ct = [positionalObjects count],allCt = [[[self currentEditableLayer] graphics]count];
	for (i = ct - 1;i >= 0 && ([(PositionalObject*)[positionalObjects objectAtIndex:i]position] == (allCt - (ct - i)));i--)
		;
	NSInteger j = allCt - (ct - i);
	for (;i >= 0;i--,j--)
	   {
		NSInteger pos = [(PositionalObject*)[positionalObjects objectAtIndex:i]position];
		[self moveElementFromPosition:pos toPosition:j];
	   }
    [[NSNotificationCenter defaultCenter]postNotificationName:ACSDGraphicListChanged object:self];
	[[self undoManager] setActionName:[sender title]];
   }


- (void)replaceGraphicAtIndex:(NSInteger)i with:(ACSDGraphic*)g
   {
	[[[self undoManager] prepareWithInvocationTarget:self] replaceGraphicAtIndex:i with:[[[self currentEditableLayer] graphics]objectAtIndex:i]];
	[[[self currentEditableLayer] graphics] replaceObjectAtIndex:i withObject:g];
   }

- (void)convertToPath:(id)sender
{
	if  ([[self selectedGraphics]count] < 1)
		return;
	NSArray *selectedGraphics = [[self selectedGraphics]allObjects];
	[self clearSelection];
	ACSDGraphic *graphic;
	NSEnumerator *objEnum = [selectedGraphics objectEnumerator];
	while ((graphic = [objEnum nextObject]) != nil)
	{
		ACSDPath *newGraphic = [graphic convertToPath];
		newGraphic.attributes = [[graphic.attributes mutableCopy]autorelease];
		NSUInteger i = [[[self currentEditableLayer] graphics]indexOfObjectIdenticalTo:graphic];
		[self replaceGraphicAtIndex:i with:newGraphic];
		[newGraphic setLayer:[graphic layer]];
		[[self document]registerObject:newGraphic];
		[self selectGraphic:newGraphic];
		[newGraphic completeRebuild];
	}
	[[self undoManager] setActionName:[sender title]];
}

- (void)applyImageTransform:(id)sender
{
	if  ([[self selectedGraphics]count] == 0)
		return;
	NSArray *selectedGraphics = [[self selectedGraphics]allObjects];
	[self clearSelection];
	ACSDGraphic *graphic;
	ACSDImage *image = nil;
	NSEnumerator *objEnum = [selectedGraphics objectEnumerator];
	while ((graphic = [objEnum nextObject]) != nil)
	{
		if ([graphic rotation] != 0.0 && [graphic isKindOfClass:[ACSDImage class]])
		{
			[graphic invalidateGraphicSizeChanged:NO shapeChanged:NO redraw:NO notify:NO];
			image = [(ACSDImage*)graphic rotatedACSDImage];
			NSUInteger i = [[[self currentEditableLayer] graphics]indexOfObjectIdenticalTo:graphic];
			[self replaceGraphicAtIndex:i with:image];
			[image setLayer:[graphic layer]];
			[[self document]registerObject:image];
			[self selectGraphic:image];
			[image invalidateGraphicSizeChanged:YES shapeChanged:YES redraw:YES notify:NO];
		}
	}
	if (image)
		[[self undoManager] setActionName:@"Apply Image Transform"];
}

- (void)demercator:(id)sender
{
	if  ([[self selectedGraphics]count] == 0)
		return;
	NSArray *selectedGraphics = [[self selectedGraphics]allObjects];
	[self clearSelection];
	ACSDImage *image = nil;
	for (ACSDGraphic *graphic in selectedGraphics)
	{
		if ([graphic respondsToSelector:@selector(demercatorACSDImage)])
		{
			[graphic invalidateGraphicSizeChanged:NO shapeChanged:NO redraw:NO notify:NO];
			image = [(id)graphic demercatorACSDImage];
			NSUInteger i = [[[self currentEditableLayer] graphics]indexOfObjectIdenticalTo:graphic];
			[self replaceGraphicAtIndex:i with:image];
			[image setLayer:[graphic layer]];
			[[self document]registerObject:image];
			[self selectGraphic:image];
			[image invalidateGraphicSizeChanged:YES shapeChanged:YES redraw:YES notify:NO];
		}
	}
	if (image)
		[[self undoManager] setActionName:@"Demercator"];
}

- (void)wideCylinderHalfWrap:(id)sender
{
	if  ([[self selectedGraphics]count] == 0)
		return;
	NSArray *selectedGraphics = [[self selectedGraphics]allObjects];
	[self clearSelection];
	ACSDImage *image = nil;
	for (ACSDGraphic *graphic in selectedGraphics)
	{
		if ([graphic respondsToSelector:@selector(wideCylinderHalfWrapACSDImage)])
		{
			[graphic invalidateGraphicSizeChanged:NO shapeChanged:NO redraw:NO notify:NO];
			image = [(id)graphic wideCylinderHalfWrapACSDImage];
			NSUInteger i = [[[self currentEditableLayer] graphics]indexOfObjectIdenticalTo:graphic];
			[self replaceGraphicAtIndex:i with:image];
			[image setLayer:[graphic layer]];
			[[self document]registerObject:image];
			[self selectGraphic:image];
			[image invalidateGraphicSizeChanged:YES shapeChanged:YES redraw:YES notify:NO];
		}
	}
	if (image)
		[[self undoManager] setActionName:@"Wide Cylinder Half Wrap"];
}

- (void)wideCylinderHalfUnwrap:(id)sender
{
	if  ([[self selectedGraphics]count] == 0)
		return;
	NSArray *selectedGraphics = [[self selectedGraphics]allObjects];
	[self clearSelection];
	ACSDImage *image = nil;
	for (ACSDGraphic *graphic in selectedGraphics)
	{
		if ([graphic respondsToSelector:@selector(wideCylinderHalfUnwrapACSDImage)])
		{
			[graphic invalidateGraphicSizeChanged:NO shapeChanged:NO redraw:NO notify:NO];
			image = [(id)graphic wideCylinderHalfUnwrapACSDImage];
			NSUInteger i = [[[self currentEditableLayer] graphics]indexOfObjectIdenticalTo:graphic];
			[self replaceGraphicAtIndex:i with:image];
			[image setLayer:[graphic layer]];
			[[self document]registerObject:image];
			[self selectGraphic:image];
			[image invalidateGraphicSizeChanged:YES shapeChanged:YES redraw:YES notify:NO];
		}
	}
	if (image)
		[[self undoManager] setActionName:@"Wide Cylinder Half Unwrap"];
}

- (void)applyTransform:(id)sender
{
	if  ([[self selectedGraphics]count] == 0)
		return;
	NSArray *selectedGraphics = [[self selectedGraphics]allObjects];
	ACSDGraphic *graphic;
	NSEnumerator *objEnum = [selectedGraphics objectEnumerator];
	while ((graphic = [objEnum nextObject]) != nil)
	{
		if ([graphic transform] && [graphic respondsToSelector:@selector(applyTransform)])
			[(id)graphic applyTransform];
	}
	[[self undoManager] setActionName:@"Apply Transform"];
}

- (void)reOpenPath:(id)sender
{
	if  ([[self selectedGraphics]count] != 1)
		return;
	ACSDGraphic *graphic = [[[self selectedGraphics]allObjects]objectAtIndex:0];
	if (![graphic isKindOfClass:[ACSDPath class]])
		return;
	[[ToolWindowController sharedToolWindowController:nil] selectToolAtRow:3 column:0];
	creatingPath = graphic;
	[creatingPath setAddingPoints:YES];
	[(id)creatingPath constructAddingPointPath];
	[[self undoManager] setActionName:@"Reopen Path"];
}

- (void)closePath:(id)sender
   {
	if([[[self selectedGraphics]allObjects]orMakeAllObjectsPerformSelector:@selector(uSetSubPathsIsClosedTo:) withObject:[NSNumber numberWithBool:YES]])
		[[self undoManager] setActionName:[sender title]];
   }

- (void)openPath:(id)sender
   {
	if([[[self selectedGraphics]allObjects]orMakeAllObjectsPerformSelector:@selector(uSetSubPathsIsClosedTo:) withObject:[NSNumber numberWithBool:NO]])
		[[self undoManager] setActionName:[sender title]];
   }

- (void)mergePoints:(id)sender
   {
	if ([[[[self selectedGraphics]allObjects]objectAtIndex:0]uMergePoints])
		[[self undoManager] setActionName:[sender title]];
   }

- (void)connectPaths:(id)sender
   {
	if  ([[self selectedGraphics]count] < 2)
		return;
	NSArray *graphics = [self selectedGraphicsSortedByTimestamp];
	NSMutableArray *subPaths = [NSMutableArray arrayWithCapacity:10];
	int startInd = 0;
    for (unsigned i = 0;i < [graphics count];i++)
	   {
		ACSDPath *obj = [graphics objectAtIndex:i];
		if (i > 0)
		   {
			ACSDSubPath *sp = [subPaths objectAtIndex:[subPaths count]-1];
			NSArray* pathElements = [[[obj subPaths]objectAtIndex:0]copyOfPathElements];
			[[pathElements objectAtIndex:0]setIsLineToPoint:YES];
			[[sp pathElements]addObjectsFromArray:pathElements];
		   }
		[subPaths addObjectsFromArray:[[[obj subPaths]objectsAtIndexes:
			[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(startInd,[[obj subPaths] count]-startInd)]]copiedObjects]];
		if (i == 0)
			startInd = 1;
	   }
	ACSDGraphic *modelObject = [[graphics objectAtIndex:0]retain];
	if (!([sender keyEquivalentModifierMask] & NSAlternateKeyMask))
		[self deleteSelectedGraphics];
	[self insertNewGraphicFromSubPaths:subPaths modelObject:modelObject];
	[modelObject release];
	[[self undoManager] setActionName:[sender title]];
   }

- (void)joinPaths:(id)sender
   {
	if  ([[self selectedGraphics]count] < 2)
		return;
	NSArray *graphics = [self selectedGraphicsSortedByTimestamp];
	NSMutableArray *subPaths = [NSMutableArray arrayWithCapacity:10];
	NSPoint joinPoint = [[graphics objectAtIndex:0]lastPoint];
	for (unsigned i = 0;i < [graphics count];i++)
	   {
		ACSDPath *path = [[[graphics objectAtIndex:i]copy]autorelease];
		if (i == 0)
			[subPaths addObjectsFromArray:[[path subPaths]copiedObjects]];
		else
		   {
			NSPoint newPoint = [path firstPoint];
			NSPoint offset = NSMakePoint(joinPoint.x - newPoint.x,joinPoint.y - newPoint.y);
			[path offsetPointValue:[NSValue valueWithPoint:offset]];
			ACSDPathElement *pe0 = [[[subPaths lastObject]pathElements]lastObject];
			ACSDPathElement *pe1 = [[[[path subPaths]objectAtIndex:0]pathElements]objectAtIndex:0];
			[pe0 setPostControlPoint:[pe1 postControlPoint]];
			[pe0 setHasPostControlPoint:[pe1 hasPostControlPoint]];
			[[[[path subPaths]objectAtIndex:0]pathElements]removeObjectAtIndex:0];
			[[[subPaths lastObject]pathElements]addObjectsFromArray:[[[path subPaths]objectAtIndex:0]pathElements]];
			if ([[path subPaths]count] > 1)
				[subPaths addObjectsFromArray:[[path subPaths]objectsAtIndexes:
					[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(1,[[path subPaths] count]-1)]]];
			
			joinPoint = [path lastPoint];
		   }
	   }
	ACSDGraphic *modelObject = [[graphics objectAtIndex:0]retain];
	if (!([sender keyEquivalentModifierMask] & NSAlternateKeyMask))
		[self deleteSelectedGraphics];
	[self insertNewGraphicFromSubPaths:subPaths modelObject:modelObject];
	[modelObject release];
	[[self undoManager] setActionName:[sender title]];
   }

+ (NSMutableArray*)intersectedSubPathsFromVertexList:(NSArray*)vertexList
   {
	NSMutableArray *resultArray = [NSMutableArray arrayWithCapacity:5];
	bool allVisited = NO;
	NSInteger vCount = [vertexList count];
	while (!allVisited)
	   {
		allVisited = YES;
		int vInd = 0;
		while (vInd < vCount && allVisited)
		   {
			IVertex *v = [vertexList objectAtIndex:vInd];
			NSSet *segSet = [v candidateSegmentsIntersect];
			if ([segSet count] > 0)
			   {
				id res = [ACSDSubPath intersectionSubPathFromVertex:v];
				if (res)
					[resultArray addObject:res];
				allVisited = NO;
			   }
			vInd++;
		   }
	   }
	return resultArray;
   }

+ (NSMutableArray*)subPathsFromObjects:(NSArray*)arr
   {
	NSInteger ct = [arr count];
	NSMutableArray *pathArray = [NSMutableArray arrayWithCapacity:ct];
	for (int i = 0;i < ct;i++)
	   {
	    id g = [arr objectAtIndex:i];
		if (![g isMemberOfClass:[ACSDPath class]])
			g = [g convertToPath];
		if (![g isCounterClockWise])
			[g reversePathWithStrokeList:nil];
		[pathArray addObject:g];
	   }
	return pathArray;
   }

- (NSMutableArray*)subPathsFromSelectedObjects:(NSArray*)arr
   {
	NSInteger ct = [arr count];
	NSMutableArray *pathArray = [NSMutableArray arrayWithCapacity:ct];
	bool strokesChanged = NO;
	for (int i = 0;i < ct;i++)
	   {
	    id g = [arr objectAtIndex:i];
		if ([g isMemberOfClass:[ACSDPath class]])
			g = [[g copy]autorelease];
		else
			g = [g convertToPath];
		[g applyTransform];
		if (![g isCounterClockWise])
			strokesChanged = [g reversePathWithStrokeList:[[self document]strokes]] || strokesChanged;
		[pathArray addObject:g];
	   }
	if (strokesChanged)
		[[[PalletteViewController sharedPalletteViewController] strokeController]refreshStrokes];
	return pathArray;
   }

- (void)clearObjects:(NSArray*)arr andInsertSubPaths:(NSMutableArray*)subPaths pathObjects:(NSArray*)pathArray
   {
	[self clearSelection];
	NSInteger ct = [arr count];
	for (NSInteger i = 0;i < ct - 1;i++)
	   {
	    id g = [arr objectAtIndex:i];
		[self uDeleteGraphic:g];
	   }
	ACSDGraphic *g = [arr objectAtIndex:ct - 1];
	if (![g isMemberOfClass:[ACSDPath class]])
	   {
		NSUInteger i = [[[self currentEditableLayer] graphics]indexOfObjectIdenticalTo:g];
	    [self uDeleteGraphic:g];
		ACSDPath *newGraphic = [pathArray objectAtIndex:0];
		[self insertGraphic:newGraphic atIndex:i];
		[newGraphic completeRebuild];
		g = newGraphic;
	   }
	[self uRestoreSubPaths:subPaths forPath:(ACSDPath*)g];
	[self selectGraphic:g];
   }

- (void)insertNewGraphicFromSubPaths:(NSMutableArray*)subPaths modelObject:(ACSDGraphic*)oldG
   {
	[self clearSelection];
	ACSDPath *newGraphic = [[ACSDPath alloc]initWithName:[ACSDPath nextNameForDocument:[self document]] fill:[oldG fill] 
		stroke:[oldG stroke]rect:[oldG bounds] layer:[self currentEditableLayer] subPaths:subPaths];
	[self uInsertGraphic:newGraphic intoLayer:[self currentEditableLayer] atIndex:[[[self currentEditableLayer]graphics]count]];
	[newGraphic completeRebuild];
	[self selectGraphic:newGraphic];
   [newGraphic release];
   }


- (void)reflectAndJoin:(id)sender
{
    NSArray *arr = [[self selectedGraphics]allObjects];
    if ([arr count] != 1)
        return;
    ACSDPath *g;
    if ([sender keyEquivalentModifierMask] & NSAlternateKeyMask)
        g = [[[arr objectAtIndex:0]copy]autorelease];
    else
        g = [arr objectAtIndex:0];
    ACSDSubPath *subPath = [[[[g subPaths]objectAtIndex:0]copy]autorelease];
    NSMutableArray *elementArray = [subPath pathElements];
    if ([elementArray count] < 2)
        return;
    ACSDPathElement *firstPoint = [elementArray objectAtIndex:0];
    ACSDPathElement *lastPoint = [elementArray objectAtIndex:[elementArray count]-1];
    NSAffineTransform *transform = [NSAffineTransform transformWithTranslateXBy:-[firstPoint point].x yBy:-[firstPoint point].y];
    float angle = getAngleForPoints([firstPoint point],[lastPoint point]);
    [transform appendTransform:[NSAffineTransform transformWithRotationByDegrees:-angle]];
    [transform appendTransform:[NSAffineTransform transformWithScaleXBy:1.0 yBy:-1.0]];
    [transform appendTransform:[NSAffineTransform transformWithRotationByDegrees:angle]];
    [transform appendTransform:[NSAffineTransform transformWithTranslateXBy:[firstPoint point].x yBy:[firstPoint point].y]];
    ACSDSubPath *newSubPath = [[subPath copy]autorelease];
    [newSubPath applyTransform:transform];
    [newSubPath reverse];
    NSMutableArray *reflectedElementArray = [newSubPath pathElements];
    
    //NSInteger j = [reflectedElementArray count] - 1;
    ACSDPathElement *pe1 = [ACSDPathElement mergePathElement1:lastPoint andPathElement2:[reflectedElementArray objectAtIndex:0]];
    [elementArray replaceObjectAtIndex:[elementArray count]-1 withObject:pe1];
    /*j--;
    while (j > 0)
	   {
           [elementArray addObject:[(ACSDPathElement*)[reflectedElementArray objectAtIndex:j]reverse]];
           j--;
       }
    ACSDPathElement *pe2 = [ACSDPathElement mergePathElement1:[reflectedElementArray objectAtIndex:j] andPathElement2:firstPoint];
    [elementArray replaceObjectAtIndex:0 withObject:pe2];*/
    
    [reflectedElementArray removeObjectAtIndex:0];
    [elementArray addObjectsFromArray:reflectedElementArray];
    [subPath setPathElements:elementArray];
    [subPath setIsClosed:YES];
    
    NSMutableArray *a = [NSMutableArray array];
    [a addObject:subPath];
    for (int i = 1; i < [[g subPaths]count];i++)
    {
        ACSDSubPath *sp = [g subPaths][i];
        [a addObject:[[sp copy]autorelease]];
        subPath = [[sp copy]autorelease];
        [subPath applyTransform:transform];
        [subPath reverse];
        [a addObject:subPath];
    }

    if ([sender keyEquivalentModifierMask] & NSAlternateKeyMask)
	   {
           [self clearSelection];
           [[[self currentEditableLayer] graphics] addObject:g];
           [self selectGraphic:g];
       }
    else
        [g invalidateInView];
    [g setSubPathsAndRebuild:a];
    [[NSNotificationCenter defaultCenter]postNotificationName:ACSDGraphicListChanged object:self];
    [[self undoManager] setActionName:@"Reflect & Join"];
}

- (void)reflect:(id)sender
{
    NSArray *arr = [[self selectedGraphics]allObjects];
    if ([arr count] != 1)
        return;
    ACSDPath *g;
    if ([sender keyEquivalentModifierMask] & NSAlternateKeyMask)
        g = [[[arr objectAtIndex:0]copy]autorelease];
    else
        g = [arr objectAtIndex:0];
//    if ([[g subPaths]count] != 1)
  //      return;
    ACSDSubPath *subPath = [[[[g subPaths]objectAtIndex:0]copy]autorelease];
    NSMutableArray *elementArray = [subPath pathElements];
    if ([elementArray count] < 2)
        return;
    ACSDPathElement *firstPoint = [elementArray objectAtIndex:0];
    ACSDPathElement *lastPoint = [elementArray objectAtIndex:[elementArray count]-1];
    NSAffineTransform *transform = [NSAffineTransform transformWithTranslateXBy:-[firstPoint point].x yBy:-[firstPoint point].y];
    float angle = getAngleForPoints([firstPoint point],[lastPoint point]);
    [transform appendTransform:[NSAffineTransform transformWithRotationByDegrees:-angle]];
    [transform appendTransform:[NSAffineTransform transformWithScaleXBy:1.0 yBy:-1.0]];
    [transform appendTransform:[NSAffineTransform transformWithRotationByDegrees:angle]];
    [transform appendTransform:[NSAffineTransform transformWithTranslateXBy:[firstPoint point].x yBy:[firstPoint point].y]];
    
    NSMutableArray *a = [NSMutableArray array];
    for (ACSDSubPath *sp in [g subPaths])
    {
        subPath = [[sp copy]autorelease];
        [subPath applyTransform:transform];
        [a addObject:subPath];
    }
    if ([sender keyEquivalentModifierMask] & NSAlternateKeyMask)
    {
        [self clearSelection];
        [[[self currentEditableLayer] graphics] addObject:g];
        [self selectGraphic:g];
    }
    else
        [g invalidateInView];
    [g setSubPathsAndRebuild:a];
    [[NSNotificationCenter defaultCenter]postNotificationName:ACSDGraphicListChanged object:self];
    [[self undoManager] setActionName:@"Reflect"];
}

- (void)aMinusB:(id)sender
   {
	NSArray *arr = [self selectedGraphicsSortedByTimestamp];
	if ([arr count] < 2)
		return;
	NSMutableArray *pathArray = [self subPathsFromSelectedObjects:arr];
	if (!pathArray)
		return;
	NSMutableArray *subPaths = [[ACSDPath aNotBSubPathsFromObjects:pathArray]subPaths];
	ACSDGraphic *modelObject = [[arr objectAtIndex:0]retain];
	if (!([sender keyEquivalentModifierMask] & NSAlternateKeyMask))
		[self deleteSelectedGraphics];
	[self insertNewGraphicFromSubPaths:subPaths modelObject:modelObject];
	[modelObject release];
	[[self undoManager] setActionName:[sender title]];
   }

- (void)intersect:(id)sender
   {
	NSArray *arr = [self sortedSelectedGraphics];
	if ([arr count] < 2)
		return;
	NSMutableArray *pathArray = [self subPathsFromSelectedObjects:arr];
	if (!pathArray)
		return;
	NSMutableArray *subPaths = [[ACSDPath intersectedSubPathsFromObjects:pathArray]subPaths];
	ACSDGraphic *modelObject = [[arr objectAtIndex:0]retain];
	if (!([sender keyEquivalentModifierMask] & NSAlternateKeyMask))
		[self deleteSelectedGraphics];
	[self insertNewGraphicFromSubPaths:subPaths modelObject:modelObject];
	[modelObject release];
	[[self undoManager] setActionName:[sender title]];
   }

- (void)unite:(id)sender
   {
	NSArray *arr = [self sortedSelectedGraphics];
	if ([arr count] < 2)
		return;
	NSMutableArray *pathArray = [self subPathsFromSelectedObjects:arr];		//array of graphics, converted to paths if necessary
	if (!pathArray)
		return;
	NSMutableArray *subPaths = [[ACSDPath unionSubPathsFromObjects:pathArray]subPaths];
	ACSDGraphic *modelObject = [[arr objectAtIndex:0]retain];
	if (!([sender keyEquivalentModifierMask] & NSAlternateKeyMask))
		[self deleteSelectedGraphics];
	[self insertNewGraphicFromSubPaths:subPaths modelObject:modelObject];
	[modelObject release];
	[[self undoManager] setActionName:[sender title]];
   }

- (void)aXorB:(id)sender
   {
	NSArray *arr = [self sortedSelectedGraphics];
	if ([arr count] < 2)
		return;
	NSMutableArray *pathArray = [self subPathsFromSelectedObjects:arr];
	if (!pathArray)
		return;
	NSMutableArray *subPaths = [[ACSDPath xorSubPathsFromObjects:pathArray]subPaths];
	ACSDGraphic *modelObject = [[arr objectAtIndex:0]retain];
	if (!([sender keyEquivalentModifierMask] & NSAlternateKeyMask))
		[self deleteSelectedGraphics];
	[self insertNewGraphicFromSubPaths:subPaths modelObject:modelObject];
	[modelObject release];
	[[self undoManager] setActionName:[sender title]];
   }

- (void)setMask:(id)sender
   {
	NSArray *arr = [self sortedSelectedGraphics];
	BOOL mask = ![[arr objectAtIndex:0]isMask];
	[arr makeObjectsPerformSelector:@selector(setGraphicMaskObj:)withObject:[NSNumber numberWithBool:mask]];
   }

- (BOOL)validateMenuItem:(id)menuItem
{
	SEL action = [menuItem action];
	if (action == @selector(cut:)||action == @selector(copy:)||action == @selector(copyLocations:)||action == @selector(duplicate:)||action == @selector(clear:)||
		action == @selector(bringToFront:)||action == @selector(sendToBack:)||action == @selector(bringForward:)||action == @selector(sendBackward:)||
		action == @selector(flipHorizontal:)||action == @selector(flipHorizontalCopy:)||action == @selector(flipVertical:)||action == @selector(flipVerticalCopy:)||
		action == @selector(definePattern:)||action == @selector(defineLineEnding:)||action == @selector(resetScale:)||action == @selector(moveToOrigin:) ||
        action == @selector(centreHorizontally:)||action == @selector(centreVertically:))
		return [[self selectedGraphics] count] > 0;
	if (action == @selector(alignLeftEdges:)||action == @selector(alignRightEdges:)||action == @selector(alignTopEdges:)||action == @selector(alignBottomEdges:)||
		action == @selector(alignVerticalCentres:)||action == @selector(alignHorizontalCentres:)||action == @selector(bringForward:)||action == @selector(sendBackward:))
		return [[self selectedGraphics] count] > 1;
	if (action == @selector(distributeVertically:)||action == @selector(distributeHorizontally:))
		return [[self selectedGraphics] count] > 2;
	if (action == @selector(ungroup:))
		return ([[self selectedGraphics] count] > 0 && [[[self selectedGraphics]anyObject]isKindOfClass:[ACSDGroup class]]);
	if (action == @selector(cropRoundCentroid:))
		return ([[self selectedGraphics] count] == 1 && [[[self selectedGraphics]anyObject]respondsToSelector:@selector(centroid)]);
    if (action == @selector(convertToPath:) || action == @selector(reloadImage:) || action == @selector(group:))
		return [[self selectedGraphics] count] >= 1;
	if (action == @selector(intersect:))
		return [[self selectedGraphics] count] >= 1;
	if (action == @selector(applyImageTransform:))
		return [[self selectedGraphics] count] >= 1;
	if (action == @selector(decompose:) || action == @selector(decomposeCopy:))
		return [[self selectedGraphics] count] >= 1;
    if (action == @selector(showLink:))
        return [[self selectedGraphics] count] == 1 && ([[[[self selectedGraphics]allObjects]objectAtIndex:0]link]!=nil);
    if (action == @selector(removeLink:))
        return [[self selectedGraphics] count] > 0 && ([[[[self selectedGraphics]allObjects]objectAtIndex:0]link]!=nil);
    if (action == @selector(reflectAndJoin:) || action == @selector(reflect:))
	{
		if ([[self selectedGraphics] count] != 1)
			return NO;
		ACSDGraphic *g = [[[self selectedGraphics]allObjects]objectAtIndex:0];
		if (![g isKindOfClass:[ACSDPath class]])
			return NO;
		return YES;
	}
	if (action == @selector(cropToRectangle:))
	{
		return [[self selectedGraphics]count] > 0;
	}
	if (action == @selector(closePath:)||action == @selector(openPath:))
	{
		NSArray *arr = [[self selectedGraphics]allObjects];
		return [arr count] > 0 && [arr allObjectsAreKindOfClass:[ACSDPath class]];
	}
	if (action == @selector(connectPaths:)||action == @selector(joinPaths:))
	{
		NSArray *arr = [[self selectedGraphics]allObjects];
		return [arr count] > 1 && [arr allObjectsAreKindOfClass:[ACSDPath class]];
	}
	if (action == @selector(mergePoints:))
	{
		if ([[self selectedGraphics] count] != 1)
			return NO;
		return [[[[self selectedGraphics]allObjects]objectAtIndex:0]graphicCanMergePoints];
	}
	if (action == @selector(applyTransform:))
	{
		if ([[self selectedGraphics] count] >= 1)
			return YES;
		return NO;
	}
	if (action == @selector(reversePath:))
	{
		NSArray *arr = [[self selectedGraphics]allObjects];
		return [arr count] > 0 && [arr allObjectsAreKindOfClass:[ACSDPath class]];
	}
	if (action == @selector(outlineStroke:))
	{
		if ([[self selectedGraphics] count] < 1)
			return NO;
	}
	if (action == @selector(repeatAction:))
	{
		[menuItem setTitle:[self repeatString]];
		return [repeatQueue count] > 0;
	}
	if (action == @selector(combinePaths:))
	{
		NSArray *arr = [[self selectedGraphics]allObjects];
		NSInteger ct = [arr count];
		if (ct < 2)
			return NO;
		return YES;
	}
	if (action == @selector(setGraphicModeNormal:))
	{
		NSArray *arr = [[self selectedGraphics]allObjects];
		NSInteger ct = [arr count];
		if (ct == 1)
		{
			ACSDGraphic *g = [arr objectAtIndex:0];
			if ([g graphicMode] == GRAPHIC_MODE_NORMAL)
			{
				if ([(NSMenuItem*)menuItem state]!= NSOnState)
					[menuItem setState:NSOnState];
			}
			else
				if ([(NSMenuItem*)menuItem state]!= NSOffState)
					[menuItem setState:NSOffState];
		}
		else if (ct == 0)
		{
			if ([(NSMenuItem*)menuItem state]!= NSOffState)
				[menuItem setState:NSOffState];
		}
		else
			[menuItem setState:NSMixedState];
		return YES;
	}
	if (action == @selector(setGraphicModeOutline:))
	{
		NSArray *arr = [[self selectedGraphics]allObjects];
		NSInteger ct = [arr count];
		if (ct == 1)
		{
			ACSDGraphic *g = [arr objectAtIndex:0];
			if ([g graphicMode] == GRAPHIC_MODE_OUTLINE)
			{
				if ([(NSMenuItem*)menuItem state]!= NSOnState)
					[menuItem setState:NSOnState];
			}
			else
				if ([(NSMenuItem*)menuItem state]!= NSOffState)
					[menuItem setState:NSOffState];
		}
		else if (ct == 0)
		{
			if ([(NSMenuItem*)menuItem state]!= NSOffState)
				[menuItem setState:NSOffState];
		}
		else
			[menuItem setState:NSMixedState];
		return YES;
	}
	if (action == @selector(setMask:))
	{
		if ([[self selectedGraphics] count] < 1)
		{
			[menuItem setState:NSOffState];
			return NO;
		}
		if ([[[self selectedGraphics]allObjects]andMakeObjectsPerformSelector:@selector(canBeMask)])
		{
			if ([[self selectedGraphics] count] == 1)
				[menuItem setState:[[[[self selectedGraphics]allObjects]objectAtIndex:0]isMask]];
			else
			{
				BOOL allOn = YES,allOff = YES;
				NSEnumerator *objEnum = [[self selectedGraphics] objectEnumerator];
				ACSDGraphic *curGraphic;
				while ((curGraphic = [objEnum nextObject]) != nil) 
				{
					if ([curGraphic isMask])
						allOff = NO;
					else
						allOn = NO;
					if (!allOn && !allOff)
					{
						[menuItem setState:NSMixedState];
						return YES;
					}
				}
				if (allOn)
					[menuItem setState:NSOnState];
				else
					[menuItem setState:NSOffState];
			}
			return YES;
		}
		return NO;
	}
	if ((action == @selector(absoluteLink:))||(action == @selector(linkTo:)))
		return ([[self selectedGraphics] count] >= 1);
	if ((action == @selector(showTextLink:))||(action == @selector(removeTextLink:)))
		return [self linkForTextSelection] != nil;
	if (action == @selector(toggleShowSelection:))
	{
		[menuItem setState:(showSelection)?NSOnState:NSOffState];
		return YES;
	}
    if (action == @selector(editPoint:))
    {
        return [[self selectedPathElements]count] == 1;
    }
	return YES;
}

- (BOOL)acceptsFirstResponder
   {
    return YES;
   }

- (void)flagsChanged:(NSEvent *)theEvent
   {
    int selectedTool = [[ToolWindowController sharedToolWindowController:nil] currentTool];
	if ((selectedTool == ACSD_PEN_TOOL) && creatingPath)
	   {
		[creatingPath invalidateInView];
	    NSPoint pt1,pt2=[creatingPath actualAddingPoint];
		if ([theEvent modifierFlags] & NSShiftKeyMask)
		   {
			if ([((ACSDPath*)creatingPath) lastPoint:&pt1])
				restrictTo45(pt1,&pt2);
		   }
		[creatingPath setAddingPoint:pt2];
		[((ACSDPath*)creatingPath) constructAddingPointPath];
		[creatingPath invalidateGraphicSizeChanged:YES shapeChanged:YES redraw:YES notify:NO];
	   }
    [[self window] invalidateCursorRectsForView:self];
   }

- (void)keyUp:(NSEvent *)event
   {
	NSString *str = [event charactersIgnoringModifiers];
	if ([str isEqualToString:@" "])
	   {
	    spaceDown = NO;
		if ([event modifierFlags] & NSAlternateKeyMask)
			[[self window] invalidateCursorRectsForView:self];
	   }
   }

- (void)insertTab:(id)sender
   {
	[(AppDelegate*)[NSApp delegate]hideShowPallettes];
   }

- (void)cropToRectangle:(id)sender
{
	NSRect r = NSZeroRect;
	for (ACSDGraphic *g in [self selectedGraphics])
		r = NSUnionRect(r,[g transformedBounds]);
	if (r.size.width > 0 && r.size.height > 0)
		[[self document]sizeToRect:r];
	[[self undoManager] setActionName:@"Crop To Rectangle"];
}

-(void)cropRoundCentroid:(id)sender
{
    NSArray *arr = [[self selectedGraphics]allObjects];
    if ([arr count] == 1)
    {
        ACSDGraphic *g = arr[0];
        if ([g respondsToSelector:@selector(centroid)])
        {
            NSPoint pt = [(id)g centroid];
            pt.x = round(pt.x);
            pt.y = round(pt.y);
            NSSize sz = [self frame].size;
            CGFloat lx = 0,rx = sz.width,bot = 0,top = sz.height;
            CGFloat diff = sz.width - pt.x;
            if (diff > pt.x)
                lx = pt.x - diff;
            else
                rx = pt.x + pt.x;
            diff = sz.height - pt.y;
            if (diff > pt.y)
                bot = pt.y - diff;
            else
                top = pt.y + pt.y;
            [[self document]sizeToRect:NSMakeRect(lx, bot, rx - lx, top - bot)];
            [[self undoManager] setActionName:@"Crop Around Centroid"];
        }
    }
}

-(IBAction)nextPage:(id)sender
{
    if (currentPageInd < [pages count] - 1)
    {
        [self setCurrentPageIndex:currentPageInd+1 force:NO withUndo:YES];
        [[self undoManager] setActionName:@"Next Page"];
    }
}

-(IBAction)prevPage:(id)sender
{
    if (currentPageInd > 0)
    {
        [self setCurrentPageIndex:currentPageInd-1 force:NO withUndo:YES];
        [[self undoManager] setActionName:@"Previous Page"];
    }
}

- (void)keyDown:(NSEvent *)event
{
	NSString *str = [event charactersIgnoringModifiers];
	if ([str isEqualToString:@" "])
	{
	    spaceDown = YES;
		if ([event modifierFlags] & NSAlternateKeyMask)
			[[self window] invalidateCursorRectsForView:self];
	} 
	else if ([str isEqualToString:@"s"])
		[self toggleShowSelection:self];
	else if ([str isEqualToString:@"n"])
		[self nextPage:self];
	else if ([str isEqualToString:@"b"])
		[self prevPage:self];
    else if ([str isEqualToString:@"d"])
        [self toggleShowPathDirection:self];
    else if ([str isEqualToString:@"§"])
        [[ToolWindowController sharedToolWindowController:nil] selectLastTool];
	else
		[self interpretKeyEvents:[NSArray arrayWithObject:event]];
}

- (void)pageUp:(id)sender
   {
	if (currentPageInd > 0)
		[self setCurrentPageIndex:currentPageInd-1 force:NO withUndo:YES];
   }

- (void)pageDown:(id)sender
   {
	if ((unsigned)currentPageInd < ([pages count] - 1))
		[self setCurrentPageIndex:currentPageInd+1 force:NO withUndo:YES];
   }

-(void)insertNewline:(id)sender
{
    NSArray *selectedArray = [self sortedSelectedGraphics];
    NSInteger ct = [selectedArray count];
    if (ct != 1)
        return;
    ACSDGraphic *graphic = [selectedArray objectAtIndex:0];
   if (graphic && [graphic isEditable])
   {
       [self startEditingGraphic:graphic withEvent:nil];
       return;
   }
}
- (void)backgroundChanged:(id)sender
  {
	[self setNeedsDisplay:YES];
   }

- (void)cancelOp:(id)sender
{
	if (cursorMode == GV_MODE_DOING_LINK)
	{
		cursorMode = GV_MODE_NONE;
		[[self document] setLinkGraphics:nil];
		[[self document] setLinkRanges:nil];
		[highLightLayer highLightObject:nil modifiers:0];
		[[self window] invalidateCursorRectsForView:self];
		[self setNeedsDisplay];
	}
	else if (creatingGraphic)
		[creatingGraphic setOpCancelled:YES];
	else if (trackingGraphic)
		[trackingGraphic setOpCancelled:YES];
	else if (creatingPath)
	{
		[creatingPath setAddingPoints:NO];
		[creatingPath invalidateInView];
		[self setCreatingPath:nil];
		[[NSNotificationCenter defaultCenter] postNotificationName:ACSDShowCoordinatesNotification object:self
														  userInfo:[NSDictionary dictionaryWithObject:[NSNumber numberWithBool:NO] forKey:@"vis"]];
	}
	else if (cursorMode == GV_MODE_LINKING_TEXT_BLOCKS)
	{
		cursorMode = GV_MODE_NONE;
		linkingTextBlock = nil;
		[[self window] invalidateCursorRectsForView:self];
	}
	else if (editingGraphic)
		[self endEditing];
	else if ([[ToolWindowController sharedToolWindowController:nil] currentTool])
		[[ToolWindowController sharedToolWindowController:nil] selectArrowTool];
}


- (void)cancelOperation:(id)sender
   {
	[[NSNotificationCenter defaultCenter]postNotificationName:ACSDCancelOpNotification object:[self document]];
   }

- (BOOL)knowsPageRange:(NSRangePointer)range
   {
    range->location = 1;
    range->length = [pages count];
    return YES;
   }

- (NSRect)rectForPage:(NSInteger)page
   {
    NSPrintInfo *printInfo = [[self document] printInfo];
	NSSize pSize = [printInfo paperSize];
	pSize.height -= ([printInfo topMargin] + [printInfo bottomMargin]);
	pSize.width -= ([printInfo leftMargin] + [printInfo rightMargin]);
	if ([self bounds].size.height > pSize.height || [self bounds].size.width > pSize.width)
	   {
		NSRect r = [self bounds];
		r.size = pSize;
		return r;
	   }
	else
		return [self bounds];
   }

-(void)createPatternWindowForSelectedGraphics
   {
	ACSDGraphic *g;
	NSArray *selectedArray = [self sortedSelectedGraphics];
	NSInteger ct = [selectedArray count];
	if (ct == 0)
		return;
	if (ct == 1)
		g = [[[selectedArray objectAtIndex:0]copy]autorelease];
	else
	   {
		NSMutableArray *arr = [NSMutableArray arrayWithCapacity:ct];
		for (int i = 0;i < ct;i++)
			[arr addObject:[[[selectedArray objectAtIndex:i]copy]autorelease]];
		g = [[[ACSDGroup alloc]initWithName:@"patgroup" graphics:arr layer:nil]autorelease];
	   }
	[[self document]createPatternWindowWithPattern:[ACSDPattern patternWithGraphic:g]isNew:YES];
	[[NSNotificationCenter defaultCenter] postNotificationName:ACSDFillAdded object:self];
   }

-(void)createLineEndingWindowForSelectedGraphics
   {
	ACSDGraphic *g;
	NSArray *selectedArray = [self sortedSelectedGraphics];
	NSInteger ct = [selectedArray count];
	if (ct == 0)
		return;
	if (ct == 1)
		g = [[selectedArray objectAtIndex:0]copy];
	else
	   {
		NSMutableArray *arr = [NSMutableArray arrayWithCapacity:ct];
		for (int i = 0;i < ct;i++)
			[arr addObject:[[[selectedArray objectAtIndex:i]copy]autorelease]];
		g = [[ACSDGroup alloc]initWithName:@"legroup" graphics:arr layer:nil];
	   }
	NSRect b = [g bounds];
	float sc = 4.0 / b.size.height;
	NSPoint centralPoint = b.origin;
	centralPoint.x = -(centralPoint.x + b.size.width / 2);
	centralPoint.y = -(centralPoint.y + b.size.height / 2);
	[g moveBy:centralPoint];
	[[self document]createLineEndingWindowWithLineEnding:[ACSDLineEnding lineEndingWithGraphic:g scale:sc aspect:1.0 offset:0]isNew:YES];
	[[NSNotificationCenter defaultCenter] postNotificationName:ACSDRefreshLineEndingsNotification object:self];
   }

- (void)defineLineEnding:(id)sender
   {
	[self createLineEndingWindowForSelectedGraphics];
   }

- (void)definePattern:(id)sender
   {
	[self createPatternWindowForSelectedGraphics];
   }

- (BOOL)rulerView:(NSRulerView *)aRulerView shouldMoveMarker:(NSRulerMarker *)aMarker
   {
	if ([[[self window]windowController]respondsToSelector:@selector(rulerView:shouldMoveMarker:)])
		return [(id)[[self window]windowController] rulerView:aRulerView shouldMoveMarker:aMarker];
	return YES;
   }

- (BOOL)rulerView:(NSRulerView *)aRulerView shouldRemoveMarker:(NSRulerMarker *)aMarker
   {
	if ([[[self window]windowController]respondsToSelector:@selector(rulerView:shouldMoveMarker:)])
		return [(id)[[self window]windowController] rulerView:aRulerView shouldMoveMarker:aMarker];
	return NO;
   }

- (void)rulerView:(NSRulerView *)aRulerView didMoveMarker:(NSRulerMarker *)aMarker
   {
	if ([[[self window]windowController]respondsToSelector:@selector(rulerView:didMoveMarker:)])
		 [(id)[[self window]windowController] rulerView:aRulerView didMoveMarker:aMarker];
   }	

-(BOOL)recursionForObject:(id)obj
   {
	if ([[[self window]windowController]respondsToSelector:@selector(representedObject)])
		return [(id)[[self window]windowController] representedObject] == obj;
	return NO;
   }

-(void)updateForStyle:(id)style oldAttributes:(NSDictionary*)oldAttrs
   {
	[pages makeObjectsPerformSelector:@selector(updateForStyle:oldAttributes:)withObject:style andObject:oldAttrs];
	if (editingGraphic && editor)
		[editor setTypingAttributes:[style textAndStyleAttributes]];
   }

-(NSImage*)imageFromCurrentPageOfSize:(NSSize)sz
{
	NSBitmapImageRep *bm = newBitmap(sz.width,sz.height);
	NSImage *im = [[[NSImage alloc]initWithSize:sz]autorelease];
	[im addRepresentation:bm];
	[im lockFocusFlipped:YES];
	NSRect b = [self bounds];
	[[NSAffineTransform transformWithScaleXBy:  sz.width/b.size.width yBy: sz.height/b.size.height]concat];
	[[NSAffineTransform transformWithTranslateXBy:0 yBy:b.size.height]concat];
	[[NSAffineTransform transformWithScaleXBy:1.0 yBy:-1.0]concat];
	[self drawPage:[self currentPage] rect:b drawingToScreen:NO drawMarkers:NO
			 drawingToPDF:nil substitutions:[NSMutableDictionary dictionaryWithCapacity:5]
                  options:[NSDictionary dictionaryWithObject:[NSNumber numberWithFloat:sz.width/b.size.width] forKey:@"overrideScale"]];
	[im unlockFocus];
	return im;
}

-(IBAction)copyScreen:(id)sender
{
    NSImage *im = [self imageFromCurrentPageOfSize:[self bounds].size];
    NSPasteboard *pb = [NSPasteboard generalPasteboard];
	[pb clearContents];
    [pb writeObjects:@[im]];
    AppDelegate *appdel = [NSApp delegate];
    [appdel.copiedScreens removeAllObjects];
    [appdel.copiedScreens addObject:im];
}

-(IBAction)copyScreenAppend:(id)sender
{
    NSImage *im = [self imageFromCurrentPageOfSize:[self bounds].size];
    AppDelegate *appdel = [NSApp delegate];
    [appdel.copiedScreens addObject:im];
    NSPasteboard *pb = [NSPasteboard generalPasteboard];
	[pb clearContents];
    [pb writeObjects:appdel.copiedScreens];
}


static NSString *IncrementStringLowHigh(NSString *str,unichar lochar,unichar hichar)
{
    unichar uc = [str characterAtIndex:[str length] - 1];
    if (uc >= lochar && uc <= hichar)
    {
        if (uc < hichar)
        {
            uc++;
            return [NSString stringWithFormat:@"%@%C",[str substringToIndex:[str length] - 1],uc];
        }
        else
        {
            return [str stringByAppendingString:[NSString stringWithFormat:@"%C",lochar]];
        }
    }
    return str;
}

NSString *IncrementString(NSString *str)
{
    if ([str length] == 0)
        return str;
    unichar uc = [str characterAtIndex:[str length] - 1];
    if (uc >= '0' && uc <= '9')
        return IncrementStringLowHigh(str,'0','9');
    if (uc >= 'a' && uc <= 'z')
        return IncrementStringLowHigh(str,'a','z');
    if (uc >= 'A' && uc <= 'Z')
        return IncrementStringLowHigh(str,'A','Z');
    return str;
}

-(int)renameGraphics:(NSArray*)grphs usingRegularExpression:(NSRegularExpression*)regexp template:(NSString*)templateString
{
	int numberDone = 0;
	for (ACSDGraphic *g in grphs)
	{
		NSString *nm = [g name];
		if ([regexp numberOfMatchesInString:nm options:0 range:NSMakeRange(0, [nm length])])
		{
			NSString *outstr = [regexp stringByReplacingMatchesInString:nm options:0 range:NSMakeRange(0, [nm length]) withTemplate:templateString];
			[g setGraphicName:outstr];
			numberDone++;
		}
		
	}
	if (numberDone > 0)
		[[self undoManager]setActionName:@"Rename"];
	return numberDone;
}

-(int)renameSelectedGraphicsUsingRegularExpression:(NSRegularExpression*)regexp template:(NSString*)templateString
{
    NSArray<ACSDGraphic*> *selGraphics = [[self selectedGraphics]allObjects];
    return [self renameGraphics:selGraphics usingRegularExpression:regexp template:templateString];
}

-(void)renameSelectedGraphicsUsingParams:(NSMutableArray*)params startA:(NSString*)starta startN:(int)startN orderBy:(int)orderBy rowAscending:(BOOL)rowAscending colAscending:(BOOL)colAscending
{
    NSArray *selGraphics;
    rowAscending = !rowAscending;
    if (orderBy == 1)
        selGraphics = [self selectedGraphicsSortedByRowColumnRowFirst:YES rowAsc:rowAscending colAsc:colAscending];
    else if (orderBy == 2)
        selGraphics = [self selectedGraphicsSortedByRowColumnRowFirst:NO rowAsc:rowAscending colAsc:colAscending];
    else
        selGraphics = [self selectedGraphicsSortedByTimestamp];
    
    if ([selGraphics count] == 0)
        return;
    for (int i = 0;i < [params count];i++)
    {
        if ([params[i] isKindOfClass:[NSArray class]])
        {
            NSArray *pars = params[i];
            if ([(NSString*)pars[0] isEqualToString:@"a"])
                [params replaceObjectAtIndex:i withObject:@[pars[0],starta]];
            else if ([(NSString*)pars[0] isEqualToString:@"n"])
                [params replaceObjectAtIndex:i withObject:@[pars[0],@(startN)]];
        }
    }
    for (ACSDGraphic *g in selGraphics)
    {
        NSMutableString *currentName = [NSMutableString string];
        for (int i = 0;i < [params count];i++)
        {
            if ([params[i] isKindOfClass:[NSArray class]])
            {
                NSArray *pars = params[i];
                if ([(NSString*)pars[0] isEqualToString:@"a"])
                {
                    NSString *s = pars[1];
                    [currentName appendString:s];
                    [params replaceObjectAtIndex:i withObject:@[pars[0],IncrementString(s)]];
                }
                else if ([(NSString*)pars[0] isEqualToString:@"n"])
                {
                    int n = [pars[1]intValue];
                    [currentName appendFormat:@"%d",n];
                    [params replaceObjectAtIndex:i withObject:@[pars[0],@(n+1)]];
                }
            }
            else
                [currentName appendString:params[i]];
        }
        [g setGraphicName:currentName];
     }
}

@end
