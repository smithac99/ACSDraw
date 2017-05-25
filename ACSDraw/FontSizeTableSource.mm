#import "FontSizeTableSource.h"

@implementation FontSizeTableSource

- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(int)rowIndex
{
	if (rowIndex >= 0 && rowIndex < [objectList count])
		return [objectList objectAtIndex:rowIndex];
	return nil;
}


@end
