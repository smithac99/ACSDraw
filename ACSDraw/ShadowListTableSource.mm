#import "ShadowListTableSource.h"
#import "ShadowType.h"

@implementation ShadowListTableSource

- (id)init
   {
	if (self = [super init])
		shadowList = nil;
	return self;
   }

-(void)dealloc
{
	[shadowList release];
	[super dealloc];
}

- (void)setShadowList:(NSMutableArray*)list
{
	if (shadowList == list)
		return;
	[shadowList release];
	shadowList = [list retain];
	[tableView reloadData];
}


- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn
			row:(NSInteger)rowIndex
{
	if(rowIndex < 0 || rowIndex >= [shadowList count])
		return nil;
	ShadowType *sType = [shadowList objectAtIndex:rowIndex];
	if ([[aTableColumn identifier]isEqualTo:@"shadow"])
		return sType;
	else if ([[aTableColumn identifier]isEqualTo:@"radius"])
		return @([sType blurRadius]);
	else if ([[aTableColumn identifier]isEqualTo:@"xoff"])
		return @([sType xOffset]);
	else if ([[aTableColumn identifier]isEqualTo:@"yoff"])
		return @([sType yOffset]);
	else if ([[aTableColumn identifier]isEqualTo:@"sel"])
		return @([sType showIndicator]);
	return nil;
}

- (void)tableView:(NSTableView *)aTableView setObjectValue:anObject forTableColumn:(NSTableColumn *)aTableColumn
			  row:(int)rowIndex
{
	if(rowIndex < 0 || rowIndex >= [shadowList count])
		return;
	ShadowType *sType = [shadowList objectAtIndex:rowIndex];
	if (![sType itsShadow])
		return;
	if ([[aTableColumn identifier]isEqualTo:@"radius"])
		[sType setBlurRadius:[anObject floatValue]];
	else if ([[aTableColumn identifier]isEqualTo:@"xoff"])
		[sType setOffset:NSMakeSize([anObject floatValue],[sType yOffset])];
	else if ([[aTableColumn identifier]isEqualTo:@"yoff"])
		[sType setOffset:NSMakeSize([sType xOffset],[anObject floatValue])];
}

- (NSInteger)numberOfRowsInTableView:(NSTableView *)aTableView
   {
    if (shadowList)
		return [shadowList count];
	return 0;
   }

@end
