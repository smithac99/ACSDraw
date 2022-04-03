#import "FontFamilyTableSource.h"

@implementation FontFamilyTableSource

- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex
{
	if (rowIndex >= 0 && rowIndex < [self.objectList count])
		return self.objectList[rowIndex];
	return nil;
}


@end
