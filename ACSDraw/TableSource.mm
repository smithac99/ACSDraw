#import "TableSource.h"

@implementation TableSource

-(void)dealloc
   {
	if (objectList)
		[objectList release];
	[super dealloc];
   }

- (void)setObjectList:(NSMutableArray*)list
{
	if (objectList == list)
		return;
	[objectList release];
	objectList = [list retain];
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
