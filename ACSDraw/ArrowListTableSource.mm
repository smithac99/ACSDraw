#import "ArrowListTableSource.h"
#import "ACSDGraphic.h"
#import "ACSDLineEnding.h"
#import "StrokePanelController.h"

@implementation ArrowListTableSource
- (id)init
{
	if (self = [super init])
		self.arrowList = nil;
	return self;
}


- (void)setArrowList:(NSMutableArray*)list
{
	if (_arrowList == list)
		return;
	_arrowList = list;
	[tableView reloadData];
}


- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn
            row:(int)rowIndex
{
    if(!(rowIndex >= 0 && rowIndex < (int)[_arrowList count]))
        return nil;
    ACSDLineEnding *le = _arrowList[rowIndex];
    if ([[aTableColumn identifier]isEqualTo:@"lineEnding"])
        return le;
    else if ([[aTableColumn identifier]isEqualTo:@"offset"])
        return @([le offset]);
    else if ([[aTableColumn identifier]isEqualTo:@"scale"])
        return @([le scale]);
    else if ([[aTableColumn identifier]isEqualTo:@"aspect"])
        if ([le showIndicator] > 0)
            return @(-[le aspect]);
        else
            return @([le aspect]);
    return nil;
}

- (void)tableView:(NSTableView *)aTableView setObjectValue:anObject forTableColumn:(NSTableColumn *)aTableColumn
              row:(int)rowIndex
{
    if(!(rowIndex >= 0 && rowIndex < (int)[_arrowList count]))
        return;
    ACSDLineEnding *le = _arrowList[rowIndex];
    if (!le)
        return;
    if ([[aTableColumn identifier]isEqualTo:@"scale"])
        [le setScale:[anObject floatValue]];
    else if ([[aTableColumn identifier]isEqualTo:@"offset"])
        [le setOffset:[anObject floatValue]];
    else if ([[aTableColumn identifier]isEqualTo:@"aspect"])
        [le setAspect:fabs([anObject floatValue])];
    [((StrokePanelController*)windowController) refreshStrokes];
}

- (NSInteger)numberOfRowsInTableView:(NSTableView *)aTableView
   {
    if (_arrowList)
		return [_arrowList count];
	return 0;
   }

@end
