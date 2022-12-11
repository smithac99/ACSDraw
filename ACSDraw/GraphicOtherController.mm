//
//  GraphicOtherController.m
//  ACSDraw
//
//  Created by Alan on 10/12/2014.
//
//

#import "GraphicOtherController.h"
#import "GraphicView.h"
#import "ACSDGraphic.h"
#import "ArrayAdditions.h"

NSString *ACSDrawGraphicIdxPasteboardType = @"ACSDrawGraphicIdx";
NSString *ACSDrawGraphicAttribIdxPasteboardType = @"ACSDrawGraphicAttribidx";

@implementation GraphicOtherController

-(id)init
{
    if (self = [super initWithTitle:@"Attributes"])
    {
		self.tempAttributes = [NSMutableArray array];
    }
    return self;
}

-(void)dealloc
{
	[[NSNotificationCenter defaultCenter]removeObserver:self];
}

- (void)zeroControls
{
    [self.attributesTableView reloadData];
}

-(void)setGraphicControls
{
    [self.attributesTableView reloadData];
}

- (void)selectionChanged:(NSNotification *)notification
{
    [self addChange:GOC_SELECTION_CHANGE];
}

-(NSArray*)selectedGraphics
{
    return [[[self inspectingGraphicView] selectedGraphics]allObjects];
}

-(IBAction)attrsPlusHit:(id)sender
{
    NSArray *graphics = [self selectedGraphics];
    if ([graphics count] == 1)
    {
        ACSDGraphic *g = graphics[0];
        NSInteger idx = [self.attributesTableView selectedRow];
        if (idx < 0)
            idx = [g.attributes count];
        else
            idx++;
        [g uInsertAttributeName:@"" value:@"" atIndex:idx notify:NO];
        [self.attributesTableView reloadData];
        [self.attributesTableView selectRowIndexes:[NSIndexSet indexSetWithIndex:idx] byExtendingSelection:NO];
        [[[self inspectingGraphicView] undoManager] setActionName:@"Add attribute"];
    }
	else if ([graphics count] > 1)
	{
		NSInteger idx = [self.attributesTableView selectedRow];
		if (idx < 0)
			idx = [self.tempAttributes count];
		else
			idx++;
		[self.tempAttributes insertObject:@[@"",@""] atIndex:idx];
		[self.attributesTableView reloadData];
		[self.attributesTableView selectRowIndexes:[NSIndexSet indexSetWithIndex:idx] byExtendingSelection:NO];
	}
}

-(IBAction)attrsMinusHit:(id)sender
{
	NSInteger idx = [self.attributesTableView selectedRow];
	if (idx < 0)
		return;
    NSArray *graphics = [self selectedGraphics];
    if ([graphics count] == 1)
    {
        ACSDGraphic *g = graphics[0];
        [g uDeleteAttributeAtIndex:idx notify:NO];
        [self.attributesTableView reloadData];
        [[[self inspectingGraphicView] undoManager] setActionName:@"Delete attribute"];
    }
	else if ([graphics count] > 1)
	{
		NSString *key = self.tempAttributes[idx][0];
		[self.tempAttributes removeObjectAtIndex:idx];
		for (ACSDGraphic *g in graphics)
			[g uDeleteAttributeForName:key notify:NO];
		[self.attributesTableView reloadData];
	}
}

-(void)sourceChange:(NSNotification*)notif
{
    [self addChange:GOC_SOURCE_CHANGE];
}

-(void)graphicSelectionChange
{
	[self addChange:GOC_SELECTION_CHANGE];
}

-(void)attributeChange:(NSNotification*)notif
{
	[self addChange:GOC_ATTRIBUTE_CHANGE];
}

-(void)setDocumentControls:(ACSDrawDocument*)doc
{
    [self sourceChange:nil];
}

- (void)awakeFromNib
{
    [super awakeFromNib];
    NSButtonCell *bc = [[NSButtonCell alloc]init];
    rowForContextualMenu = -1;
    displayRowForContextualMenu = -1;
    [bc setButtonType:NSButtonTypeToggle];
    [bc setImage:[NSImage imageNamed:@"eye2"]];
    [bc setAlternateImage:[NSImage imageNamed:@"eye3"]];
	[bc setBordered:NO];
	[bc setImageScaling:NSImageScaleProportionallyUpOrDown];
    [[[self.graphicsTableView tableColumns]objectAtIndex:0] setDataCell:bc];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(unsetRowForContextualMenu:) name:NSMenuDidEndTrackingNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(sourceChange:) name:ACSDPageChanged object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(sourceChange:) name:ACSDCurrentLayerChanged object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(sourceChange:) name:ACSDGraphicListChanged object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(attributeChange:) name:ACSDGraphicAttributeChanged object:nil];
    [self.graphicsTableView registerForDraggedTypes:[NSArray arrayWithObjects:ACSDrawGraphicIdxPasteboardType,nil]];
    [self.attributesTableView registerForDraggedTypes:[NSArray arrayWithObjects:ACSDrawGraphicAttribIdxPasteboardType,nil]];
}

-(void)effectSourceChange
{
    [self.graphicsTableView reloadData];
    [self addChange:GOC_SELECTION_CHANGE];
}

-(void)effectSelectionChange
{
    ACSDLayer *l = [[self inspectingGraphicView]currentEditableLayer];
    if (l == nil)
        [self.graphicsTableView selectRowIndexes:[NSIndexSet indexSet] byExtendingSelection:NO];
    else
    {
        NSIndexSet *ixs = [l indexesOfSelectedGraphics];
		NSIndexSet *rixs = ReversedIndexSet(ixs,[[l graphics]count]);
        [self.graphicsTableView selectRowIndexes:rixs byExtendingSelection:NO];
		if ([rixs count] == 1)
			[self.graphicsTableView scrollRowToVisible:[rixs firstIndex]];

    }
	[self.tempAttributes removeAllObjects];
    [self addChange:GOC_ATTRIBUTE_CHANGE];
}

-(void)effectAttributeChange
{
	[self.attributesTableView reloadData];
}

-(void)updateControls
{
    actionsDisabled = YES;
    if (self.changed & GOC_SOURCE_CHANGE)
        [self effectSourceChange];
	if (self.changed & GOC_SELECTION_CHANGE)
		[self effectSelectionChange];
	if (self.changed & GOC_ATTRIBUTE_CHANGE)
		[self effectAttributeChange];
    actionsDisabled = NO;
}
#pragma mark - 
#pragma mark table stuff

- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex
{
    if (aTableView == self.graphicsTableView)
    {
        NSArray *graphics = [self graphicList];
        if (graphics && rowIndex >=0 && rowIndex < [graphics count])
        {
            ACSDGraphic *g = [graphics objectAtReversedIndex:rowIndex];
            if ([[aTableColumn identifier]isEqualTo:@"name"])
                return [g name];
            else
                return @(!g.hidden);
        }
        else
            return nil;
    }
    else
    {
        NSArray *graphics = [self selectedGraphics];
        if ([graphics count] == 0)
            return nil;
        NSArray *arr = nil;
        if ([graphics count] == 1)
            arr = ((ACSDGraphic*)graphics[0]).attributes;
        else
            arr = self.tempAttributes;
        if (rowIndex < 0 || rowIndex >= [arr count])
            return nil;
        if ([[aTableColumn identifier]isEqualTo:@"attr"])
            return arr[rowIndex][0];
        else if ([[aTableColumn identifier]isEqualTo:@"value"])
            return arr[rowIndex][1];
        return nil;
    }
}

- (void)tableView:(NSTableView *)aTableView setObjectValue:anObject forTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex
{
    if (aTableView == self.graphicsTableView)
    {
        NSArray *graphics = [self graphicList];
        if (graphics && rowIndex >=0 && rowIndex < [graphics count])
        {
            ACSDGraphic *g = [graphics objectAtReversedIndex:rowIndex];
            if ([[aTableColumn identifier]isEqualTo:@"name"])
                [g setGraphicName:anObject];
            else if ([[aTableColumn identifier]isEqualTo:@"xxx-vis"])
            {
                if ([anObject isKindOfClass:[NSNumber class]])
                {
                    BOOL newVal = ![anObject boolValue];
                    int noChanged = 0;
                    if ([[[self inspectingGraphicView] selectedGraphics]containsObject:g])
                        for (ACSDGraphic *g2 in [self selectedGraphics])
                            if ([g2 setGraphicHidden:newVal])
                                noChanged++;
                    else
                        if ([g setGraphicHidden:newVal])
                            noChanged++;
                    NSString *str = @"Hide";
                    if (!newVal)
                        str = @"Show";
                    NSString *plural = @"s";
                    if (noChanged == 1)
                        plural = @"";
                    [[[self inspectingGraphicView] undoManager] setActionName:[NSString stringWithFormat:@"%@ object%@",str,plural]];
                }
            }
        }
    }
    else
    {
        NSArray *graphics = [self selectedGraphics];
        if ([graphics count] == 0)
            return;
        NSArray *arr = nil;
        if ([graphics count] == 1)
        {
            ACSDGraphic *g = graphics[0];
            arr = g.attributes;
            if (arr && rowIndex >= 0 && rowIndex < [arr count])
            {
                if ([[aTableColumn identifier]isEqualTo:@"attr"])
                {
                    [g uSetAttributeName:anObject atIndex:rowIndex notify:NO];
                    [[[self inspectingGraphicView] undoManager] setActionName:@"Set Attribute Name"];
                }
                else if ([[aTableColumn identifier]isEqualTo:@"value"])
                {
                    [g uSetAttributeValue:anObject atIndex:rowIndex notify:NO];
                    [[[self inspectingGraphicView] undoManager] setActionName:@"Set Attribute Value"];
                }
            }
        }
        else
        {
            arr = self.tempAttributes;
            if (arr && rowIndex >= 0 && rowIndex < [arr count])
            {
                if ([[aTableColumn identifier]isEqualTo:@"attr"])
                {
                    [self.tempAttributes replaceObjectAtIndex:rowIndex withObject:@[anObject,arr[rowIndex][1]]];
                }
                else if ([[aTableColumn identifier]isEqualTo:@"value"])
                {
                    [self.tempAttributes replaceObjectAtIndex:rowIndex withObject:@[arr[rowIndex][0],anObject]];
                    for (ACSDGraphic *g in graphics)
                        [g uSetAttributeValue:anObject forName:arr[rowIndex][0] notify:NO];
                    [[[self inspectingGraphicView] undoManager] setActionName:@"Set Multiple Attributes"];
                }
            }
        }
        return;
    }
}

-(NSArray*)graphicList
{
    return [[[self inspectingGraphicView]currentEditableLayer]graphics];
}

- (NSInteger)numberOfRowsInTableView:(NSTableView *)aTableView
{
    if (aTableView == self.graphicsTableView)
    {
        return [[self graphicList]count];
    }
    else
    {
        NSArray *graphics = [self selectedGraphics];
        if ([graphics count] == 1)
        {
            ACSDGraphic *g = graphics[0];
            return [g.attributes count];
        }
        else if ([graphics count]>0)
        {
            return [self.tempAttributes count];
        }
        return 0;
    }
}

static NSIndexSet *ReversedIndexSet(NSIndexSet *ixs,NSInteger arrayCount)
{
    NSMutableIndexSet *mixs = [NSMutableIndexSet indexSet];
    [ixs enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
        [mixs addIndex:arrayCount - 1 - idx];
    }];
    return mixs;
}

- (void)graphicsTableSelectionChange:(NSInteger)row
{
    //if (row > -1)
    {
        NSIndexSet *ixs = [self.graphicsTableView selectedRowIndexes];
        ACSDLayer *l = [[self inspectingGraphicView] currentEditableLayer];
        [[self inspectingGraphicView]selectGraphicsInCurrentLayerFromIndexSet:ReversedIndexSet(ixs,[[l graphics]count])];
    }
}
- (void)tableViewSelectionDidChange:(NSNotification *)notif
{
    if ([self actionsDisabled])
        return;
    if ([notif object] == self.graphicsTableView)
        [self graphicsTableSelectionChange:[self.graphicsTableView selectedRow]];
}

-(BOOL)tableView:(NSTableView *)tableView shouldSelectRow:(NSInteger)row
{
	if ([[self inspectingGraphicView]cursorMode] == GV_MODE_DOING_LINK)
	{
		NSArray *graphics = [self graphicList];
		if (graphics && row >=0 && row < [graphics count])
		{
			ACSDGraphic *g = [graphics objectAtReversedIndex:row];
			if (![[[[self inspectingGraphicView]document] linkGraphics] containsObject:g])
				[[self inspectingGraphicView]processLinkToObj:g modifierFlags:[[NSApp currentEvent]modifierFlags]];
		}
		return NO;
	}
	return YES;
}
#pragma mark -
#pragma mark drag and drop

- (BOOL)tableView:(NSTableView *)tableView writeRowsWithIndexes:(NSIndexSet *)rowIndexes toPasteboard:(NSPasteboard*)pboard
{
    if (tableView == self.graphicsTableView)
    {
        NSArray *typeArray = [NSArray arrayWithObjects:ACSDrawGraphicIdxPasteboardType,nil];
        [pboard declareTypes:typeArray owner:self];
        return [pboard setData:[NSKeyedArchiver archivedDataWithRootObject:rowIndexes] forType:ACSDrawGraphicIdxPasteboardType];
    }
    else
    {
        NSArray *graphics = [self selectedGraphics];
        if ([graphics count] != 1)
            return NO;
        NSArray *typeArray = [NSArray arrayWithObjects:ACSDrawGraphicAttribIdxPasteboardType,nil];
        [pboard declareTypes:typeArray owner:self];
        return [pboard setData:[NSKeyedArchiver archivedDataWithRootObject:rowIndexes] forType:ACSDrawGraphicAttribIdxPasteboardType];
    }
    return YES;
}

- (NSDragOperation)tableView:(NSTableView*)tabView validateDrop:(id <NSDraggingInfo>)info
                 proposedRow:(NSInteger)row proposedDropOperation:(NSTableViewDropOperation)operation
{
    if (operation == NSTableViewDropOn)
        return NSDragOperationNone;
    if ([info draggingSource] == tabView)
        return  NSDragOperationMove;
    else
        return  NSDragOperationNone;
}

void MoveRowsFromIndexSetToPosition(NSMutableArray* arr,NSIndexSet *ixs,NSInteger pos)
{
    NSArray *temparr = [arr objectsAtIndexes:ixs];
    NSUInteger ind = [ixs lastIndex];
    while (ind != NSNotFound && ind >= pos)
    {
        [arr removeObjectAtIndex:ind];
        ind = [ixs indexLessThanIndex:ind];
    }
    [arr insertObjects:temparr atIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(pos, [temparr count])]];
    while (ind != NSNotFound)
    {
        [arr removeObjectAtIndex:ind];
        ind = [ixs indexLessThanIndex:ind];
    }
}

- (BOOL)tableView:(NSTableView*)aTableView acceptDrop:(id <NSDraggingInfo>)info row:(NSInteger)row dropOperation:(NSTableViewDropOperation)operation
{
    GraphicView *graphicView = [self inspectingGraphicView];
    if (!graphicView)
        return NO;
    NSPasteboard* pboard = [info draggingPasteboard];
    if (aTableView == self.graphicsTableView)
    {
        ACSDLayer *l = [graphicView currentEditableLayer];
        if (l == nil)
            return NO;
        NSData* rowData = [pboard dataForType:ACSDrawGraphicIdxPasteboardType];
        NSIndexSet* rowIndexes = ReversedIndexSet([NSKeyedUnarchiver unarchiveObjectWithData:rowData],[[l graphics]count]);
        NSMutableArray *newArray = [[l graphics]mutableCopy];
        MoveRowsFromIndexSetToPosition(newArray,rowIndexes,[[l graphics]count] - row);
        [graphicView uSetGraphics:newArray forLayer:l];
        [[[self inspectingGraphicView] undoManager] setActionName:@"Reorder graphics"];
    }
    else
    {
        NSArray *graphics = [self selectedGraphics];
        if ([graphics count] != 1)
            return NO;
        ACSDGraphic *g = graphics[0];
        NSData* rowData = [pboard dataForType:ACSDrawGraphicAttribIdxPasteboardType];
        NSIndexSet* rowIndexes = [NSKeyedUnarchiver unarchivedObjectOfClass:[NSIndexSet class] fromData:rowData error:NULL];
        NSMutableArray *newArray = [[g attributes]mutableCopy];
        MoveRowsFromIndexSetToPosition(newArray,rowIndexes,row);
        [g uSetAttributes:newArray];
        [[[self inspectingGraphicView] undoManager] setActionName:@"Reorder graphic attributes"];
    }
    return YES;
}


- (BOOL)handleClickAtPoint:(NSPoint)pt inTableView:(NSTableView*)tableView
{
    if (tableView != self.graphicsTableView)
        return NO;
    NSInteger col = [tableView columnAtPoint:pt];
    if (col != 0)
        return NO;
    NSInteger row = [tableView rowAtPoint:pt];
    GraphicView *gv = [self inspectingGraphicView];
    NSArray *graphics = [[gv currentEditableLayer] graphics];

    if (row < 0 || row >= (int)[graphics count])
        return NO;
    row = [graphics count] - 1 - row;
    ACSDGraphic *g = graphics[row];
    BOOL newVal = !g.hidden;
    int noChanged = 0;
    if ([[gv selectedGraphics]containsObject:g])
    {
        for (ACSDGraphic *g2 in [self selectedGraphics])
            if ([g2 setGraphicHidden:newVal])
                noChanged++;
    }
    else
        if ([g setGraphicHidden:newVal])
            noChanged++;
    if (noChanged)
    {
        NSString *str = @"Hide";
        if (!newVal)
            str = @"Show";
        NSString *plural = @"s";
        if (noChanged == 1)
            plural = @"";
        [[[self inspectingGraphicView] undoManager] setActionName:[NSString stringWithFormat:@"%@ object%@",str,plural]];
        
    }
    return YES;
}

#pragma mark -

-(IBAction)reloadImage:(id)sender
{
    NSInteger clickedRow = [self.graphicsTableView clickedRow];
    NSIndexSet *targetRows = nil;
    NSIndexSet *selectedRows = [self.graphicsTableView selectedRowIndexes];
    if ([selectedRows containsIndex:clickedRow])
        targetRows = selectedRows;
    else
        targetRows = [NSIndexSet indexSetWithIndex:clickedRow];
    GraphicView *gv = [self inspectingGraphicView];
    targetRows = ReversedIndexSet(targetRows, [[[gv currentEditableLayer] graphics]count]);
    [gv reloadImages:[[[gv currentEditableLayer] graphics]objectsAtIndexes:targetRows]];
    [[[self inspectingGraphicView] undoManager] setActionName:@"Reload Images"];
}

-(IBAction)copyAttributes:(id)sender
{
	NSArray *gs = [self selectedGraphics];
	if ([gs count] > 0)
	{
		NSMutableArray *attrs = [NSMutableArray array];
		for (ACSDGraphic *g in gs)
		{
			for (NSArray *arr in g.attributes)
			{
				if ([arr count] > 1)
				{
					NSString *str = [NSString stringWithFormat:@"%@\t%@",arr[0],arr[1]];
					[attrs addObject:str];
				}
			}
		}
		if ([attrs count] > 0)
		{
			[[NSPasteboard generalPasteboard]clearContents];
			[[NSPasteboard generalPasteboard]writeObjects:attrs];
		}
	}
}

-(IBAction)pasteAttributes:(id)sender
{
	NSArray *strs = [[NSPasteboard generalPasteboard]readObjectsForClasses:@[[NSString class]] options:[NSDictionary dictionary]];
	NSArray *gs = [self selectedGraphics];
	if ([strs count] > 0 && [gs count] > 0)
	{
		NSString *attrkey=@"",*attr=@"";
		for (NSString *str in strs)
		{
			NSRange r = [str rangeOfString:@"\t"];
			if (r.location == NSNotFound)
				attrkey = str;
			else
			{
				attrkey = [str substringToIndex:r.location];
				if (r.location + 1 < [str length])
					attr = [str substringFromIndex:r.location + 1];
			}
			for (ACSDGraphic *g in gs)
			{
				[g uSetAttributeValue:attr forName:attrkey notify:YES];
			}
			[[[self inspectingGraphicView] undoManager] setActionName:@"Paste Attributes"];
		}
	}
}

-(IBAction)copySelectedAttributes:(id)sender
{
	NSIndexSet *ixs = [self.attributesTableView selectedRowIndexes];
	if ([ixs count] > 0)
	{
		NSMutableArray *attrs = [NSMutableArray array];
		[ixs enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
			NSTableColumn *col = [self.attributesTableView tableColumnWithIdentifier:@"attr"];
			NSString *attrkey = [self tableView:self.attributesTableView objectValueForTableColumn:col row:idx];
			col = [self.attributesTableView tableColumnWithIdentifier:@"value"];
			NSString *value = [self tableView:self.attributesTableView objectValueForTableColumn:col row:idx];
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
	if (action == @selector(reloadImage:))
		return [self.graphicsTableView clickedRow] > -1;
	if (action == @selector(copyAttributes:))
		return [self.graphicsTableView clickedRow] > -1;
	if (action == @selector(pasteAttributes:))
        return ([self.graphicsTableView clickedRow] > -1) && ([[NSPasteboard generalPasteboard]availableTypeFromArray:@[NSPasteboardTypeString]]);
	if (action == @selector(copySelectedAttributes:))
		return [self.attributesTableView clickedRow] > -1;
    return NO;
}

@end
