#import "StyleTableSource.h"
#import "ACSDStyle.h"
#import "StyleWindowController.h"

@implementation StyleTableSource

- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(int)rowIndex
   {
    if(rowIndex >= 0 && rowIndex < (int)[objectList count])
	{
		if ([[aTableColumn identifier]isEqualTo:@"style"])
			return [[objectList objectAtIndex:rowIndex]name];
	}
	return nil;
   }

- (void)tableView:(NSTableView *)aTableView setObjectValue:anObject forTableColumn:(NSTableColumn *)aTableColumn
			  row:(int)rowIndex
   {
    NSParameterAssert(rowIndex >= 0 && rowIndex < (int)[objectList count]);
	ACSDStyle *st = [objectList objectAtIndex:rowIndex];
	if ([anObject length] > 0)
		[windowController uSetStyle:st name:anObject];
   }

@end
