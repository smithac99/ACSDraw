#import "FillListTableSource.h"
#import "ACSDFill.h"

@implementation FillListTableSource
- (id)init
   {
	if (self = [super init])
		fillList = nil;
	return self;
   }

-(void)dealloc
   {
	[fillList release];
	[super dealloc];
   }

- (void)setFillList:(NSMutableArray*)list
{
	if (fillList == list)
		return;
	[fillList release];
	fillList = [list retain];
	[tableView reloadData];
}


- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn
    row:(int)rowIndex
   {
	if (rowIndex >= 0 && rowIndex < (int)[fillList count])
	{
		ACSDFill *f = fillList[rowIndex];
		if ([[aTableColumn identifier]isEqualTo:@"sel"])
			return @([f showIndicator]);
        return f;
	}
    return nil;
   }

- (void)tableView:(NSTableView *)aTableView setObjectValue:anObject forTableColumn:(NSTableColumn *)aTableColumn
    row:(int)rowIndex
   {
    NSParameterAssert(rowIndex >= 0 && rowIndex < (int)[fillList count]);
//	if ([anObject isKindOfClass:[ACSDStroke class]])
//			[fillList replaceObjectAtIndex:rowIndex withObject:anObject];
   }

- (NSInteger)numberOfRowsInTableView:(NSTableView *)aTableView
   {
    if (fillList)
		return [fillList count];
	return 0;
   }

@end
