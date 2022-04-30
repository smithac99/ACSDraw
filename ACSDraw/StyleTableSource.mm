#import "StyleTableSource.h"
#import "ACSDStyle.h"
#import "StyleWindowController.h"

@implementation StyleTableSource

- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex
   {
    if(rowIndex >= 0 && rowIndex < [self.objectList count])
	{
		if ([[aTableColumn identifier]isEqualTo:@"style"])
			return [self.objectList[rowIndex]name];
	}
	return nil;
   }

- (void)tableView:(NSTableView *)aTableView setObjectValue:anObject forTableColumn:(NSTableColumn *)aTableColumn
			  row:(NSInteger)rowIndex
   {
    NSParameterAssert(rowIndex >= 0 && rowIndex < [self.objectList count]);
	ACSDStyle *st = self.objectList[rowIndex];
	if ([anObject length] > 0)
		[windowController uSetStyle:st name:anObject];
   }

@end
