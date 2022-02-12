#import "TableSource.h"

@implementation TableSource

- (void)setObjectList:(NSMutableArray*)list
{
	if (objectList == list)
		return;
	objectList = list;
	[tableView reloadData];
}

- (NSInteger)numberOfRowsInTableView:(NSTableView *)aTableView
{
    if ([self objectList])
		return [[self objectList] count];
	return 0;
}

-(NSTableView*)tableView
{
	return tableView;
}
	
-(NSMutableArray*)objectList
{
	return objectList;
}


@end
