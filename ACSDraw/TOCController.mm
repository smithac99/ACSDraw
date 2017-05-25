#import "TOCController.h"
#import "MainWindowController.h"
#import "TableSource.h"
#import "ACSDStyle.h"

@implementation TOCController

- (id)initWithController:(MainWindowController*)cont
{
	if (self = [super init])
	{
		controller = cont;
		[[NSBundle mainBundle]loadNibNamed:@"TocPanel" owner:self topLevelObjects:nil];
		keepStyles = [[NSMutableArray arrayWithCapacity:10]retain];
	}
	return self;
}

-(void)dealloc
{
	[keepStyles release];
	self.tocSheet = nil;
	self.tocStyleSource = nil;
	self.allStyleSource = nil;
	[super dealloc];
}
	
- (IBAction)mapMenuHitHit:(id)sender
   {
	NSInteger row = [[_tocStyleSource tableView]selectedRow];
	if (row == -1)
		return;
	NSInteger mRow = [sender indexOfSelectedItem];
	NSMutableArray *arr = [[_tocStyleSource objectList]objectAtIndex:[[_tocStyleSource tableView]selectedRow]];
	if ([keepStyles objectAtIndex:mRow] != [arr objectAtIndex:1])
	{
		[arr replaceObjectAtIndex:1 withObject:[keepStyles objectAtIndex:mRow]];
		[[_tocStyleSource tableView]reloadData];
	}	
   }

- (void)tableViewSelectionDidChange:(NSNotification *)aNotification
{
	NSInteger row = [[_tocStyleSource tableView]selectedRow];
	if (row == -1)
		return;
	NSUInteger ind = [keepStyles indexOfObjectIdenticalTo:[[[_tocStyleSource objectList]objectAtIndex:row]objectAtIndex:1]];
	if (ind != NSNotFound && ind != (unsigned)[mapMenu indexOfSelectedItem])
	{
		[mapMenu selectItemAtIndex:ind];
	}
}

- (IBAction)allToTOCButtonHit:(id)sender
   {
	NSInteger row = [[_allStyleSource tableView]selectedRow];
	if (row == -1)
		return;
	NSMutableArray *arr = [NSMutableArray arrayWithCapacity:2];
	[arr addObject:[[_allStyleSource objectList] objectAtIndex:row]];
	[arr addObject:[[_allStyleSource objectList] objectAtIndex:row]];
	[[_tocStyleSource objectList]addObject:arr];
	[[_allStyleSource objectList]removeObjectAtIndex:row];
	[[_allStyleSource tableView]reloadData];
	[[_tocStyleSource tableView]reloadData];
   }

- (IBAction)TOCToAllButtonHit:(id)sender
   {
	NSInteger row = [[_tocStyleSource tableView]selectedRow];
	if (row == -1)
		return;
	[[_allStyleSource objectList]addObject:[[[_tocStyleSource objectList] objectAtIndex:row]objectAtIndex:0]];
	[[_tocStyleSource objectList]removeObjectAtIndex:row];
	[[_allStyleSource tableView]reloadData];
	[[_tocStyleSource tableView]reloadData];
   }

- (IBAction)closeTOCSheet: (id)sender
   {
	[controller generateTocUsingStyles:[_tocStyleSource objectList]];
	[NSApp endSheet:_tocSheet returnCode:[sender tag]];
   }

-(void)setStyles:(NSArray*)styles
{
	NSUInteger ct = [styles count];
	NSMutableArray *s = [NSMutableArray arrayWithCapacity:ct];
	while ([mapMenu numberOfItems] > 0)
		[mapMenu removeItemAtIndex:0];
	[keepStyles removeAllObjects];
	for (unsigned i = 0;i < ct;i++)
	{
		[s addObject:[styles objectAtIndex:i]];
		[keepStyles addObject:[styles objectAtIndex:i]];
		[mapMenu addItemWithTitle:[[styles objectAtIndex:i]name]];
	}
	[_allStyleSource setObjectList:s];
	[_tocStyleSource setObjectList:[NSMutableArray arrayWithCapacity:10]];
}
@end
