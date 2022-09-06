//
//  PagesController.mm
//  ACSDraw
//
//  Created by alan on 08/02/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "PagesController.h"
#import "GraphicView.h"
#import "ACSDLayer.h"
#import "ACSDGraphic.h"
#import "ACSDPage.h"
#import "SelCell.h"
#import "LayerTableView.h"
#import "DragView.h"
#import "LayerListTableSource.h"
#import "PageListTableSource.h"

NSString *ACSDrawLayerPasteboardType = @"ACSDrawLayer";
NSString *ACSDrawLayerIntPasteboardType = @"ACSDrawLayerInt";
NSString *ACSDrawLayerSelPasteboardType = @"ACSDrawLayerSel";
NSString *ACSDrawPageIntPasteboardType = @"ACSDrawPageInt";

@implementation PagesController

-(id)init
{
	if ((self = [super initWithTitle:@"Pages"]))
	{
	}
	return self;
}

- (void)dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
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
	[[[layerTableView tableColumns]objectAtIndex:3] setDataCell:[[SelCell alloc]init]];
	NSButtonCell *bc = [[NSButtonCell alloc]init];
    [bc setButtonType:NSButtonTypeToggle];
	[bc setImage:[NSImage imageNamed:@"eye2"]];
	[bc setAlternateImage:[NSImage imageNamed:@"eye"]];
	[bc setBordered:NO];
	[[[layerTableView tableColumns]objectAtIndex:0] setDataCell:bc];
	bc = [[NSButtonCell alloc]init];
    [bc setButtonType:NSButtonTypeToggle];
	[bc setImage:[NSImage imageNamed:@"lock2"]];
	[bc setAlternateImage:[NSImage imageNamed:@"lock"]];
	[bc setBordered:NO];
	[[[layerTableView tableColumns]objectAtIndex:1] setDataCell:bc];
	cell = [[[layerTableView tableColumns]objectAtIndex:2] dataCell];
	if (cell)
	{
		NSFont *font = [cell font];
		if (font == nil)
			font = [NSFont systemFontOfSize:[NSFont smallSystemFontSize]];
		[cell setFont:[[NSFontManager sharedFontManager]convertFont:font toSize:[NSFont smallSystemFontSize]]];
	}
	[pageTableView registerForDraggedTypes:@[ACSDrawPageIntPasteboardType,ACSDrawLayerIntPasteboardType]];
	[layerTableView registerForDraggedTypes:[NSArray arrayWithObjects:ACSDrawLayerIntPasteboardType,nil]];
	[layerTableView registerForDraggedTypes:[NSArray arrayWithObjects:ACSDrawLayerSelPasteboardType,nil]];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(pageChanged:) name:ACSDPageChanged object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(refreshLayerSelection:) name:ACSDLayerSelectionChanged object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(refreshLayerSelection:) name:ACSDGraphicViewSelectionDidChangeNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(refreshLayers:) name:ACSDCurrentLayerChanged object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(inactivateColourWells:) name:ACSDInactivateFillWells object:nil];
}

#pragma mark actions

-(void)inactivateColourWells:(NSNotification *)notification
{
    [backgroundColour deactivate];
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
    [[self inspectingGraphicView]setNeedsDisplay:YES];
}

-(IBAction)layerExportableCBHit:(id)sender
{
	[[self inspectingGraphicView]setCurrentLayerExportable:[sender intValue]];
}


-(IBAction)layerZposHit:(id)sender
{
    [[self inspectingGraphicView]setCurrentLayerZPosOffset:[sender floatValue]];
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
			[layerTableView selectRowIndexes:[NSIndexSet indexSetWithIndex:row] byExtendingSelection:NO];
		}
	   }
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
			NSUInteger modifierFlags = [[[pagePlus window]currentEvent]modifierFlags];
            if (modifierFlags & NSEventModifierFlagOption)
			{
				[self duplicatePageAtRow:row];
				return;
			}
			row++;
			[[self inspectingGraphicView] addNewPageAtIndex:row];
			[pageTableView reloadData];
			[pageTableView selectRowIndexes:[NSIndexSet indexSetWithIndex:row] byExtendingSelection:NO];
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

-(IBAction)attrsPlusHit:(id)sender
{
	ACSDPage *page = [[self inspectingGraphicView] currentPage];
	if (page == nil)
		return;
	NSInteger idx = [self.attributeTableView selectedRow];
	if (idx < 0)
		idx = [page.attributes count];
	else
		idx++;
	[page uInsertAttributeName:@"" value:@"" atIndex:idx notify:NO];
	[self.attributeTableView reloadData];
	[self.attributeTableView selectRowIndexes:[NSIndexSet indexSetWithIndex:idx] byExtendingSelection:NO];
	[[[self inspectingGraphicView] undoManager] setActionName:@"Add attribute"];
}
-(IBAction)attrsMinusHit:(id)sender
{
	ACSDPage *page = [[self inspectingGraphicView] currentPage];
	if (page == nil)
		return;
	NSInteger idx = [self.attributeTableView selectedRow];
	if (idx < 0)
		return;
	[page uDeleteAttributeAtIndex:idx notify:NO];
	[self.attributeTableView reloadData];
	[[[self inspectingGraphicView] undoManager] setActionName:@"Delete attribute"];
}

- (IBAction)pageTitleHit:(id)sender
{
	[[self inspectingGraphicView] changePageTitle:[pageTitle stringValue]];
    [[pageTableView window]makeFirstResponder:pageTableView];
    [pageTableView reloadData];
}

- (void)controlTextDidChange:(NSNotification *)notification
{
	NSTextField *textField = [notification object];
	if (textField == pageTitle)
	{
		[[self inspectingGraphicView] changePageTitle:[pageTitle stringValue]];
		[pageTableView reloadData];
	}
}
- (IBAction)backgroundColourHit:(id)sender
{
	ACSDPage *currentPage = [[self inspectingGraphicView] currentPage];
	if (!currentPage)
		return;
    NSColor *col = [sender color];
    //if ([col alphaComponent] == 0.0)
        //col = nil;
	[currentPage uSetBackgroundColour:col];
	[[[self inspectingGraphicView] undoManager] setActionName:@"Set Page Background Colour"];	
}

-(IBAction)clearBackgroundColour:(id)sender
{
    ACSDPage *currentPage = [[self inspectingGraphicView] currentPage];
    if (!currentPage)
        return;
    [currentPage uSetBackgroundColour:nil];
    [[[self inspectingGraphicView] undoManager] setActionName:@"Clear Page Background Colour"];
}
- (void)setLayerList:(NSMutableArray*)f
{
	if (layerList == f)
		return;
	layerList = f;
	[(LayerListTableSource*)[layerTableView dataSource]setLayerList:f];
}

- (void)setPageList:(NSMutableArray*)f
{
	if (pageList == f)
		return;
	pageList = f;
	[(PageListTableSource*)[pageTableView dataSource]setPageList:f];
}

#pragma mark manage controls

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
	[layerExportableCB setIntValue:0];
	[layerExportableCB setEnabled:NO];
	[self.attributeTableView reloadData];
    [lzpos setIntValue:0];
    [lzpos setEnabled:NO];
}

-(void)setGraphicControls
{
	[self setControlsForLayers:[[[self inspectingGraphicView] currentPage]currentLayerInd]];
	[layerTableView setAllowsEmptySelection:NO];
}

-(void)refreshLayers:(NSNotification *)notification
{
	if (![self inspectingGraphicView])
		return;
	[self setActionsDisabled:YES];
    NSInteger oldSel = [layerTableView selectedRow];
	[layerTableView selectRowIndexes:[NSIndexSet indexSetWithIndex:[[[self inspectingGraphicView] currentPage]currentLayerInd]] byExtendingSelection:NO];
	[layerTableView reloadData];
    if (oldSel != [layerTableView selectedRow])
        [layerTableView scrollRowToVisible:[layerTableView selectedRow]];
	[self setGraphicControls];
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
	for (id o in arr)
		[layerTableView reDisplayRow:[o intValue] column:SELECTION_COLUMN];
	[self setActionsDisabled:YES];
	[self setGraphicControls];
	[self setActionsDisabled:NO];

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
    NSUInteger modifierFlags = 0;
    if ([tableView isKindOfClass:[ACSDTableView class]])
        modifierFlags = [(ACSDTableView*)tableView modifierFlags];
    if (col == 0)
    {
        if ([l visible])
            actionName = [NSString stringWithFormat:@"Hide %@",[l name]];
        else
            actionName = [NSString stringWithFormat:@"Show %@",[l name]];
        [[self inspectingGraphicView]toggleVisibilityForLayer:l modifierFlags:modifierFlags];
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
	[[[self inspectingGraphicView]undoManager] setActionName:[NSString stringWithFormat:@"Select Page '%@'",[[[self inspectingGraphicView]currentPage]Desc]]];	

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
    [[[self inspectingGraphicView]undoManager]setActionName:@"Change Layer"];
	[self setControlsForLayers:row];
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
        if (layerInd == NSNotFound)
            [layerTableView selectRowIndexes:[NSIndexSet indexSet] byExtendingSelection:NO];
        else
            [layerTableView selectRowIndexes:[NSIndexSet indexSetWithIndex:layerInd] byExtendingSelection:NO];
        [layerTableView refreshSelectionIndicatorForRow:oldSel];
    }
    [layerTableView refreshSelectionIndicatorForRow:layerInd];
    if (layerInd >= 0)
    {
        [layerExportableCB setEnabled:YES];
        ACSDLayer *l = [[[[self inspectingGraphicView] currentPage]layers]objectAtIndex:layerInd];
        BOOL exp = [l exportable];
        [layerExportableCB setIntValue:exp];
        [lzpos setEnabled:YES];
        [lzpos setFloatValue:[l zPosOffset]];
    }
}

- (void)setControlsForPage
{
	[self.attributeTableView reloadData];
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

#pragma mark table actions

- (void)tableViewSelectionDidChange:(NSNotification *)notif
{
	if ([self actionsDisabled])
		return;
	else if ([notif object] == pageTableView)
		[self pageTableSelectionChange:[pageTableView selectedRow]];
	else if ([notif object] == layerTableView)
		[self layerTableSelectionChange:[layerTableView selectedRow]];
}

-(void)selectLayerRowWithNoActions:(NSInteger)row
{
	[self setActionsDisabled:YES];
	[layerTableView selectRowIndexes:[NSIndexSet indexSetWithIndex:row]byExtendingSelection:NO];
	[self setActionsDisabled:NO];
}

-(void)selectPageRowWithNoActions:(NSInteger)row
{
	[self setActionsDisabled:YES];
	[pageTableView selectRowIndexes:[NSIndexSet indexSetWithIndex:row]byExtendingSelection:NO];
	[self setActionsDisabled:NO];
}

-(int)displayRowForContextualMenu
{
	return -1;
}

-(IBAction)duplicatePage:(id)sender
{
	if (rowForContextualMenu > -1)
		[self duplicatePageAtRow:rowForContextualMenu];
}

-(void)duplicatePageAtRow:(NSInteger)row
{
    [[self inspectingGraphicView]duplicatePageAtIndex:row];
}

- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex
{
	ACSDPage *page = [[self inspectingGraphicView] currentPage];
	if (page == nil)
		return nil;
	NSArray *arr = page.attributes;
	if (arr && rowIndex >= 0 && rowIndex < [arr count])
	{
		if ([[aTableColumn identifier]isEqualTo:@"attr"])
			return arr[rowIndex][0];
		else if ([[aTableColumn identifier]isEqualTo:@"value"])
			return arr[rowIndex][1];
	}
	return nil;
}

- (void)tableView:(NSTableView *)aTableView setObjectValue:anObject forTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex
{
	ACSDPage *page = [[self inspectingGraphicView] currentPage];
	if (page == nil)
		return;
	NSArray *arr = page.attributes;
	if (arr && rowIndex >= 0 && rowIndex < [arr count])
	{
		if ([[aTableColumn identifier]isEqualTo:@"attr"])
		{
			[page uSetAttributeName:anObject atIndex:rowIndex notify:NO];
			[[[self inspectingGraphicView] undoManager] setActionName:@"Set Attribute Name"];
		}
		else if ([[aTableColumn identifier]isEqualTo:@"value"])
		{
			[page uSetAttributeValue:anObject atIndex:rowIndex notify:NO];
			[[[self inspectingGraphicView] undoManager] setActionName:@"Set Attribute Value"];
		}
	}
}

- (NSUInteger)numberOfRowsInTableView:(NSTableView *)aTableView
{
	ACSDPage *page = [[self inspectingGraphicView] currentPage];
	if (page)
		return [[page attributes]count];
	return 0;
}

- (BOOL)tableView:(NSTableView *)tableView shouldEditTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
    if (tableView == pageTableView)
    {
        __weak NSWindow *w = [pageTableView window];
        __weak id pt = pageTitle;
        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, 0.2 * NSEC_PER_SEC);
        dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
            [w makeFirstResponder:pt];
        });
        return NO;
    }
    return YES;
}
#pragma mark -

-(IBAction)pasteAttributes:(id)sender
{
	NSArray *strs = [[NSPasteboard generalPasteboard]readObjectsForClasses:@[[NSString class]] options:[NSDictionary dictionary]];
	ACSDPage *page = [[self inspectingGraphicView] currentPage];
	if (page == nil)
		return;
	if ([strs count] > 0)
	{
		NSString *attrkey=@"",*attr=@"";
		for (NSString *str in strs)
		{
			NSArray *comps = [str componentsSeparatedByCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"\t="]];
			if ([comps count] > 0)
			{
				if ([comps count] > 1)
				{
					attrkey = comps[0];
					attr = comps[1];
					attr = [attr stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"\""]];
				}
				else
				{
					attrkey = comps[0];
				}
				[page uSetAttributeValue:attr forName:attrkey notify:NO];
			}
		}
		[self.attributeTableView reloadData];
		[[[self inspectingGraphicView] undoManager] setActionName:@"Paste Attributes"];
	}
}

-(IBAction)copySelectedAttributes:(id)sender
{
	NSIndexSet *ixs = [self.attributeTableView selectedRowIndexes];
	if ([ixs count] > 0)
	{
		ACSDPage *page = [[self inspectingGraphicView] currentPage];
		if (page == nil)
			return;
		NSMutableArray *attrs = [NSMutableArray array];
		[ixs enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
			NSTableColumn *col = [self.attributeTableView tableColumnWithIdentifier:@"attr"];
			NSString *attrkey = [self tableView:self.attributeTableView objectValueForTableColumn:col row:idx];
			col = [self.attributeTableView tableColumnWithIdentifier:@"value"];
			NSString *value = [self tableView:self.attributeTableView objectValueForTableColumn:col row:idx];
			NSString *str = [NSString stringWithFormat:@"%@\t%@",attrkey,value];
			[attrs addObject:str];
			if ([attrs count] > 0)
			{
				[[NSPasteboard generalPasteboard]clearContents];
				[[NSPasteboard generalPasteboard]writeObjects:attrs];
			}
		}];
		
	}
}

- (BOOL)validateMenuItem:(id)menuItem
{
	SEL action = [menuItem action];
	if (action == @selector(pasteAttributes:))
		return ([[NSPasteboard generalPasteboard]availableTypeFromArray:@[NSStringPboardType]]!=nil);
	if (action == @selector(copySelectedAttributes:))
		return [self.attributeTableView clickedRow] > -1;
	return YES;
}

@end
