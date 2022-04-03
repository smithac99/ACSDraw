#import "FontSizeTableSource.h"

@implementation FontSizeTableSource

- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(int)rowIndex
{
	if (rowIndex >= 0 && rowIndex < [self.objectList count])
		return self.objectList[rowIndex];
	return nil;
}


@end
