//
//  TOCTableSource.mm
//  ACSDraw
//
//  Created by alan on 28/01/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "TOCTableSource.h"
#import "ACSDStyle.h"
#import "StyleWindowController.h"


@implementation TOCTableSource

- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(int)rowIndex
   {
    NSParameterAssert(rowIndex >= 0 && rowIndex < (int)[objectList count]);
	NSArray *arr = [objectList objectAtIndex:rowIndex];
	if ([[aTableColumn identifier]isEqualTo:@"style"])
		return [[arr objectAtIndex:0]name];
	if ([[aTableColumn identifier]isEqualTo:@"map"])
		return [[arr objectAtIndex:1]name];
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
