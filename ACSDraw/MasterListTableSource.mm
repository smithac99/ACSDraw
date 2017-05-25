#import "MasterListTableSource.h"

@implementation MasterListTableSource

- (NSInteger)numberOfRowsInTableView:(NSTableView *)aTableView
   {
    if (masterList)
		return [masterList count];
	return 0;
   }

-(NSArray*)masterList
   {
	return masterList;
   }

- (void)setMasterList:(NSMutableArray*)list
{
	if (masterList == list)
		return;
	[masterList release];
	masterList = [list retain];
	[tableView reloadData];
}


@end
