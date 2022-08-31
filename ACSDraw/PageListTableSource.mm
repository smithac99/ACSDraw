//
//  PageListTableSource.mm
//  ACSDraw
//
//  Created by alan on 09/03/06.
//  Copyright 2006 Alan C Smith. All rights reserved.
//

#import "PageListTableSource.h"
#import "ACSDPage.h"
#import "ACSDLayer.h"
#import "GraphicView.h"
#import "PagesController.h"
#import "LayerTableView.h"
#import "SelectionSet.h"

@implementation PageListTableSource
- (id)init
   {
	if ((self = [super init]))
		pageList = nil;
	return self;
   }

- (void)setPageList:(NSMutableArray*)list
{
	if (pageList == list)
		return;
	pageList = list;
	[tableView reloadData];
}


- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn
			row:(int)rowIndex
{
	if(rowIndex >= 0 && rowIndex < (int)[pageList count])
	{
		if (pageList)
		{
			if ([[aTableColumn identifier]isEqualTo:@"desc"])
				return [[pageList objectAtIndex:rowIndex]Desc];
		}
	}
	return nil;
}

- (void)tableView:(NSTableView *)aTableView setObjectValue:anObject forTableColumn:(NSTableColumn *)aTableColumn
			  row:(int)rowIndex
   {
    NSParameterAssert(rowIndex >= 0 && rowIndex < (int)[pageList count]);
   }

- (NSUInteger)numberOfRowsInTableView:(NSTableView *)aTableView
   {
    if (pageList)
		return [pageList count];
	return 0;
   }

- (BOOL)tableView:(NSTableView *)tableView writeRowsWithIndexes:(NSIndexSet *)rowIndexes toPasteboard:(NSPasteboard*)pboard
   {
	NSArray *typeArray = [NSArray arrayWithObjects:ACSDrawPageIntPasteboardType,nil];
	[pboard declareTypes:typeArray owner:self];
	return [pboard setData:[NSKeyedArchiver archivedDataWithRootObject:rowIndexes requiringSecureCoding:NO error:nil] forType:ACSDrawPageIntPasteboardType];
   }

- (NSDragOperation)tableView:(NSTableView*)tabView validateDrop:(id <NSDraggingInfo>)info
				 proposedRow:(int)row proposedDropOperation:(NSTableViewDropOperation)operation
{
    id source = [info draggingSource];
    if ([source isKindOfClass:[LayerTableView class]])
    {
        return NSDragOperationMove;
    }
    else
    {
        if (operation == NSTableViewDropOn)
            return  NSDragOperationNone;
        else
            return NSDragOperationMove;
    }
    return  NSDragOperationNone;
}

-(BOOL)dragPageData:(NSData*)rowData row:(NSInteger)row
{
    NSIndexSet* rowIndexes = [NSKeyedUnarchiver unarchiveObjectWithData:rowData];
    NSUInteger dragRow = [rowIndexes firstIndex];
    GraphicView *graphicView = [windowController inspectingGraphicView];
    row = [graphicView movePageFromIndex:dragRow toIndex:row];
    [(PagesController*)[tableView delegate] selectPageRowWithNoActions:row];
    [tableView reloadData];
    return YES;
}

-(BOOL)dragLayerIndexData:(NSData*)rowData row:(NSInteger)row dragType:(int)dragType
{
    GraphicView *graphicView = [windowController inspectingGraphicView];
    NSIndexSet* rowIndexes = [NSKeyedUnarchiver unarchiveObjectWithData:rowData];
    if (dragType == DRAG_TYPE_SELECTION)
    {
        ACSDLayer *sourceLayer = [graphicView currentEditableLayer];
        ACSDPage *destPage = pageList[row];
        ACSDLayer *destLayer = [destPage currentLayer];
        if (sourceLayer == destLayer)
            return NO;
        NSIndexSet *ixs = [sourceLayer indexesOfSelectedGraphics];
        NSArray *grs = [[sourceLayer selectedGraphics]allObjects];
        [graphicView uSetSelectionForLayer:sourceLayer toObjects:@[]];
        [graphicView moveGraphicsFromLayer:sourceLayer atIndexes:ixs toLayer:destLayer atIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange([[destLayer graphics]count],[ixs count])]];
        [graphicView uSetSelectionForLayer:destLayer toObjects:grs];
        [[graphicView undoManager]setActionName:@"Move Graphics between layers"];
    }
    else
    {
        ACSDPage *sourcePage = [graphicView currentPage];
        ACSDPage *destPage = pageList[row];
        if (sourcePage == destPage)
            return NO;
        __block BOOL success = NO;
        [rowIndexes enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
            if ([[sourcePage layers]count] > 1)
            {
                NSInteger cidx = idx;
                if (cidx >= [[sourcePage layers]count] - 1)
                    cidx--;
                [graphicView setCurrentEditableLayerIndex:cidx force:YES select:NO withUndo:YES];
                [graphicView uMoveLayerAtIndex:idx page:sourcePage toIndex:[[destPage layers]count] page:destPage];
                [[NSNotificationCenter defaultCenter] postNotificationName:ACSDCurrentLayerChanged object:self];
                [[graphicView undoManager]setActionName:@"Move Layer"];
                success = YES;
            }
        }];
        return success;
    }
	[[NSNotificationCenter defaultCenter]postNotificationName:ACSDGraphicListChanged object:self];
    return YES;
}

- (BOOL)tableView:(NSTableView*)aTableView acceptDrop:(id <NSDraggingInfo>)info row:(NSInteger)row dropOperation:(NSTableViewDropOperation)operation
{
    GraphicView *graphicView = [windowController inspectingGraphicView];
    if (!graphicView)
        return NO;
    NSPasteboard* pboard = [info draggingPasteboard];
    NSData* rowData = [pboard dataForType:ACSDrawPageIntPasteboardType];
    if	(rowData)
    {
        [self dragPageData:rowData row:row];
    }
    else
    {
        rowData = [pboard dataForType:ACSDrawLayerIntPasteboardType];
        if (rowData)
        {
            LayerTableView *tv = [info draggingSource];
            [self dragLayerIndexData:rowData row:row dragType:[tv dragType]];
        }
    }
    return YES;
}


@end
