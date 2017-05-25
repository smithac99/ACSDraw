#import "StrokeListTableSource.h"
#import "ACSDStroke.h"

@implementation StrokeListTableSource

- (id)init
   {
	if (self = [super init])
		strokeList = nil;
	return self;
   }

-(void)dealloc
{
	[strokeList release];
	[super dealloc];
}

- (void)setStrokeList:(NSMutableArray*)list
{
	if (strokeList == list)
		return;
	[strokeList release];
	strokeList = [list retain];
	[tableView reloadData];
}


- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex
{
	if (rowIndex >= 0 && rowIndex < [strokeList count])
	{
		ACSDStroke *stroke = [strokeList objectAtIndex:rowIndex];
		if ([[aTableColumn identifier]isEqualTo:@"stroke"])
			return stroke;
		else if ([[aTableColumn identifier]isEqualTo:@"linewidth"])
		{
			if ([stroke showIndicator] > 0)
				return [NSNumber numberWithFloat:-[stroke lineWidth]];
			else
				return [NSNumber numberWithFloat:[stroke lineWidth]];
		}
	}
    return nil;
}

- (void)tableView:(NSTableView *)aTableView setObjectValue:anObject forTableColumn:(NSTableColumn *)aTableColumn
    row:(int)rowIndex
   {
    //NSParameterAssert(rowIndex >= 0 && rowIndex < (int)[strokeList count]);
	ACSDStroke *stroke = [strokeList objectAtIndex:rowIndex];
	if (!stroke)
		return;
	if ([[aTableColumn identifier]isEqualTo:@"linewidth"])
		[stroke changeLineWidth:fabs([anObject floatValue]) view:nil];
   }

- (NSInteger)numberOfRowsInTableView:(NSTableView *)aTableView
   {
    if (strokeList)
		return [strokeList count];
	return 0;
   }

@end
