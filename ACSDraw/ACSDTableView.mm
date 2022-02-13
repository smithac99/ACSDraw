#import "ACSDTableView.h"
#import "TableViewDelegate.h"
//#import "PanelController.h"
#import "ViewController.h"

@implementation ACSDTableView

- (void)rightMouseDown:(NSEvent *)theEvent
{
	if ([self delegate] && [[self delegate] respondsToSelector:@selector(setRowForContextualMenu:)])
	{
		NSPoint curPoint = [self convertPoint:[theEvent locationInWindow] fromView:nil];
		NSInteger i = [self rowAtPoint:curPoint];
		[(id)[self delegate]setRowForContextualMenu:(int)i];
		[(id)[self delegate]setTableViewForContextualMenu:self];
	}
	[super rightMouseDown:theEvent];
}

-(NSInteger)modifierFlags
{
	return modifierFlags;
}

-(NSInteger)clickedRow
{
	//return clickedRow;
	return [super clickedRow];
}

-(NSInteger)selectedRowPriorToClick
{
	return selectedRowPriorToClick;
}

- (void)mouseDown:(NSEvent *)theEvent
{
	modifierFlags = [theEvent modifierFlags];
	selectedRowPriorToClick = [self selectedRow];
	NSPoint curPoint = [self convertPoint:[theEvent locationInWindow] fromView:nil];
	clickedRow = [self rowAtPoint:curPoint];
	if (!([self delegate] && [[self delegate]respondsToSelector:@selector(handleClickAtPoint:inTableView:)] && [(id<TableViewDelegate>)[self delegate]handleClickAtPoint:curPoint inTableView:self]))
		[super mouseDown:theEvent];
}

-(void)reloadRowAtIndex:(NSInteger)rowIndex
{
	[self reloadDataForRowIndexes:[NSIndexSet indexSetWithIndex:rowIndex] columnIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, [[self tableColumns]count]-1)]];
}

-(void)reDisplayRow:(NSInteger)row
{
	NSRect r = NSZeroRect;
	for (int i = 0;i < [self numberOfColumns];i++)
		r = NSUnionRect(r,[self frameOfCellAtColumn:i row:row]);
	[self setNeedsDisplayInRect:r];
}

-(void)reDisplayRow:(NSInteger)row column:(NSInteger)col
{
	[self setNeedsDisplayInRect:[self frameOfCellAtColumn:col row:row]];
}

- (void)drawRow:(NSInteger)rowIndex clipRect:(NSRect)clipRect
{
	[super drawRow:rowIndex clipRect:clipRect];
	if ([self delegate] && [[self delegate] respondsToSelector:@selector(displayRowForContextualMenu)])
	{
		int row = [(id<TableViewDelegate>)[self delegate] displayRowForContextualMenu];
		if (row != rowIndex)
			return;
		NSRect r = NSInsetRect([self rectOfRow:row],2.0,2.0);
		[[NSColor blueColor] set];
		[NSBezierPath setDefaultLineWidth:4.0];
		[NSBezierPath strokeRect:r];
		
	}
}

-(void)refreshSelectionIndicatorForRow:(NSInteger)row
{
	NSInteger col = [self columnWithIdentifier:@"sel"];
	if (col > -1 && row > -1)
		[self reDisplayRow:row column:col];
}

#pragma mark -

-(void)editNextColumn
{
    NSInteger row = [self editedRow];
    NSInteger col = [self editedColumn];
    if (col < [self numberOfColumns]-1)
        [self editColumn:col + 1 row:row withEvent:nil select:YES];
    else if (row < [self numberOfRows] - 1)
    {
        [self selectRowIndexes:[NSIndexSet indexSetWithIndex:row + 1] byExtendingSelection:NO];
        [self editColumn:0 row:row + 1 withEvent:nil select:YES];
    }
}

-(void)editPrevColumn
{
    NSInteger row = [self editedRow];
    NSInteger col = [self editedColumn];
    if (col > 0)
        [self editColumn:col - 1 row:row withEvent:nil select:YES];
    else if (row > 0)
    {
        [self selectRowIndexes:[NSIndexSet indexSetWithIndex:row - 1] byExtendingSelection:NO];
        [self editColumn:[self numberOfColumns]-1 row:row - 1 withEvent:nil select:YES];
    }
}

-(void)editNextRow
{
    NSInteger row = [self editedRow];
    NSInteger col = [self editedColumn];
    if (row < [self numberOfRows] - 1)
    {
        [self selectRowIndexes:[NSIndexSet indexSetWithIndex:row + 1] byExtendingSelection:NO];
        [self editColumn:col row:row + 1 withEvent:nil select:YES];
    }
}

-(void)editPrevRow
{
    NSInteger row = [self editedRow];
    NSInteger col = [self editedColumn];
    if (row > 0)
    {
        [self selectRowIndexes:[NSIndexSet indexSetWithIndex:row - 1] byExtendingSelection:NO];
        [self editColumn:col row:row - 1 withEvent:nil select:YES];
    }
}

@end
