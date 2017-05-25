#import "PagesPanelController.h"
#import "GraphicView.h"
#import "ACSDGraphic.h"
#import "ACSDPage.h"
#import "ACSDLayer.h"
#import "SelCell.h"
#import "LayerTableView.h"
#import "DragView.h"
#import "PanelCoordinator.h"

//NSString *ACSDrawLayerPasteboardType = @"ACSDrawLayer";
//NSString *ACSDrawLayerIntPasteboardType = @"ACSDrawLayerInt";
//NSString *ACSDrawLayerSelPasteboardType = @"ACSDrawLayerSel";
//NSString *ACSDrawPageIntPasteboardType = @"ACSDrawPageInt";

PagesPanelController *_sharedPagesPanelController = nil;

@implementation PagesPanelController

+ (id)sharedPagesPanelController
{
	if (!_sharedPagesPanelController)
		[PanelCoordinator sharedPanelCoordinator];
    return _sharedPagesPanelController;
}

- (void)dealloc
{
    [self setLayerList:nil];
    [self setPageList:nil];
	[[NSNotificationCenter defaultCenter] removeObserver:self];
    [super dealloc];
}

- (IBAction)inactiveCBHit:(id)sender
{
	[[self inspectingGraphicView]setPageInactive:[sender intValue]];
}

- (IBAction)masterCBHit:(id)sender
{
	[[self inspectingGraphicView]setPageType:[sender intValue]];
}

- (IBAction)masterTypeRBHit:(id)sender
{
	[[self inspectingGraphicView]setMasterType:(int)[sender selectedRow]];
}

- (IBAction)useMasterRBHit:(id)sender
{
	[[self inspectingGraphicView]setUseMaster:(int)[sender selectedRow]];
}

- (IBAction)layerPlusHit:(id)sender
{
	if (layerList)
	   {
	    NSInteger row = [layerTableView selectedRow];
		if (row >= 0)
		{
			row++;
			[[self inspectingGraphicView] addNewLayerAtIndex:row];
			[layerTableView reloadData];
			[layerTableView selectRow:row byExtendingSelection:NO];
		}
	   }
}

- (void)setLayerList:(NSMutableArray*)f
{
	if (layerList)
		[layerList autorelease];
	if (f)
		layerList = [f retain];
	else
		layerList = nil;
	[[layerTableView dataSource]setLayerList:f];
}

- (void)setPageList:(NSMutableArray*)f
{
	if (pageList)
		[pageList autorelease];
	if (f)
		pageList = [f retain];
	else
		pageList = nil;
	[[pageTableView dataSource]setPageList:f];
}

- (void)zeroControls
{
	[layerTableView setAllowsEmptySelection:YES];
	[pageTableView setAllowsEmptySelection:YES];
	[self setPageList:nil];
	[pageTableView selectRowIndexes:[NSIndexSet indexSet] byExtendingSelection:NO];
	[pageTableView reloadData];
	[self setLayerList:nil];
	[layerTableView selectRowIndexes:[NSIndexSet indexSet] byExtendingSelection:NO];
	[layerTableView reloadData];
	[[masterListTableView enclosingScrollView] setHidden:YES];
	[pageType setIntValue:0];
	[pageType setEnabled:NO];
	[useMasterRB setHidden:YES];
	[masterTypeRB setHidden:YES];
	[pageTitle setEnabled:NO];
	[backgroundColour setEnabled:NO];
}

-(void)refreshLayers:(NSNotification *)notification
{
	if (![self inspectingGraphicView])
		return;
	[self setActionsDisabled:YES];
	[layerTableView selectRowIndexes:[NSIndexSet indexSetWithIndex:[[[self inspectingGraphicView] currentPage]currentLayerInd]] byExtendingSelection:NO];
	[layerTableView reloadData];
	[self setActionsDisabled:NO];
}

-(void)refreshLayerSelection:(NSNotification *)notification
{
	if (![self inspectingGraphicView])
		return;
    NSArray *arr = [[notification userInfo]objectForKey:@"layers"];
	if ((arr == nil) || ([arr count] == 0))
	   {
		[layerTableView reloadData];
		return;
	   }
	for (id el in arr)
		[layerTableView reDisplayRow:[el intValue] column:SELECTION_COLUMN];
}

- (BOOL)handleClickAtPoint:(NSPoint)pt inTableView:(NSTableView*)tableView
{
	if (tableView != layerTableView)
		return NO;
	NSInteger col = [tableView columnAtPoint:pt];
	if (col < 0 || col > 1)
		return NO;
	NSInteger row = [tableView rowAtPoint:pt];
	if (row < 0 || row >= (int)[layerList count])
		return NO;
	ACSDLayer *l = [layerList objectAtIndex:row];
	NSString *actionName = nil;
	if (col == 0)
	{
		if ([l visible])
			actionName = [NSString stringWithFormat:@"Hide %@",[l name]];
		else
			actionName = [NSString stringWithFormat:@"Show %@",[l name]];
		[[self inspectingGraphicView]toggleVisibilityForLayer:l];
		[[[self inspectingGraphicView] undoManager] setActionName:actionName];
	}
	else if (col == 1)
	{
		if ([l editable])
			actionName = [NSString stringWithFormat:@"Lock %@",[l name]];
		else
			actionName = [NSString stringWithFormat:@"Unlock %@",[l name]];
		[[self inspectingGraphicView]toggleLockingForLayer:l];
		[[[self inspectingGraphicView] undoManager] setActionName:actionName];
	}
	return YES;
}

-(void)awakeFromNib
{
	[super awakeFromNib];
	rowForContextualMenu = -1;
	displayRowForContextualMenu = -1;
	NSCell *cell = [[[pageTableView tableColumns]objectAtIndex:0] dataCell];
	if (cell)
	{
		NSFont *font = [cell font];
		if (font == nil)
			font = [NSFont systemFontOfSize:[NSFont smallSystemFontSize]];
		[cell setFont:[[NSFontManager sharedFontManager]convertFont:font toSize:[NSFont smallSystemFontSize]]];
		[pageTableView setRowHeight:[NSFont smallSystemFontSize] * 1.2];
	}
	[[[layerTableView tableColumns]objectAtIndex:3] setDataCell:[[[SelCell alloc]init]autorelease]];
	NSButtonCell *bc = [[NSButtonCell alloc]init];
	[bc setButtonType:NSToggleButton];
	[bc setImage:[NSImage imageNamed:@"eye2"]];
	[bc setAlternateImage:[NSImage imageNamed:@"eye"]];
	[bc setAction:@selector(showHideLayer:)];
	[bc setTarget:self];
	[[[layerTableView tableColumns]objectAtIndex:0] setDataCell:[bc autorelease]];
	bc = [[NSButtonCell alloc]init];
	[bc setButtonType:NSToggleButton];
	[bc setImage:[NSImage imageNamed:@"lock2"]];
	[bc setAlternateImage:[NSImage imageNamed:@"lock"]];
	[[[layerTableView tableColumns]objectAtIndex:1] setDataCell:[bc autorelease]];
	cell = [[[layerTableView tableColumns]objectAtIndex:2] dataCell];
	if (cell)
	{
		NSFont *font = [cell font];
		if (font == nil)
			font = [NSFont systemFontOfSize:[NSFont smallSystemFontSize]];
		[cell setFont:[[NSFontManager sharedFontManager]convertFont:font toSize:[NSFont smallSystemFontSize]]];
	}
	[pageTableView registerForDraggedTypes:[NSArray arrayWithObjects:ACSDrawPageIntPasteboardType,nil]];
	[layerTableView registerForDraggedTypes:[NSArray arrayWithObjects:ACSDrawLayerIntPasteboardType,nil]];
	[layerTableView registerForDraggedTypes:[NSArray arrayWithObjects:ACSDrawLayerSelPasteboardType,nil]];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(pageChanged:) name:ACSDPageChanged object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(refreshLayerSelection:) name:ACSDLayerSelectionChanged object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(refreshLayerSelection:) name:ACSDGraphicViewSelectionDidChangeNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(refreshLayers:) name:ACSDCurrentLayerChanged object:nil];
}

- (void)pageChanged:(NSNotification *)notification				//page changed by graphicView
{
	if (![self inspectingGraphicView])
		return;
	[self setActionsDisabled:YES];
	NSInteger pageInd = [[self inspectingGraphicView] currentPageInd];
	[pageTableView selectRowIndexes:[NSIndexSet indexSetWithIndex:pageInd] byExtendingSelection:NO];
	[pageTableView reloadData];
	[self setControlsForPage];
	[self setLayerList:[[[self inspectingGraphicView] currentPage]layers]];
	[layerTableView selectRowIndexes:[NSIndexSet indexSetWithIndex:[[[self inspectingGraphicView] currentPage]currentLayerInd]] byExtendingSelection:NO];
	[layerTableView reloadData];
	[self setActionsDisabled:NO];
}

- (void)pageTableSelectionChange:(NSInteger)row
{
	if (![self inspectingGraphicView])
		return;
	[[self inspectingGraphicView] setCurrentPageIndex:row force:NO withUndo:YES];
//	[self setControlsForPage];
//	[self setLayerList:[[[self inspectingGraphicView] currentPage]layers]];
//	[layerTableView selectRowIndexes:[NSIndexSet indexSetWithIndex:[[self inspectingGraphicView] currentLayerInd]] byExtendingSelection:NO];
//	[layerTableView reloadData];
//	[[self inspectingGraphicView] setNeedsDisplay:YES];
}

- (void)layerTableSelectionChange:(NSInteger)row
{
	if (![self inspectingGraphicView])
		return;
	[[self inspectingGraphicView] setCurrentEditableLayerIndex:row force:NO select:YES withUndo:YES];
}

- (IBAction)layerMinusHit:(id)sender
{
	if (layerList && ([layerList count] > 1))
	   {
	    NSInteger row = [layerTableView selectedRow];
		if (row >= 0)
		{
			[[self inspectingGraphicView] deleteCurrentLayer];
			[layerTableView reloadData];
			//			[pageTableView selectRow:row byExtendingSelection:NO];
		}
	   }
}

- (IBAction)pagePlusHit:(id)sender
{
	if (pageList)
	   {
	    NSInteger row = [pageTableView selectedRow];
		if (row >= 0)
		{
			row++;
			[[self inspectingGraphicView] addNewPageAtIndex:row];
			[pageTableView reloadData];
			[pageTableView selectRow:row byExtendingSelection:NO];
		}
	   }
}

- (IBAction)pageMinusHit:(id)sender
{
	if (pageList && ([pageList count] > 1))
	   {
	    NSInteger row = [pageTableView selectedRow];
		if (row >= 0)
		{
			[[self inspectingGraphicView] deleteCurrentPage];
			[pageTableView reloadData];
//			[pageTableView selectRow:row byExtendingSelection:NO];
		}
	   }
}

-(void)setGraphicControls
{
	[self setControlsForLayers:[[[self inspectingGraphicView] currentPage]currentLayerInd]];
	[layerTableView setAllowsEmptySelection:NO];
}

-(void)setDocumentControls:(ACSDrawDocument*)doc
{
	[self setPageList:[inspectingGraphicView pages]];
	[self setLayerList:[[inspectingGraphicView currentPage]layers]];
	[self setControlsForPage];
}


-(void)setControls
{
	[self setControlsForPage];
//	[pageTableView selectRowIndexes:[NSIndexSet indexSetWithIndex:[[self inspectingGraphicView] currentPageInd]] byExtendingSelection:NO];
	[pageTableView setAllowsEmptySelection:NO];
//	[layerTableView selectRowIndexes:[NSIndexSet indexSetWithIndex:[[[self inspectingGraphicView] currentPage]currentLayerInd]] byExtendingSelection:NO];
	[self setControlsForLayers:[[[self inspectingGraphicView] currentPage]currentLayerInd]];
	[layerTableView setAllowsEmptySelection:NO];
}

- (void)setControlsForLayers:(NSInteger)layerInd
{
	NSInteger oldSel = [layerTableView selectedRow];
	if (oldSel != layerInd)
	   {
		[layerTableView selectRow:layerInd byExtendingSelection:NO];
		[layerTableView refreshSelectionIndicatorForRow:oldSel];
	   }
	[layerTableView refreshSelectionIndicatorForRow:layerInd];
}

- (void)setControlsForPage
{
	ACSDPage *currentPage = [[self inspectingGraphicView] currentPage];
	if (!currentPage)
		return;
	[pageTableView selectRowIndexes:[NSIndexSet indexSetWithIndex:[[self inspectingGraphicView] currentPageInd]] byExtendingSelection:NO];
	[pageTableView scrollRowToVisible:[[self inspectingGraphicView] currentPageInd]];
//	[self setControlsForLayers:[currentPage currentLayerInd]];	
	[pageType setEnabled:YES];
	[pageType setIntValue:[currentPage pageType]];
	[inactiveCB setEnabled:YES];
	[inactiveCB setIntValue:[currentPage inactive]];
	[useMasterTitle setHidden:NO];
	[useMasterRB setHidden:NO];
	[masterTypeRB setHidden:([currentPage pageType] != PAGE_TYPE_MASTER)];
	[masterTypeRB selectCellAtRow:[currentPage masterType] column:0];
	[useMasterRB selectCellAtRow:[currentPage useMasterType] column:0];
	[[masterListTableView enclosingScrollView] setHidden:([useMasterRB intValue]!=USE_MASTER_LIST)];
	[pageTitle setEnabled:YES];
	NSString *t = [currentPage pageTitle];
	if (t == nil)
		t = @"";
	[pageTitle setStringValue:t];
	[backgroundColour setEnabled:YES];
	if (NSColor *col = [currentPage backgroundColour])
		[backgroundColour setColor:col];
	else
		[backgroundColour setColor:[NSColor clearColor]];
}

- (void)tableViewSelectionDidChange:(NSNotification *)notif
{
	if ([self actionsDisabled])
		return;
	else if ([notif object] == pageTableView)
		[self pageTableSelectionChange:[pageTableView selectedRow]];
	else if ([notif object] == layerTableView)
		[self layerTableSelectionChange:[layerTableView selectedRow]];
}

-(void)selectLayerRowWithNoActions:(int)row
{
	[self setActionsDisabled:YES];
	[layerTableView selectRowIndexes:[NSIndexSet indexSetWithIndex:row]byExtendingSelection:NO];
	[self setActionsDisabled:NO];
}

-(void)selectPageRowWithNoActions:(int)row
{
	[self setActionsDisabled:YES];
	[pageTableView selectRowIndexes:[NSIndexSet indexSetWithIndex:row]byExtendingSelection:NO];
	[self setActionsDisabled:NO];
}

- (IBAction)pageTitleHit:(id)sender
{
	[[self inspectingGraphicView] changePageTitle:[pageTitle stringValue]];
}

- (IBAction)backgroundColourHit:(id)sender
{
	ACSDPage *currentPage = [[self inspectingGraphicView] currentPage];
	if (!currentPage)
		return;
	[currentPage uSetBackgroundColour:[sender color]];
	[[[self inspectingGraphicView] undoManager] setActionName:@"Set Background Colour"];	
}


@end
