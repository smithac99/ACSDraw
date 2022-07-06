#import "ACSDLayer.h"
#import "LayerTableView.h"
#import "LayerListTableSource.h"
#import "SelectionSet.h"

@implementation LayerTableView

+ (id)selectionImage:(int)num
{
    static NSImage *selectionImage = nil;
	if (selectionImage == nil)
        selectionImage = [NSImage imageNamed:@"selectionimage"];
    return selectionImage;
}

- (BOOL)canDragRowsWithIndexes:(NSIndexSet *)rowIndexes atPoint:(NSPoint)mouseDownPoint
{
	NSInteger colInd = [self columnAtPoint:mouseDownPoint];
	dragType = DRAG_TYPE_NORMAL;
	if (colInd == SELECTION_COLUMN)
    {
		NSInteger rowInd = [self rowAtPoint:mouseDownPoint];
		if ([[self selectedRowIndexes]containsIndex:rowInd])
        {
			ACSDLayer *currentLayer = [[(LayerListTableSource*)[self dataSource]layerList]objectAtIndex:rowInd];
			if ([[currentLayer selectedGraphics]count] > 0)
				dragType = DRAG_TYPE_SELECTION;
        }
    }
	return YES;
}

- (NSImage *)dragImageForRowsWithIndexes:(NSIndexSet *)dragRows tableColumns:(NSArray *)tableColumns event:(NSEvent*)dragEvent offset:(NSPointPointer)dragImageOffset
{
	if (dragType == DRAG_TYPE_SELECTION)
		return [LayerTableView selectionImage:1];
	else
		return [super dragImageForRowsWithIndexes:dragRows tableColumns:tableColumns event:dragEvent offset:dragImageOffset];
}

-(int)dragType
{
	return dragType;
}

@end
