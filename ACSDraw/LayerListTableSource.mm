#import "LayerListTableSource.h"
#import "ACSDLayer.h"
#import "ACSDPrefsController.h"
#import "LayerTableView.h"
#import "GraphicView.h"
#import "ViewController.h"
#import "PagesController.h"


@implementation LayerListTableSource

- (id)init
{
	if ((self = [super init]))
		layerList = nil;
	return self;
}

-(void)dealloc
{
	[layerList release];
	[super dealloc];
}

-(NSArray*)layerList
   {
	return layerList;
   }

- (void)setLayerList:(NSMutableArray*)list
{
	if (layerList == list)
		return;
	[layerList release];
	layerList = [list retain];
	[tableView reloadData];
}


- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex
{
	if (rowIndex >= 0 && rowIndex < [layerList count])
	{
		ACSDLayer *l = [layerList objectAtIndex:rowIndex];
		if ([[aTableColumn identifier]isEqualTo:@"name"])
		{
			if ([l isGuideLayer])
			{
				NSDictionary *dict = [NSDictionary dictionaryWithObject:[[ACSDPrefsController sharedACSDPrefsController:nil]guideColour] forKey:NSForegroundColorAttributeName];
				return [[[NSAttributedString alloc]initWithString:[l name] attributes:dict]autorelease];
			}
			else
				return [l name];
		}
		else if ([[aTableColumn identifier]isEqualTo:@"visible"])
			return [NSNumber numberWithBool:[l visible]];
		else if ([[aTableColumn identifier]isEqualTo:@"editable"])
			return [NSNumber numberWithBool:[l editable]];
		else if ([[aTableColumn identifier]isEqualTo:@"sel"])
			return @([l showIndicator]);
	}
	return nil;
}

- (void)tableView:(NSTableView *)aTableView setObjectValue:anObject forTableColumn:(NSTableColumn *)aTableColumn
    row:(int)rowIndex
   {
    NSParameterAssert(rowIndex >= 0 && rowIndex < (int)[layerList count]);
	if ([[aTableColumn identifier]isEqualTo:@"name"])
	   {
		if ([anObject isKindOfClass:[NSString class]])
		   {
		    id o = [layerList objectAtIndex:rowIndex];
			if ([o respondsToSelector:@selector(setName:)])
				[(ACSDLayer*)o setName:anObject];
		   }
	   }
	else if ([[aTableColumn identifier]isEqualTo:@"visible"])
	   {
		if ([anObject isKindOfClass:[NSNumber class]])
			[[layerList objectAtIndex:rowIndex] setLayerVisible:[anObject boolValue]];
	   }
	else if ([[aTableColumn identifier]isEqualTo:@"editable"])
	   {
		if ([anObject isKindOfClass:[NSNumber class]])
			[[layerList objectAtIndex:rowIndex] setEditable:[anObject boolValue]];
	   }
   }

- (NSUInteger)numberOfRowsInTableView:(NSTableView *)aTableView
   {
    if (layerList)
		return [layerList count];
	return 0;
   }


- (BOOL)tableView:(NSTableView *)tableView writeRowsWithIndexes:(NSIndexSet *)rowIndexes toPasteboard:(NSPasteboard*)pboard
   {
	NSArray *typeArray = [NSArray arrayWithObjects:ACSDrawLayerIntPasteboardType,nil];
	[pboard declareTypes:typeArray owner:self];
	return [pboard setData:[NSKeyedArchiver archivedDataWithRootObject:rowIndexes] forType:ACSDrawLayerIntPasteboardType];
   }

- (NSDragOperation)tableView:(NSTableView*)tabView validateDrop:(id <NSDraggingInfo>)info
				 proposedRow:(int)row proposedDropOperation:(NSTableViewDropOperation)operation
   {
	int dragType = [tableView dragType];
	if (dragType == DRAG_TYPE_SELECTION)
	   {
		if (operation == NSTableViewDropOn)
			return  NSDragOperationMove;
		else
			return NSDragOperationNone;
	   }
	if (row == 0 || operation == NSTableViewDropOn)
		return NSDragOperationNone;
	if ([info draggingSource] == tabView)
		return  NSDragOperationMove;
	else
		return  NSDragOperationCopy;
   }

- (BOOL)tableView:(NSTableView*)aTableView acceptDrop:(id <NSDraggingInfo>)info row:(NSInteger)row dropOperation:(NSTableViewDropOperation)operation
   {
	GraphicView *graphicView = [windowController inspectingGraphicView];
	if (!graphicView)
		return NO;
	NSPasteboard* pboard = [info draggingPasteboard];
    NSData* rowData = [pboard dataForType:ACSDrawLayerIntPasteboardType];
    NSIndexSet* rowIndexes = [NSKeyedUnarchiver unarchiveObjectWithData:rowData];
    NSInteger dragRow = [rowIndexes firstIndex];
	if (operation == NSTableViewDropOn)
	   {
		[graphicView moveSelectedGraphicsToLayer:row];
	   }
	else
	   {
		row = [graphicView moveLayerFromIndex:dragRow toIndex:row];
	   }
	[(PagesController*)[tableView delegate] selectLayerRowWithNoActions:row];
	[tableView reloadData];
    [[NSNotificationCenter defaultCenter]postNotificationName:ACSDGraphicListChanged object:self];
	return YES;
   }

@end
