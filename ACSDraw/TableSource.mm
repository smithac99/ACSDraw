#import "TableSource.h"

@implementation TableSource

- (void)setObjectList:(NSMutableArray*)list
{
	if (_objectList == list)
		return;
	_objectList = list;
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
	
@end
